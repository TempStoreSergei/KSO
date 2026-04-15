// ============================================
// lib/presentation/booking/widgets/step_guest_info.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';
import 'package:provider/provider.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';

class StepGuestInfo extends StatefulWidget {
  final Function(String, String, String, String) onChanged;
  final TextEditingController fullNameController;
  final TextEditingController phoneNumberController;
  final FocusNode fullNameFocusNode;
  final FocusNode phoneNumberFocusNode;

  const StepGuestInfo({
    super.key,
    required this.onChanged,
    required this.fullNameController,
    required this.phoneNumberController,
    required this.fullNameFocusNode,
    required this.phoneNumberFocusNode,
  });

  @override
  State<StepGuestInfo> createState() => _StepGuestInfoState();
}

class _StepGuestInfoState extends State<StepGuestInfo> {
  @override
  void initState() {
    super.initState();
    widget.fullNameController.addListener(_onDataChanged);
    widget.phoneNumberController.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
    final unmaskedPhone = keyboardNotifier.unmaskedPhone;
    final fullName = widget.fullNameController.text.trim();
    final nameParts = fullName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final lastName = nameParts.isNotEmpty ? nameParts[0] : '';
    final firstName = nameParts.length > 1 ? nameParts[1] : '';
    final middleName = nameParts.length > 2 ? nameParts.sublist(2).join(' ') : '';

    widget.onChanged(
      firstName,
      lastName,
      middleName,
      unmaskedPhone.isEmpty ? '' : '7$unmaskedPhone',
    );
  }

  @override
  void dispose() {
    widget.fullNameController.removeListener(_onDataChanged);
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
            title: const Text('ФИО'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CupertinoTextField(
                controller: widget.fullNameController,
                focusNode: widget.fullNameFocusNode,
                textAlign: TextAlign.start,
                style: const TextStyle(color: CupertinoColors.systemGrey),
                decoration: null,
                placeholder: 'Фамилия Имя Отчество',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                minLines: 1,
                maxLines: 3,
              ),
            ),
          ),
          CupertinoListTile(
            title: const Text('Телефон *'),
            additionalInfo: Expanded(
              child: CupertinoTextField(
                controller: widget.phoneNumberController,
                focusNode: widget.phoneNumberFocusNode,
                textAlign: TextAlign.end,
                style: const TextStyle(color: CupertinoColors.systemGrey),
                decoration: null,
                placeholder: '+7 (999) 000-00-00',
                keyboardType: TextInputType.phone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
