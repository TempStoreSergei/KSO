import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/presentation/booking/room_booking_screen.dart';
import 'package:motel/presentation/admin_login/admin_login_screen.dart';

// Модели данных
class ScreensaverFile {
  final int id;
  final int order;
  final String fileUrl;
  final bool soundIsEnable;
  final int timeShowImage;
  final String fileType;

  ScreensaverFile({
    required this.id,
    required this.order,
    required this.fileUrl,
    required this.soundIsEnable,
    required this.timeShowImage,
    required this.fileType,
  });

  factory ScreensaverFile.fromJson(Map<String, dynamic> json) {
    return ScreensaverFile(
      id: json['id'] ?? 0,
      order: json['order'] ?? 0,
      fileUrl: json['fileUrl'] ?? '',
      soundIsEnable: json['soundIsEnable'] ?? false,
      timeShowImage: json['timeShowImage'] ?? 200,
      fileType: json['fileType'] ?? '',
    );
  }
}

class ScreensaverSettings {
  final bool isEnable;
  final bool soundIsEnable;
  final int timeShowImage;
  final int idleTime;
  final bool showClock;

  ScreensaverSettings({
    required this.isEnable,
    required this.soundIsEnable,
    required this.timeShowImage,
    required this.idleTime,
    required this.showClock,
  });

  factory ScreensaverSettings.fromJson(Map<String, dynamic> json) {
    return ScreensaverSettings(
      isEnable: json['isEnable'] ?? false,
      soundIsEnable: json['soundIsEnable'] ?? false,
      timeShowImage: json['timeShowImage'] ?? 200,
      idleTime: json['idleTime'] ?? 100,
      showClock: json['showClock'] ?? true,
    );
  }
}

class LockScreen extends StatefulWidget {
  LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final ApiClient _apiClient = ApiClient.instance;
  final PageController _pageController = PageController();

  List<ScreensaverFile>? _files;
  ScreensaverSettings? _settings;
  bool _isLoading = true;

  int _secretTapCount = 0;
  Timer? _secretTapTimer;

  Timer? _pageChangeTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    print("[LockScreen | initState] Экран инициализируется...");

