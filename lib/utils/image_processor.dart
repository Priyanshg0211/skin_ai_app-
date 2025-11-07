import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/image_processing_data.dart';

Future<Uint8List> processImageInIsolate(ImageProcessingData data) async {
  return await Isolate.run(() {
    img.Image? decodedImage = img.decodeImage(data.imageBytes);
    if (decodedImage != null) {
      decodedImage = img.bakeOrientation(decodedImage);
      return Uint8List.fromList(img.encodeJpg(decodedImage, quality: 85));
    }
    return data.imageBytes;
  });
}

