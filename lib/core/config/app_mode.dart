class AppMode {
  AppMode._();

  static const bool dentistrySelfService = true;

  static const String appTitle =
      dentistrySelfService ? 'СТОМАТОЛОГИЯ • КАССА' : 'КАССА САМООБСЛУЖИВАНИЯ';
}
