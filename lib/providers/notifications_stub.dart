// notifications_stub.dart
// Stub usado na compilação web para flutter_local_notifications,
// que não suporta o navegador. Todas as classes são no-ops.

class FlutterLocalNotificationsPlugin {
  Future<bool?> initialize(
    InitializationSettings settings, {
    Function? onDidReceiveNotificationResponse,
    Function? onDidReceiveBackgroundNotificationResponse,
  }) async =>
      false;

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails notificationDetails,
  }) async {}
}

class InitializationSettings {
  final AndroidInitializationSettings? android;
  const InitializationSettings({this.android});
}

class AndroidInitializationSettings {
  final String defaultIcon;
  const AndroidInitializationSettings(this.defaultIcon);
}

class NotificationDetails {
  final AndroidNotificationDetails? android;
  const NotificationDetails({this.android});
}

class AndroidNotificationDetails {
  final String channelId;
  final String channelName;
  final String? channelDescription;
  final Importance? importance;
  final Priority? priority;
  final bool? onlyAlertOnce;
  final bool? showProgress;
  final int? maxProgress;
  final int? progress;

  const AndroidNotificationDetails(
    this.channelId,
    this.channelName, {
    this.channelDescription,
    this.importance,
    this.priority,
    this.onlyAlertOnce,
    this.showProgress,
    this.maxProgress,
    this.progress,
  });
}

enum Importance { low, defaultImportance, high, max, min, none, unspecified }

enum Priority { low, defaultPriority, high, max, min }