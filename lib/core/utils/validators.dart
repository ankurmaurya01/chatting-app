class Validators {
  // 1. Username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Username is required.";
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return "Username must be at least 3 characters.";
    }
    if (trimmed.length > 25) {
      return "Username cannot exceed 25 characters.";
    }
    final regex = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!regex.hasMatch(trimmed)) {
      return "Only letters, numbers, periods and underscores allowed.";
    }
    return null;
  }

  // 2. Full Name
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Full name is required.";
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return "Full name is too short.";
    }
    return null;
  }

  // 3. Mobile Number
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Mobile number is required.";
    }
    final clean = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final regex = RegExp(r'^\+?[1-9]\d{6,14}$');
    if (!regex.hasMatch(clean)) {
      return "Enter a valid international phone number (e.g. +1234567890).";
    }
    return null;
  }

  // 4. Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email address is required.";
    }
    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    if (!regex.hasMatch(value.trim())) {
      return "Please enter a valid email address.";
    }
    return null;
  }

  // 5. Date of Birth
  static String? validateDob(DateTime? date) {
    if (date == null) {
      return "Date of birth is required.";
    }
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return "Date of birth cannot be in the future.";
    }
    // Age check (minimum 13 years old)
    final age = now.year - date.year - ((now.month < date.month || (now.month == date.month && now.day < date.day)) ? 1 : 0);
    if (age < 13) {
      return "You must be at least 13 years old to use Whisper.";
    }
    if (age > 120) {
      return "Please enter a valid date of birth.";
    }
    return null;
  }

  // 6. Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required.";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters.";
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return "Must include at least one uppercase letter.";
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return "Must include at least one lowercase letter.";
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return "Must include at least one number.";
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return "Must include at least one special character.";
    }
    return null;
  }

  // 7. Confirm Password
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password.";
    }
    if (value != originalPassword) {
      return "Passwords do not match.";
    }
    return null;
  }
}
