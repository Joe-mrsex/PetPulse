import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Bloquea el acceso a la app hasta que el usuario haga clic en el enlace
/// real que Firebase le envió a su correo. Revisa automáticamente cada
/// pocos segundos si ya se verificó, y permite reenviar el correo.
class VerifyEmailScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const VerifyEmailScreen({super.key, required this.onVerified});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _auth = AuthService();
  Timer? _timer;
  bool _sending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Consulta cada 4 segundos si el usuario ya confirmó el correo.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final verified = await _auth.reloadAndCheckVerified();
      if (verified) {
        _timer?.cancel();
        widget.onVerified();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await _auth.resendVerificationEmail();
      setState(() => _cooldown = 30);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_cooldown <= 1) {
          t.cancel();
          setState(() => _cooldown = 0);
        } else {
          setState(() => _cooldown -= 1);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Correo de verificación reenviado.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_auth.friendlyError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkNow() async {
  final verified = await _auth.reloadAndCheckVerified();
  if (verified) {
    _timer?.cancel();
    widget.onVerified();
  } else if (mounted) {
    setState(() {}); // <-- FORZA A FLUTTER A REDEBUJAR LA PANTALLA
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todavía no detectamos la verificación. Revisa tu correo.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_unread_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Verifica tu correo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Enviamos un enlace de confirmación a:\n$email',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ábrelo desde tu bandeja de entrada (o Spam) para continuar. Esta pantalla se actualiza sola.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLight, fontSize: 12.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkNow,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Ya verifiqué mi correo'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _sending || _cooldown > 0 ? null : _resend,
                child: Text(_cooldown > 0 ? 'Reenviar en ${_cooldown}s' : 'Reenviar correo de verificación'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _auth.signOut(),
                child: const Text('Usar otra cuenta', style: TextStyle(color: AppColors.textLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
