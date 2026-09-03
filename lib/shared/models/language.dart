class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool rtl;
  final bool popular;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.rtl = false,
    this.popular = false,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'] ?? 'en',
      name: json['name'] ?? 'English',
      nativeName: json['nativeName'] ?? 'English',
      flag: json['flag'] ?? '🌐',
      rtl: json['rtl'] ?? false,
      popular: json['popular'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'nativeName': nativeName,
    'flag': flag,
    'rtl': rtl,
    'popular': popular,
  };
}
