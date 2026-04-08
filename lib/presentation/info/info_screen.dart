import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  // ─── QR screen ────────────────────────────────────────────────────────────

  void _openQrScreen(
    BuildContext context, {
    required String title,
    required String data,
  }) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => _QrCodeScreen(title: title, data: data),
      ),
    );
  }

  Widget _linkTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required String qrTitle,
    required String qrData,
    required BuildContext context,
  }) {
    return _tile(
      icon: icon,
      iconColor: iconColor,
      label: label,
      subtitle: subtitle,
      isLink: true,
      onTap: () => _openQrScreen(context, title: qrTitle, data: qrData),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
    bool isLink = false,
  }) {
    return CupertinoListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: CupertinoColors.white, size: 20),
      ),
      title: Text(
        label,
        style: isLink
            ? const TextStyle(
                color: CupertinoColors.activeBlue,
                decoration: TextDecoration.underline,
              )
            : null,
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const CupertinoListTileChevron() : null,
      onTap: onTap,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Информация'),
          ),
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('НАИМЕНОВАНИЕ ОРГАНИЗАЦИИ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.building_2_fill,
                      iconColor: CupertinoColors.systemIndigo,
                      label: 'ООО «УК „Дельта“»',
                      subtitle:
                          'Общество с ограниченной ответственностью «Управляющая компания „Дельта“»',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('РЕКВИЗИТЫ ОРГАНИЗАЦИИ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.number_circle_fill,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'ИНН',
                      subtitle: '5029237065',
                    ),
                    _tile(
                      icon: CupertinoIcons.number_circle_fill,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'ОГРН',
                      subtitle: '1185053043438',
                    ),
                    _tile(
                      icon: CupertinoIcons.number_circle_fill,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'КПП',
                      subtitle: '502901001',
                    ),
                    _tile(
                      icon: CupertinoIcons.number_circle_fill,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'ОКПО',
                      subtitle: '34757016',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ЮРИДИЧЕСКИЙ АДРЕС'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.location_solid,
                      iconColor: CupertinoColors.systemRed,
                      label: '141014, Московская область',
                      subtitle: 'г. Мытищи, ул. Селезнёва, влд. 46, стр. 1, ком. 1.6',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('РУКОВОДИТЕЛЬ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.person_fill,
                      iconColor: CupertinoColors.systemGreen,
                      label: 'Галеев Ильдар Баязитович',
                      subtitle: 'Генеральный директор',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ОСНОВНОЙ ВИД ДЕЯТЕЛЬНОСТИ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.briefcase_fill,
                      iconColor: CupertinoColors.systemTeal,
                      label: 'Предоставление мест для временного проживания',
                      subtitle: 'ОКВЭД 55.90',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('РЕЕСТР КЛАССИФИЦИРОВАННЫХ СРЕДСТВ РАЗМЕЩЕНИЯ'),
                  children: [
                    _linkTile(
                      icon: CupertinoIcons.doc_text_search,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Запись в реестре',
                      subtitle: 'tourism.fsa.gov.ru',
                      qrTitle: 'Реестр',
                      qrData:
                          'https://tourism.fsa.gov.ru/ru/resorts/hotels/2465c787-c609-11ef-92da-550e676af76d/about-resort/',
                      context: context,
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ДОКУМЕНТЫ, ПОДТВЕРЖДАЮЩИЕ ДЕЯТЕЛЬНОСТЬ'),
                  children: [
                    _linkTile(
                      icon: CupertinoIcons.doc_richtext,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Свидетельство о присвоении категории',
                      subtitle: 'PDF на hoteldelta3.ru',
                      qrTitle: 'Свидетельство категории',
                      qrData:
                          'https://hoteldelta3.ru/wp-content/uploads/2025/01/Svid_vo_o_prisvoenie_gostinitse_kategorii_UK_DEL_TA_compressed.pdf',
                      context: context,
                    ),
                    _linkTile(
                      icon: CupertinoIcons.doc_text,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Политика конфиденциальности',
                      subtitle: 'PDF на hoteldelta3.ru',
                      qrTitle: 'Политика конфиденциальности',
                      qrData:
                          'https://hoteldelta3.ru/wp-content/uploads/2023/01/Политика-конфиденциальности.pdf',
                      context: context,
                    ),
                    _linkTile(
                      icon: CupertinoIcons.doc_text,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Согласие на обработку данных',
                      subtitle: 'PDF на hoteldelta3.ru',
                      qrTitle: 'Согласие на обработку данных',
                      qrData:
                          'https://hoteldelta3.ru/wp-content/uploads/2023/01/Согласие-на-обработку-данных.pdf',
                      context: context,
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('УСЛОВИЯ ПРЕДОСТАВЛЕНИЯ УСЛУГ И СПЕЦИАЛЬНЫЕ ТАРИФЫ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.money_rubl_circle_fill,
                      iconColor: CupertinoColors.systemOrange,
                      label: 'Стоимость проживания',
                      subtitle: 'От 185 рублей в сутки (специальный туристический тариф)',
                    ),
                    _linkTile(
                      icon: CupertinoIcons.tag_fill,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Положение о «Туристическом тарифе»',
                      subtitle: 'PDF на hoteldelta3.ru',
                      qrTitle: 'Туристический тариф',
                      qrData:
                          'https://hoteldelta3.ru/wp-content/uploads/2026/01/Положение_о_проведении_акции_Туристический_тариф.pdf',
                      context: context,
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ФОРМЫ ПРИЁМА ОПЛАТЫ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.creditcard_fill,
                      iconColor: CupertinoColors.systemGreen,
                      label: 'Оплата принимается наличными и безналично',
                    ),
                    _tile(
                      icon: CupertinoIcons.book_fill,
                      iconColor: CupertinoColors.systemGrey,
                      label: 'Гражданский кодекс РФ',
                      subtitle: 'Статья 861 (о формах расчётов)',
                    ),
                    _tile(
                      icon: CupertinoIcons.book_fill,
                      iconColor: CupertinoColors.systemGrey,
                      label: 'Федеральный закон № 54-ФЗ',
                      subtitle:
                          'О применении ККТ при осуществлении расчётов в Российской Федерации',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ОСНОВАНИЯ ДЛЯ ПРИЁМА ПЛАТЕЖЕЙ'),
                  footer: const Text(
                    'Кассовый чек или иной документ, подтверждающий расчёт, выдаётся клиенту в соответствии с требованиями законодательства.',
                  ),
                  children: [
                    _tile(
                      icon: CupertinoIcons.doc_on_doc_fill,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'Договор/анкета проживающего',
                      subtitle: 'Допускается электронная форма',
                    ),
                    _tile(
                      icon: CupertinoIcons.list_bullet,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'Выставленные счета/ценники',
                      subtitle: 'С обязательным указанием стоимости услуг',
                    ),
                    _tile(
                      icon: CupertinoIcons.tag_circle_fill,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'Условия специальных тарифов и акций',
                      subtitle: 'Согласно положению о «Туристическом тарифе»',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ОБРАБОТКА ПЕРСОНАЛЬНЫХ ДАННЫХ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.lock_shield_fill,
                      iconColor: CupertinoColors.systemPurple,
                      label: 'Федеральный закон № 152-ФЗ',
                      subtitle: '«О персональных данных»',
                    ),
                    _tile(
                      icon: CupertinoIcons.checkmark_shield_fill,
                      iconColor: CupertinoColors.systemPurple,
                      label: 'Применимые нормативные акты РФ',
                      subtitle: 'В сфере защиты персональных данных',
                    ),
                    _linkTile(
                      icon: CupertinoIcons.doc_text_fill,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Согласие на обработку персональных данных',
                      subtitle: 'PDF на hoteldelta3.ru',
                      qrTitle: 'Согласие на обработку персональных данных',
                      qrData:
                          'https://hoteldelta3.ru/wp-content/uploads/2023/01/Согласие-на-обработку-данных.pdf',
                      context: context,
                    ),
                  ],
                ),
              ),

              // ── §12 Ошибки терминала ──────────────────────────────────────
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ОШИБКИ И НЕИСПРАВНОСТИ ТЕРМИНАЛА'),
                  footer: const Text(
                    'Если возникли проблемы (платёж не прошёл, чек не распечатался, система зависла) — следуйте инструкциям ниже.',
                  ),
                  children: [
                    _tile(
                      icon: CupertinoIcons.person_crop_circle_fill_badge_exclam,
                      iconColor: CupertinoColors.systemOrange,
                      label: 'Сообщите сотруднику',
                      subtitle: 'Укажите номер терминала и опишите проблему',
                    ),
                    _tile(
                      icon: CupertinoIcons.doc_text_fill,
                      iconColor: CupertinoColors.systemGrey,
                      label: 'Запишите код ошибки',
                      subtitle: 'Если отображается на экране',
                    ),
                    _tile(
                      icon: CupertinoIcons.phone_circle_fill,
                      iconColor: CupertinoColors.systemGrey,
                      label: 'Техподдержка платёжной системы',
                      subtitle: 'Логотип указан на терминале',
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ОБЯЗАННОСТИ ПЕРСОНАЛА'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.checkmark_seal_fill,
                      iconColor: CupertinoColors.systemGreen,
                      label: 'Зафиксировать инцидент',
                      subtitle: 'В журнале учёта неисправностей',
                    ),
                    _tile(
                      icon: CupertinoIcons.checkmark_seal_fill,
                      iconColor: CupertinoColors.systemGreen,
                      label: 'Проверить статус платежа',
                      subtitle: 'В системе учёта',
                    ),
                    _tile(
                      icon: CupertinoIcons.creditcard_fill,
                      iconColor: CupertinoColors.systemBlue,
                      label: 'Альтернативный способ оплаты',
                      subtitle: 'Наличные, другой терминал, онлайн-перевод',
                    ),
                    _tile(
                      icon: CupertinoIcons.arrow_uturn_left_circle_fill,
                      iconColor: CupertinoColors.systemRed,
                      label: 'Возврат средств',
                      subtitle: 'При ошибочном списании (согласно законодательству)',
                    ),
                  ],
                ),
              ),

              // ── §13 Жалобы ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ПОРЯДОК ПОДАЧИ ЖАЛОБ И ОБРАЩЕНИЙ'),
                  footer: const Text(
                    'Срок рассмотрения — не более 10 рабочих дней с момента получения. Ответ направляется способом, указанным в обращении.',
                  ),
                  children: [
                    _tile(
                      icon: CupertinoIcons.person_fill,
                      iconColor: CupertinoColors.systemIndigo,
                      label: 'Обратиться к администратору',
                      subtitle: 'Устное разъяснение или устранение проблемы',
                    ),
                    _linkTile(
                      icon: CupertinoIcons.globe,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Форма обратной связи на сайте',
                      subtitle: 'hoteldelta3.ru',
                      qrTitle: 'Сайт',
                      qrData: 'https://hoteldelta3.ru',
                      context: context,
                    ),
                    _linkTile(
                      icon: CupertinoIcons.envelope_fill,
                      iconColor: CupertinoColors.systemOrange,
                      label: 'Электронная почта',
                      subtitle: 'info@hoteldelta3.ru',
                      qrTitle: 'Электронная почта',
                      qrData: 'mailto:info@hoteldelta3.ru',
                      context: context,
                    ),
                    _linkTile(
                      icon: CupertinoIcons.phone_fill,
                      iconColor: CupertinoColors.systemGreen,
                      label: 'Телефон',
                      subtitle: '+7 966 349‑88‑99',
                      qrTitle: 'Телефон',
                      qrData: 'tel:+79663498899',
                      context: context,
                    ),
                  ],
                ),
              ),

              // ── §14 Контакты ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('КОНТАКТЫ ДЛЯ СВЯЗИ'),
                  children: [
                    _linkTile(
                      icon: CupertinoIcons.phone_fill,
                      iconColor: CupertinoColors.systemGreen,
                      label: 'Телефон',
                      subtitle: '+7 966 349‑88‑99',
                      qrTitle: 'Телефон',
                      qrData: 'tel:+79663498899',
                      context: context,
                    ),
                    _linkTile(
                      icon: CupertinoIcons.envelope_fill,
                      iconColor: CupertinoColors.systemOrange,
                      label: 'Электронная почта',
                      subtitle: 'info@hoteldelta3.ru',
                      qrTitle: 'Электронная почта',
                      qrData: 'mailto:info@hoteldelta3.ru',
                      context: context,
                    ),
                    _linkTile(
                      icon: CupertinoIcons.globe,
                      iconColor: CupertinoColors.activeBlue,
                      label: 'Сайт',
                      subtitle: 'hoteldelta3.ru',
                      qrTitle: 'Сайт',
                      qrData: 'https://hoteldelta3.ru',
                      context: context,
                    ),
                  ],
                ),
              ),

              // ── §15 Доп. информация ───────────────────────────────────────
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ'),
                  children: [
                    _tile(
                      icon: CupertinoIcons.doc_person_fill,
                      iconColor: CupertinoColors.systemPurple,
                      label: 'Регистрация иностранных граждан в ФМС',
                      subtitle: 'Оформление в течение 3 рабочих дней',
                    ),
                    _tile(
                      icon: CupertinoIcons.building_2_fill,
                      iconColor: CupertinoColors.systemIndigo,
                      label: 'Условия для юридических лиц',
                      subtitle:
                          'Индивидуальные предложения, договор на гостиничные услуги, полный пакет для бухучёта',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrCodeScreen extends StatelessWidget {
  final String title;
  final String data;

  const _QrCodeScreen({
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        previousPageTitle: 'Информация',
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 280,
                ),
                const SizedBox(height: 14),
                Text(
                  data,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
