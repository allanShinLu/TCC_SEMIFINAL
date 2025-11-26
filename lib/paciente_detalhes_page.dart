import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/paciente_model.dart';
import '../model/sessao_model.dart';
import '../services/database_service.dart';
import 'nova_sessao_page.dart';

class PacienteDetalhesPage extends StatefulWidget {
  const PacienteDetalhesPage({super.key});

  @override
  State<PacienteDetalhesPage> createState() => _PacienteDetalhesPageState();
}

class _PacienteDetalhesPageState extends State<PacienteDetalhesPage> {
  final DatabaseService _databaseService = DatabaseService();
  late Paciente _paciente;
  bool _editando = false;

  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _gestacaoController = TextEditingController();
  final _tratamentoController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final paciente = ModalRoute.of(context)!.settings.arguments as Paciente;
    _paciente = paciente;
    _carregarDados();
  }

  void _carregarDados() {
    _nomeController.text = _paciente.nome;
    _idadeController.text = _paciente.idade.toString();
    _alturaController.text = _paciente.altura.toString();
    _pesoController.text = _paciente.peso.toString();
    _gestacaoController.text = _paciente.periodoGestacional.toString();
    _tratamentoController.text = _paciente.tratamento;
  }

  Future<void> _salvarAlteracoes() async {
    final pacienteAtualizado = _paciente.copyWith(
      nome: _nomeController.text.trim(),
      idade: int.tryParse(_idadeController.text) ?? 0,
      altura: double.tryParse(_alturaController.text) ?? 0.0,
      peso: double.tryParse(_pesoController.text) ?? 0.0,
      periodoGestacional: int.tryParse(_gestacaoController.text) ?? 0,
      tratamento: _tratamentoController.text,
    );

    final sucesso = await _databaseService.atualizarPaciente(pacienteAtualizado);
    
    if (sucesso) {
      setState(() {
        _paciente = pacienteAtualizado;
        _editando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Dados atualizados com sucesso!'),
        ),
      );
      Navigator.pop(context, pacienteAtualizado);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Erro ao atualizar dados!'),
        ),
      );
    }
  }

  void _mostrarDetalhesSessao(Sessao sessao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sessão - ${DateFormat('dd/MM/yyyy').format(sessao.dataSessao)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duração: ${sessao.duracaoMinutos} minutos'),
              SizedBox(height: 8),
              Text('Observações: ${sessao.observacoes.isEmpty ? "Nenhuma" : sessao.observacoes}'),
              SizedBox(height: 16),
              Text('Métricas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              ...sessao.metricas.entries.map((e) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('${_formatarTituloMetrica(e.key)}: ${e.value.toStringAsFixed(1)}'),
                )
              ).toList(),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sessao.resumoMovimentos, 
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue[800]),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  void _mostrarTodasSessoes(List<Sessao> sessoes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text(
                'Todas as Sessões (${sessoes.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sessoes.length,
                  itemBuilder: (context, index) {
                    final sessao = sessoes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.assignment, color: Colors.purple),
                        title: Text(DateFormat('dd/MM/yyyy - HH:mm').format(sessao.dataSessao)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duração: ${sessao.duracaoMinutos} min'),
                            Text(
                              sessao.resumoMovimentos,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _mostrarDetalhesSessao(sessao);
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('FECHAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FORMATAR TÍTULO MÉTRICA - SEM ROTAÇÃO
  String _formatarTituloMetrica(String titulo) {
    final map = {
      'anterior': 'Anterior',
      'posterior': 'Posterior',
      'lateral_direita': 'Lateral Direita',
      'lateral_esquerda': 'Lateral Esquerda',
      // REMOVIDO: 'rotacao': 'Rotação',
    };
    return map[titulo] ?? titulo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes - ${_paciente.nome}'),
        backgroundColor: Color(0xFF89CFF0),
        actions: [
          if (!_editando)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, _paciente);
              },
            ),
          IconButton(
            icon: Icon(_editando ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_editando) {
                _salvarAlteracoes();
              } else {
                setState(() => _editando = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABEÇALHO COM AVATAR
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF89CFF0), Color(0xFFB5EAD7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF89CFF0).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFB7C5), Color(0xFFFFD1DC)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Text(
                          _paciente.nome[0],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF89CFF0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _paciente.nome,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // CARTÃO DE INFORMAÇÕES
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB7C5).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFF0F0F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações da Paciente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 15),
                    
                    // CAMPO NOME
                    _buildInfoItem(
                      label: 'Nome',
                      value: _nomeController.text,
                      unit: '',
                      icon: Icons.person,
                      color: const Color(0xFFFF6B8B), 
                      editando: _editando,
                      controller: _nomeController,
                    ),
                    // CAMPO IDADE
                    _buildInfoItem(
                      label: 'Idade',
                      value: _idadeController.text,
                      unit: 'anos',
                      icon: Icons.calendar_today,
                      color: const Color(0xFFFFB7C5),
                      editando: _editando,
                      controller: _idadeController,
                    ),
                    
                    // CAMPO ALTURA
                    _buildInfoItem(
                      label: 'Altura',
                      value: _alturaController.text,
                      unit: 'm',
                      icon: Icons.height,
                      color: const Color(0xFF89CFF0),
                      editando: _editando,
                      controller: _alturaController,
                    ),
                    
                    // CAMPO PESO
                    _buildInfoItem(
                      label: 'Peso',
                      value: _pesoController.text,
                      unit: 'kg',
                      icon: Icons.monitor_weight,
                      color: const Color(0xFFB5EAD7),
                      editando: _editando,
                      controller: _pesoController,
                    ),
                    
                    // CAMPO PERÍODO GESTACIONAL
                    _buildInfoItem(
                      label: 'Período Gestacional',
                      value: _gestacaoController.text,
                      unit: 'semanas',
                      icon: Icons.pregnant_woman,
                      color: const Color(0xFFFFD1DC),
                      editando: _editando,
                      controller: _gestacaoController,
                    ),
                    
                    // CAMPO TRATAMENTO
                    _buildInfoItem(
                      label: 'Tratamento',
                      value: _tratamentoController.text,
                      unit: '',
                      icon: Icons.medical_services,
                      color: const Color(0xFFC9C9FF),
                      editando: _editando,
                      controller: _tratamentoController,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // LISTA DE SESSÕES
              FutureBuilder<List<Sessao>>(
                future: _databaseService.getSessoesPorPaciente(_paciente.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.assessment, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Nenhuma sessão registrada',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NovaSessaoPage(paciente: _paciente),
                                ),
                              );
                            },
                            child: Text('CRIAR PRIMEIRA SESSÃO'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final sessoes = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sessões Realizadas (${sessoes.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555555),
                            ),
                          ),
                          if (sessoes.length > 3)
                            TextButton(
                              onPressed: () {
                                _mostrarTodasSessoes(sessoes);
                              },
                              child: Text('Ver todas'),
                            ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ...sessoes.take(3).map((sessao) => Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(Icons.assignment, color: Colors.purple),
                          title: Text(DateFormat('dd/MM/yyyy - HH:mm').format(sessao.dataSessao)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duração: ${sessao.duracaoMinutos} min'),
                              Text(
                                sessao.resumoMovimentos,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _mostrarDetalhesSessao(sessao);
                          },
                        ),
                      )).toList(),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),

              // BOTÃO VER EXAMES
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9370DB).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/exames',
                      arguments: _paciente,
                    );
                  },
                  icon: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: const Text(
                    'VER EXAMES E GRÁFICOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9370DB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // BOTÃO NOVA SESSÃO
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6B8B).withOpacity(0.4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NovaSessaoPage(paciente: _paciente),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.add_chart,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    'NOVA SESSÃO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF6B8B),
                    padding: EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              // BOTÕES DE AÇÃO (quando editando)
              if (_editando) ...[
                SizedBox(height: 20),
                Row(
                  children: [
                    // BOTÃO CANCELAR
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _editando = false;
                              _carregarDados();
                            });
                          },
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // BOTÃO SALVAR
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB5EAD7).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _salvarAlteracoes,
                          child: const Text(
                            'Salvar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB5EAD7),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET AUXILIAR PARA OS CAMPOS DE INFORMAÇÃO
  Widget _buildInfoItem({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool editando,
    required TextEditingController controller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                editando
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (unit.isNotEmpty)
                            Text(
                              ' $unit',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      )
                    : Text(
                        '$value${unit.isNotEmpty ? ' $unit' : ''}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}