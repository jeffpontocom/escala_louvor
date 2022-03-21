class Cantico {
  static const String collection = 'canticos';

  late String nome;
  late String cifraUrl;
  String? youTubeUrl;
  String? letra;
  late bool isHino;
  late bool ativo;

  Cantico({
    required this.nome,
    required this.cifraUrl,
    this.youTubeUrl,
    this.letra,
    required this.isHino,
    required this.ativo,
  });

  Cantico.fromJson(Map<String, Object?> json)
      : this(
          nome: (json['nome'] ?? '[novo cantico]') as String,
          cifraUrl: (json['cifraUrl'] ?? '') as String,
          youTubeUrl: (json['youTubeUrl'] ?? '') as String,
          letra: (json['letra'] ?? '') as String,
          isHino: (json['isHino'] ?? false) as bool,
          ativo: (json['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'cifraUrl': cifraUrl,
      'youTubeUrl': youTubeUrl ?? '',
      'letra': letra ?? '',
      'isHino': isHino,
      'ativo': ativo,
    };
  }
}
