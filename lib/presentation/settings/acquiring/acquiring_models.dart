// ============================================
// lib/presentation/settings/acquiring/acquiring_models.dart
// ============================================

/// Модель ответа от API эквайринга
class AcquiringResponse {
  final bool status;
  final String detail;
  final Map<String, dynamic>? data;

  AcquiringResponse({
    required this.status,
    required this.detail,
    this.data,
  });

  factory AcquiringResponse.fromJson(Map<String, dynamic> json) {
    return AcquiringResponse(
      status: json['status'] ?? false,
      detail: json['detail'] ?? '',
      data: json['data'],
    );
  }
}

/// Состояние подключения эквайринга
class AcquiringConnectionState {
  final bool isConnected;
  final String connectionMethod;
  final bool isChecking;

  AcquiringConnectionState({
    this.isConnected = false,
    this.connectionMethod = '',
    this.isChecking = false,
  });

  AcquiringConnectionState copyWith({
    bool? isConnected,
    String? connectionMethod,
    bool? isChecking,
  }) {
    return AcquiringConnectionState(
      isConnected: isConnected ?? this.isConnected,
      connectionMethod: connectionMethod ?? this.connectionMethod,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}
