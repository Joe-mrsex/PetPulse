import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../adopter/chat_screen.dart';

/// Vista técnica con el perfil completo del adoptante: datos de vivienda,
/// ubicación real en un mapa, contacto, y acciones para aceptar/rechazar
/// la solicitud o escribirle directamente por chat.
class ApplicantDetailScreen extends StatefulWidget {
  final AdoptionMatch match;
  final UserProfile shelterProfile;

  const ApplicantDetailScreen({super.key, required this.match, required this.shelterProfile});

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  final _firestore = FirestoreService();
  UserProfile? _adopter;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _firestore.getProfile(widget.match.adopterId);
    if (mounted) setState(() => _adopter = profile);
  }

  Future<void> _updateStatus(MatchStatus status) async {
    setState(() => _updating = true);
    try {
      await _firestore.updateMatchStatus(
        widget.match.id,
        status,
        petId: status == MatchStatus.accepted ? widget.match.petId : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == MatchStatus.accepted
                ? 'Solicitud aceptada. La mascota se retiró del feed y las demás solicitudes pendientes para ella se cerraron automáticamente.'
                : 'Solicitud rechazada'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adopter = _adopter;
    return Scaffold(
      backgroundColor: AppColors.shelterBg,
      appBar: AppBar(
        backgroundColor: AppColors.shelterBg,
        foregroundColor: AppColors.shelterText,
        elevation: 0,
        title: const Text('Ficha del solicitante'),
      ),
      body: adopter == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.shelterAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.shelterBorder,
                        backgroundImage: adopter.photoUrl != null ? NetworkImage(adopter.photoUrl!) : null,
                        child: adopter.photoUrl == null ? const Icon(Icons.person_rounded, color: AppColors.shelterTextMuted, size: 30) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(adopter.name, style: const TextStyle(color: AppColors.shelterText, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Solicita adoptar a ${widget.match.petName}', style: const TextStyle(color: AppColors.shelterAccent, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Datos de contacto'),
                  _dataRow(Icons.email_outlined, adopter.email),
                  _dataRow(Icons.phone_outlined, adopter.phone ?? 'No especificado'),
                  const SizedBox(height: 20),
                  _sectionTitle('Compatibilidad habitacional'),
                  Row(
                    children: [
                      _MiniStat(icon: adopter.housingType?.icon ?? Icons.home_outlined, label: adopter.housingType?.label ?? 'N/D'),
                      const SizedBox(width: 10),
                      _MiniStat(icon: Icons.child_care_outlined, label: (adopter.hasChildren ?? false) ? 'Con niños' : 'Sin niños'),
                      const SizedBox(width: 10),
                      _MiniStat(icon: Icons.pets_rounded, label: (adopter.hasOtherPets ?? false) ? 'Otras mascotas' : 'Sin mascotas'),
                    ],
                  ),
                  if (adopter.bio != null && adopter.bio!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Motivación'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.shelterSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.shelterBorder)),
                      child: Text(adopter.bio!, style: const TextStyle(color: AppColors.shelterText, fontSize: 13.5, height: 1.5)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionTitle('Ubicación del hogar'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.shelterSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.shelterBorder)),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined, color: AppColors.shelterAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (adopter.addressLabel == null || adopter.addressLabel!.isEmpty)
                                ? 'El adoptante no ha compartido su ubicación'
                                : adopter.addressLabel!,
                            style: const TextStyle(color: AppColors.shelterText, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nota: cuando actives Google Maps más adelante, aquí se
                  // puede volver a mostrar el mapa real usando
                  // adopter.latitude / adopter.longitude (ya existen en el modelo).
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _updating || widget.match.status == MatchStatus.rejected ? null : () => _updateStatus(MatchStatus.rejected),
                          icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 18),
                          label: const Text('Rechazar', style: TextStyle(color: AppColors.danger)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _updating || widget.match.status == MatchStatus.accepted ? null : () => _updateStatus(MatchStatus.accepted),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Aceptar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.shelterAccent,
                            foregroundColor: AppColors.shelterBg,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: widget.match.chatId,
                          currentUserId: widget.shelterProfile.uid,
                          title: adopter.name,
                          subtitle: 'Sobre ${widget.match.petName}',
                        ),
                      )),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.shelterAccent, size: 18),
                      label: const Text('Escribirle por chat', style: TextStyle(color: AppColors.shelterAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.shelterAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(color: AppColors.shelterTextMuted, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.4)),
      );

  Widget _dataRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.shelterAccent),
            const SizedBox(width: 10),
            Text(value, style: const TextStyle(color: AppColors.shelterText, fontSize: 13.5)),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: AppColors.shelterSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.shelterBorder)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.shelterAccent, size: 18),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.shelterText, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
