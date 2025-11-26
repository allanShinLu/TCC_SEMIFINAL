import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../model/paciente_model.dart';
import '../model/profissional_model.dart';
import '../services/database_service.dart';

class CadastroPacientePage extends StatefulWidget {
  final Profissional profissional;
  
  const CadastroPacientePage({super.key, required this.profissional});

  @override
  State<CadastroPacientePage> createState() => _CadastroPacientePageState();
}

class _CadastroPacientePageState extends State<CadastroPacientePage> {
  final _nomeController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _solicitarNome();
    });
  }

  void _solicitarNome() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Nome da Paciente',
          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _nomeController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Digite o nome completo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person, color: Colors.pink),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_nomeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('⚠️ Por favor, digite um nome'))
                );
                return;
              }
              Navigator.pop(context);
              _cadastrarPacienteAutomatico();
            },
            child: Text('CADASTRAR', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cadastrarPacienteAutomatico() async {
    setState(() => _carregando = true);

    try {
      final novoPaciente = Paciente(
        id: Uuid().v4(),
        nome: _nomeController.text.trim(),
        idade: 0,
        altura: 0.0,
        peso: 0.0,
        periodoGestacional: 0,
        tratamento: 'Fisioterapia Pélvica Pré-Natal',
        profissionalId: widget.profissional.id,
      );

      final sucesso = await _databaseService.salvarPaciente(novoPaciente);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ ${_nomeController.text} cadastrada com sucesso!'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('❌ Erro ao cadastrar paciente!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('❌ Erro: $e'),
        ),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6FF),
      appBar: AppBar(
        title: Text('Cadastrar Paciente'),
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      body: _carregando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.pink),
                  SizedBox(height: 20),
                  Text(
                    'Cadastrando ${_nomeController.text}...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView( // ✅ GARANTIR SCROLL
              padding: EdgeInsets.all(16),
              child: ConstrainedBox( // ✅ ADICIONADO
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 100,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: 60, color: Colors.pink),
                    SizedBox(height: 20),
                    Text(
                      'Aguardando nome da paciente...',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _solicitarNome,
                      child: Text('DIGITAR NOME NOVAMENTE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                    ),
                    SizedBox(height: 100), 
                  ],
                ),
              ),
            ),
    );
  }
}