part of 'login_bloc.dart';

@immutable
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class CheckAuth extends LoginEvent {
  final String ip, username, password;
  final apiToken;

  CheckAuth({
    required this.ip,
    required this.username,
    required this.password,
    required this.apiToken,
  });
}

class LoadLogin extends LoginEvent {}
