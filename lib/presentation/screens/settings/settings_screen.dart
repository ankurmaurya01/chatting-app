import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out of Whisper?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (route) => false);
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // Theme Section
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
            child: Text(
              "APPEARANCE & THEME",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded),
            title: const Text("Theme Mode"),
            subtitle: Text(
              themeProvider.themeMode == ThemeMode.system
                  ? "System Default"
                  : themeProvider.themeMode == ThemeMode.dark
                      ? "Dark Mode"
                      : "Light Mode",
            ),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text("System")),
                DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark")),
              ],
              onChanged: (mode) {
                if (mode != null) themeProvider.setThemeMode(mode);
              },
            ),
          ),

          // Bubble Color Customizer
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text("Chat Bubble Color"),
            subtitle: const Text("Select primary color for sent message bubbles"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: AppColors.customBubbleColors.map((color) {
                final isSelected = themeProvider.bubbleColor.value == color.value;
                return GestureDetector(
                  onTap: () => themeProvider.setBubbleColor(color),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Wallpaper Palette
          ListTile(
            leading: const Icon(Icons.wallpaper_rounded),
            title: const Text("Chat Wallpaper Background"),
            subtitle: const Text("Choose background tint for chats"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: AppColors.wallpaperColors.map((color) {
                final isSelected = themeProvider.chatWallpaperColor.value == color.value;
                return GestureDetector(
                  onTap: () => themeProvider.setChatWallpaper(color),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color == Colors.transparent ? Theme.of(context).cardColor : color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: color == Colors.transparent
                        ? const Center(child: Text("None", style: TextStyle(fontSize: 10)))
                        : isSelected
                            ? Icon(Icons.check, size: 20, color: Theme.of(context).primaryColor)
                            : null,
                  ),
                );
              }).toList(),
            ),
          ),

          // Font Size Slider
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              "CHAT TEXT SIZE",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.format_size_rounded),
            title: const Text("Message Font Size"),
            subtitle: Slider(
              value: themeProvider.fontSizeDelta,
              min: -2.0,
              max: 3.0,
              divisions: 5,
              label: themeProvider.fontSizeDelta == 0.0
                  ? "Standard"
                  : themeProvider.fontSizeDelta < 0
                      ? "Small"
                      : "Large",
              onChanged: (val) => themeProvider.setFontSizeDelta(val),
            ),
          ),

          // Privacy & Security
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              "PRIVACY & SECURITY",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security_rounded),
            title: const Text("Privacy & Security"),
            subtitle: const Text("App lock, biometrics, read receipts, online presence"),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacySettings),
          ),

          // Account Logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => _showLogoutDialog(context, auth),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
