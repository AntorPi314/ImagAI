class Validators {
  static String? validateApiKey(String value) {
    if (value.trim().isEmpty) {
<<<<<<< HEAD
      return 'API key dite hobe.';
    }

    if (value.trim().length < 10) {
      return 'API key ta thik mone hocche na.';
=======
      return 'API key is required.'
    }

    if (value.trim().length < 10) {
      return 'The API key doesn't look valid.'
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
    }

    return null;
  }
}
