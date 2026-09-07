import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../adopter/chat_screen.dart';

class ShelterChatsScreen extends StatelessWidget {
  final UserProfile profile;

  const ShelterChatsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.shelterBg,
      appBar: AppBar(
        backgroundColor: AppColors.shelterBg,
        foregroundColor: AppColors.shelterText,
        elevation: 0,
        title: const Text('Conversaciones'),
      ),
      body: StreamBuilder<List<AdoptionMatch>>(
        stream: firestore.watchMatchesForShelter(profile.uid),
        builder: (context, snapshot) {
          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return const Center(child: Text('Aún no tienes conversaciones', style: TextStyle(color: AppColors.shelterTextMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 84, color: AppColors.shelterBorder),
            itemBuilder: (context, i) {
              final m = matches[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.shelterBorder,
                  backgroundImage: m.adopterPhotoUrl != null ? NetworkImage(m.adopterPhotoUrl!) : null,
                  child: m.adopterPhotoUrl == null ? const Icon(Icons.person_rounded, color: AppColors.shelterTextMuted) : null,
                ),
                title: Text(m.adopterName, style: const TextStyle(color: AppColors.shelterText, fontWeight: FontWeight.w700, fontSize: 14.5)),
                subtitle: Text('Sobre ${m.petName}', style: const TextStyle(color: AppColors.shelterTextMuted, fontSize: 12.5)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.shelterTextMuted),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(chatId: m.chatId, currentUserId: profile.uid, title: m.adopterName, subtitle: 'Sobre ${m.petName}'),
                )),
              );
            },
          );
        },
      ),
    );
  }
}
