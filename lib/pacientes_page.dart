import 'package:flutter/material.dart';
import '../model/paciente_model.dart';
import '../model/profissional_model.dart';
import '../services/database_service.dart';
import 'paciente_detalhes_page.dart';
import 'cadastro_paciente_page.dart';

class PacientesPage extends StatefulWidget {
  final Profissional profissional;
  
  const PacientesPage({super.key, required this.profissional});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];
  bool _carregando = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPacientes();
    _searchController.addListener(_filtrarPacientes);
  }

  Future<void> _carregarPacientes() async {
    try {
      final pacientes = await _databaseService.getPacientesPorProfissional(widget.profissional.id);
      setState(() {
        _pacientes = pacientes;
        _pacientesFiltrados = pacientes;
        _carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar pacientes: $e');
      setState(() => _carregando = false);
    }
  }

  void _filtrarPacientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _pacientesFiltrados = _pacientes;
      } else {
        _pacientesFiltrados = _pacientes.where((paciente) {
          return paciente.nome.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _atualizarPacienteNaLista(Paciente pacienteAtualizado) {
    setState(() {
      final index = _pacientes.indexWhere((p) => p.id == pacienteAtualizado.id);
      if (index != -1) {
        _pacientes[index] = pacienteAtualizado;
        _filtrarPacientes();
      }
    });
  }

  Future<void> _adicionarPaciente() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroPacientePage(profissional: widget.profissional),
      ),
    );
    _carregarPacientes();
  }

  Future<void> _atualizarLista() async {
    setState(() => _carregando = true);
    await _carregarPacientes();
  }

  // ✅ NOVO MÉTODO: Voltar para o Login
  void _voltarParaLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pacientes - ${widget.profissional.nome.split(' ')[0]}'),
        backgroundColor: Colors.blue,
        actions: [
          // ✅ BOTÃO SAIR - VOLTAR PARA LOGIN
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _voltarParaLogin,
            tooltip: 'Sair para Login',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarPaciente,
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Adicionar nova paciente',
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '🔍 Buscar paciente...',
                prefixIcon: Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),

          // INDICADOR DE RESULTADOS
          if (_searchController.text.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '${_pacientesFiltrados.length} paciente(s) encontrado(s)',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: Text(
                      'Limpar',
                      style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // LISTA DE PACIENTES
          Expanded(
            child: _carregando
                ? Center(child: CircularProgressIndicator(color: Colors.blue))
                : _pacientesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isEmpty ? Icons.people_outline : Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty 
                                  ? 'Nenhuma paciente cadastrada.\nClique no + para adicionar.'
                                  : 'Nenhuma paciente encontrada.\nTente outro nome.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            if (_searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                child: Text('Limpar busca'),
                              ),
                            // ✅ BOTÃO VOLTAR PARA LOGIN NO CENTRO TAMBÉM
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _voltarParaLogin,
                              icon: Icon(Icons.arrow_back, size: 16),
                              label: Text('Voltar para Login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _atualizarLista,
                        child: ListView.builder(
                          itemCount: _pacientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final paciente = _pacientesFiltrados[index];
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    paciente.nome[0],
                                    style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  paciente.nome,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Idade: ${paciente.idade} anos'),
                                    Text('Período gestacional: ${paciente.periodoGestacional} semanas'),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                onTap: () async {
                                  final pacienteAtualizado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PacienteDetalhesPage(),
                                      settings: RouteSettings(arguments: paciente),
                                    ),
                                  );
                                  
                                  if (pacienteAtualizado != null && pacienteAtualizado is Paciente) {
                                    _atualizarPacienteNaLista(pacienteAtualizado);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // ✅ BOTÃO VOLTAR PARA LOGIN NO RODAPÉ
          if (_pacientesFiltrados.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _voltarParaLogin,
                icon: Icon(Icons.arrow_back, size: 16),
                label: Text('Voltar para Tela de Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}