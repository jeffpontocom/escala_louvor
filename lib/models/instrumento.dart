class Instrumento {
  static const String collection = 'instrumentos';

  late String nome;
  late String iconAsset;
  late int composMin;
  late int composMax;
  late bool permiteOutro;
  late int ordem;
  late bool ativo;

  Instrumento({
    required this.nome,
    required this.iconAsset,
    this.composMin = 0,
    this.composMax = 2,
    this.permiteOutro = false,
    this.ordem = 99,
    this.ativo = true,
  });

  Instrumento.fromJson(Map<String, Object?> json)
      : this(
          nome: (json['nome'] ?? '[novo instrumento]') as String,
          iconAsset: (json['iconAsset'] ?? '') as String,
          composMin: (json['composMin'] ?? 0) as int,
          composMax: (json['composMax'] ?? 2) as int,
          permiteOutro: (json['permiteOutro'] ?? false) as bool,
          ordem: (json['ordem'] ?? 99) as int,
          ativo: (json['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'iconAsset': iconAsset,
      'composMin': composMin,
      'composMax': composMax,
      'permiteOutro': permiteOutro,
      'ordem': ordem,
      'ativo': ativo,
    };
  }
}
