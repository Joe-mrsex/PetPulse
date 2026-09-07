import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  final UserProfile profile;

  const ExploreScreen({super.key, required this.profile});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _firestore = FirestoreService();
  int _currentIndex = 0;
  bool _requesting = false;

  Future<void> _handleMatch(Pet pet, int totalPets) async {
    setState(() => _requesting = true);
    try {
      await _firestore.requestAdoption(pet: pet, adopter: widget.profile);
      if (mounted) {
        setState(() => _currentIndex = totalPets <= 1 ? 0 : (_currentIndex + 1) % totalPets);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solicitud enviada para ${pet.name}. El refugio revisará tu perfil.'),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text('PetPulse',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 24)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<AdoptionMatch>>(
          // Primero se obtienen las solicitudes que ya envió este adoptante,
          // para poder ocultar del feed las mascotas que ya pidió (evita
          // que pueda "espamear" solicitudes repetidas a la misma mascota).
          stream: _firestore.watchMatchesForAdopter(widget.profile.uid),
          builder: (context, matchesSnapshot) {
            final requestedPetIds = (matchesSnapshot.data ?? []).map((m) => m.petId).toSet();

            return StreamBuilder<List<Pet>>(
              stream: _firestore.watchAvailablePets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final pets = (snapshot.data ?? []).where((p) => !requestedPetIds.contains(p.id)).toList();
                if (pets.isEmpty) {
                  return const _EmptyExplore();
                }
                if (_currentIndex >= pets.length) _currentIndex = 0;
                final pet = pets[_currentIndex];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: PetCard(key: ValueKey(pet.id), pet: pet, onShowVaccineCard: () => _showVaccineCard(pet)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CircleButton(
                        icon: Icons.close_rounded,
                        size: 56,
                        color: AppColors.danger,
                        onTap: () => setState(() => _currentIndex = (_currentIndex + 1) % pets.length),
                      ),
                      _CircleButton(
                        icon: Icons.favorite_rounded,
                        size: 74,
                        color: AppColors.primary,
                        loading: _requesting,
                        onTap: () => _handleMatch(pet, pets.length),
                      ),
                      _CircleButton(
                        icon: Icons.info_outline_rounded,
                        size: 56,
                        color: AppColors.info,
                        onTap: () => _showDetails(pet),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
              },
            );
          },
        ),
      ),
    );
  }

  void _showVaccineCard(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VaccineCardSheet(pet: pet),
    );
  }

  void _showDetails(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              Text(pet.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('${pet.breed} · ${pet.age}', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 20),
              _detailRow(Icons.location_on_outlined, pet.addressLabel ?? 'Ubicación no especificada'),
              const SizedBox(height: 12),
              _detailRow(pet.housingIcon, pet.housingTag),
              const SizedBox(height: 12),
              _detailRow(Icons.volunteer_activism_rounded, 'Publicado por ${pet.shelterName}'),
              const SizedBox(height: 20),
              const Text('Sobre esta mascota', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 15)),
              const SizedBox(height: 8),
              Text(pet.description, style: const TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textDark, fontSize: 14))),
      ],
    );
  }
}

class _EmptyExplore extends StatelessWidget {
  const _EmptyExplore();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_rounded, size: 52, color: AppColors.textLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No hay mascotas disponibles todavía', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Los refugios están publicando nuevas mascotas constantemente. Vuelve pronto.', style: TextStyle(color: AppColors.textLight, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onShowVaccineCard;

  const PetCard({super.key, required this.pet, required this.onShowVaccineCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: pet.imageUrl,
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(color: AppColors.border, child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),
              errorWidget: (c, u, e) => Container(color: AppColors.border, child: const Icon(Icons.pets_rounded, size: 64, color: Colors.white)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.90)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${pet.breed} · ${pet.age}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(pet.addressLabel ?? pet.shelterName,
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onShowVaccineCard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Ver Carnet de Vacunación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _CircleButton({required this.icon, required this.size, required this.color, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: color.withOpacity(0.5),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: loading
              ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
              : Icon(icon, color: Colors.white, size: size * 0.42),
        ),
      ),
    );
  }
}

/// Muestra el carnet de vacunación: puede ser una imagen o un PDF real
/// subido por el refugio a Firebase Storage.
class VaccineCardSheet extends StatelessWidget {
  final Pet pet;

  const VaccineCardSheet({super.key, required this.pet});

  bool get _isPdf => pet.vaccineCardUrl?.toLowerCase().contains('.pdf') ?? false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Carnet de Vacunación', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    Text('Trazabilidad médica de ${pet.name}', style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (pet.vaccineCardUrl == null)
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(18)),
              child: const Center(child: Text('El refugio aún no subió el carnet', style: TextStyle(color: AppColors.textLight))),
            )
          else if (_isPdf)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Documento PDF disponible', style: TextStyle(fontWeight: FontWeight.w600))),
                  TextButton(onPressed: () {}, child: const Text('Abrir')),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(imageUrl: pet.vaccineCardUrl!, height: 170, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 20),
          const Text('Verificación de estado sanitario', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
          const SizedBox(height: 10),
          ...pet.healthChecklist.entries.map((e) => _ChecklistItem(label: e.key, verified: e.value)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final bool verified;

  const _ChecklistItem({required this.label, required this.verified});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(verified ? Icons.check_circle_rounded : Icons.cancel_rounded, color: verified ? AppColors.primary : AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: verified ? FontWeight.w500 : FontWeight.w400)),
          const Spacer(),
          Text(verified ? 'Al día' : 'Pendiente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: verified ? AppColors.primary : AppColors.textLight)),
        ],
      ),
    );
  }
}
