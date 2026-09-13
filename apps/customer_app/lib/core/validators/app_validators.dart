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
    if (cleaned.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }
}
