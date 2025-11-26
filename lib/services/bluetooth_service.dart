import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/esp32_config.dart';

// ✅ MUDE O NOME DA CLASSE para evitar conflito
class ESP32BluetoothService {
  static final ESP32BluetoothService _instance = ESP32BluetoothService._internal();
  factory ESP32BluetoothService() => _instance;
  ESP32BluetoothService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;
  bool _isConnected = false;
  bool _isScanning = false;

  // Stream para dados recebidos
  final StreamController<Map<String, dynamic>> _dataController = 
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;

  // Stream para status de conexão
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<bool> initializeBluetooth() async {
    try {
      // Solicitar permissões
      await _requestPermissions();

      // Verificar se o Bluetooth está ligado
      bool isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        print('❌ Bluetooth desligado');
        return false;
      }

      // Configurar listener de estado do Bluetooth
      FlutterBluePlus.adapterState.listen((state) {
        print('📡 Estado do Bluetooth: $state');
        if (state == BluetoothAdapterState.on) {
          _connectionController.add(true);
        } else {
          _connectionController.add(false);
          _isConnected = false;
        }
      });

      return true;
    } catch (e) {
      print('❌ Erro ao inicializar Bluetooth: $e');
      return false;
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
    
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  // Escanear dispositivos ESP32
  Stream<List<BluetoothDevice>> scanForESP32({int timeoutSeconds = 15}) {
  final devices = <BluetoothDevice>[];
  
  // Parar scan anterior
  if (_isScanning) {
    FlutterBluePlus.stopScan();
  }

  _isScanning = true;

  print('🔍 Iniciando scan Bluetooth...');

  // Iniciar novo scan com filtros mais amplos
  FlutterBluePlus.startScan(
    timeout: Duration(seconds: timeoutSeconds),
    // withNames: [ESP32Config.deviceName], // ✅ COMENTE ESTA LINHA temporariamente
  );

  // Retornar stream com dispositivos encontrados
  return FlutterBluePlus.scanResults.map((results) {
    if (!_isScanning) return devices;

    final newDevices = results
        .where((result) => result.device.platformName.isNotEmpty)
        .map((result) => result.device)
        .where((device) => 
            device.name.contains('ESP32') || 
            device.name.contains(ESP32Config.deviceName) ||
            device.name.isNotEmpty)
        .toList();

    // Adicionar apenas dispositivos novos
    for (var device in newDevices) {
      if (!devices.any((d) => d.id == device.id)) {
        devices.add(device);
        print('📱 Dispositivo encontrado: ${device.name} - ${device.id}');
      }
    }

    return devices;
  });
}

  // Conectar à ESP32 - CORRIGIDO
  Future<bool> connectToESP32(BluetoothDevice device) async {
    try {
      print('🔗 Conectando à ESP32: ${device.name}');

      // Configurar timeout de conexão
      await device.connect(timeout: Duration(seconds: 15));
      _connectedDevice = device;

      // Descobrir serviços - ✅ USE ALIAS para evitar conflito
      List<BluetoothService> services = await device.discoverServices();
      
      bool characteristicFound = false;
      
      for (BluetoothService service in services) {
        print('🔍 Serviço: ${service.uuid}');

        if (service.uuid.toString().toLowerCase() == 
            ESP32Config.serviceUUID.toLowerCase()) {
          
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            print('📊 Characteristic: ${characteristic.uuid}');

            if (characteristic.uuid.toString().toLowerCase() == 
                ESP32Config.characteristicUUID.toLowerCase()) {
              
              _characteristic = characteristic;
              characteristicFound = true;

              // Configurar notificações
              await characteristic.setNotifyValue(true);
              
              // Listener para dados recebidos
              characteristic.value.listen((data) {
                _processReceivedData(data);
              });

              print('✅ Characteristic configurado com sucesso!');
              break;
            }
          }
        }
        
        if (characteristicFound) break;
      }

      if (!characteristicFound) {
        print('❌ Characteristic não encontrado');
        await device.disconnect();
        return false;
      }

      _isConnected = true;
      _connectionController.add(true);
      
      print('✅ Conectado à ESP32 com sucesso!');
      return true;

    } catch (e) {
      print('❌ Erro na conexão: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  // Processar dados recebidos
  void _processReceivedData(List<int> data) {
    try {
      if (data.isEmpty) return;

      String dataString = String.fromCharCodes(data).trim();
      print('📡 Dados recebidos: $dataString');

      // Processar diferentes formatos de dados
      Map<String, dynamic> processedData = _parseData(dataString);
      
      if (processedData.isNotEmpty) {
        _dataController.add(processedData);
      }

    } catch (e) {
      print('❌ Erro ao processar dados: $e');
    }
  }

  // Parsear dados da ESP32
  Map<String, dynamic> _parseData(String data) {
    Map<String, dynamic> result = {};
    
    try {
      // Formato 1: Movimento: X, Índice: Y
      if (data.contains('Movimento:') && data.contains('Índice:')) {
        RegExp movimentoRegex = RegExp(r'Movimento:\s*(\w+)');
        RegExp indiceRegex = RegExp(r'Índice:\s*(\d)');
        
        Match? movimentoMatch = movimentoRegex.firstMatch(data);
        Match? indiceMatch = indiceRegex.firstMatch(data);
        
        if (movimentoMatch != null && indiceMatch != null) {
          String movimento = movimentoMatch.group(1)!;
          int indice = int.parse(indiceMatch.group(1)!);
          
          if (movimento != 'Neutro') {
            String movimentoApp = ESP32Config.getMovimentoPorVariavel(movimento);
            if (movimentoApp.isNotEmpty) {
              result = {
                'tipo': 'movimento',
                'movimento': movimentoApp,
                'valor': indice.toDouble(),
                'timestamp': DateTime.now(),
                'rawData': data
              };
            }
          }
        }
      }
      // Formato 2: Dados brutos que podem ser processados
      else if (data.length > 5) {
        result = {
          'tipo': 'raw',
          'data': data,
          'timestamp': DateTime.now()
        };
      }

    } catch (e) {
      print('❌ Erro no parse: $e');
    }

    return result;
  }

  // Enviar comando para ESP32
  Future<bool> sendCommand(String command) async {
    try {
      if (_characteristic == null || !_isConnected) {
        print('❌ Não conectado ou characteristic não disponível');
        return false;
      }

      List<int> bytes = [...command.codeUnits, 0]; // Adicionar null terminator
      await _characteristic!.write(bytes);
      
      print('📤 Comando enviado: $command');
      return true;

    } catch (e) {
      print('❌ Erro ao enviar comando: $e');
      return false;
    }
  }

  // Desconectar
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      
      _isConnected = false;
      _connectedDevice = null;
      _characteristic = null;
      
      _connectionController.add(false);
      print('🔌 Desconectado da ESP32');

    } catch (e) {
      print('❌ Erro ao desconectar: $e');
    }
  }

  // Parar scan
  void stopScan() {
    if (_isScanning) {
      FlutterBluePlus.stopScan();
      _isScanning = false;
    }
  }

  // Getters
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Dispose
  void dispose() {
    stopScan();
    disconnect();
    _dataController.close();
    _connectionController.close();
  }
}