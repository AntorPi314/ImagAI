import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/chat_message_model.dart';

class ChatController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  // Rate limit tracking (1 min = 5 messages)
  final List<DateTime> _sentTimes = [];
  static const int _maxPerMinute = 5;
  static const int _maxMessages = 250;

  User? get currentUser => _auth.currentUser;

  String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  Stream<List<ChatMessageModel>> messagesStream() {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((s) => s.docs.map(ChatMessageModel.fromDoc).toList());
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Sign up a brand-new user with email/password + display name.
  /// Throws [FirebaseAuthException] on failure — caller should catch it
  /// and use [authErrorMessage] to show a friendly message.
  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user != null && name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }
    return _auth.currentUser;
  }

  /// Sign in an existing user with email/password.
  /// Throws [FirebaseAuthException] on failure.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  /// Sends a password-reset email. Throws [FirebaseAuthException] on failure.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Maps common [FirebaseAuthException] codes to friendly English
  /// messages for display in the UI.
  String authErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email. Please login.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'user-not-found':
          return 'No account found with this email. Please sign up.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return error.toString();
  }

  /// Returns error string if rate limited, null if ok
  String? checkRateLimit() {
    final now = DateTime.now();
    _sentTimes.removeWhere((t) => now.difference(t).inSeconds >= 60);
    if (_sentTimes.length >= _maxPerMinute) {
      return 'You can send a maximum of $_maxPerMinute messages per minute.';
    }
    return null;
  }

  Future<String?> sendMessage(String text) async {
    final user = currentUser;
    if (user == null || text.trim().isEmpty) return null;

    // Word limit check (200 words)
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    if (wordCount > 200) {
      return 'Message cannot exceed 200 words. (Current: $wordCount)';
    }

    // Rate limit check
    final rateError = checkRateLimit();
    if (rateError != null) return rateError;

    final name = user.displayName ?? user.email ?? 'User';
    await _firestore.collection('messages').add({
      'uid': user.uid,
      'name': name,
      'initials': initials(name),
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'reportedBy': <String>[],
    });

    _sentTimes.add(DateTime.now());

    // Auto cleanup if over 250 messages
    await _autoCleanup();

    return null;
  }

  Future<void> _autoCleanup() async {
    final snapshot = await _firestore
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();

    final total = snapshot.docs.length;
    if (total <= _maxMessages) return;

    // Delete oldest messages, keep last 200
    final toDelete = snapshot.docs.take(total - 200).toList();
    final batch = _firestore.batch();
    for (final doc in toDelete) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
  }

  Future<String?> reportMessage(String messageId, String currentUid) async {
    final docRef = _firestore.collection('messages').doc(messageId);

    try {
      final snap = await docRef.get();
      if (!snap.exists) return 'Message not found.';

      final data = snap.data() as Map<String, dynamic>;
      final reportedBy = List<String>.from(data['reportedBy'] ?? []);

      if (reportedBy.contains(currentUid)) {
        return 'You have already reported this message.';
      }

      reportedBy.add(currentUid);

      // Step 1: update reportedBy first (allowed by update rule)
      await docRef.update({'reportedBy': reportedBy});

      // Step 2: if 2+ reports now, delete (allowed by delete rule since resource already has 2+)
      if (reportedBy.length >= 2) {
        await docRef.delete();
      }

      return null;
    } catch (e) {
      return 'Failed to report message: $e';
    }
  }

  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
