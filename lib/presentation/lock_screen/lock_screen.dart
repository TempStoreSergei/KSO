import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/presentation/admin_login/admin_login_screen.dart';
import 'package:motel/presentation/booking/room_booking_screen.dart';
import 'package:motel/presentation/info/info_screen.dart';

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
  const LockScreen({super.key});

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
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadScreensaverData();
  }

  Future<void> _loadScreensaverData() async {
    try {
      final filesResponse = await _apiClient.get('/screensaver/get_files');
      final filesList = (filesResponse['files'] as List)
          .map((json) => ScreensaverFile.fromJson(json))
          .toList();
      filesList.sort((a, b) => a.order.compareTo(b.order));

      final settingsResponse = await _apiClient.get('/screensaver/get_settings');
      final settings = ScreensaverSettings.fromJson(settingsResponse);

      if (mounted) {
        setState(() {
          _files = filesList;
          _settings = settings;
          _isLoading = false;
        });

        if (filesList.isNotEmpty && settings.isEnable) {
          _startPageChangeTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _secretTapTimer?.cancel();
    _pageChangeTimer?.cancel();
    super.dispose();
  }

  void _startPageChangeTimer() {
    _pageChangeTimer?.cancel();

    if (_files == null || _files!.isEmpty) return;

    final currentFileIndex = _currentPage % _files!.length;
    final currentFile = _files![currentFileIndex];
    final duration = Duration(seconds: currentFile.timeShowImage);

    _pageChangeTimer = Timer(duration, () {
      if (_files == null || _files!.isEmpty || !mounted) return;
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
    setState(() {
      _currentPage = page;
    });
    _startPageChangeTimer();
  }

  void _onUnlockTap() {
    if (_isNavigating) return;
    _isNavigating = true;
    _pageChangeTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isNavigating = false;
        return;
      }

      Navigator.of(context)
          .push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RoomBookingScreen(),
              transitionDuration: const Duration(milliseconds: 600),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          )
          .then((_) {
            _isNavigating = false;
            if (mounted) _startPageChangeTimer();
          });
    });
  }

  void _openInfoScreen() {
    if (_isNavigating) return;
    _isNavigating = true;
    _pageChangeTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isNavigating = false;
        return;
      }

      Navigator.of(context)
          .push(
            CupertinoPageRoute(builder: (_) => const InfoScreen()),
          )
          .then((_) {
            _isNavigating = false;
            if (mounted && (_files?.isNotEmpty ?? false) && (_settings?.isEnable ?? false)) {
              _startPageChangeTimer();
            }
          });
    });
  }

  void _handleSecretTap() {
    _secretTapTimer?.cancel();
    setState(() => _secretTapCount++);

    if (_secretTapCount >= 5) {
      if (_isNavigating) return;
      _isNavigating = true;
      _secretTapTimer?.cancel();
      _secretTapCount = 0;
      _pageChangeTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isNavigating = false;
          return;
        }

        Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            )
            .then((_) {
              _isNavigating = false;
              if (mounted) _startPageChangeTimer();
            });
      });
    } else {
      _secretTapTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
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
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _onUnlockTap,
              behavior: HitTestBehavior.opaque,
              child: _buildBackgroundContent(),
            ),
          ),
          if (_settings?.showClock ?? true)
            Center(
              child: GestureDetector(
                onTap: _handleSecretTap,
                behavior: HitTestBehavior.opaque,
                child: const _ClockWidget(),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IgnorePointer(child: _buildUnlockButton()),
                    const SizedBox(height: 12),
                    _buildInfoButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _openInfoScreen,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 70),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.info_circle_fill, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Информация',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
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

    if (_settings?.isEnable == false || _files == null || _files!.isEmpty) {
      return _buildBackground('assets/images/hostel_social_area.jpg', isNetwork: false);
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: null,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final actualIndex = index % _files!.length;
        return _buildBackground(_files![actualIndex].fileUrl, isNetwork: true);
      },
    );
  }

  Widget _buildBackground(String path, {required bool isNetwork}) {
    final ImageProvider imageProvider =
        isNetwork ? NetworkImage(path) : AssetImage(path) as ImageProvider;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildUnlockButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
      ),
      child: const Center(
        child: Text(
          'Нажми на меня!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(blurRadius: 5, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();

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
