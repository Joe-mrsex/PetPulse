import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'screens/adopter/adopter_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/shelter/shelter_shell.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PetPulseApp());
}

class PetPulseApp extends StatelessWidget {
  const PetPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetPulse',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

/// Controla todo el flujo de entrada a la app en un solo lugar:
///  1. Sin sesión           -> LoginScreen (con acceso a RegisterScreen).
///  2. Sesión sin verificar -> VerifyEmailScreen (correo real pendiente).
///  3. Verificado, sin      -> ProfileSetupScreen (foto + datos obligatorios).
///     onboarding completo
///  4. Todo listo           -> AdopterShell o ShelterShell según el rol.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Se guarda como campo (no se crea de nuevo en cada build) para que
  // StreamBuilder NUNCA pierda su suscripción al reconstruirse: si se
  // crea un stream nuevo en cada build, cada rebuild reinicia la
  // suscripción y la pantalla se queda en "cargando" para siempre.
  final Stream<User?> _authStream = FirebaseAuth.instance.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Importante: NO se usa `user.emailVerified` (viene del snapshot
        // del stream, que no cambia solo por verificar el correo). Se lee
        // siempre el valor más reciente de currentUser, que sí se
        // actualiza al llamar reload().
        final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

        if (!isVerified) {
          return VerifyEmailScreen(
            onVerified: () => setState(() {}),
          );
        }

        return StreamBuilder<UserProfile?>(
          stream: FirestoreService().watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }
            final profile = profileSnapshot.data;
            if (profile == null) {
              return const _SplashScreen();
            }
            if (!profile.onboardingComplete) {
              return ProfileSetupScreen(
                profile: profile,
                onComplete: () {},
              );
            }
            return profile.role == UserRole.shelter ? ShelterShell(profile: profile) : AdopterShell(profile: profile);
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
