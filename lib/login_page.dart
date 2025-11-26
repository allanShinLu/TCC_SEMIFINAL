import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'services/database_service.dart';
import 'cadastro_profissional_page.dart';
import 'pacientes_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _carregando = false;
  bool _mostrarSenha = false;

  Future<void> _fazerLogin() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Preencha email e senha!'),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      final profissional = await _databaseService.loginProfissional(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (profissional != null) {
        // Login bem-sucedido
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PacientesPage(profissional: profissional),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Email ou senha incorretos!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Erro ao fazer login: $e'),
        ),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  // ✅ NOVO MÉTODO: Voltar para tela inicial
  void _voltarParaTelaInicial() {
    Navigator.pushReplacementNamed(context, '/'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      //  title: const Text('Voltar'),
      backgroundColor: Colors.pink,
      elevation: 0,
      //  leading: IconButton( 
       //   icon: const Icon(Icons.arrow_back),
       //   onPressed: _voltarParaTelaInicial,
    //    ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Área de Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _senhaController,
              obscureText: !_mostrarSenha,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),
            
            Row(
              children: [
                Checkbox(
                  value: _mostrarSenha,
                  onChanged: (value) {
                    setState(() {
                      _mostrarSenha = value!;
                    });
                  },
                ),
                const Text('Mostrar senha'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _carregando ? null : _fazerLogin,
              child: _carregando 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('ENTRAR', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF89CFF0),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _carregando ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CadastroProfissionalPage(),
                  ),
                );
              },
              child: const Text('CRIAR NOVA CONTA', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFB7C5).withOpacity(0.3),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            // ✅ BOTÃO VOLTAR PARA TELA INICIAL
            const SizedBox(height: 12),
            TextButton(
              onPressed: _voltarParaTelaInicial,
              child: const Text(
                '← Voltar para Tela Inicial',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}