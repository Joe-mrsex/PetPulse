import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

/// Lista de conversaciones del adoptante (una por cada solicitud enviada).
class ChatListScreen extends StatelessWidget {
  final UserProfile profile;

  const ChatListScreen({super.key, required this.profile});

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
        title: const Text('Chats', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: StreamBuilder<List<AdoptionMatch>>(
        stream: firestore.watchMatchesForAdopter(profile.uid),
        builder: (context, snapshot) {
          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 52, color: AppColors.textLight.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No tienes conversaciones todavía', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  const Text('Envía una solicitud de adopción para empezar a chatear con un refugio.',
                      style: TextStyle(color: AppColors.textLight, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 84, color: AppColors.border),
            itemBuilder: (context, i) {
              final m = matches[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(imageUrl: m.petImageUrl, width: 52, height: 52, fit: BoxFit.cover),
                ),
                title: Text(m.shelterName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                subtitle: Text('Sobre ${m.petName}', style: const TextStyle(color: AppColors.textLight, fontSize: 12.5)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(chatId: m.chatId, currentUserId: profile.uid, title: m.shelterName, subtitle: 'Sobre ${m.petName}'),
                )),
              );
            },
          );
        },
      ),
    );
  }
}
