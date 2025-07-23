part of 'services_cubit.dart';

abstract class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object> get props => [];
}

/// Начальное состояние, ничего не происходит.
class ServicesInitial extends ServicesState {}

/// Состояние загрузки данных.
class ServicesLoading extends ServicesState {}

/// Состояние успешной загрузки данных.
class ServicesLoaded extends ServicesState {
  final List<ServiceEntity> services;

  const ServicesLoaded(this.services);

  @override
  List<Object> get props => [services];
}

/// Состояние ошибки.
class ServicesError extends ServicesState {
  final String message;

  const ServicesError(this.message);

  @override
  List<Object> get props => [message];
}