import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'login_page.dart';
import 'cadastro_profissional_page.dart';
import 'paciente_detalhes_page.dart';
import 'exames_page.dart';
import 'tela_inicial_page.dart'; 
import 'area_exercicios_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar o banco (agora é automático)
  final databaseService = DatabaseService();
  await databaseService.database; // Isso inicializa o banco
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Médico - SQLite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => TelaInicialPage(),
        '/login': (context) => LoginPage(),
        '/cadastro_profissional': (context) => CadastroProfissionalPage(),
        '/area_exercicios': (context) => AreaExerciciosPage(),
        //'/pacientes': (context) => PacientesPage(),
        '/detalhes': (context) => PacienteDetalhesPage(),
        '/exames': (context) => ExamesPage(),
      },
      initialRoute: '/',
    );
  }
}