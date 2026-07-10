class Validators {
  static String? validateApiKey(String value) {
    if (value.trim().isEmpty) {
      return 'API key is required.'
    }

    if (value.trim().length < 10) {
      return 'The API key doesn't look valid.'
    }

    return null;
  }
}
