// lib/presentation/lock_screen/lock_screen.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/repositories/screensaver_repository_impl.dart';
import 'package:motel/domain/entities/screensaver_file.dart';
import 'package:motel/domain/usecases/get_screensaver_files.dart';
import 'package:motel/presentation/guest_info_screen.dart';
import 'package:motel/presentation/admin_login/admin_login_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  late Future<List<ScreensaverFile>> _screensaverFilesFuture;
  final PageController _pageController = PageController();
  double _slideProgress = 0.0;
  double _dragOffset = 0.0;
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;
  int _secretTapCount = 0;
  Timer? _secretTapTimer;
  late Timer _clockTimer;
  late DateTime _currentTime;

  // --- ИЗМЕНЕНИЯ ДЛЯ АВТОПРОКРУТКИ ---
  Timer? _pageChangeTimer;
  int _currentPage = 0;
  int _totalPageCount = 0;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    print("[LockScreen | initState] Экран инициализируется...");

    _loadScreensaverFiles();

    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _arrowAnimationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _arrowAnimation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _arrowAnimationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _arrowAnimationController.reverse();
      if (status == AnimationStatus.dismissed) _arrowAnimationController.forward();
    });
    _arrowAnimationController.forward();
  }

  void _loadScreensaverFiles() {
    print("[LockScreen | _loadScreensaverFiles] Начинаю процесс загрузки файлов заставки...");
    final getScreensaverFilesUseCase = GetScreensaverFiles(
      ScreensaverRepositoryImpl(ApiClient.instance),
    );
    _screensaverFilesFuture = getScreensaverFilesUseCase.call();
  }

  @override
  void dispose() {
    print("[LockScreen | dispose] Экран уничтожается, очищаем ресурсы.");
    _pageController.dispose();
    _arrowAnimationController.dispose();
    _clockTimer.cancel();
    _secretTapTimer?.cancel();
    _pageChangeTimer?.cancel(); // <-- ИЗМЕНЕНИЕ: Останавливаем таймер прокрутки
    super.dispose();
  }

  // --- НОВЫЕ МЕТОДЫ ДЛЯ АВТОПРОКРУТКИ ---
  /// Запускает таймер автоматического перелистывания страниц.
  void _startPageChangeTimer() {
    _pageChangeTimer?.cancel(); // Отменяем старый таймер, если он есть
    _pageChangeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _currentPage++;
      if (_currentPage >= _totalPageCount) {
        _currentPage = 0; // Возвращаемся на первую страницу
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Перезапускает таймер при ручном скролле.
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Перезапускаем таймер, чтобы отсчет 5 секунд начался заново
    _startPageChangeTimer();
  }
  // ------------------------------------------

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
      _pageChangeTimer?.cancel(); // <-- ИЗМЕНЕНИЕ: Останавливаем прокрутку при переходе
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => GuestInfoScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ).then((_) {
        // <-- ИЗМЕНЕНИЕ: Возобновляем прокрутку, если вернулись на экран
        if(mounted) _startPageChangeTimer();
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
      _pageChangeTimer?.cancel(); // <-- ИЗМЕНЕНИЕ: Останавливаем прокрутку при переходе
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      ).then((_) {
        // <-- ИЗМЕНЕНИЕ: Возобновляем прокрутку, если вернулись на экран
        if(mounted) _startPageChangeTimer();
      });
    } else {
      _secretTapTimer = Timer(const Duration(seconds: 2), () {
        if(mounted) {
          print("[LockScreen | _handleSecretTap] Таймер сработал, сбрасываю счетчик нажатий.");
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
          FutureBuilder<List<ScreensaverFile>>(
            future: _screensaverFilesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                print("[LockScreen | FutureBuilder] Состояние: ЗАГРУЗКА (ConnectionState.waiting).");
                return const Center(child: CupertinoActivityIndicator(radius: 20, color: Colors.white));
              }
              if (snapshot.hasError) {
                print("[LockScreen | FutureBuilder] Состояние: ОШИБКА (snapshot.hasError).");
                print(" >>>> Детали ошибки: ${snapshot.error}");
                return _buildBackground('assets/images/hostel_social_area.jpg', isNetwork: false);
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                print("[LockScreen | FutureBuilder] Состояние: ДАННЫЕ ОТСУТСТВУЮТ или ПУСТЫ. Показываю локальную заглушку.");
                return _buildBackground('assets/images/hostel_social_area.jpg', isNetwork: false);
              }

              final files = snapshot.data!;

              // --- ИЗМЕНЕНИЕ: Запускаем таймер после успешной загрузки ---
              if (_totalPageCount == 0) { // Запускаем только один раз
                print("[LockScreen | FutureBuilder] УСПЕХ. Загружено ${files.length} файлов. ЗАПУСКАЮ ТАЙМЕР.");
                _totalPageCount = files.length;
                _startPageChangeTimer();
              }
              // --------------------------------------------------------

              return PageView.builder(
                controller: _pageController,
                itemCount: files.length,
                onPageChanged: _onPageChanged, // <-- ИЗМЕНЕНИЕ: Отслеживаем ручной скролл
                itemBuilder: (context, index) {
                  return _buildBackground(files[index].fullUrl, isNetwork: true);
                },
              );
            },
          ),
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

  Widget _buildBackground(String path, {required bool isNetwork}) {
    ImageProvider imageProvider = isNetwork ? NetworkImage(path) : AssetImage(path);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          onError: isNetwork ? (exception, stackTrace) {
            print("[LockScreen | _buildBackground] КРИТИЧЕСКАЯ ОШИБКА при загрузке сетевого изображения: $path. Ошибка: $exception");
          } : null,
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
                  const Text('Потяни для разблокировки', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
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