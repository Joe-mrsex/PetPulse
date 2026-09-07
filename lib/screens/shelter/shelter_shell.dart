import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'applicants_screen.dart';
import 'publish_pet_screen.dart';
import 'shelter_chats_screen.dart';
import 'shelter_pets_screen.dart';
import 'shelter_profile_screen.dart';

/// Contenedor principal de la experiencia de REFUGIO/RESCATISTA: una
/// interfaz deliberadamente distinta a la del adoptante — más "técnica",
/// tipo panel de administración — para evaluar solicitantes con datos
/// completos (vivienda, ubicación, contacto) y gestionar publicaciones.
class ShelterShell extends StatefulWidget {
  final UserProfile profile;

  const ShelterShell({super.key, required this.profile});

  @override
  State<ShelterShell> createState() => _ShelterShellState();
}

class _ShelterShellState extends State<ShelterShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ApplicantsScreen(profile: widget.profile),
      ShelterPetsScreen(profile: widget.profile),
      const PublishPetScreen(),
      ShelterChatsScreen(profile: widget.profile),
      ShelterProfileScreen(profile: widget.profile),
    ];

    return Scaffold(
      backgroundColor: AppColors.shelterBg,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.shelterSurface,
          border: Border(top: BorderSide(color: AppColors.shelterBorder)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.shelterSurface,
            elevation: 0,
            selectedItemColor: AppColors.shelterAccent,
            unselectedItemColor: AppColors.shelterTextMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), activeIcon: Icon(Icons.fact_check_rounded), label: 'Solicitudes'),
              BottomNavigationBarItem(icon: Icon(Icons.pets_outlined), activeIcon: Icon(Icons.pets_rounded), label: 'Mis Mascotas'),
              BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box_rounded), label: 'Publicar'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Chats'),
              BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings_rounded), label: 'Organización'),
            ],
          ),
        ),
      ),
    );
  }
}
