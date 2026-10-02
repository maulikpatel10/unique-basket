class AppValidators {
  static bool isValidIndianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return true;
    }
    if (cleaned.length == 12 && cleaned.startsWith('91') && RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned.substring(2))) {
      return true;
    }
    return false;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter mobile number';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) {
      return 'Enter valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8 or 9';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter OTP';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 4 && cleaned.length != 6) {
      return 'OTP must be 4 digits';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(trimmed)) {
      return 'Please enter a valid name';
    }
    return null;
  }

  static String? validateFullAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter full address';
    }
    final trimmed = value.trim();
    if (trimmed.length < 4) {
      return 'Address must be at least 4 characters';
    }
    return null;
  }

  static String? validateAreaLocality(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter area / locality';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Area must be at least 3 characters';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter city';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'City must be at least 2 characters';
    }
    return null;
  }

  static String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter state';
    }
    return null;
  }

  static bool isValidPinCodeFormat(String? value) {
    if (value == null) return false;
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    return cleaned.length == 6;
  }

  static String? validatePinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter PIN code';
    }
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 6) {
      return 'PIN code must be 6 digits';
    }
    return null;
  }
}
