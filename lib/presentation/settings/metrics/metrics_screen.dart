import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'cubit/metrics_cubit.dart';
import 'cubit/metrics_state.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MetricsCubit(ApiClient.instance)..loadMetrics(),
      child: const _MetricsView(),
    );
  }
}

class _MetricsView extends StatelessWidget {
  const _MetricsView();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Метрики'),
        previousPageTitle: 'Настройки',
      ),
      child: BlocBuilder<MetricsCubit, MetricsState>(
        builder: (context, state) {
          if (state is MetricsLoading) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (state is MetricsError) {
            return Center(child: Text(state.message));
          } else if (state is MetricsLoaded) {
            return ListView.builder(
              itemCount: state.metrics.length,
              itemBuilder: (context, index) {
                final key = state.metrics.keys.elementAt(index);
                final value = state.metrics[key];
                return CupertinoListTile(
                  title: Text(key),
                  trailing: Text(value.toString()),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
