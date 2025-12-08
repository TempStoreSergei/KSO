import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/presentation/helpers/adaptive_text.dart';
import 'package:provider/provider.dart';
import 'keyboard_notifier.dart';

class FocusableTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final int controllerIndex;
  final FocusNode? focusNode;

  const FocusableTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.controllerIndex,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = Provider.of<KeyboardNotifier>(context);
    final bool isActive = keyboardNotifier.isControllerActive(controller);

    return GestureDetector(
      onTap: () {
        keyboardNotifier.setActiveControllerByIndex(controllerIndex);
        if (focusNode != null) {
          FocusScope.of(context).requestFocus(focusNode);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.24),
                width: isActive ? 2 : 1,
              ),
            ),
            child: AbsorbPointer(
              child: CupertinoTextField(
                focusNode: focusNode,
                controller: controller,
                placeholder: placeholder,
                placeholderStyle: TextStyle(color: CupertinoColors.white.withValues(alpha: 0.54), fontSize: scaleText(context, 20)),
                readOnly: true,
                showCursor: true,
                cursorColor: CupertinoColors.white,
                style: TextStyle(color: CupertinoColors.white, fontSize: scaleText(context, 20)),
                // <<< ИЗМЕНЕНИЕ ЗДЕСЬ: ВЫСОТА ПОЛЕЙ УВЕЛИЧЕНА ВДВОЕ ---
                // Вертикальные отступы изменены с 18.0 на 36.0
                padding: EdgeInsets.only(
                  left: isActive ? 65.0 : 20.0,
                  right: 20.0,
                  top: 36.0,
                  bottom: 36.0,
                ),
                decoration: const BoxDecoration(),
              ),
            ),
          ),
          Positioned(
            left: 10,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.0,
              child: isActive
                  ? CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                child: const Icon(Icons.arrow_right_alt, color: Colors.black54),
              )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}