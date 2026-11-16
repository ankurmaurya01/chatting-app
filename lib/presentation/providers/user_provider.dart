import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  List<UserModel> _contacts = [];
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get contacts => _contacts;
  List<UserModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load Initial Contacts List
  Future<void> loadRecentContacts(String currentUserId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _contacts = await _userService.getRecentContacts(currentUserId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search Contacts by Username, Phone or Email
  Future<void> searchUsers(String query, String currentUserId) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      _searchResults = await _userService.searchUsers(query, currentUserId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // Update Profile
  Future<bool> updateProfile({
    required String userId,
    required String fullName,
    required String bio,
    required DateTime dob,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _userService.updateProfile(
        userId: userId,
        fullName: fullName,
        bio: bio,
        dob: dob,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
