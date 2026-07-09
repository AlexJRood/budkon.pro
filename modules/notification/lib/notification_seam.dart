import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/kernel/kernel.dart';

import 'notification_service.dart';

/// Concrete [NotificationGateway] backed by the module's `fcmTokenProvider`.
class _NotificationGatewayImpl implements NotificationGateway {
  final Ref _ref;
  _NotificationGatewayImpl(this._ref);

  @override
  Future<void> reRegister() =>
      _ref.read(fcmTokenProvider.notifier).reRegister();

  @override
  Future<void> logOut() => _ref.read(fcmTokenProvider.notifier).logOut();
}

/// Provider overrides that install the notification module's implementation of
/// the kernel seams. Spread into every entrypoint's `ProviderScope` /
/// `ProviderContainer` overrides so `user` (and any other core layer) can drive
/// push registration without importing this module.
final List<Override> notificationSeamOverrides = [
  notificationGatewayProvider
      .overrideWith((ref) => _NotificationGatewayImpl(ref)),
  fcmTokenSeamProvider.overrideWith((ref) => ref.watch(fcmTokenProvider)),
  notificationUnreadCountProvider
      .overrideWith((ref) => ref.watch(notificationProvider).unreadCount),
];
