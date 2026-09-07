import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdopterProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const AdopterProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text('Mi Perfil', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primarySoft,
                      image: profile.photoUrl != null ? DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover) : null,
                    ),
                    child: profile.photoUrl == null ? const Icon(Icons.person_rounded, color: AppColors.primaryDark, size: 44) : null,
                  ),
                  const SizedBox(height: 14),
                  Text(profile.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(profile.email, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text(profile.role.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Información de la cuenta', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _InfoTile(icon: Icons.email_outlined, label: 'Correo', value: profile.email),
            const SizedBox(height: 10),
            _InfoTile(icon: Icons.phone_outlined, label: 'Teléfono', value: profile.phone ?? 'No especificado'),
            const SizedBox(height: 10),
            _InfoTile(icon: Icons.place_outlined, label: 'Ubicación', value: profile.addressLabel ?? 'No especificada'),
            const SizedBox(height: 10),
            _InfoTile(icon: profile.housingType?.icon ?? Icons.home_outlined, label: 'Tipo de vivienda', value: profile.housingType?.label ?? 'No especificado'),
            const SizedBox(height: 10),
            _InfoTile(icon: Icons.child_care_outlined, label: 'Niños en el hogar', value: (profile.hasChildren ?? false) ? 'Sí' : 'No'),
            const SizedBox(height: 10),
            _InfoTile(icon: Icons.pets_rounded, label: 'Otras mascotas', value: (profile.hasOtherPets ?? false) ? 'Sí' : 'No'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => auth.signOut(),
                icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.danger),
                label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: DeleteAccountButton(
                onDeleteData: () => FirestoreService().deleteAllAccountData(profile.uid, profile.role),
                onReauthenticateAndDelete: (password) => auth.reauthenticateAndDeleteAccount(password),
                errorMapper: (e) => auth.friendlyError(e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryDark, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
