import 'dart:io';

import 'package:flutter/services.dart';

import 'native_core.dart';

/// Where the core listens and the token it wants.
class Endpoint {
  const Endpoint({required this.address, this.port = 0, required this.token});

  final InternetAddress address;
  final int port;
  final String token;
}

/// Starts the core of this platform (inside the app) and says where it listens.
abstract class CoreLauncher {
  Future<Endpoint> endpoint();

  static CoreLauncher forPlatform() => Platform.isAndroid ? AndroidLauncher() : DesktopLauncher();
}

/// Android: the core runs inside the app (gomobile AAR); Kotlin starts it
/// and hands over the socket path and token.
class AndroidLauncher implements CoreLauncher {
  static const _ch = MethodChannel('dev.dbmanager/core');

  @override
  Future<Endpoint> endpoint() async {
    final r = await _ch.invokeMapMethod<String, String>('start');
    if (r == null) throw StateError('core did not start');
    return Endpoint(address: InternetAddress(r['socket']!, type: InternetAddressType.unix), token: r['token']!);
  }
}

/// Desktop: the core runs inside the app ([NativeCore]) on a private socket.
class DesktopLauncher implements CoreLauncher {
  @override
  Future<Endpoint> endpoint() async {
    final r = NativeCore.instance.start();
    final err = r['error'];
    if (err != null) throw SocketException('the core did not start: $err');
    return parse(r['address'] as String, r['token'] as String);
  }

  static Endpoint parse(String addr, String token) {
    if (addr.startsWith('unix://')) {
      return Endpoint(address: InternetAddress(addr.substring('unix://'.length), type: InternetAddressType.unix), token: token);
    }
    final i = addr.lastIndexOf(':');
    return Endpoint(address: InternetAddress(addr.substring(0, i)), port: int.parse(addr.substring(i + 1)), token: token);
  }
}
