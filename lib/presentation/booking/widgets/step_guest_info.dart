// ============================================
// lib/presentation/booking/widgets/step_guest_info.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';

class StepGuestInfo extends StatefulWidget {
  final Function(String, String, String, String) onChanged;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController phoneNumberController;
  final FocusNode lastNameFocusNode;
  final FocusNode firstNameFocusNode;
  final FocusNode middleNameFocusNode;
  final FocusNode phoneNumberFocusNode;

  const StepGuestInfo({
    super.key,
    required this.onChanged,
    required this.lastNameController,
    required this.firstNameController,
    required this.middleNameController,
    required this.phoneNumberController,
    required this.lastNameFocusNode,
    required this.firstNameFocusNode,
    required this.middleNameFocusNode,
    required this.phoneNumberFocusNode,
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
    widget.phoneNumberController.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    widget.onChanged(
      widget.firstNameController.text,
      widget.lastNameController.text,
      widget.middleNameController.text,
      widget.phoneNumberController.text,
    );
  }

  @override
  void dispose() {
    widget.lastNameController.removeListener(_onDataChanged);
    widget.firstNameController.removeListener(_onDataChanged);
    widget.middleNameController.removeListener(_onDataChanged);
    widget.phoneNumberController.removeListener(_onDataChanged);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return StepContainer(
      icon: CupertinoIcons.person_fill,
      title: 'Данные гостя',
      subtitle: 'Пожалуйста, укажите ФИО как в паспорте',
      child: CupertinoListSection.insetGrouped(
        backgroundColor: CupertinoColors.transparent,
        margin: EdgeInsets.zero,
        children: [
          CupertinoListTile(
            title: const Text('Фамилия'),
            additionalInfo: Expanded(
              child: CupertinoTextField(
                controller: widget.lastNameController,
                focusNode: widget.lastNameFocusNode,
                textAlign: TextAlign.end,
                style: const TextStyle(color: CupertinoColors.systemGrey),
                decoration: null,
                placeholder: 'Фамилия',
              ),
            ),
          ),
          CupertinoListTile(
            title: const Text('Имя'),
            additionalInfo: Expanded(
              child: CupertinoTextField(
                controller: widget.firstNameController,
                focusNode: widget.firstNameFocusNode,
                textAlign: TextAlign.end,
                style: const TextStyle(color: CupertinoColors.systemGrey),
                decoration: null,
                placeholder: 'Имя',
              ),
            ),
          ),
          CupertinoListTile(
            title: const Text('Отчество'),
            additionalInfo: Expanded(
              child: CupertinoTextField(
                controller: widget.middleNameController,
                focusNode: widget.middleNameFocusNode,
                textAlign: TextAlign.end,
                style: const TextStyle(color: CupertinoColors.systemGrey),
                decoration: null,
                placeholder: 'если есть',
              ),
            ),
          ),
          CupertinoListTile(
            title: const Text('Телефон'),
            additionalInfo: Expanded(
              child: CupertinoTextField(
                controller: widget.phoneNumberController,
                focusNode: widget.phoneNumberFocusNode,
                textAlign: TextAlign.end,
                style: const TextStyle(color: CupertinoColors.systemGrey),
                decoration: null,
                placeholder: '+7 999 000-00-00',
                keyboardType: TextInputType.phone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
