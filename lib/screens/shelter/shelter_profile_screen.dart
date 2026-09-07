import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ShelterProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const ShelterProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      backgroundColor: AppColors.shelterBg,
      appBar: AppBar(
        backgroundColor: AppColors.shelterBg,
        foregroundColor: AppColors.shelterText,
        elevation: 0,
        title: const Text('Organización'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.shelterBorder,
                    backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                    child: profile.photoUrl == null ? const Icon(Icons.volunteer_activism_rounded, color: AppColors.shelterAccent, size: 40) : null,
                  ),
                  const SizedBox(height: 14),
                  Text(profile.organizationName ?? profile.name, style: const TextStyle(color: AppColors.shelterText, fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(profile.email, style: const TextStyle(color: AppColors.shelterTextMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _sectionTitle('Datos de la organización'),
            _infoTile(Icons.phone_outlined, 'Teléfono', profile.phone ?? 'No especificado'),
            _infoTile(Icons.badge_outlined, 'RUC / Registro legal', profile.legalIdOrRuc ?? 'No especificado'),
            _infoTile(Icons.place_outlined, 'Ubicación', profile.addressLabel ?? 'No especificada'),
            if (profile.organizationDescription != null && profile.organizationDescription!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Descripción'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.shelterSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.shelterBorder)),
                child: Text(profile.organizationDescription!, style: const TextStyle(color: AppColors.shelterText, fontSize: 13.5, height: 1.5)),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => auth.signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                label: const Text('Cerrar sesión', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(color: AppColors.shelterAccent, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.4)),
      );

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.shelterSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.shelterBorder)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.shelterAccent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.shelterTextMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: AppColors.shelterText, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
