import 'dart:io';
import 'dart:typed_data';

/// Sends raw ESC/POS bytes to a network printer (TCP, usually port **9100**).
Future<void> sendEscPosBytesToTcpPrinter({
  required String host,
  required int port,
  required List<int> bytes,
  Duration timeout = const Duration(seconds: 15),
}) async {
  Socket? socket;
  try {
    socket = await Socket.connect(host, port, timeout: timeout);
    socket.add(Uint8List.fromList(bytes));
    await socket.flush();
  } on SocketException catch (e, st) {
    Error.throwWithStackTrace(
      Exception('Printer not reachable at $host:$port — ${e.message}'),
      st,
    );
  } finally {
    socket?.destroy();
  }
}
