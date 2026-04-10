class SystemSettings {
  final SystemDevices devices;
  final SbpPaymentSettings sbpPayment;

  const SystemSettings({
    required this.devices,
    required this.sbpPayment,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    final devicesJson = json['devices'];
    final sbpPaymentJson = json['sbpPayment'];

    return SystemSettings(
      devices: SystemDevices.fromJson(
        devicesJson is Map<String, dynamic> ? devicesJson : const <String, dynamic>{},
      ),
      sbpPayment: SbpPaymentSettings.fromJson(
        sbpPaymentJson is Map<String, dynamic> ? sbpPaymentJson : const <String, dynamic>{},
      ),
    );
  }

  List<String> get availablePaymentMethods {
    final methods = <String>[];

    if (devices.acquiring) {
      methods.add('Карта');
    }
    if (sbpPayment.isEnable) {
      methods.add('СБП');
    }
    if (devices.cashSystem) {
      methods.add('Наличные');
    }

    return methods;
  }
}

class SystemDevices {
  final bool fiscal;
  final bool scanner;
  final bool cashSystem;
  final bool acquiring;

  const SystemDevices({
    required this.fiscal,
    required this.scanner,
    required this.cashSystem,
    required this.acquiring,
  });

  factory SystemDevices.fromJson(Map<String, dynamic> json) {
    return SystemDevices(
      fiscal: json['fiscal'] == true,
      scanner: json['scanner'] == true,
      cashSystem: json['cashSystem'] == true,
      acquiring: json['acquiring'] == true,
    );
  }
}

class SbpPaymentSettings {
  final bool isEnable;
  final String qrUrl;

  const SbpPaymentSettings({
    required this.isEnable,
    required this.qrUrl,
  });

  factory SbpPaymentSettings.fromJson(Map<String, dynamic> json) {
    return SbpPaymentSettings(
      isEnable: json['isEnable'] == true,
      qrUrl: json['qrUrl']?.toString() ?? '',
    );
  }
}
