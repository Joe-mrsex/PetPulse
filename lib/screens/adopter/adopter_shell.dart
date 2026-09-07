import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import 'explore_screen.dart';
import 'matches_screen.dart';
import 'chat_list_screen.dart';
import 'adopter_profile_screen.dart';

/// Contenedor principal de la experiencia de ADOPTANTE: swipe de mascotas,
/// mis solicitudes, chats con refugios, y perfil.
class AdopterShell extends StatefulWidget {
  final UserProfile profile;

  const AdopterShell({super.key, required this.profile});

  @override
  State<AdopterShell> createState() => _AdopterShellState();
}

class _AdopterShellState extends State<AdopterShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExploreScreen(profile: widget.profile),
      MatchesScreen(profile: widget.profile),
      ChatListScreen(profile: widget.profile),
      AdopterProfileScreen(profile: widget.profile),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.card,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore_rounded), label: 'Explorar'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_border_rounded), activeIcon: Icon(Icons.favorite_rounded), label: 'Mis Matches'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Chats'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}
