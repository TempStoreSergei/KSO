// lib/presentation/payment/shift_not_open_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/presentation/admin_login/admin_login_screen.dart';
import 'package:motel/presentation/widgets/shared_background.dart';

/// Экран, показываемый когда смена не открыта.
/// Предлагает позвать консультанта и предоставляет доступ в админку.
class ShiftNotOpenScreen extends StatelessWidget {
  const ShiftNotOpenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;

          return Column(
            children: [
              // Кнопка "Назад"
              Padding(
                padding: EdgeInsets.all(w * 0.04),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: w * 0.02, vertical: h * 0.015),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(h * 0.03),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.chevron_left,
                              size: h * 0.025, color: Colors.white),
                          SizedBox(width: w * 0.01),
                          Text(
                            'Назад',
                            style: TextStyle(
                              fontSize: h * 0.02,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Центральная панель
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: w * 0.5),
                    margin: EdgeInsets.symmetric(
                        horizontal: w * 0.04, vertical: h * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.05),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.05,
                      vertical: h * 0.04,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Иконка предупреждения
                        Container(
                          width: h * 0.18,
                          height: h * 0.18,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            size: h * 0.08,
                            color: Colors.orange,
                          ),
                        ),

                        SizedBox(height: h * 0.03),

                        Text(
                          'Смена не открыта',
                          style: TextStyle(
                            fontSize: h * 0.036,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF000000),
                          ),
                        ),

                        SizedBox(height: h * 0.015),

                        Text(
                          'Для проведения оплаты необходимо\nоткрыть смену на кассе',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: h * 0.02,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF757575),
                          ),
                        ),

                        SizedBox(height: h * 0.025),

                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: h * 0.01),
                          child: Divider(
                              color: Colors.grey[300], thickness: 1),
                        ),

                        SizedBox(height: h * 0.015),

                        Text(
                          'Позовите консультанта\nдля открытия смены',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: h * 0.028,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1976D2),
                          ),
                        ),

                        SizedBox(height: h * 0.03),

                        // Кнопка входа в админку
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => const AdminLoginScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                vertical: h * 0.02),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              borderRadius:
                                  BorderRadius.circular(h * 0.02),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  color: Colors.white,
                                  size: h * 0.025,
                                ),
                                SizedBox(width: w * 0.015),
                                Text(
                                  'Войти в админ-панель',
                                  style: TextStyle(
                                    fontSize: h * 0.022,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
