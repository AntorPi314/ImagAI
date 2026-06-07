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

  /// Returns error string if rate limited, null if ok
  String? checkRateLimit() {
    final now = DateTime.now();
    _sentTimes.removeWhere((t) => now.difference(t).inSeconds >= 60);
    if (_sentTimes.length >= _maxPerMinute) {
      return 'প্রতি মিনিটে সর্বোচ্চ $_maxPerMinute টি message পাঠানো যাবে।';
    }
    return null;
  }

  Future<String?> sendMessage(String text) async {
    final user = currentUser;
    if (user == null || text.trim().isEmpty) return null;

    // Word limit check (200 words)
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    if (wordCount > 200) {
      return '200 word এর বেশি message পাঠানো যাবে না। (বর্তমান: $wordCount)';
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

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}