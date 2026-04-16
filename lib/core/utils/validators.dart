class Validators {
  static String? validateApiKey(String value) {
    if (value.trim().isEmpty) {
      return 'API key dite hobe.';
    }

    if (value.trim().length < 10) {
      return 'API key ta thik mone hocche na.';
    }

    return null;
  }
}
