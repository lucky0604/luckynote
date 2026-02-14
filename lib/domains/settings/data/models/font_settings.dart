class FontSettings {
  final String fontFamily;
  final double fontSize;

  const FontSettings({this.fontFamily = 'SF Pro Text', this.fontSize = 16.0});

  FontSettings copyWith({String? fontFamily, double? fontSize}) {
    return FontSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {'fontFamily': fontFamily, 'fontSize': fontSize};
  }

  factory FontSettings.fromJson(Map<String, dynamic> json) {
    return FontSettings(
      fontFamily: json['fontFamily'] as String? ?? 'SF Pro Text',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
    );
  }
}
