import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
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

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient.instance;
  final PageController _pageController = PageController();

  List<ScreensaverFile>? _files;
  ScreensaverSettings? _settings;
  bool _isLoading = true;

  double _slideProgress = 0.0;
  double _dragOffset = 0.0;
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;
  int _secretTapCount = 0;
  Timer? _secretTapTimer;
  late Timer _clockTimer;
  late DateTime _currentTime;

  Timer? _pageChangeTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    print("[LockScreen | initState] Экран инициализируется...");

    _loadScreensaverData();

    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _arrowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _arrowAnimation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _arrowAnimationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _arrowAnimationController.reverse();
      if (status == AnimationStatus.dismissed) _arrowAnimationController.forward();
    });
    _arrowAnimationController.forward();
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
    _arrowAnimationController.dispose();
    _clockTimer.cancel();
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

  void _onPointerMove(PointerMoveEvent details, double sliderWidth) {
    if (details.buttons == kPrimaryMouseButton) {
      setState(() {
        _slideProgress = (_slideProgress + details.delta.dx / sliderWidth).clamp(0.0, 1.0);
        _dragOffset = _slideProgress * sliderWidth;
      });
    }
  }

  void _onPointerUp(PointerUpEvent details) {
    if (_slideProgress > 0.8) {
      print("[LockScreen | _onPointerUp] Экран разблокирован.");
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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _slideProgress = 0.0;
            _dragOffset = 0.0;
          });
        }
      });
    } else {
      setState(() {
        _slideProgress = 0.0;
        _dragOffset = 0.0;
      });
    }
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
      _secretTapTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          print("[LockScreen | _handleSecretTap] Таймер сброса счетчика сработал.");
          setState(() => _secretTapCount = 0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundContent(),
          if (_settings?.showClock ?? true)
            Center(
              child: GestureDetector(
                onTap: _handleSecretTap,
                child: _buildHud(context),
              ),
            ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: LayoutBuilder(builder: (context, constraints) {
                  final sliderWidth = constraints.maxWidth - 80;
                  return Listener(
                    onPointerMove: (event) => _onPointerMove(event, sliderWidth),
                    onPointerUp: _onPointerUp,
                    child: _buildSlideToUnlock(sliderWidth),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundContent() {
    if (_isLoading) {
      print("[LockScreen | _buildBackgroundContent] Состояние: ЗАГРУЗКА.");
      return const Center(
        child: CupertinoActivityIndicator(radius: 20, color: Colors.white),
      );
    }

    // Если заставка выключена или нет файлов - показываем заглушку
    if (_settings?.isEnable == false || _files == null || _files!.isEmpty) {
      print("[LockScreen | _buildBackgroundContent] Заставка выключена или файлы отсутствуют. Показываю заглушку.");
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

  Widget _buildHud(BuildContext context) {
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

  Widget _buildSlideToUnlock(double sliderWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: _dragOffset + 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: const [Colors.white24, Colors.white, Colors.white24],
                stops: const [0.0, 0.5, 1.0],
                transform: _SlideGradientTransform(_slideProgress),
              ).createShader(bounds),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _arrowAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_arrowAnimation.value, 0),
                      child: const Row(children: [
                        Icon(CupertinoIcons.chevron_right, color: Colors.white, size: 24),
                        Icon(CupertinoIcons.chevron_right, color: Colors.white, size: 24),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Потяни для разблокировки',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: _dragOffset,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.arrow_right, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double progress;
  const _SlideGradientTransform(this.progress);

  @override
  Matrix4? transform(ui.Rect bounds, {ui.TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * progress * 2 - bounds.width, 0.0, 0.0);
}