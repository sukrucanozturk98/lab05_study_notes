// Part 7: your own tests (at least 2, besides the example). They must test real code.
// Ideas: a 100-character title is accepted; body is trimmed; 'network-request-failed';
// signUp failure with whenCalling(...).thenThrow(...) (see lab05_test.dart).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab05_study_notes/data/auth_repository.dart';
import 'package:lab05_study_notes/data/notes_repository.dart';
import 'package:lab05_study_notes/models/note.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  // Create one fake first: it makes FieldValue.serverTimestamp() work in tests.
  setUpAll(FakeFirebaseFirestore.new);

  test('example: messageFor maps weak-password', () {
    expect(AuthRepository.messageFor('weak-password'), contains('6 characters'));
  });

  test('addNote accepts a 100-character title and trims the body', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db);
    final exact100Title = 'a' * 100;

    await repo.addNote('u1', '  $exact100Title  ', '  trimmed body text  ');
    final notes = await repo.watchNotes('u1').first;

    expect(notes, hasLength(1));
    expect(notes.single.title, exact100Title);
    expect(notes.single.title.length, 100);
    expect(notes.single.body, 'trimmed body text');
  });

  test('signUp failure becomes an AuthFailure with friendly message and messageFor maps network-request-failed', () async {
    expect(
      AuthRepository.messageFor('network-request-failed'),
      'No connection. Check your network.',
    );

    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
        .on(auth)
        .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    final repo = AuthRepository(auth);

    await expectLater(
      repo.signUp('ada@agu.edu.tr', 'secret123'),
      throwsA(
        isA<AuthFailure>().having(
          (f) => f.message,
          'message',
          'An account already exists for this email.',
        ),
      ),
    );
  });

  test('Note.fromFirestore throws FormatException when body is not a String', () {
    expect(
      () => Note.fromFirestore('n1', {'title': 'Valid title', 'body': 123}),
      throwsFormatException,
    );
  });
}
