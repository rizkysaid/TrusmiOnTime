part of 'login_bloc.dart';

@immutable
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class CheckAuth extends LoginEvent {
  final String ip, username, password, fcmToken;
  final apiToken;

  CheckAuth({
    required this.ip,
    required this.username,
    required this.password,
    required this.fcmToken,
    required this.apiToken,
  });
}

class LoadLogin extends LoginEvent {}
