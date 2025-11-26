import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../model/profissional_model.dart';
import '../model/paciente_model.dart';
import '../model/sessao_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_medico.db');
    return await openDatabase(
      path,
      version: 3, // ✅ AUMENTE A VERSÃO PARA 3
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sessoes(
              id TEXT PRIMARY KEY,
              pacienteId TEXT NOT NULL,
              dataSessao TEXT NOT NULL,
              observacoes TEXT NOT NULL,
              metricas TEXT NOT NULL,
              duracaoMinutos INTEGER NOT NULL,
              FOREIGN KEY (pacienteId) REFERENCES pacientes (id)
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabela de profissionais
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profissionais(
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        registro TEXT UNIQUE NOT NULL,
        especialidade TEXT NOT NULL,
        senha TEXT NOT NULL,
        dataCadastro TEXT NOT NULL
      )
    ''');

    // Tabela de pacientes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pacientes(
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        idade INTEGER NOT NULL,
        altura REAL NOT NULL,
        peso REAL NOT NULL,
        periodoGestacional INTEGER NOT NULL,
        tratamento TEXT NOT NULL,
        dataCadastro TEXT NOT NULL,
        profissionalId TEXT NOT NULL,
        FOREIGN KEY (profissionalId) REFERENCES profissionais (id)
      )
    ''');

    // ✅ TABELA DE SESSÕES
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessoes(
        id TEXT PRIMARY KEY,
        pacienteId TEXT NOT NULL,
        dataSessao TEXT NOT NULL,
        observacoes TEXT NOT NULL,
        metricas TEXT NOT NULL,
        duracaoMinutos INTEGER NOT NULL,
        FOREIGN KEY (pacienteId) REFERENCES pacientes (id)
      )
    ''');
  }

  // ========== DEBUG - VERIFICAR TABELAS ==========
  Future<void> debugVerificarTabelas() async {
    final db = await database;
    print('🔍 VERIFICANDO TABELAS EXISTENTES:');
    
    try {
      final tabelas = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      for (var tabela in tabelas) {
        print('📊 Tabela: ${tabela['name']}');
      }
      
      // Verificar estrutura da tabela sessoes
      if (tabelas.any((t) => t['name'] == 'sessoes')) {
        final estrutura = await db.rawQuery("PRAGMA table_info(sessoes)");
        print('📋 Estrutura da tabela sessoes:');
        for (var coluna in estrutura) {
          print('   ${coluna['name']} - ${coluna['type']}');
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar tabelas: $e');
    }
  }

  // ========== CRIPTOGRAFIA ==========
  String _criptografarSenha(String senha) {
    var bytes = utf8.encode(senha);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ========== PROFISSIONAIS ==========
  Future<bool> cadastrarProfissional(Profissional profissional) async {
    final db = await database;
    try {
      final profissionalComSenhaCripto = Profissional(
        id: profissional.id,
        nome: profissional.nome,
        email: profissional.email,
        registro: profissional.registro,
        especialidade: profissional.especialidade,
        senha: _criptografarSenha(profissional.senha),
        dataCadastro: profissional.dataCadastro,
      );

      await db.insert('profissionais', profissionalComSenhaCripto.toMap());
      return true;
    } catch (e) {
      print('Erro ao cadastrar profissional: $e');
      return false;
    }
  }

  Future<Profissional?> loginProfissional(String email, String senha) async {
    final db = await database;
    try {
      final senhaCriptografada = _criptografarSenha(senha);
      
      final results = await db.query(
        'profissionais',
        where: 'email = ? AND senha = ?',
        whereArgs: [email, senhaCriptografada],
      );

      if (results.isNotEmpty) {
        return Profissional.fromMap(results.first);
      }
      return null;
    } catch (e) {
      print('Erro no login: $e');
      return null;
    }
  }

  Future<bool> emailJaCadastrado(String email) async {
    final db = await database;
    final results = await db.query(
      'profissionais',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty;
  }

  Future<bool> registroJaCadastrado(String registro) async {
    final db = await database;
    final results = await db.query(
      'profissionais',
      where: 'registro = ?',
      whereArgs: [registro],
    );
    return results.isNotEmpty;
  }

  // ========== PACIENTES ==========
  Future<bool> salvarPaciente(Paciente paciente) async {
    final db = await database;
    try {
      await db.insert('pacientes', paciente.toMap());
      return true;
    } catch (e) {
      print('Erro ao salvar paciente: $e');
      return false;
    }
  }

  Future<List<Paciente>> getPacientesPorProfissional(String profissionalId) async {
    final db = await database;
    final results = await db.query(
      'pacientes',
      where: 'profissionalId = ?',
      whereArgs: [profissionalId],
      orderBy: 'nome ASC',
    );

    return results.map((map) => Paciente.fromMap(map)).toList();
  }

  Future<bool> atualizarPaciente(Paciente paciente) async {
    final db = await database;
    try {
      final linhasAfetadas = await db.update(
        'pacientes',
        paciente.toMap(),
        where: 'id = ?',
        whereArgs: [paciente.id],
      );
      return linhasAfetadas > 0;
    } catch (e) {
      print('Erro ao atualizar paciente: $e');
      return false;
    }
  }

  Future<bool> deletarPaciente(String id) async {
    final db = await database;
    try {
      final linhasAfetadas = await db.delete(
        'pacientes',
        where: 'id = ?',
        whereArgs: [id],
      );
      return linhasAfetadas > 0;
    } catch (e) {
      print('Erro ao deletar paciente: $e');
      return false;
    }
  }

  Future<Paciente?> getPacientePorId(String id) async {
    final db = await database;
    final results = await db.query(
      'pacientes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return Paciente.fromMap(results.first);
    }
    return null;
  }

  // ========== SESSÕES ==========
  Future<bool> salvarSessao(Sessao sessao) async {
    final db = await database;
    try {
      print('💾 Salvando sessão no banco...');
      print('   ID: ${sessao.id}');
      print('   PacienteID: ${sessao.pacienteId}');
      print('   Métricas: ${sessao.metricas}');
      
      final mapa = sessao.toMap();
      print('   Mapa para inserção: $mapa');
      
      await db.insert('sessoes', mapa);
      print('✅ Sessão inserida com sucesso!');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar sessão: $e');
      return false;
    }
  }

  Future<List<Sessao>> getSessoesPorPaciente(String pacienteId) async {
    final db = await database;
    try {
      final results = await db.query(
        'sessoes',
        where: 'pacienteId = ?',
        whereArgs: [pacienteId],
        orderBy: 'dataSessao DESC',
      );

      print('📋 Sessões encontradas: ${results.length}');
      return results.map((map) => Sessao.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar sessões: $e');
      return [];
    }
  }

  Future<bool> deletarSessao(String id) async {
    final db = await database;
    try {
      final linhasAfetadas = await db.delete(
        'sessoes',
        where: 'id = ?',
        whereArgs: [id],
      );
      return linhasAfetadas > 0;
    } catch (e) {
      print('Erro ao deletar sessão: $e');
      return false;
    }
  }
  // No DatabaseService - adicione este método se não existir
Future<List<Sessao>> listarSessoesPorPaciente(String pacienteId) async {
  try {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessoes',
      where: 'pacienteId = ?',
      whereArgs: [pacienteId],
      orderBy: 'dataSessao DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Sessao.fromMap(maps[i]);
    });
  } catch (e) {
    print('❌ Erro ao listar sessões por paciente: $e');
    return [];
  }
}
}