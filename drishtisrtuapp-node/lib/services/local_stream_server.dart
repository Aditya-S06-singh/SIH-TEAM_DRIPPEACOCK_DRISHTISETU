import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class LocalStreamServer {
  HttpServer? _server;
  Uint8List? _latestFrame;
  final List<HttpResponse> _activeClients = [];
  int port = 8088;

  Future<String> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _listenRequests();

      // Explicitly prioritize Wi-Fi network interface (wlan, wifi, en) and exclude cellular interfaces (ccmni, rmnet, pdp, ppp)
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String? wifiIp;
      String? lanFallbackIp;

      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        final isCellular = name.contains('ccmni') ||
            name.contains('rmnet') ||
            name.contains('pdp') ||
            name.contains('ppp') ||
            name.contains('cellular') ||
            name.contains('radio');

        if (isCellular) continue;

        for (final addr in interface.addresses) {
          if (addr.isLoopback) continue;

          final isWifiName = name.contains('wlan') || name.contains('wifi') || name.contains('en');
          final isPrivateLan = addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.');

          if (isWifiName || isPrivateLan) {
            wifiIp = addr.address;
            break;
          } else if (lanFallbackIp == null) {
            lanFallbackIp = addr.address;
          }
        }
        if (wifiIp != null) break;
      }

      final chosenIp = wifiIp ?? lanFallbackIp ?? '127.0.0.1';
      return 'http://' + chosenIp + ':' + port.toString() + '/stream';
    } catch (_) {
      return 'http://127.0.0.1:' + port.toString() + '/stream';
    }
  }

  void updateFrame(Uint8List jpegBytes) {
    _latestFrame = jpegBytes;
    final boundary = '--boundary\r\nContent-Type: image/jpeg\r\nContent-Length: ' + jpegBytes.length.toString() + '\r\n\r\n';

    final deadClients = <HttpResponse>[];
    for (final client in _activeClients) {
      try {
        client.add(Uint8List.fromList(boundary.codeUnits));
        client.add(jpegBytes);
        client.add(Uint8List.fromList('\r\n'.codeUnits));
      } catch (_) {
        deadClients.add(client);
      }
    }
    _activeClients.removeWhere(deadClients.contains);
  }

  void _listenRequests() {
    _server?.listen((HttpRequest request) async {
      final path = request.uri.path;
      if (path == '/stream') {
        final response = request.response;
        response.headers.set(
          'Content-Type',
          'multipart/x-mixed-replace; boundary=boundary',
        );
        response.headers.set('Cache-Control', 'no-cache, private');
        response.headers.set('Connection', 'close');
        response.headers.set('Access-Control-Allow-Origin', '*');

        _activeClients.add(response);
      } else if (path == '/snapshot') {
        final response = request.response;
        response.headers.set('Content-Type', 'image/jpeg');
        response.headers.set('Access-Control-Allow-Origin', '*');
        if (_latestFrame != null) {
          response.add(_latestFrame!);
        }
        await response.close();
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });
  }

  void stop() {
    for (final client in _activeClients) {
      try {
        client.close();
      } catch (_) {}
    }
    _activeClients.clear();
    _server?.close(force: true);
  }
}
