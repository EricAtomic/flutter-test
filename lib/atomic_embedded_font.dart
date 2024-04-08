import 'package:atomic_sdk_flutter/atomic_session.dart';

/// Represents an embedded font, which is integrated into the project bundle. When an embedded
/// font is specified, this local font will be used instead of downloading a font file from a remote URL,
/// as specified in your stream container theme. The font family name, weight and style must match
/// exactly for an embedded font to be used.
/// Steps to use an embedded font:
/// 1. Set up the font in a theme within the Atomic Workbench;
/// 2. Add the font file to the project - make sure you also declare the font in the `pubspec` file.
/// 3. Call [AACSession.registerEmbeddedFonts] after the application is launched, passing an array of embedded
/// fonts you wish to use.
enum AACFontWeight {
  bold,
  regular,
  weight100,
  weight200,
  weight300,
  weight400,
  weight500,
  weight600,
  weight700,
  weight800,
  weight900,
  weight950
}

extension AACFontWeightSerialize on AACFontWeight {
  String get stringValue {
    switch (this) {
      case AACFontWeight.bold:
        return "bold";
      case AACFontWeight.regular:
        return "regular";
      case AACFontWeight.weight100:
        return "weight100";
      case AACFontWeight.weight200:
        return "weight200";
      case AACFontWeight.weight300:
        return "weight300";
      case AACFontWeight.weight400:
        return "weight400";
      case AACFontWeight.weight500:
        return "weight500";
      case AACFontWeight.weight600:
        return "weight500";
      case AACFontWeight.weight700:
        return "weight700";
      case AACFontWeight.weight800:
        return "weight800";
      case AACFontWeight.weight900:
        return "weight900";
      case AACFontWeight.weight950:
        return "weight950";
    }
  }
}

enum AACFontStyle { italic, normal }

extension AACFontStyleSerialize on AACFontStyle {
  String get stringValue {
    switch (this) {
      case AACFontStyle.italic:
        return "italic";
      case AACFontStyle.normal:
        return "normal";
    }
  }
}

class AACEmbeddedFont {
  AACEmbeddedFont(
    this.familyName,
    this.postscriptName,
    this.style,
    this.weight,
  );
  final String familyName;
  final String postscriptName;
  final AACFontStyle style;
  final AACFontWeight weight;

  Map<String, dynamic> toJson() {
    return {
      "familyName": familyName,
      "postscriptName": postscriptName,
      "style": style.stringValue,
      "weight": weight.stringValue,
    };
  }
}
