import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/models/booking_data.dart';
import 'package:motel/presentation/cash_payment_screen.dart';
import 'package:motel/presentation/helpers/adaptive_text.dart';
import 'package:motel/presentation/helpers/glassmorphic_container.dart';
import 'package:motel/presentation/helpers/app_background.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final BookingData bookingData;
  const PaymentScreen({Key? key, required this.bookingData}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Map<String, double> _servicePrices = {
    'Проживание': 1500.0,
    'Платная уборка комнаты': 500.0,
    'Внеплановая замена белья': 300.0,
    'Штраф за нарушение правил проживания': 2000.0,
    'Стоянка автотранспорта': 250.0,
    'Стирка': 200.0,
  };

  final GlobalKey _qrBlockKey = GlobalKey();
  double _buttonHeight = 150.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtonHeight());
  }

  void _updateButtonHeight() {
    final RenderBox? renderBox = _qrBlockKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final totalHeight = renderBox.size.height;
    final newButtonHeight = (totalHeight - 25) / 2;

    if (newButtonHeight > 0 && _buttonHeight != newButtonHeight) {
      setState(() {
        _buttonHeight = newButtonHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amount = _servicePrices[widget.bookingData.selectedService] ?? 0.0;
    final qrData = "Service: ${widget.bookingData.selectedService}\n"
        "Client: ${widget.bookingData.firstName} ${widget.bookingData.lastName}\n"
        "Amount: ${amount.toStringAsFixed(2)} RUB";

    return Scaffold(
      body: AppBackground(
        child: Container(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassmorphicContainer(
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(10),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Icon(CupertinoIcons.back, color: Colors.white, size: 35),
                      ),
                    ),
                    const SizedBox(height: 30),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              title: 'Плательщик',
                              child: Text(
                                '${widget.bookingData.firstName} ${widget.bookingData.lastName}',
                                style: TextStyle(color: Colors.white, fontSize: scaleText(context, 20), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: _buildInfoCard(
                              title: 'К оплате',
                              child: Text(
                                '${amount.toStringAsFixed(2)} руб. / Услуга: ${widget.bookingData.selectedService}',
                                style: TextStyle(color: Colors.white, fontSize: scaleText(context, 20), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            key: _qrBlockKey,
                            child: GlassmorphicContainer(
                              padding: const EdgeInsets.all(25),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("QR-код (СБП)", style: TextStyle(color: Colors.white, fontSize: scaleText(context, 22), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                    child: QrImageView(data: qrData, version: QrVersions.auto, size: 220.0),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInstructionStep(CupertinoIcons.device_phone_portrait, "1. Откройте приложение вашего банка"),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(CupertinoIcons.qrcode_viewfinder, "2. Выберите 'Оплата по QR-коду'"),
                                  const SizedBox(height: 12),
                                  _buildInstructionStep(CupertinoIcons.camera, "3. Наведите камеру и оплатите"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 25),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              SizedBox(
                                height: _buttonHeight,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Терминал оплаты временно недоступен.')),
                                    );
                                  },
                                  child: _buildPaymentTile(title: 'Картой', icon: CupertinoIcons.creditcard_fill),
                                ),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                height: _buttonHeight,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (_) => CashPaymentScreen(bookingData: widget.bookingData),
                                    ));
                                  },
                                  child: _buildPaymentTile(title: 'Наличными', icon: CupertinoIcons.money_rubl_circle_fill),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: scaleText(context, 16))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentTile({required String title, required IconData icon}) {
    return SizedBox.expand(
      child: GlassmorphicContainer(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: scaleText(context, 16), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white70, fontSize: scaleText(context, 15)),
          ),
        ),
      ],
    );
  }
}