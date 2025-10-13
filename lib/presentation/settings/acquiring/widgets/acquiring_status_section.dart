// ============================================
// lib/presentation/settings/acquiring/widgets/acquiring_status_section.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_cubit.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_models.dart';

/// Виджет для отображения статуса подключения к терминалу эквайринга
class AcquiringStatusSection extends StatelessWidget {
  const AcquiringStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcquiringCubit, AcquiringConnectionState>(
      builder: (context, state) {
        return CupertinoListSection.insetGrouped(
          header: const Text('СТАТУС ПОДКЛЮЧЕНИЯ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: state.isConnected
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  state.isConnected ? CupertinoIcons.checkmark : CupertinoIcons.xmark,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: Text(
                state.isConnected ? 'Подключено' : 'Не подключено',
                style: TextStyle(
                  color: state.isConnected
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: state.connectionMethod.isNotEmpty
                  ? Text(state.connectionMethod)
                  : null,
              trailing: state.isChecking
                  ? const CupertinoActivityIndicator(radius: 10)
                  : CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.read<AcquiringCubit>().checkConnection(),
                      child: const Icon(
                        CupertinoIcons.refresh,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
