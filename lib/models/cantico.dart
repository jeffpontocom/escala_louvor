class Cantico {
  static const String collection = 'canticos';

  late String nome;
  String? autor;
  String? tom;
  String? compasso;
  String? letra;
  String? cifraUrl;
  String? youTubeUrl;
  late bool isHino;
  late bool ativo;

  Cantico({
    required this.nome,
    this.autor,
    this.tom,
    this.compasso,
    this.letra,
    this.cifraUrl,
    this.youTubeUrl,
    this.isHino = false,
    this.ativo = true,
  });

  Cantico.fromJson(Map<String, Object?> json)
      : this(
          nome: (json['nome'] ?? '[novo cantico]') as String,
          autor: json['autor'] as String?,
          tom: json['tom'] as String?,
          compasso: json['compasso'] as String?,
          letra: json['letra'] as String?,
          cifraUrl: json['cifraUrl'] as String?,
          youTubeUrl: json['youTubeUrl'] as String?,
          isHino: (json['isHino'] ?? false) as bool,
          ativo: (json['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'autor': autor,
      'tom': tom,
      'compasso': compasso,
      'letra': letra,
      'cifraUrl': cifraUrl,
      'youTubeUrl': youTubeUrl,
      'isHino': isHino,
      'ativo': ativo,
    };
  }
}
