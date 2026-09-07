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
  MatchStatus? _filter;

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
          final pending = all.where((m) => m.status == MatchStatus.pending).length;
          final accepted = all.where((m) => m.status == MatchStatus.accepted).length;
          final filtered = _filter == null ? all : all.where((m) => m.status == _filter).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    _StatChip(label: 'Total', value: '${all.length}', color: AppColors.shelterAccent),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Pendientes', value: '$pending', color: AppColors.warning),
                    const SizedBox(width: 10),
                    _StatChip(label: 'Aceptadas', value: '$accepted', color: AppColors.info),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'Todas', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Pendientes', selected: _filter == MatchStatus.pending, onTap: () => setState(() => _filter = MatchStatus.pending)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Aceptadas', selected: _filter == MatchStatus.accepted, onTap: () => setState(() => _filter = MatchStatus.accepted)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Rechazadas', selected: _filter == MatchStatus.rejected, onTap: () => setState(() => _filter = MatchStatus.rejected)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No hay solicitudes en esta categoría', style: TextStyle(color: AppColors.shelterTextMuted)),
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
