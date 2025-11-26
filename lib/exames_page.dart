import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/paciente_model.dart';
import '../model/sessao_model.dart';
import '../services/database_service.dart';

class ExamesPage extends StatefulWidget {
  const ExamesPage({super.key});

  @override
  State<ExamesPage> createState() => _ExamesPageState();
}

class _ExamesPageState extends State<ExamesPage> {
  late Paciente _paciente;
  final DatabaseService _databaseService = DatabaseService();
  List<Sessao> _sessoes = [];
  bool _carregando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _paciente = ModalRoute.of(context)!.settings.arguments as Paciente;
    _carregarSessoes();
  }

  Future<void> _carregarSessoes() async {
    try {
      final sessoes = await _databaseService.listarSessoesPorPaciente(_paciente.id);
      setState(() {
        _sessoes = sessoes;
        _carregando = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar sessões: $e');
      setState(() {
        _carregando = false;
      });
    }
  }

  void _novaSessao() {
    Navigator.pushNamed(context, '/novaSessao', arguments: _paciente)
        .then((_) => _carregarSessoes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exames - ${_paciente.nome}'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _novaSessao,
            tooltip: 'Nova Sessão',
          ),
        ],
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : _sessoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Nenhum exame encontrado',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Inicie uma nova sessão para ver os resultados',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _novaSessao,
                        icon: Icon(Icons.play_arrow),
                        label: Text('INICIAR PRIMEIRA SESSÃO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // RESUMO DO PACIENTE
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.purple.withOpacity(0.2),
                                child: Icon(Icons.person, color: Colors.purple),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _paciente.nome,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${_sessoes.length} sessão(ões) realizadas',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // LISTA DE EXAMES/SESSÕES
                      Expanded(
                        child: ListView.builder(
                          itemCount: _sessoes.length,
                          itemBuilder: (context, index) {
                            final sessao = _sessoes[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // CABEÇALHO DA SESSÃO
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sessão ${DateFormat('dd/MM/yyyy').format(sessao.dataSessao)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('HH:mm').format(sessao.dataSessao),
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: 8),
                                    
                                    // INFORMAÇÕES DA SESSÃO
                                    if (sessao.observacoes != null && sessao.observacoes!.isNotEmpty)
                                      Column(
                                        children: [
                                          Text(
                                            'Observações: ${sessao.observacoes}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                        ],
                                      ),
                                    
                                    Text(
                                      'Duração: ${sessao.duracaoMinutos} minutos',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    
                                    SizedBox(height: 16),
                                    
                                    // GRÁFICO RADAR
                                    Container(
                                      height: 250,
                                      child: Center(
                                        child: RadarChart(
                                          metricas: sessao.metricas,
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(height: 16),
                                    
                                    // VALORES NUMÉRICOS
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: sessao.metricas.entries.map((entry) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getColorPorMovimento(entry.key).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _getColorPorMovimento(entry.key).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getIconPorMovimento(entry.key),
                                                size: 16,
                                                color: _getColorPorMovimento(entry.key),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${_formatarTituloCurto(entry.key)}: ${entry.value.toInt()}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getColorPorMovimento(entry.key),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      // BOTÃO FLUTUANTE PARA NOVA SESSÃO
      floatingActionButton: FloatingActionButton(
        onPressed: _novaSessao,
        backgroundColor: Colors.purple,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Nova Sessão',
      ),
    );
  }

  // ✅ FORMATAR TÍTULO 
  String _formatarTituloCurto(String titulo) {
    final map = {
      'anterior': 'Anterior',
      'posterior': 'Posterior',
      'lateral_direita': 'Direita',
      'lateral_esquerda': 'Esquerda',
    };
    return map[titulo] ?? titulo;
  }

  // ✅ ÍCONES - SEM ROTAÇÃO
  IconData _getIconPorMovimento(String movimento) {
    final icons = {
      'Anterior': Icons.arrow_upward,
      'Posterior': Icons.arrow_downward,
      'lateral_direita': Icons.arrow_forward,
      'lateral_esquerda': Icons.arrow_back,
    };
    return icons[movimento] ?? Icons.help;
  }

  // ✅ CORES
  Color _getColorPorMovimento(String movimento) {
    final colors = {
      'Anterior': Colors.green,
      'Posterior': Colors.blue,
      'lateral_direita': Colors.orange,
      'lateral_esquerda': Colors.purple,
    };
    return colors[movimento] ?? Colors.grey;
  }
}

// GRÁFICO RADAR - WIDGET PERSONALIZADO
class RadarChart extends StatelessWidget {
  final Map<String, double> metricas;

  const RadarChart({super.key, required this.metricas});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(220, 220),
      painter: RadarChartPainter(metricas: metricas),
    );
  }
}

// PAINTER PARA DESENHAR O GRÁFICO RADAR - QUADRADO (4 DIREÇÕES)
class RadarChartPainter extends CustomPainter {
  final Map<String, double> metricas;

  RadarChartPainter({required this.metricas});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.75;
    
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // ✅ DEFINIR OS 4 PONTOS (quadrado) - SEM ROTAÇÃO
    final List<Offset> pontosExternos = [];
    final List<String> direcoes = ['anterior', 'lateral_direita', 'posterior', 'lateral_esquerda'];
    final List<Color> cores = [Colors.green, Colors.orange, Colors.blue, Colors.purple];
    
    // DESENHAR CÍRCULOS CONCÊNTRICOS (níveis 1-5)
    for (int nivel = 1; nivel <= 5; nivel++) {
      final circlePaint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      
      canvas.drawCircle(center, radius * nivel / 5, circlePaint);
    }
    
    // CALCULAR PONTOS EXTERNOS E PONTOS DOS VALORES
    final List<Offset> pontosValores = [];
    
    for (int i = 0; i < 4; i++) { // ✅ AGORA 4 DIREÇÕES
      final angle = -pi / 2 + (2 * pi * i / 4); // ✅ 4 DIREÇÕES
      
      // Ponto externo (valor máximo)
      final pontoExterno = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      pontosExternos.add(pontoExterno);
      
      // Linha do centro até o ponto externo
      canvas.drawLine(center, pontoExterno, linePaint);
      
      // Ponto do valor real
      double valor = metricas[direcoes[i]] ?? 0.0;
      double valorNormalizado = (valor / 5.0).clamp(0.0, 1.0);
      
      final pontoValor = Offset(
        center.dx + radius * valorNormalizado * cos(angle),
        center.dy + radius * valorNormalizado * sin(angle),
      );
      pontosValores.add(pontoValor);
    }
    
    // DESENHAR ÁREA PREENCHIDA (os "cones")
    final areaPath = Path();
    for (int i = 0; i < pontosValores.length; i++) {
      if (i == 0) {
        areaPath.moveTo(pontosValores[i].dx, pontosValores[i].dy);
      } else {
        areaPath.lineTo(pontosValores[i].dx, pontosValores[i].dy);
      }
    }
    areaPath.close();
    
    final areaPaint = Paint()
      ..color = Colors.purple.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(areaPath, areaPaint);
    
    // DESENHAR LINHA DA ÁREA
    final linhaPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(areaPath, linhaPaint);
    
    // DESENHAR PONTOS NOS VALORES
    for (int i = 0; i < pontosValores.length; i++) {
      final pontoPaint = Paint()
        ..color = cores[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(pontosValores[i], 4, pontoPaint);
    }
    
    // DESENHAR LINHA EXTERNA DO QUADRADO
    final externoPath = Path();
    externoPath.moveTo(pontosExternos[0].dx, pontosExternos[0].dy);
    for (int i = 1; i < pontosExternos.length; i++) {
      externoPath.lineTo(pontosExternos[i].dx, pontosExternos[i].dy);
    }
    externoPath.close();
    canvas.drawPath(externoPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}