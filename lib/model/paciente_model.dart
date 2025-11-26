class Paciente {
  final String id;
  final String nome;
  final int idade;
  final double altura;
  final double peso;
  final int periodoGestacional;
  final String tratamento;
  final DateTime dataCadastro;
  final String profissionalId;

  Paciente({
    required this.id,
    required this.nome,
    required this.idade,
    required this.altura,
    required this.peso,
    required this.periodoGestacional,
    required this.tratamento,
    required this.profissionalId,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // Converter para Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'idade': idade,
      'altura': altura,
      'peso': peso,
      'periodoGestacional': periodoGestacional,
      'tratamento': tratamento,
      'dataCadastro': dataCadastro.toIso8601String(),
      'profissionalId': profissionalId,
    };
  }

  // Criar a partir de Map (SQLite)
  factory Paciente.fromMap(Map<String, dynamic> map) {
    return Paciente(
      id: map['id'],
      nome: map['nome'],
      idade: map['idade'],
      altura: map['altura'],
      peso: map['peso'],
      periodoGestacional: map['periodoGestacional'],
      tratamento: map['tratamento'],
      profissionalId: map['profissionalId'],
      dataCadastro: DateTime.parse(map['dataCadastro']),
    );
  }

  // Método para atualizar
  Paciente copyWith({
    String? nome,
    int? idade,
    double? altura,
    double? peso,
    int? periodoGestacional,
    String? tratamento,
  }) {
    return Paciente(
      id: id,
      nome: nome ?? this.nome,
      idade: idade ?? this.idade,
      altura: altura ?? this.altura,
      peso: peso ?? this.peso,
      periodoGestacional: periodoGestacional ?? this.periodoGestacional,
      tratamento: tratamento ?? this.tratamento,
      profissionalId: profissionalId,
      dataCadastro: dataCadastro,
    );
  }
}