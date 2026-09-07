import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'applicant_detail_screen.dart';

/// Panel técnico donde el refugio revisa cada solicitud de adopción:
/// filtra por estado, ve datos resumidos y entra al detalle completo del
/// adoptante para aceptar/rechazar con criterio informado.
class ApplicantsScreen extends StatefulWidget {
  final UserProfile profile;

  const ApplicantsScreen({super.key, required this.profile});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final _firestore = FirestoreService();
  // Por defecto solo se muestran las pendientes: en cuanto se aceptan o
  // rechazan, desaparecen de esta vista principal y pasan al Historial,
  // así el refugio siempre ve una bandeja limpia de "por decidir".
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.shelterBg,
      appBar: AppBar(
        backgroundColor: AppColors.shelterBg,
        elevation: 0,
        titleSpacing: 20,
        title: const Text('Panel de Solicitudes',
            style: TextStyle(color: AppColors.shelterText, fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: StreamBuilder<List<AdoptionMatch>>(
        stream: _firestore.watchMatchesForShelter(widget.profile.uid),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final pending = all.where((m) => m.status == MatchStatus.pending).toList();
          final history = all.where((m) => m.status != MatchStatus.pending).toList();
          final accepted = all.where((m) => m.status == MatchStatus.accepted).length;
          final filtered = _showHistory ? history : pending;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    _StatChip(label: 'Total', value: '${all.length}', color: AppColors.shelterAccent),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Pendientes', value: '${pending.length}', color: AppColors.warning),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Aceptadas', value: '$accepted', color: AppColors.info),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  children: [
                    _FilterChip(label: 'Pendientes', selected: !_showHistory, onTap: () => setState(() => _showHistory = false)),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Historial', selected: _showHistory, onTap: () => setState(() => _showHistory = true)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _showHistory ? 'Aún no hay solicitudes decididas' : 'No tienes solicitudes pendientes por revisar',
                          style: const TextStyle(color: AppColors.shelterTextMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final m = filtered[i];
                          return _ApplicantRow(
                            match: m,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ApplicantDetailScreen(match: m, shelterProfile: widget.profile),
                            )),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.shelterSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.shelterBorder),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.shelterTextMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.shelterAccent : AppColors.shelterSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.shelterAccent : AppColors.shelterBorder),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? AppColors.shelterBg : AppColors.shelterTextMuted, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  final AdoptionMatch match;
  final VoidCallback onTap;

  const _ApplicantRow({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.shelterSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.shelterBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.shelterBorder,
              backgroundImage: match.adopterPhotoUrl != null ? NetworkImage(match.adopterPhotoUrl!) : null,
              child: match.adopterPhotoUrl == null ? const Icon(Icons.person_rounded, color: AppColors.shelterTextMuted) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.adopterName, style: const TextStyle(color: AppColors.shelterText, fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text('Solicita a ${match.petName}', style: const TextStyle(color: AppColors.shelterTextMuted, fontSize: 12.5)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: match.status.color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(match.status.label, style: TextStyle(color: match.status.color, fontWeight: FontWeight.w700, fontSize: 10)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.shelterTextMuted),
          ],
        ),
      ),
    );
  }
}
