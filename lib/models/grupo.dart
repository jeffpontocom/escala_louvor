class Grupo {
  static const String collection = 'grupos';

  late String nome;
  late bool ativo;

  Grupo({required this.ativo, required this.nome});

  Grupo.fromJson(Map<String, Object?> json)
      : this(
          nome: (json['nome'] ?? '[novo grupo]') as String,
          ativo: (json['ativo'] ?? true) as bool,
        );

  Map<String, Object?> toJson() {
    return {
      'nome': nome,
      'ativo': ativo,
    };
  }
}
