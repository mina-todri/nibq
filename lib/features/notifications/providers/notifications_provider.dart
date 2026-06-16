import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_repository.dart';
import '../../../core/models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';

import '../../../core/services/support_repository.dart';

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository();
});

final supportRepositoryProvider = Provider((ref) => SupportRepository());

final allComplaintsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(supportRepositoryProvider).watchAllComplaints();
});

final pendingComplaintsCountProvider = Provider.autoDispose<int>((ref) {
  final complaints = ref.watch(allComplaintsProvider).value ?? [];
  return complaints.where((c) => c['status'] == 'pending').length;
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(notificationRepositoryProvider)
      .watchNotifications(user.uid)
      .handleError((error) {
        // Silently handle permission-denied during logout
        if (error.toString().contains('permission-denied')) {
          return [];
        }
        throw error;
      });
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
