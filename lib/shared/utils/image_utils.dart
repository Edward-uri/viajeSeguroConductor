import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

Uint8List _encodeJpg(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return input;
  return img.encodeJpg(decoded, quality: 85);
}

/// Decodifica y recomprime a JPEG en un isolate (vía [compute]) para no bloquear
/// el hilo de UI mientras se procesa la imagen tomada/seleccionada.
Future<Uint8List> compressToJpeg(Uint8List input) => compute(_encodeJpg, input);
