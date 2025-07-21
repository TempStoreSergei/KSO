import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:motel/models/booking_data.dart';
import 'package:motel/presentation/helpers/adaptive_text.dart';
import 'package:motel/presentation/helpers/glassmorphic_container.dart';

class CashPaymentScreen extends StatefulWidget {
  final BookingData bookingData;
  const CashPaymentScreen({Key? key, required this.bookingData}) : super(key: key);

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen> {
  final Map<String, double> _servicePrices = {
    'Проживание': 1500.0,
    'Платная уборка комнаты': 500.0,
    'Внеплановая замена белья': 300.0,
    'Штраф за нарушение правил проживания': 2000.0,
    'Стоянка автотранспорта': 250.0,
    'Стирка': 200.0,
  };

  double _totalAmount = 0;
  final List<int> _enteredBills = [5000, 1000, 200, 50, 50];

  final List<int> _acceptedBanknotes = [5000, 2000, 1000, 500, 200, 100, 50];
  final Map<int, Color> _banknoteColors = {
    5000: Colors.red.shade400,
    2000: Colors.blue.shade600,
    1000: Colors.teal.shade400,
    500: Colors.purple.shade400,
    200: Colors.green.shade600,
    100: Colors.brown.shade400,
    50: Colors.blue.shade300,
  };

  @override
  void initState() {
    super.initState();
    _totalAmount = _servicePrices[widget.bookingData.selectedService] ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final double enteredAmount = _enteredBills.fold(0.0, (sum, item) => sum + item);
    final double change = enteredAmount - _totalAmount;

    final contentBlock = Container(
      padding: const EdgeInsets.all(25),
      width: 1020,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 25),
          _buildStaggeredGrid(enteredAmount, change),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/hostel_cozy_room.jpg'), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: contentBlock,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GlassmorphicContainer(
          child: CupertinoButton(
            padding: const EdgeInsets.all(10),
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.back, color: Colors.white, size: 35),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: GlassmorphicContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Оплата наличными", style: TextStyle(color: Colors.white, fontSize: scaleText(context, 24), fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Услуга: ${widget.bookingData.selectedService}", style: TextStyle(color: Colors.white70, fontSize: scaleText(context, 16))),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildStaggeredGrid(double enteredAmount, double change) {
    return GridView.custom(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 3,
        mainAxisSpacing: 25,
        crossAxisSpacing: 25,
        pattern: const [
          QuiltedGridTile(2, 2),
          QuiltedGridTile(2, 1),
        ],
      ),
      childrenDelegate: SliverChildListDelegate([
        GlassmorphicContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialRow(
                title: "К оплате:",
                valueWidget: _buildValueOval("${_totalAmount.toStringAsFixed(2)} руб."),
              ),
              const SizedBox(height: 15),
              _buildFinancialRow(
                title: "Внесено:",
                valueWidget: _buildValueOval("${enteredAmount.toStringAsFixed(2)} руб."),
              ),
              const Divider(color: Colors.white24, height: 30),
              _buildFinancialRow(
                title: "Сдача:",
                valueWidget: _buildValueOval(change >= 0 ? "${change.toStringAsFixed(2)} руб." : "0.00 руб."),
              ),
              const SizedBox(height: 20),
              Text("Внесенные купюры:", style: TextStyle(color: Colors.white70, fontSize: scaleText(context, 14))),
              const SizedBox(height: 10),
              Expanded(
                child: _enteredBills.isEmpty
                    ? Center(child: Text("Ожидание купюр...", style: TextStyle(color: Colors.white54, fontSize: scaleText(context, 14))))
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _enteredBills.length,
                    itemBuilder: (context, index) {
                      return _buildEnteredBillListItem(_enteredBills[index]);
                    },
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withOpacity(0.15),
                      height: 1,
                      thickness: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        GlassmorphicContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Принимаемые купюры:", style: TextStyle(color: Colors.white70, fontSize: scaleText(context, 18))),
              const SizedBox(height: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _acceptedBanknotes
                      .map((bill) => _buildBanknoteDisplay(bill, _banknoteColors[bill] ?? Colors.grey))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildFinancialRow({required String title, required Widget valueWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(color: Colors.white70, fontSize: scaleText(context, 18))),
        valueWidget,
      ],
    );
  }

  Widget _buildValueOval(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: scaleText(context, 20),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEnteredBillListItem(int bill) {
    return GlassmorphicContainer(
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(
              CupertinoIcons.money_rubl_circle_fill,
              color: Colors.black.withOpacity(0.7),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$bill рублей",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scaleText(context, 20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Купюра принята",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: scaleText(context, 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanknoteDisplay(int value, Color color) {
    return GlassmorphicContainer(
      borderRadius: 8,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.25), color.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 1))],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                "₽",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.08),
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}