import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'publish_pet_screen.dart';

/// Inventario técnico de mascotas publicadas por este refugio: útil para
/// llevar control de cuántas están activas y su estado sanitario a simple
/// vista, además de poder editar o eliminar cada publicación.
class ShelterPetsScreen extends StatelessWidget {
  final UserProfile profile;

  const ShelterPetsScreen({super.key, required this.profile});

  Future<void> _confirmDelete(BuildContext context, FirestoreService firestore, Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.shelterSurface,
        title: const Text('Eliminar publicación', style: TextStyle(color: AppColors.shelterText)),
        content: Text(
          '¿Seguro que quieres eliminar a ${pet.name}? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.shelterTextMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await firestore.deletePet(pet.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${pet.name} fue eliminado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.shelterBg,
      appBar: AppBar(
        backgroundColor: AppColors.shelterBg,
        foregroundColor: AppColors.shelterText,
        elevation: 0,
        title: const Text('Mis Mascotas Publicadas'),
      ),
      body: StreamBuilder<List<Pet>>(
        stream: firestore.watchShelterPets(profile.uid),
        builder: (context, snapshot) {
          final pets = snapshot.data ?? [];
          if (pets.isEmpty) {
            return const Center(
              child: Text('Aún no has publicado ninguna mascota', style: TextStyle(color: AppColors.shelterTextMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final pet = pets[i];
              final verifiedCount = pet.healthChecklist.values.where((v) => v).length;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.shelterSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.shelterBorder)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(pet.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(width: 56, height: 56, color: AppColors.shelterBorder)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pet.name, style: const TextStyle(color: AppColors.shelterText, fontWeight: FontWeight.w700, fontSize: 14.5)),
                          const SizedBox(height: 3),
                          Text('${pet.breed} · ${pet.age}', style: const TextStyle(color: AppColors.shelterTextMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.shelterAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: Text('$verifiedCount/${pet.healthChecklist.length} salud', style: const TextStyle(color: AppColors.shelterAccent, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 6),
                              if (!pet.active)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Ya adoptada', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.shelterTextMuted),
                      color: AppColors.shelterSurface,
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublishPetScreen(existingPet: pet)));
                        } else if (value == 'delete') {
                          _confirmDelete(context, firestore, pet);
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, color: AppColors.shelterText, size: 18),
                            SizedBox(width: 10),
                            Text('Editar', style: TextStyle(color: AppColors.shelterText)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                            SizedBox(width: 10),
                            Text('Eliminar', style: TextStyle(color: AppColors.danger)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
