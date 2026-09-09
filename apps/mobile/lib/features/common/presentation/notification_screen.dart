import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/theme/app_colors.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/controllers/auth_controller.dart';

final AutoDisposeFutureProvider<List<NotificationItem>> notificationsProvider = FutureProvider.autoDispose((Ref ref) async {
  final AsyncValue<AppAuthState> authAsync = ref.watch(authControllerProvider);
  final String userId = switch (authAsync.value) {
    AuthAuthenticated(:final UserProfile profile) => profile.id,
    AuthOnboardingRequired(:final sb.User user) => user.id,
    _ => '',
  };

  if (userId.isEmpty) return <NotificationItem>[];

  final INotificationRepository repo = ref.watch(notificationRepositoryProvider);
  
  // Mark all as read when opening the screen
  await repo.markAllAsRead(userId);
  
  return repo.getNotifications(userId: userId);
});

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NotificationItem>> notificationsAsync = ref.watch(notificationsProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Text('Failed to load notifications: $error'),
        ),
        data: (List<NotificationItem> notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (BuildContext context, int index) => Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            itemBuilder: (BuildContext context, int index) {
              final NotificationItem item = notifications[index];
              return _NotificationTile(item: item, isDark: isDark);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.isDark});

  final NotificationItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = switch (item.eventType) {
      'booking_update' => Colors.blue,
      'payment' => AppColors.success,
      'verification' => AppColors.primary,
      _ => Colors.grey,
    };

    final IconData icon = switch (item.eventType) {
      'booking_update' => Icons.assignment_rounded,
      'payment' => Icons.account_balance_wallet_rounded,
      'verification' => Icons.verified_rounded,
      _ => Icons.notifications_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      color: item.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.createdAt != null)
                  Text(
                    item.createdAt!.toLocal().toString().split('.')[0], // simple formatting
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