    _loadScreensaverData();
  }

  Future<void> _loadScreensaverData() async {
    try {
      print("[LockScreen | _loadScreensaverData] Начинаю загрузку данных заставки...");

      // Загружаем файлы
      final filesResponse = await _apiClient.get('/screensaver/get_files');
      final filesList = (filesResponse['files'] as List)
          .map((json) => ScreensaverFile.fromJson(json))
          .toList();

      // Сортируем по order
      filesList.sort((a, b) => a.order.compareTo(b.order));

      // Загружаем настройки
      final settingsResponse = await _apiClient.get('/screensaver/get_settings');
      final settings = ScreensaverSettings.fromJson(settingsResponse);

      if (mounted) {
        setState(() {
          _files = filesList;
          _settings = settings;
          _isLoading = false;
        });

        // Запускаем автопрокрутку если есть файлы и заставка включена
        if (filesList.isNotEmpty && settings.isEnable) {
          print("[LockScreen | _loadScreensaverData] УСПЕХ. Загружено ${filesList.length} файлов. ЗАПУСКАЮ ТАЙМЕР.");
          _startPageChangeTimer();
        }
      }
    } catch (e) {
      print("[LockScreen | _loadScreensaverData] Ошибка загрузки: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    print("[LockScreen | dispose] Экран уничтожается, очищаем ресурсы.");
    _pageController.dispose();
    _secretTapTimer?.cancel();
    _pageChangeTimer?.cancel();
    super.dispose();
  }

  void _startPageChangeTimer() {
    _pageChangeTimer?.cancel();

    if (_files == null || _files!.isEmpty) return;

    // Получаем текущий файл по индексу
    final currentFileIndex = _currentPage % _files!.length;
    final currentFile = _files![currentFileIndex];

    // Используем время показа текущего файла
    final duration = Duration(seconds: currentFile.timeShowImage);

    print("[LockScreen | _startPageChangeTimer] Устанавливаю таймер на ${currentFile.timeShowImage} секунд для файла #$currentFileIndex");

    _pageChangeTimer = Timer(duration, () {
      if (_files == null || _files!.isEmpty || !mounted) {
        return;
      }

      print("[LockScreen | _startPageChangeTimer] Таймер сработал! Переключаю страницу.");

      _currentPage++;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int page) {
    print("[LockScreen | _onPageChanged] Страница изменена на: $page");
    setState(() {
      _currentPage = page;
    });
    // Перезапускаем таймер с новым временем для нового файла
    _startPageChangeTimer();
  }

  void _onUnlockTap() {
    print("[LockScreen | _onUnlockTap] Экран разблокирован.");
    _pageChangeTimer?.cancel();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RoomBookingScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      if (mounted) _startPageChangeTimer();
    });
  }

  void _handleSecretTap() {
    _secretTapTimer?.cancel();
    setState(() => _secretTapCount++);
    print("[LockScreen | _handleSecretTap] Секретное нажатие! Счетчик: $_secretTapCount");

    if (_secretTapCount >= 5) {
      _secretTapTimer?.cancel();
      _secretTapCount = 0;
      print("[LockScreen | _handleSecretTap] Вход в админ-панель активирован.");
      _pageChangeTimer?.cancel();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      ).then((_) {
        if (mounted) _startPageChangeTimer();
      });
    } else {
      _secretTapTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          print("[LockScreen | _handleSecretTap] Таймер сброса счетчика сработал. Переход к бронированию.");
          setState(() => _secretTapCount = 0);
          _onUnlockTap();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onUnlockTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            _buildBackgroundContent(),
            if (_settings?.showClock ?? true)
              Center(
                child: GestureDetector(
                  onTap: _handleSecretTap,
                  behavior: HitTestBehavior.opaque,
                  child: _ClockWidget(),
                ),
              ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: IgnorePointer(
                    child: _buildUnlockButton(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundContent() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 20, color: Colors.white),
      );
    }

    // Если заставка выключена или нет файлов - показываем заглушку
    if (_settings?.isEnable == false || _files == null || _files!.isEmpty) {
      return _buildBackground('assets/images/hostel_social_area.jpg', isNetwork: false);
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: null, // Бесконечная прокрутка
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final actualIndex = index % _files!.length;
        return _buildBackground(_files![actualIndex].fileUrl, isNetwork: true);
      },
    );
  }

  Widget _buildBackground(String path, {required bool isNetwork}) {
    ImageProvider imageProvider = isNetwork ? NetworkImage(path) : AssetImage(path) as ImageProvider;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          onError: isNetwork
              ? (exception, stackTrace) {
            print("[LockScreen | _buildBackground] КРИТИЧЕСКАЯ ОШИБКА при загрузке сетевого изображения: $path. Ошибка: $exception");
          }
              : null,
        ),
      ),
    );
  }

  Widget _buildUnlockButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Text(
          'Нажми на меня!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(blurRadius: 5, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

// Отдельный виджет для часов с собственным состоянием
class _ClockWidget extends StatefulWidget {
  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late Timer _clockTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final formattedTime = DateFormat('HH:mm').format(_currentTime);
    final formattedDate = DateFormat('EEEE, d MMMM', 'ru').format(_currentTime);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.25,
            fontWeight: FontWeight.w200,
            height: 0.9,
            letterSpacing: -5,
            shadows: const [
              Shadow(blurRadius: 20, color: Colors.black54),
              Shadow(blurRadius: 40, color: Colors.black54),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          formattedDate,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w500,
            shadows: const [Shadow(blurRadius: 5, color: Colors.black54)],
          ),
        ),
      ],
    );
  }
}