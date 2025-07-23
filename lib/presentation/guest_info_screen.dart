import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:motel/models/booking_data.dart';
import 'package:motel/presentation/dashboard_screen/booking_dashboard_screen.dart';
import 'package:motel/presentation/helpers/adaptive_text.dart';
import 'package:motel/presentation/helpers/glassmorphic_container.dart';
import 'package:motel/presentation/helpers/app_background.dart';
import 'package:provider/provider.dart';
import 'guest_info/keyboard_notifier.dart';
import 'guest_info/custom_keyboard.dart';
import 'guest_info/focusable_textfield.dart';

class GuestInfoScreen extends StatelessWidget {
  const GuestInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KeyboardNotifier(),
      child: const _GuestInfoView(),
    );
  }
}

class _GuestInfoView extends StatefulWidget {
  const _GuestInfoView();
  @override
  State<_GuestInfoView> createState() => _GuestInfoViewState();
}

class _GuestInfoViewState extends State<_GuestInfoView> {
  final BookingData bookingData = BookingData();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();

  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _patronymicFocusNode = FocusNode();

  bool _canProceed = false;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
      keyboardNotifier.registerFields(
        controllers: [_firstNameController, _lastNameController, _patronymicController],
        focusNodes: [_firstNameFocusNode, _lastNameFocusNode, _patronymicFocusNode],
      );
    });
    _firstNameController.addListener(_validateFields);
    _lastNameController.addListener(_validateFields);
  }

  void _validateFields() {
    final canProceed = _firstNameController.text.isNotEmpty && _lastNameController.text.isNotEmpty;
    if (canProceed != _canProceed) {
      setState(() {
        _canProceed = canProceed;
        if (canProceed && _showValidationError) {
          _showValidationError = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_validateFields);
    _lastNameController.removeListener(_validateFields);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _patronymicFocusNode.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_canProceed) {
      bookingData.firstName = _firstNameController.text;
      bookingData.lastName = _lastNameController.text;
      bookingData.patronymic = _patronymicController.text;
      Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => BookingDashboardScreen(bookingData: bookingData),
      ));
    } else {
      if (!_showValidationError) {
        setState(() => _showValidationError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);

    final nextButton = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _onNextPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: (_showValidationError && !_canProceed)
              ? Colors.white
              : Colors.black.withOpacity(_canProceed ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: (_showValidationError && !_canProceed)
                ? Text('Заполните Имя и Фамилию', key: const ValueKey('error'), textAlign: TextAlign.center, style: TextStyle(fontSize: scaleText(context, 16), fontWeight: FontWeight.bold, color: CupertinoColors.systemRed))
                : Text('Далее', key: const ValueKey('next'), textAlign: TextAlign.center, style: TextStyle(fontSize: scaleText(context, 20), fontWeight: FontWeight.bold, color: Colors.white.withOpacity(_canProceed ? 1.0 : 0.5))),
          ),
        ),
      ),
    );

    final backButton = GlassmorphicContainer(
      child: CupertinoButton(
        padding: const EdgeInsets.all(10),
        onPressed: () => Navigator.of(context).pop(),
        child: const Icon(CupertinoIcons.back, color: Colors.white, size: 35),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1020),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      backButton,
                      const Spacer(),
                      Text('Данные гостя', style: TextStyle(color: Colors.white, fontSize: scaleText(context, 40), fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 10)])),
                      const Spacer(),
                      Opacity(opacity: 0, child: backButton),
                    ],
                  ),
                  const SizedBox(height: 30),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              FocusableTextField(
                                controller: _firstNameController,
                                placeholder: 'Имя *',
                                controllerIndex: 0,
                                focusNode: _firstNameFocusNode,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: FocusableTextField(
                                      controller: _lastNameController,
                                      placeholder: 'Фамилия *',
                                      controllerIndex: 1,
                                      focusNode: _lastNameFocusNode,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: FocusableTextField(
                                      controller: _patronymicController,
                                      placeholder: 'Отчество',
                                      controllerIndex: 2,
                                      focusNode: _patronymicFocusNode,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: nextButton,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomKeyboard(onKeyPressed: keyboardNotifier.onKeyPressed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}