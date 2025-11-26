import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'services/database_service.dart';
import 'model/profissional_model.dart';

class CadastroProfissionalPage extends StatefulWidget {
  const CadastroProfissionalPage({super.key});

  @override
  State<CadastroProfissionalPage> createState() => _CadastroProfissionalPageState();
}

class _CadastroProfissionalPageState extends State<CadastroProfissionalPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _registroController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  
  final List<String> _especialidades = [
    'Fisioterapia Pélvica',
    'Ginecologia',
    'Obstetrícia',
    'Fisioterapia',
    'Enfermagem'
  ];

  String _especialidadeSelecionada = 'Fisioterapia Pélvica';
  bool _carregando = false;

  Future<void> _cadastrarProfissional() async {
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('As senhas não coincidem!'),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      // Verificar se email já existe
      final emailExiste = await _databaseService.emailJaCadastrado(_emailController.text.trim());
      if (emailExiste) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Este email já está cadastrado!'),
          ),
        );
        return;
      }

      // Verificar se registro já existe
      final registroExiste = await _databaseService.registroJaCadastrado(_registroController.text.trim());
      if (registroExiste) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Este registro profissional já está cadastrado!'),
          ),
        );
        return;
      }

      final novoProfissional = Profissional(
        id: Uuid().v4(),
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        registro: _registroController.text.trim(),
        especialidade: _especialidadeSelecionada,
        senha: _senhaController.text,
      );

      final sucesso = await _databaseService.cadastrarProfissional(novoProfissional);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Profissional cadastrado com sucesso!'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Erro ao cadastrar profissional!'),
          ),
        );
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Erro: $e'),
        ),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro Profissional'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox( // ✅ ADICIONADO
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 100,
          ),
          child: Column(
            children: [
              const Text(
                'CADASTRO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _especialidadeSelecionada,
                items: _especialidades.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _especialidadeSelecionada = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Especialidade',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅
                ),
              ),
              
              const SizedBox(height: 12),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _registroController,
                decoration: const InputDecoration(
                  labelText: 'Registro Profissional',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmarSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Senha',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _carregando ? null : _cadastrarProfissional,
                child: _carregando 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CADASTRAR PROFISSIONAL', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 40), // ✅ MAIS ESPAÇO
            ],
          ),
        ),
      ),
    );
  }
}