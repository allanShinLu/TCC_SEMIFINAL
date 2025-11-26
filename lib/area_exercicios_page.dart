import 'package:flutter/material.dart';
import 'dart:async';

class AreaExerciciosPage extends StatefulWidget {
  const AreaExerciciosPage({super.key});

  @override
  State<AreaExerciciosPage> createState() => _AreaExerciciosPageState();
}

class _AreaExerciciosPageState extends State<AreaExerciciosPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  bool _exercicioIniciado = false;
  int _direcaoAtual = 0; // 0: frente, 1: trás, 2: direita, 3: esquerda
  int _tempoRestante = 4;
  Timer? _timer;

  final List<Map<String, dynamic>> _direcoes = [
    {
      'nome': 'PARA FRENTE',
      'icone': Icons.arrow_upward,
      'cor': Color(0xFF4CAF50), // Verde
      'rotacao': 0.0,
    },
    {
      'nome': 'PARA TRÁS',
      'icone': Icons.arrow_downward,
      'cor': Color(0xFF2196F3), // Azul
      'rotacao': 3.14, // 180 graus
    },
    {
      'nome': 'DIREITA',
      'icone': Icons.arrow_forward,
      'cor': Color(0xFFFF9800), // Laranja
      'rotacao': 1.57, // 90 graus
    },
    {
      'nome': 'ESQUERDA',
      'icone': Icons.arrow_back,
      'cor': Color(0xFF9C27B0), // Roxo
      'rotacao': -1.57, // -90 graus
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  void _iniciarExercicio() {
    setState(() {
      _exercicioIniciado = true;
      _direcaoAtual = 0;
      _tempoRestante = 4;
    });
    
    _iniciarContagem();
  }

  void _iniciarContagem() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _tempoRestante--;
      });

      if (_tempoRestante == 0) {
        _proximaDirecao();
      }
    });
  }

  void _proximaDirecao() {
    setState(() {
      _direcaoAtual = (_direcaoAtual + 1) % _direcoes.length;
      _tempoRestante = 4;
    });
    
    // Animação de transição
    _animationController.reset();
    _animationController.forward();
  }

  void _pararExercicio() {
    _timer?.cancel();
    setState(() {
      _exercicioIniciado = false;
      _tempoRestante = 4;
      _direcaoAtual = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final direcao = _direcoes[_direcaoAtual];

    return Scaffold(
      backgroundColor: Color(0xFFF8F6FF),
      appBar: AppBar(
        title: Text('Área de Exercícios'),
        backgroundColor: Color(0xFFFFB7C5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _pararExercicio();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // INSTRUÇÕES
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Exercícios de Movimentação',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Siga as direções indicadas pela bola\nCada movimento dura 4 segundos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // BOLA ANIMADA
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: direcao['rotacao'] * _animation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: direcao['cor'],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: direcao['cor'].withOpacity(0.5),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_basketball,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // INDICADOR DE DIREÇÃO
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_exercicioIniciado) ...[
                  // DIREÇÃO ATUAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        direcao['icone'],
                        color: direcao['cor'],
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        direcao['nome'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: direcao['cor'],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // CONTAGEM REGRESSIVA
                  Text(
                    '$_tempoRestante',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: direcao['cor'],
                    ),
                  ),
                  Text(
                    'segundos',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // BOTÃO PARAR
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pararExercicio,
                      icon: Icon(Icons.stop, color: Colors.white),
                      label: Text('PARAR EXERCÍCIO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // BOTÃO INICIAR
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _iniciarExercicio,
                      icon: Icon(Icons.play_arrow, color: Colors.white),
                      label: Text('INICIAR EXERCÍCIO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFB7C5),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Text(
                    'Clique em iniciar para começar os exercícios\nA bola irá girar para cada direção automaticamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}