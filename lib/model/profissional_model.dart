class Profissional {
  final String id;
  final String nome;
  final String email;
  final String registro;
  final String especialidade;
  final String senha;
  final DateTime dataCadastro;

  Profissional({
    required this.id,
    required this.nome,
    required this.email,
    required this.registro,
    required this.especialidade,
    required this.senha,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // Converter para Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'registro': registro,
      'especialidade': especialidade,
      'senha': senha,
      'dataCadastro': dataCadastro.toIso8601String(),
    };
  }

  // Criar a partir de Map (SQLite)
  factory Profissional.fromMap(Map<String, dynamic> map) {
    return Profissional(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      registro: map['registro'],
      especialidade: map['especialidade'],
      senha: map['senha'],
      dataCadastro: DateTime.parse(map['dataCadastro']),
    );
  }
}