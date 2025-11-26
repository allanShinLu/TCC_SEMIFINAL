// config/esp32_config.dart
class ESP32Config {
  static const String deviceName = "ESP32_MPU6050";
  static const String serviceUUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String characteristicUUID = "0000ffe1-0000-1000-8000-00805f9b34fb";

  //MAPEAMENTO DOS MOVIMENTOS DO FIRMWARE
  static Map<String, String> movimentoMap = {
    'Frente': 'anterior',
    'Trás': 'posterior', 
    'Direita': 'lateral_direita',
    'Esquerda': 'lateral_esquerda',
    'Neutro': 'neutro'
  };

  //CONVERTER movimento do firmware para formato do app
  static String getMovimentoPorVariavel(String movimentoFirmware) {
    return movimentoMap[movimentoFirmware] ?? '';
  }

  // Método para converter valor do firmware (agora recebe movimento e valor)
  static double converterValorFirmware(String movimento, double valorBruto) {
    //converter para double
    return valorBruto.toDouble();
  }
}