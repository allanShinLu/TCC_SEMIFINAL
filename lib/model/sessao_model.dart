class Sessao {
  final String id;
  final String pacienteId;
  final DateTime dataSessao;
  final String observacoes;
  final Map<String, double> metricas; 
  final int duracaoMinutos;

  Sessao({
    required this.id,
    required this.pacienteId,
    required this.dataSessao,
    this.observacoes = '',
    required this.metricas,
    this.duracaoMinutos = 0,
  });

  // Converter para Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pacienteId': pacienteId,
      'dataSessao': dataSessao.toIso8601String(),
      'observacoes': observacoes,
      'metricas': mapToJson(metricas),
      'duracaoMinutos': duracaoMinutos,
    };
  }

  // Criar a partir de Map (SQLite)
  factory Sessao.fromMap(Map<String, dynamic> map) {
    return Sessao(
      id: map['id'],
      pacienteId: map['pacienteId'],
      dataSessao: DateTime.parse(map['dataSessao']),
      observacoes: map['observacoes'],
      metricas: jsonToMap(map['metricas']), 
      duracaoMinutos: map['duracaoMinutos'],
    );
  }

  // ✅ MÉTODOS AGORA SÃO PÚBLICOS
  static String mapToJson(Map<String, double> map) {
    return map.entries.map((entry) => '${entry.key}:${entry.value}').join(';');
  }

  static Map<String, double> jsonToMap(String json) {
    final Map<String, double> result = {};
    if (json.isNotEmpty) {
      final entries = json.split(';');
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          result[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
        }
      }
    }
    return result;
  }

  // Calcular métricas resumidas
  double get amplitudeMedia {
    if (metricas.isEmpty) return 0.0;
    final valores = metricas.values.toList();
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  // ✅ RESUMO MOVIMENTOS 
  String get resumoMovimentos {
    final movimentos = {
      'frontal': metricas['frontal'] ?? 0,
      'traseiro': metricas['traseiro'] ?? 0,
      'lateral_direita': metricas['lateral_direita'] ?? 0,
      'lateral_esquerda': metricas['lateral_esquerda'] ?? 0,
    };
    
    final melhorMovimento = movimentos.entries.reduce((a, b) => a.value > b.value ? a : b);
    return 'Melhor movimento: ${_formatarMovimento(melhorMovimento.key)} (${melhorMovimento.value.toStringAsFixed(1)})';
  }

  // ✅ FORMATAR MOVIMENTO 
  String _formatarMovimento(String movimento) {
    final map = {
      'frontal': 'Frontal',
      'traseiro': 'Traseiro',
      'lateral_direita': 'Lateral Direita',
      'lateral_esquerda': 'Lateral Esquerda',
    
    };
    return map[movimento] ?? movimento;
  }
}