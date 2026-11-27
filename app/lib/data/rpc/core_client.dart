import 'package:grpc/grpc.dart';

import 'endpoint.dart';
import 'gen/cellar.pbgrpc.dart';
import '../../core/i18n.dart';

/// The gRPC client of the core, with the bearer token on every call.
class CoreClient {
  CoreClient._(this._channel, this.api);

  final ClientChannel _channel;
  final CellarClient api;

  static Future<CoreClient> connect(CoreLauncher launcher) async {
    final e = await launcher.endpoint();
    final ch = ClientChannel(
      e.address,
      port: e.port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure(), idleTimeout: Duration(minutes: 30)),
    );
    final opts = CallOptions(metadata: {'authorization': 'Bearer ${e.token}'});
    return CoreClient._(ch, CellarClient(ch, options: opts));
  }

  Future<void> close() => _channel.shutdown();
}

/// A short human message for a failed call.
String errorText(Object e) {
  if (e is GrpcError) {
    final m = e.message ?? '';
    return switch (e.code) {
      StatusCode.unavailable when m.isEmpty => tr('No connection to the core', 'Нет связи с ядром'),
      StatusCode.deadlineExceeded => tr('Timed out', 'Превышено время ожидания'),
      StatusCode.cancelled => tr('Cancelled', 'Отменено'),
      _ => m.isEmpty ? e.codeName : m,
    };
  }
  return e.toString();
}
