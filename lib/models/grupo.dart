class Grupo {
  late bool ativo;
  late String nome;

  Grupo({required this.ativo, required this.nome});

  Grupo.fromJson(Map<String, Object?> json)
      : this(
          ativo: (json['ativo'] ?? true) as bool,
          nome: (json['nome'] ?? '[novo grupo]') as String,
        );

  Map<String, Object?> toJson() {
    return {
      'ativo': ativo,
      'nome': nome,
    };
  }
}
