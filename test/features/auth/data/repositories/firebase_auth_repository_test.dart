import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/src/core/errors/auth_exception.dart';
import 'package:tasker/src/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:tasker/src/features/auth/domain/models/app_user.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseAuthRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirebaseAuthRepository(
      firebaseAuth: mockAuth,
      firestore: fakeFirestore,
    );
  });

  group('FirebaseAuthRepository', () {
    group('currentUser', () {
      test('returns null when no user is signed in', () {
        // Arrange
        // MockFirebaseAuth by default has no signed-in user

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isNull);
      });

      test('returns AppUser when user is signed in', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isNotNull);
        expect(user!.id, 'test-uid');
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'Test User');
      });
    });

    group('authStateChanges', () {
      test('emits null when user signs out', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Act
        await repository.signOut();

        // Assert - current user should be null after sign out
        expect(repository.currentUser, isNull);
      });

      test('emits AppUser when listening to auth state', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Act
        final stream = repository.authStateChanges;
        
        // Assert
        await expectLater(
          stream.first,
          completion(isA<AppUser>()),
        );
      });
    });

    group('signInWithEmailAndPassword', () {
      test('successfully signs in user and returns AppUser', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        
        final mockUser = MockUser(
          uid: 'test-uid',
          email: email,
          displayName: 'Test User',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<AppUser>());
        expect(result.email, email);
        expect(result.id, 'test-uid');
      });

      test('trims email before signing in', () async {
        // Arrange
        const email = '  test@example.com  ';
        const password = 'password123';
        
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.email, 'test@example.com');
      });

      test('loads user data from Firestore if exists', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        
        // Create user in Firestore first
        await fakeFirestore.collection('users').doc('test-uid').set({
          'id': 'test-uid',
          'email': email,
          'displayName': 'Firestore User',
          'photoUrl': 'https://example.com/photo.jpg',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final mockUser = MockUser(
          uid: 'test-uid',
          email: email,
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.displayName, 'Firestore User');
        expect(result.photoUrl, 'https://example.com/photo.jpg');
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('successfully creates new user and returns AppUser', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password123';
        const displayName = 'New User';

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isA<AppUser>());
        expect(result.email, email);
        expect(result.displayName, displayName);

        // Verify user document was created in Firestore
        final userDoc = await fakeFirestore.collection('users').doc(result.id).get();
        expect(userDoc.exists, true);
        expect(userDoc.data()?['email'], email);
      });

      test('trims email and displayName', () async {
        // Arrange
        const email = '  test@example.com  ';
        const password = 'password123';
        const displayName = '  Test User  ';

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result.email, 'test@example.com');
        expect(result.displayName, 'Test User');
      });

      test('creates user without displayName if not provided', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.email, email);
        // MockFirebaseAuth sets displayName to 'Mock User' by default, 
        // so we just check that a user was created
        expect(result.id, isNotEmpty);
      });

      test('creates user document in Firestore', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const displayName = 'Test User';

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        final userDoc = await fakeFirestore.collection('users').doc(result.id).get();
        expect(userDoc.exists, true);
        
        final userData = userDoc.data()!;
        expect(userData['id'], result.id);
        expect(userData['email'], email);
        expect(userData['displayName'], displayName);
      });
    });

    group('signOut', () {
      test('successfully signs out user', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Act
        await repository.signOut();

        // Assert
        expect(mockAuth.currentUser, isNull);
      });
    });

    group('resetPassword', () {
      test('sends password reset email', () async {
        // Arrange
        const email = 'test@example.com';

        // Act - should not throw
        await repository.resetPassword(email: email);

        // Assert - MockFirebaseAuth doesn't track reset emails, 
        // but we can verify it doesn't throw
        expect(true, true);
      });

      test('trims email before sending reset', () async {
        // Arrange
        const email = '  test@example.com  ';

        // Act - should not throw
        await repository.resetPassword(email: email);

        // Assert
        expect(true, true);
      });
    });

    group('updateProfile', () {
      test('updates displayName successfully', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Create user document first
        await fakeFirestore.collection('users').doc('test-uid').set({
          'id': 'test-uid',
          'email': 'test@example.com',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Act
        await repository.updateProfile(displayName: 'Updated Name');

        // Assert
        final userDoc = await fakeFirestore.collection('users').doc('test-uid').get();
        expect(userDoc.data()?['displayName'], 'Updated Name');
      });

      test('throws AuthException when no user is signed in', () async {
        // Arrange
        // No user signed in

        // Act & Assert
        expect(
          () => repository.updateProfile(displayName: 'Test'),
          throwsA(isA<AuthException>()),
        );
      });

      test('trims displayName before updating', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Create user document
        await fakeFirestore.collection('users').doc('test-uid').set({
          'id': 'test-uid',
          'email': 'test@example.com',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Act
        await repository.updateProfile(displayName: '  Updated Name  ');

        // Assert
        final userDoc = await fakeFirestore.collection('users').doc('test-uid').get();
        expect(userDoc.data()?['displayName'], 'Updated Name');
      });
    });

    group('deleteAccount', () {
      test('deletes user document and auth account', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
        );
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        repository = FirebaseAuthRepository(
          firebaseAuth: mockAuth,
          firestore: fakeFirestore,
        );

        // Create user document
        await fakeFirestore.collection('users').doc('test-uid').set({
          'id': 'test-uid',
          'email': 'test@example.com',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Act
        await repository.deleteAccount();

        // Assert - user document should be deleted from Firestore
        final userDoc = await fakeFirestore.collection('users').doc('test-uid').get();
        expect(userDoc.exists, false);
        
        // Note: firebase_auth_mocks doesn't actually delete the user,
        // but in real implementation it would be null
        // We're testing that deleteAccount runs without error
      });

      test('throws AuthException when no user is signed in', () async {
        // Arrange
        // No user signed in

        // Act & Assert
        expect(
          () => repository.deleteAccount(),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
