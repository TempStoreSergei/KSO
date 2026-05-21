// lib/core/constants/api_endpoints.dart

/// Константы API-эндпоинтов
/// Централизованное хранение всех URL для легкого управления и предотвращения ошибок
class ApiEndpoints {
  ApiEndpoints._();

  // ==================== Стоматология ====================

  /// Отправка оплаченного стоматологического заказа
  static const String sendPaidOrder = '/dentistry/send_paid_order';

  /// Отправка отсканированного стоматологического кода
  static const String sendScannedCode = '/dentistry/send_scanned_code';

  /// Получение списка ошибочных стоматологических заказов
  static const String getWrongOrders = '/dentistry/get_wrong_orders';

  /// Мягкое удаление ошибочного заказа
  static String softDeleteWrongOrder(String orderId) =>
      '/dentistry/soft_delete_wrong_order/$orderId';

  /// Добавление транзакции в отчет
  static const String addTransactionToReport =
      '/dentistry/add_transaction_to_report';

  /// Повторная отправка ошибочного оплаченного заказа
  static const String resendPaidOrder = '/dentistry/resend_paid_order';

  /// Получение отчетов по заказам
  static const String getOrderReports = '/dentistry/get_order_reports';

  /// Получение Excel-файла отчетов по заказам
  static const String getOrderReportsExcel =
      '/dentistry/get_order_reports_excel';

  // ==================== Платежи ====================

  /// Оплата заказа (чек прихода)
  static const String payOrder = '/payments/pay_order';

  /// Установка статуса оплаты в процессе
  static const String setPayInProgress = '/payments/set_pay_in_progress';

  /// Возврат прихода
  static const String refundCheckByFd = '/payments/refund_check_by_fd';

  // ==================== Фискальные операции ====================

  /// Статус смены
  static const String shiftStatus = '/fiscal/shift/status';

  /// Открытие смены
  static const String openShift = '/fiscal/shift/open';

  /// Закрытие смены
  static const String closeShift = '/fiscal/shift/close';

  /// X-отчет
  static const String xReport = '/fiscal/shift/x-report';

  // ==================== Эквайринг ====================

  /// Начало оплаты картой
  static const String startCardPayment = '/acquiring/start_payment';

  /// Отмена оплаты картой
  static const String cancelCardPayment = '/acquiring/cancel_payment';

  /// Возврат оплаты картой
  static const String refundCardPayment = '/acquiring/refund_payment';

  /// Сверка итогов
  static const String receiptReport = '/acquiring/receipt_report';

  /// Архив отчетов эквайринга
  static const String acquiringReports = '/acquiring/get_reports';

  /// Архив чеков эквайринга
  static const String acquiringChecks = '/acquiring/get_checks';

  /// Проверка соединения
  static const String checkAcquiringConnect = '/acquiring/check_connect';

  // ==================== Наличная система ====================

  /// Инициализация наличной системы
  static const String initCashSystem = '/cash_system/init_system';

  /// Начало приема наличных
  static const String startAcceptingPayment =
      '/cash_system/start_accepting_payment';

  /// Остановка приема наличных
  static const String stopAcceptingPayment =
      '/cash_system/stop_accepting_payment';

  /// Выдача сдачи
  static const String dispenseChange = '/cash_system/dispense_change';

  // ==================== Система ====================

  /// Проверка состояния системы
  static const String checkSystem = '/system/check_system';

  /// Получение системных настроек
  static const String getSystemSettings = '/system/get_system_settings';

  /// Установка системных настроек
  static const String setSystemSettings = '/system/set_system_settings';

  /// Включение серверного режима
  static const String enableDevMode = '/system/dev_mode/on';

  /// Выключение серверного режима
  static const String disableDevMode = '/system/dev_mode/off';

  /// Получение приветствий
  static const String getGreetings = '/system/get_greetings';

  /// Установка приветствий
  static const String setGreetings = '/system/set_greetings';

  /// Получение серверных настроек автоматического управления сменой
  static const String getAutoCloseShift = '/system/get_auto_close_shift';

  /// Установка серверных настроек автоматического управления сменой
  static const String setAutoCloseShift = '/system/set_auto_close_shift';

  // ==================== Аутентификация ====================

  /// Вход пользователя
  static const String login = '/auth/login';

  /// Выход пользователя
  static const String logout = '/auth/logout';

  /// Изменение пароля
  static const String changePassword = '/auth/change_password';

  // ==================== Заставка ====================

  /// Получение файлов заставки
  static const String getScreensaverFiles = '/screensaver/get_files';

  /// Добавление файла заставки
  static const String addScreensaverFile = '/screensaver/add_file';

  /// Удаление файла заставки
  static const String deleteScreensaverFile = '/screensaver/delete_file';

  /// Обновление файла заставки
  static const String updateScreensaverFile = '/screensaver/update_file';

  /// Получение настроек заставки
  static const String getScreensaverSettings = '/screensaver/get_settings';

  /// Обновление настроек заставки
  static const String updateScreensaverSettings =
      '/screensaver/update_settings';

  // ==================== Уведомления ====================

  /// Запуск Telegram уведомлений
  static const String startTelegramNotifications = '/notifications/tg/start';

  /// Остановка Telegram уведомлений
  static const String stopTelegramNotifications = '/notifications/tg/stop';

  /// Запуск email уведомлений
  static const String startEmailNotifications = '/notifications/email/start';

  /// Остановка email уведомлений
  static const String stopEmailNotifications = '/notifications/email/stop';
}
