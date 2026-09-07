import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Registro inicial: correo (validado con verificación real por Firebase),
/// contraseña y rol. Los datos de perfil detallados (foto, ubicación,
/// vivienda, etc.) se completan después en el flujo de onboarding.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();
  final _firestore = FirestoreService();

  UserRole _role = UserRole.adopter;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Verificación de formato + dominio simple. La verificación REAL (que el
  /// correo exista y le pertenezca al usuario) la hace Firebase Auth al
  /// enviar el enlace de confirmación — por eso el usuario no puede avanzar
  /// en la app hasta hacer clic en ese enlace (ver VerifyEmailScreen).
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico';
    final regex = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v.trim())) return 'Formato de correo inválido';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = await _auth.registerWithEmail(email: _emailCtrl.text, password: _passCtrl.text);
      final uid = credential.user!.uid;

      final profile = UserProfile(
        uid: uid,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        role: _role,
        onboardingComplete: false,
      );
      await _firestore.createInitialProfile(profile);
      // Cierra esta pantalla para dejar ver lo que AuthGate ya muestra
      // debajo (VerifyEmailScreen), que cambia solo al crear la cuenta.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = _auth.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Crear cuenta',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 6),
                const Text('Te enviaremos un correo real para verificar tu cuenta.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13.5)),
                const SizedBox(height: 24),
                const Text('¿Cuál es tu rol?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.favorite_rounded,
                        title: 'Quiero Adoptar',
                        subtitle: 'Busco una mascota compatible',
                        selected: _role == UserRole.adopter,
                        onTap: () => setState(() => _role = UserRole.adopter),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.volunteer_activism_rounded,
                        title: 'Refugio / Rescatista',
                        subtitle: 'Publico mascotas en adopción',
                        selected: _role == UserRole.shelter,
                        onTap: () => setState(() => _role = UserRole.shelter),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                  controller: _nameCtrl,
                  decoration: fieldDecoration(
                      _role == UserRole.adopter ? 'Nombre completo' : 'Nombre del refugio / rescatista',
                      Icons.badge_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration('Correo electrónico', Icons.email_outlined),
                  validator: _validateEmail,
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: fieldDecoration('Confirmar contraseña', Icons.lock_outline_rounded),
                  validator: (v) => (v == null || v.isEmpty) ? 'Confirma tu contraseña' : null,
                ),
                const SizedBox(height: 28),
                LoadingButton(loading: _loading, label: 'Crear cuenta', onPressed: _register),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard(
      {required this.icon, required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.primaryDark : AppColors.textLight, size: 26),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: selected ? AppColors.primaryDark : AppColors.textDark)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
