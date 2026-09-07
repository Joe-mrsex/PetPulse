import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  final UserProfile profile;

  const MatchesScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text('Mis Matches', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: StreamBuilder<List<AdoptionMatch>>(
        stream: firestore.watchMatchesForAdopter(profile.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return const _EmptyMatches();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _MatchCard(
              match: matches[i],
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: matches[i].chatId,
                  currentUserId: profile.uid,
                  title: matches[i].shelterName,
                  subtitle: 'Sobre ${matches[i].petName}',
                ),
              )),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded, size: 52, color: AppColors.textLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Aún no tienes solicitudes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Explora mascotas y envía tu primera solicitud de adopción.', style: TextStyle(color: AppColors.textLight, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final AdoptionMatch match;
  final VoidCallback onTap;

  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(imageUrl: match.petImageUrl, width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.petName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Text(match.shelterName, style: const TextStyle(color: AppColors.textLight, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: AppColors.info),
                      const SizedBox(width: 4),
                      const Text('Toca para chatear', style: TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(label: match.status.label, color: match.status.color, icon: match.status.icon),
          ],
        ),
      ),
    );
  }
}
