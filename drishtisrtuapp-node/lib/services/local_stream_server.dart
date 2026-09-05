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

      // Find local Wi-Fi IP address
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String localIp = '127.0.0.1';
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }
      return 'http://$localIp:$port/stream';
    } catch (_) {
      return 'http://127.0.0.1:$port/stream';
    }
  }

  void updateFrame(Uint8List jpegBytes) {
    _latestFrame = jpegBytes;
    final boundary = '--boundary\r\nContent-Type: image/jpeg\r\nContent-Length: ${jpegBytes.length}\r\n\r\n';

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
