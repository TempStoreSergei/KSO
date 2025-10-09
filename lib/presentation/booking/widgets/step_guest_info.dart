// ============================================
// lib/presentation/booking/widgets/step_guest_info.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepGuestInfo extends StatefulWidget {
  final Function(String, String, String) onChanged;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final FocusNode lastNameFocusNode;
  final FocusNode firstNameFocusNode;
  final FocusNode middleNameFocusNode;
  final int focusedFieldIndex;

  const StepGuestInfo({
    super.key,
    required this.onChanged,
    required this.lastNameController,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameFocusNode,
    required this.firstNameFocusNode,
    required this.middleNameFocusNode,
    required this.focusedFieldIndex,
  });

  @override
  State<StepGuestInfo> createState() => _StepGuestInfoState();
}

class _StepGuestInfoState extends State<StepGuestInfo> {
  @override
  void initState() {
    super.initState();
    widget.lastNameController.addListener(_onDataChanged);
    widget.firstNameController.addListener(_onDataChanged);
    widget.middleNameController.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    widget.onChanged(
      widget.firstNameController.text,
      widget.lastNameController.text,
      widget.middleNameController.text,
    );
  }

  @override
  void dispose() {
    widget.lastNameController.removeListener(_onDataChanged);
    widget.firstNameController.removeListener(_onDataChanged);
    widget.middleNameController.removeListener(_onDataChanged);
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required FocusNode focusNode,
    required bool isFocused,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: isFocused
            ? Border.all(color: CupertinoColors.activeBlue, width: 2)
            : null,
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
        placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
        ),
        prefix: isFocused
            ? const Padding(
          padding: EdgeInsets.only(left: 12.0, right: 12.0),
          child: Icon(
            CupertinoIcons.minus_circle_fill,
            color: CupertinoColors.white,
            size: 24,
          ),
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.person_fill,
      title: 'Данные гостя',
      subtitle: 'Пожалуйста, укажите ФИО как в паспорте',
      child: Column(
        children: [
          _buildTextField(
            controller: widget.lastNameController,
            placeholder: 'Фамилия',
            focusNode: widget.lastNameFocusNode,
            isFocused: widget.focusedFieldIndex == 0,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: widget.firstNameController,
            placeholder: 'Имя',
            focusNode: widget.firstNameFocusNode,
            isFocused: widget.focusedFieldIndex == 1,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: widget.middleNameController,
            placeholder: 'Отчество (если есть)',
            focusNode: widget.middleNameFocusNode,
            isFocused: widget.focusedFieldIndex == 2,
          ),
        ],
      ),
    );
  }
}