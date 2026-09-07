import 'package:firebase_auth/firebase_auth.dart';

/// Envuelve Firebase Auth: registro, login, verificación de correo y sesión.
///
/// La verificación de correo es REAL: Firebase envía un email con un enlace
/// de confirmación a la dirección que el usuario ingresó. Mientras no haga
/// clic en ese enlace, `isEmailVerified` será false y la app lo mantiene
/// en la pantalla de espera (ver VerifyEmailScreen).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Dispara el correo real de verificación (llega a la bandeja de entrada).
    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Vuelve a consultar a Firebase el estado real del usuario (por si ya
  /// hizo clic en el enlace del correo) y devuelve si está verificado.
 Future<bool> reloadAndCheckVerified() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await user.reload(); // Descarga el nuevo token del servidor
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }
  return false;
}

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  /// Elimina la cuenta de forma permanente. Firebase exige un login
  /// "reciente" para esta operación sensible, así que primero se vuelve a
  /// autenticar con la contraseña actual antes de borrar al usuario.
  Future<void> reauthenticateAndDeleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay una sesión activa.');
    }
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
    await user.delete();
  }

  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este correo electrónico.';
        case 'invalid-email':
          return 'El correo electrónico no es válido.';
        case 'weak-password':
          return 'La contraseña es muy débil (mínimo 6 caracteres).';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos.';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta de nuevo en unos minutos.';
        case 'network-request-failed':
          return 'Sin conexión a internet. Revisa tu red.';
        default:
          return 'Ocurrió un error: ${error.message}';
      }
    }
    return 'Ocurrió un error inesperado: $error';
  }
}
