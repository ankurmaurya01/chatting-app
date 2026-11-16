import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/privacy_provider.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  void _showSetPinDialog(BuildContext context, PrivacyProvider privacyProvider, bool isTwoStep) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTwoStep ? "Set Two-Step PIN" : "Set App Lock PIN"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: "Enter 4 to 6 digit PIN",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length >= 4) {
                if (isTwoStep) {
                  privacyProvider.setTwoStepPin(pin);
                } else {
                  privacyProvider.setAppLockPin(pin);
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isTwoStep ? "Two-step PIN configured" : "App Lock PIN enabled")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final privacyProvider = Provider.of<PrivacyProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pSettings = user.privacySettings;

    return Scaffold(
      appBar: AppBar(title: const Text("Privacy & Security")),
      body: ListView(
        children: [
          // Activity & Status
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
            child: Text(
              "PRESENCE & ACTIVITY",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text("Hide Online Status"),
            subtitle: const Text("Don't show when you are actively using Whisper"),
            value: pSettings.hideOnline,
            onChanged: (val) {
              final updated = pSettings.copyWith(hideOnline: val);
              privacyProvider.updatePrivacySettings(user.id, updated);
              auth.refreshCurrentUser();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.history_toggle_off_rounded),
            title: const Text("Hide Last Seen"),
            subtitle: const Text("Keep your last active timestamp private"),
            value: pSettings.hideLastSeen,
            onChanged: (val) {
              final updated = pSettings.copyWith(hideLastSeen: val);
              privacyProvider.updatePrivacySettings(user.id, updated);
              auth.refreshCurrentUser();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.done_all_rounded),
            title: const Text("Read Receipts"),
            subtitle: const Text("If turned off, you won't send or see read receipts"),
            value: pSettings.readReceipts,
            onChanged: (val) {
              final updated = pSettings.copyWith(readReceipts: val);
              privacyProvider.updatePrivacySettings(user.id, updated);
              auth.refreshCurrentUser();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.edit_note_rounded),
            title: const Text("Typing Indicators"),
            subtitle: const Text("Broadcast when you are writing a message"),
            value: pSettings.typingIndicators,
            onChanged: (val) {
              final updated = pSettings.copyWith(typingIndicators: val);
              privacyProvider.updatePrivacySettings(user.id, updated);
              auth.refreshCurrentUser();
            },
          ),

          const Divider(),

          // Security Lock Section
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              "APP LOCK & BIOMETRICS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline_rounded),
            title: const Text("App Lock with PIN"),
            subtitle: const Text("Require PIN to open Whisper"),
            value: privacyProvider.isAppLockEnabled,
            onChanged: (val) {
              if (val) {
                _showSetPinDialog(context, privacyProvider, false);
              } else {
                privacyProvider.disableAppLock();
              }
            },
          ),
          if (privacyProvider.isAppLockEnabled && privacyProvider.canCheckBiometrics)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text("Unlock with Fingerprint"),
              subtitle: const Text("Use biometric scan instead of PIN"),
              value: privacyProvider.isBiometricsEnabled,
              onChanged: (val) {
                privacyProvider.setBiometricsEnabled(val);
              },
            ),
          SwitchListTile(
            secondary: const Icon(Icons.pin_outlined),
            title: const Text("Two-Step Verification"),
            subtitle: const Text("Require a secure PIN when registering or logging in"),
            value: privacyProvider.isTwoStepEnabled,
            onChanged: (val) {
              if (val) {
                _showSetPinDialog(context, privacyProvider, true);
              } else {
                privacyProvider.disableTwoStep();
              }
            },
          ),

          const Divider(),

          // Blocked Accounts
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              "ACCOUNT MANAGEMENT",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Colors.red),
            title: const Text("Blocked Contacts"),
            subtitle: const Text("Manage blocked user accounts"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, AppRoutes.blockedUsers),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
