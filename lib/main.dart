import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'firebase_options.dart';

<<<<<<< HEAD
import 'app.dart';

void main() {
  runApp(const ImagAIApp());
}
=======
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SharedPreferences.getInstance();
  runApp(const ImagAIApp());
}
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2
