class Cantico {
  late String nome;
  late String cifraUrl;
  late String youtubeUrl;
  String? letra;
  bool? isHino;
  late bool ativo;

  Cantico(
    this.nome, {
    required this.cifraUrl,
    required this.youtubeUrl,
    this.letra,
    this.isHino,
    required this.ativo,
  });

  Cantico.fromJson(Map<String, Object?> json)
      : this(
          (json['nome'] ?? '[novo cantico]') as String,
          cifraUrl: (json['cifraurl'] ?? '') as String,
          youtubeUrl: (json['youtubeUrl'] ?? '') as String,
          letra: (json['letra'] ?? '') as String,
          isHino: (json['isHino'] ?? false) as bool,
          ativo: (json['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'cifraUrl': cifraUrl,
      'youtubeUrl': youtubeUrl,
      'letra': letra ?? '',
      'isHino': isHino ?? false,
      'ativo': ativo,
    };
  }
}
