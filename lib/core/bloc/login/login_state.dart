part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String username;
  final String ctmPassword;
  final String userId;
  final String officeShiftId;
  final String message;

  const LoginState({
    this.status = LoginStatus.initial,
    this.username = '',
    this.ctmPassword = '',
    this.userId = '',
    this.officeShiftId = '',
    this.message = '',
  });

  LoginState copyWith({
    LoginStatus? status,
    String? username,
    String? ctmPassword,
    String? userId,
    String? officeShiftId,
    String? message,
  }) {
    return LoginState(
      status: status ?? this.status,
      username: username ?? this.username,
      ctmPassword: ctmPassword ?? this.username,
      userId: userId ?? this.userId,
      officeShiftId: officeShiftId ?? this.officeShiftId,
      message: message ?? this.message,
    );
  }

  @override
  List<Object> get props => [
        this.status,
        this.username,
        this.ctmPassword,
        this.userId,
        this.officeShiftId,
        this.message
      ];
}
