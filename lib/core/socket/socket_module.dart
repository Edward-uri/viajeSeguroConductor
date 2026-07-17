import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/core_module.dart';
import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final client = ref.read(apiClientProvider);
  final service = SocketService(
    tokenProvider: () => client.currentToken ?? '',
    onTokenExpired: () => client.refreshSession(),
  );
  ref.onDispose(() => service.dispose());
  return service;
});
