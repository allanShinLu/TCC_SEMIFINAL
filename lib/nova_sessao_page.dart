import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/sessao_model.dart';
import '../model/paciente_model.dart';
import '../services/database_service.dart';
import '../config/esp32_config.dart';

class NovaSessaoPage extends StatefulWidget {
  final Paciente paciente;
  
  const NovaSessaoPage({super.key, required this.paciente});

  @override
  State<NovaSessaoPage> createState() => _NovaSessaoPageState();
}

class _NovaSessaoPageState extends State<NovaSessaoPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _observacoesController = TextEditingController();
  
  bool _capturandoDados = false;
  bool _dadosCapturados = false;
  Map<String, double> _metricas = {};
  Map<String, int> _maioresValores = {};
  int _tempoDecorrido = 0;
  Timer? _timerCaptura;
  bool _salvando = false;

  // ✅ VARIÁVEIS BLUETOOTH
  BluetoothDevice? _deviceESP32;
  BluetoothCharacteristic? _characteristic;
  bool _conectandoBluetooth = false;
  bool _bluetoothLigado = false;
  List<BluetoothDevice> _devicesEncontrados = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _inicializarBluetooth();
    _inicializarMaioresValores();
  }

  // ✅ INICIALIZAR MAIORES VALORES - SEM ROTAÇÃO
  void _inicializarMaioresValores() {
    setState(() {
      _maioresValores = {
        'anterior': 0,
        'posterior': 0,
        'lateral_direita': 0,
        'lateral_esquerda': 0,
      };
    });
  }

  @override
  void dispose() {
    _timerCaptura?.cancel();
    _scanSubscription?.cancel();
    _desconectarESP32();
    super.dispose();
  }

  // ✅ INICIALIZAR BLUETOOTH
  Future<void> _inicializarBluetooth() async {
    try {
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
      await Permission.location.request();

      bool isOn = await FlutterBluePlus.isOn;
      setState(() {
        _bluetoothLigado = isOn;
      });

      if (!_bluetoothLigado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor, ligue o Bluetooth'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      _iniciarScanBluetooth();

    } catch (e) {
      print('❌ Erro ao inicializar Bluetooth: $e');
    }
  }

  // ✅ INICIAR SCAN BLUETOOTH
  void _iniciarScanBluetooth() {
    _scanSubscription?.cancel();
    
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _devicesEncontrados = results
              .where((result) => result.device.platformName.isNotEmpty)
              .map((result) => result.device)
              .toList();
        });
      }
    });

    FlutterBluePlus.startScan(
      timeout: Duration(seconds: 10),
      withNames: [ESP32Config.deviceName],
    );
  }

  // ✅ CONECTAR À ESP32
  Future<void> _conectarESP32(BluetoothDevice device) async {
    if (!mounted) return;
    
    setState(() {
      _conectandoBluetooth = true;
    });

    try {
      await device.connect();
      _deviceESP32 = device;

      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString() == ESP32Config.serviceUUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == ESP32Config.characteristicUUID) {
              _characteristic = characteristic;
              
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((dados) {
                if (mounted) {
                  _processarDadosESP32(dados);
                }
              });
              
              break;
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Conectado à ESP32: ${device.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('❌ Erro ao conectar ESP32: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao conectar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _conectandoBluetooth = false;
        });
      }
    }
  }

  // ✅ PROCESSAR DADOS RECEBIDOS DA ESP32
  void _processarDadosESP32(List<int> dados) {
    try {
      String dadosString = String.fromCharCodes(dados).trim();
      print('📡 Dados recebidos: $dadosString');
      
      Map<String, double> novosDados = _processarBlocoDados(dadosString);
      
      if (novosDados.isEmpty) {
        novosDados = _parsearDadosFirmware(dadosString);
      }
      
      if (novosDados.isNotEmpty && mounted) {
        setState(() {
          novosDados.forEach((movimento, valor) {
            _metricas[movimento] = valor;
            
            int valorInteiro = valor.round();
            if (valorInteiro > (_maioresValores[movimento] ?? 0)) {
              _maioresValores[movimento] = valorInteiro;
            }
          });
          
          print('✅ Métricas atualizadas: $_metricas');
          print('✅ Maiores valores: $_maioresValores');
        });
      }

    } catch (e) {
      print('❌ Erro ao processar dados ESP32: $e');
    }
  }

  // ✅ CONVERTER DADOS DO FIRMWARE
  Map<String, double> _parsearDadosFirmware(String dadosString) {
    Map<String, double> dadosProcessados = {};
    
    try {
      String movimento = '';
      int indice = 0;
      
      List<String> linhas = dadosString.split('\n');
      
      for (String linha in linhas) {
        linha = linha.trim();
        
        if (linha.startsWith('Movimento: ')) {
          movimento = linha.replaceFirst('Movimento: ', '').trim();
          print('🎯 Movimento detectado: $movimento');
        }
        
        if (linha.startsWith('Índice (1–5): ')) {
          String indiceStr = linha.replaceFirst('Índice (1–5): ', '').trim();
          indice = int.tryParse(indiceStr) ?? 0;
          print('📊 Índice detectado: $indice');
        }
      }
      
      // ✅ CORREÇÃO: Verifica se o movimento existe no mapeamento E não é Neutro
      if (movimento.isNotEmpty && movimento != 'Neutro' && indice > 0) {
        String movimentoApp = ESP32Config.getMovimentoPorVariavel(movimento);
        if (movimentoApp.isNotEmpty) { // ✅ Só processa se o movimento for mapeado
          double valorNormalizado = ESP32Config.converterValorFirmware(movimento, indice.toDouble());
          dadosProcessados[movimentoApp] = valorNormalizado;
        }
      }
      
    } catch (e) {
      print('❌ Erro ao extrair movimento e índice: $e');
    }
    
    return dadosProcessados;
  }

  // ✅ PROCESSAMENTO POR BLOCO
  Map<String, double> _processarBlocoDados(String dadosString) {
    Map<String, double> dadosProcessados = {};
    
    try {
      if (dadosString.contains('=====================================')) {
        List<String> partes = dadosString.split('=====================================');
        
        if (partes.length >= 2) {
          String blocoDados = partes[1];
          
          RegExp movimentoRegex = RegExp(r'Movimento: (\w+)');
          RegExp indiceRegex = RegExp(r'Índice \(1–5\): (\d)');
          
          Match? movimentoMatch = movimentoRegex.firstMatch(blocoDados);
          Match? indiceMatch = indiceRegex.firstMatch(blocoDados);
          
          if (movimentoMatch != null && indiceMatch != null) {
            String movimento = movimentoMatch.group(1)!;
            int indice = int.parse(indiceMatch.group(1)!);
            
            // ✅ CORREÇÃO: Verifica se o movimento existe no mapeamento E não é Neutro
            if (movimento != 'Neutro') {
              String movimentoApp = ESP32Config.getMovimentoPorVariavel(movimento);
              if (movimentoApp.isNotEmpty) { // ✅ Só processa se o movimento for mapeado
                double valorNormalizado = ESP32Config.converterValorFirmware(movimento, indice.toDouble());
                dadosProcessados[movimentoApp] = valorNormalizado;
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Erro no processamento por bloco: $e');
    }
    
    return dadosProcessados;
  }

  // ✅ DESCONECTAR ESP32
  Future<void> _desconectarESP32() async {
    if (_deviceESP32 != null) {
      await _deviceESP32!.disconnect();
      if (mounted) {
        setState(() {
          _deviceESP32 = null;
        });
      }
    }
  }

  // ✅ INICIAR CAPTURA SIMULADA
  void _iniciarCaptura() {
    if (!mounted) return;
    
    setState(() {
      _capturandoDados = true;
      _tempoDecorrido = 0;
      _metricas = {};
      _inicializarMaioresValores();
      _dadosCapturados = false;
    });

    _timerCaptura = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _tempoDecorrido++;
        
        if (_tempoDecorrido <= 30) {
          final random = Random();
          // ✅ DADOS SIMULADOS - SEM ROTAÇÃO
          Map<String, double> novosDados = {
            'anterior': (random.nextDouble() * 4 + 1),
            'posterior': (random.nextDouble() * 4 + 1),
            'lateral_direita': (random.nextDouble() * 4 + 1),
            'lateral_esquerda': (random.nextDouble() * 4 + 1),
          };
          
          novosDados.forEach((movimento, valor) {
            _metricas[movimento] = valor;
            
            int valorInteiro = valor.round();
            if (valorInteiro > (_maioresValores[movimento] ?? 0)) {
              _maioresValores[movimento] = valorInteiro;
            }
          });
        } else {
          _finalizarCaptura();
        }
      });
    });
  }

  // ✅ CAPTURA REAL COM BLUETOOTH
  void _iniciarCapturaReal() {
    if (!mounted) return;
    
    setState(() {
      _capturandoDados = true;
      _tempoDecorrido = 0;
      _metricas = {};
      _inicializarMaioresValores();
      _dadosCapturados = false;
    });

    _timerCaptura = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _tempoDecorrido++;
      });
      
      if (_tempoDecorrido >= 30) {
        _finalizarCaptura();
      }
    });
  }

  void _finalizarCaptura() {
    _timerCaptura?.cancel();
    if (mounted) {
      setState(() {
        _capturandoDados = false;
        _dadosCapturados = true;
      });
    }
  }

  Future<void> _salvarSessao() async {
    if (_maioresValores.isEmpty || _maioresValores.values.every((v) => v == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum dado capturado para salvar'),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }

    if (_salvando) return;

    setState(() {
      _salvando = true;
    });

    try {
      final novaSessao = Sessao(
        id: Uuid().v4(),
        pacienteId: widget.paciente.id,
        dataSessao: DateTime.now(),
        observacoes: _observacoesController.text.trim(),
        metricas: _maioresValores.map((key, value) => MapEntry(key, value.toDouble())),
        duracaoMinutos: _tempoDecorrido ~/ 60,
      );

      print('📦 Dados da sessão:');
      print('   ID: ${novaSessao.id}');
      print('   PacienteID: ${novaSessao.pacienteId}');
      print('   Maiores valores: $_maioresValores');

      final sucesso = await _databaseService.salvarSessao(novaSessao);

      if (sucesso) {
        print('✅ Sessão salva com sucesso no banco!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ Sessão salva com sucesso!'),
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context, novaSessao);
        }
      } else {
        print('❌ Falha ao salvar sessão');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('❌ Erro ao salvar sessão no banco de dados!'),
          ),
        );
      }
    } catch (e) {
      print('💥 Erro ao salvar sessão: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('❌ Erro: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  // ✅ WIDGET PARA MOSTRAR MÉTRICA
  Widget _buildMetricaCard(String titulo, int valor, Color cor) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.2),
          child: Icon(
            _getIconPorMovimento(titulo),
            color: cor,
            size: 20,
          ),
        ),
        title: Text(
          _formatarTitulo(titulo),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          '$valor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ),
    );
  }

  // ✅ ÍCONES 
  IconData _getIconPorMovimento(String movimento) {
    final icons = {
      'anterior': Icons.arrow_upward,
      'posterior': Icons.arrow_downward,
      'lateral_direita': Icons.arrow_forward,
      'lateral_esquerda': Icons.arrow_back,
    };
    return icons[movimento] ?? Icons.help;
  }

  // ✅ FORMATAR TÍTULO 
  String _formatarTitulo(String titulo) {
    final map = {
      'anterior': 'Movimento Anterior',
      'posterior': 'Movimento Posterior',
      'lateral_direita': 'Lateral Direita',
      'lateral_esquerda': 'Lateral Esquerda',
    };
    return map[titulo] ?? titulo;
  }

  // ✅ CORES 
  Color _getColorPorMovimento(String movimento) {
    final colors = {
      'anterior': Colors.green,
      'posterior': Colors.blue,
      'lateral_direita': Colors.orange,
      'lateral_esquerda': Colors.purple,
    };
    return colors[movimento] ?? Colors.grey;
  }

  // ✅ WIDGET SELEÇÃO BLUETOOTH
  Widget _buildSelecaoBluetooth() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conexão Bluetooth',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            if (!_bluetoothLigado)
              Text(
                '❌ Bluetooth desligado',
                style: TextStyle(color: Colors.red),
              ),
            
            if (_conectandoBluetooth)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Conectando à ESP32...'),
                  ],
                ),
              ),
            
            if (_deviceESP32 != null)
              ListTile(
                leading: Icon(Icons.bluetooth_connected, color: Colors.green),
                title: Text('Conectado: ${_deviceESP32!.name}'),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: _desconectarESP32,
                ),
              ),
            
            if (_bluetoothLigado && _deviceESP32 == null && !_conectandoBluetooth)
              Column(
                children: [
                  Text('Dispositivos encontrados:'),
                  SizedBox(height: 8),
                  ..._devicesEncontrados
                      .where((device) => device.name.contains('ESP32') || 
                                        device.name.contains(ESP32Config.deviceName))
                      .map((device) => ListTile(
                        leading: Icon(Icons.bluetooth),
                        title: Text(device.name),
                        subtitle: Text(device.id.toString()),
                        onTap: () => _conectarESP32(device),
                      ))
                      .toList(),
                  
                  if (_devicesEncontrados.isEmpty)
                    Text('Nenhum dispositivo ESP32 encontrado'),
                  
                  ElevatedButton(
                    onPressed: _iniciarScanBluetooth,
                    child: Text('BUSCAR NOVAMENTE'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nova Sessão - ${widget.paciente.nome}'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABEÇALHO
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nova Sessão de Exercícios',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Paciente: ${widget.paciente.nome}',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // ✅ SEÇÃO BLUETOOTH
            _buildSelecaoBluetooth(),

            SizedBox(height: 20),

            // CAPTURA DE DADOS
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Captura de Dados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),

                    if (!_capturandoDados && !_dadosCapturados) ...[
                      Text(
                        'Escolha como capturar os dados:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      
                      // ✅ BOTÃO CAPTURA REAL
                      ElevatedButton.icon(
                        onPressed: _deviceESP32 != null ? _iniciarCapturaReal : null,
                        icon: Icon(_deviceESP32 != null ? Icons.play_arrow : Icons.bluetooth_disabled),
                        label: Text(_deviceESP32 != null ? 
                          'INICIAR CAPTURA ESP32 REAL' : 
                          'CONECTE A ESP32 PRIMEIRO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _deviceESP32 != null ? Colors.green : Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                      
                      SizedBox(height: 12),

                      // ✅ BOTÃO CAPTURA SIMULADA
                      ElevatedButton.icon(
                        onPressed: _iniciarCaptura,
                        icon: Icon(Icons.play_arrow),
                        label: Text('INICIAR SESSÃO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ],

                    if (_capturandoDados) ...[
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Colors.purple),
                            SizedBox(height: 16),
                            Text(
                              _deviceESP32 != null ? 
                                'Capturando dados reais da ESP32...' : 
                                'Capturando dados da sessão...',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tempo: $_tempoDecorrido segundos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _finalizarCaptura,
                              child: Text('FINALIZAR CAPTURA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_dadosCapturados && _maioresValores.isNotEmpty) ...[
                      Text(
                        '✅ Dados Capturados com Sucesso!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Duração: ${_tempoDecorrido ~/ 60}min ${_tempoDecorrido % 60}seg | Maiores valores capturados:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 12),
                      ..._maioresValores.entries.map((entry) => 
                        _buildMetricaCard(
                          entry.key, 
                          entry.value, 
                          _getColorPorMovimento(entry.key)
                        )
                      ).toList(),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // OBSERVAÇÕES
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Observações da Sessão',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _observacoesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Descreva observações relevantes desta sessão...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // BOTÃO SALVAR
            if (_dadosCapturados)
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvarSessao,
                  icon: _salvando 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.save),
                  label: _salvando 
                      ? Text('SALVANDO...')
                      : Text('SALVAR SESSÃO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _salvando ? Colors.grey : Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}