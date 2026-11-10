import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';
import 'firestore_service.dart';

class NotificationService {
  NotificationService({required FirestoreService firestore})
      : _firestore = firestore;

  final FirestoreService _firestore;

  Future<void> notifySession({
    required String title,
    required String body,
    String forRole = AppConstants.roleTeacher,
  }) async {
    await _firestore.createNotification(
      AppNotification(
        id: '',
        kind: NotificationKind.session,
        title: title,
        body: body,
        forRole: forRole,
      ),
    );
  }
}
