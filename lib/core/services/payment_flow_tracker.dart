import 'package:motel/core/services/diagnostic_logger.dart';

class PaymentFlowTracker {
  PaymentFlowTracker();

  final Stopwatch _stopwatch = Stopwatch();
  late final String flowId;
  late final String transactionId;
  String? _paymentMethod;
  int? _amount;

  void start({
    required String paymentMethod,
    required int amount,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    flowId = 'flow_$timestamp';
    transactionId = 'txn_$timestamp';
    _paymentMethod = paymentMethod;
    _amount = amount;
    DiagnosticLogger.setContext({
      'flowId': flowId,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'amount': amount,
    });
    _stopwatch
      ..reset()
      ..start();
    mark('flow_start');
  }

  void mark(String event, {Map<String, Object?> data = const {}}) {
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final payload = {
      'event': event,
      'flowId': flowId,
      'transactionId': transactionId,
      'elapsedMs': elapsedMs,
      if (_paymentMethod != null) 'paymentMethod': _paymentMethod,
      if (_amount != null) 'amount': _amount,
      ...data,
    };

    DiagnosticLogger.info('payment_flow', event, data: payload);
  }

  void finish(String result, {Map<String, Object?> data = const {}}) {
    mark('flow_finish', data: {'result': result, ...data});
    _stopwatch.stop();
    DiagnosticLogger.clearContext();
  }
}
