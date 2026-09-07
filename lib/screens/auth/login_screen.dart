import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.loginWithEmail(email: _emailCtrl.text, password: _passCtrl.text);
      // El listener de main.dart (AuthGate) redirige automáticamente
      // según el estado de verificación y el rol del usuario.
    } catch (e) {
      setState(() => _error = _auth.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ingresa tu correo arriba para enviarte el enlace.')));
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(_emailCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Te enviamos un correo para restablecer tu contraseña.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_auth.friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                        child: const Icon(Icons.pets_rounded, color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text('PetPulse',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      const Text('Adopción responsable con trazabilidad real',
                          style: TextStyle(color: AppColors.textLight, fontSize: 14), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration('Correo electrónico', Icons.email_outlined),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: fieldDecoration('Contraseña', Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20, color: AppColors.textLight),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      )),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _resetPassword, child: const Text('¿Olvidaste tu contraseña?')),
                ),
                const SizedBox(height: 12),
                LoadingButton(loading: _loading, label: 'Ingresar a PetPulse', onPressed: _login),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
