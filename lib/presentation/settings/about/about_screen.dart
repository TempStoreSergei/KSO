import 'package:flutter/cupertino.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('О приложении'),
        previousPageTitle: 'Настройки',
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Motel', style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
            const SizedBox(height: 8),
            Text('Версия 1.0.0', style: CupertinoTheme.of(context).textTheme.textStyle),
            const SizedBox(height: 16),
            CupertinoButton(
              child: const Text('Политика конфиденциальности'),
              onPressed: () {},
            ),
            CupertinoButton(
              child: const Text('Условия использования'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
