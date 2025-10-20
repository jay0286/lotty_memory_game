import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'sprite_data.dart';

/// Parses TexturePacker XML format
class SpriteSheetParser {
  /// Parse XML file and return AtlasData
  static Future<AtlasData> parseXml(String xmlPath) async {
    final xmlString = await rootBundle.loadString(xmlPath);
    final document = XmlDocument.parse(xmlString);

    final textureAtlas = document.findElements('TextureAtlas').first;

    final imagePath = textureAtlas.getAttribute('imagePath') ?? '';
    final width = double.parse(textureAtlas.getAttribute('width') ?? '0');
    final height = double.parse(textureAtlas.getAttribute('height') ?? '0');

    final sprites = <SpriteData>[];

    for (final sprite in textureAtlas.findElements('sprite')) {
      final name = sprite.getAttribute('n') ?? '';
      final x = double.parse(sprite.getAttribute('x') ?? '0');
      final y = double.parse(sprite.getAttribute('y') ?? '0');
      final w = double.parse(sprite.getAttribute('w') ?? '0');
      final h = double.parse(sprite.getAttribute('h') ?? '0');

      sprites.add(SpriteData(
        name: name,
        x: x,
        y: y,
        width: w,
        height: h,
      ));
    }

    return AtlasData(
      imagePath: imagePath,
      width: width,
      height: height,
      sprites: sprites,
    );
  }
}
