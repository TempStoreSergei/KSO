/// Маппинг разделов настроек на требуемые permissions
class PermissionsMapping {
  // ОБОРУДОВАНИЕ
  static const String screensaver = 'add_file'; // add_file, delete_file, update_file
  static const String acquiring = 'open_menu'; // Эквайринг - базовая функция
  static const String billDispenser = 'test_bill_dispenser'; // Диспенсер купюр - основной доступ
  static const String billAcceptor = 'test_bill_accept'; // Купюроприемник - основной доступ

  // ДИСПЕНСЕР КУПЮР - детальные права
  static const String billDispenserAddCount = 'add_bill_count'; // Добавление купюр
  static const String billDispenserSetNominal = 'set_nominal'; // Настройка номиналов
  static const String billDispenserTest = 'test_bill_dispenser'; // Тестирование
  static const String billDispenserReset = 'reset_bill_count'; // Инкассация/сброс

  // КУПЮРОПРИЕМНИК - детальные права
  static const String billAcceptorSetLimit = 'set_max_bill_count'; // Настройка лимита
  static const String billAcceptorTest = 'test_bill_accept'; // Тестирование
  static const String billAcceptorReset = 'reset_bill_count'; // Инкассация/сброс
  static const String billAcceptorStop = 'stop_accepting_payment'; // Остановка приема

  // СМЕНЫ
  static const String shiftManagement = 'open'; // Управление сменами - основной доступ
  static const String shiftOpen = 'open'; // Открытие смены
  static const String shiftClose = 'close'; // Закрытие смены

  // УСЛУГИ И ШТРАФЫ
  static const String services = 'add_service'; // Услуги - основной доступ
  static const String servicesGet = 'get_services'; // Просмотр услуг
  static const String servicesAdd = 'add_service'; // Добавление услуги
  static const String servicesUpdate = 'update_service'; // Редактирование услуги
  static const String servicesDelete = 'delete_service'; // Удаление услуги

  static const String fines = 'add_fine'; // Штрафы - основной доступ
  static const String finesGet = 'get_fines'; // Просмотр штрафов
  static const String finesAdd = 'add_fine'; // Добавление штрафа
  static const String finesUpdate = 'update_fine'; // Редактирование штрафа
  static const String finesDelete = 'delete_fine'; // Удаление штрафа

  static const String roomPrices = 'export_room_prices'; // Цены на жилье
  static const String transactions = 'get_transactions'; // Транзакции
  static const String taxSettings = 'add_service'; // Налоговые настройки

  // БЕЗОПАСНОСТЬ
  static const String changePassword = 'change_password'; // Смена пароля

  // УВЕДОМЛЕНИЯ
  static const String telegram = 'start_tg_bot_notifications'; // Telegram

  // ПРИЛОЖЕНИЕ
  static const String about = 'get_status'; // О приложении (доступно всем)

  // СИСТЕМНЫЕ
  static const String shutdown = 'shutdown'; // Выключение
  static const String reboot = 'reboot'; // Перезагрузка
  static const String systemSettings = 'set_system_settings'; // Системные настройки
}
