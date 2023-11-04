import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:login_absen/core/services/ApiService.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<CheckAuth>(_checkAuth);
    on<LoadLogin>(_loadLogin);
  }

  Future<void> _checkAuth(CheckAuth event, Emitter<LoginState> emit) async {
    ApiServices apiServices = ApiServices();
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final response = await apiServices.login(
          event.ip, event.username, event.password, event.fcmToken, event.apiToken);
      print(response[0]['username']);
      if (response[0]['username'] != '') {
        return emit(state.copyWith(
          status: LoginStatus.success,
          username: response[0]['username'],
          ctmPassword: response[0]['ctm_password'],
          userId: response[0]['user_id'],
          officeShiftId: response[0]['office_shift_id'],
          departmentId: response[0]['department_id'],
          departmentName: response[0]['department_name'],
          fcmToken: response[0]['fcm_token'],
          message: "Welcome " + response[0]['name'],
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          message: "Username or password is not valid",
        ));
      }
    } catch (e) {
      if (e != 'cancel') {
        emit(state.copyWith(
          status: LoginStatus.failure,
          message: "Username or password is not valid",
        ));
      }
      emit(state.copyWith(
        status: LoginStatus.failure,
        message: "Username or password is not valid",
      ));
      print('error');
      print(e.toString());
    }
  }

  Future<void> _loadLogin(LoadLogin event, Emitter<LoginState> emit) async {
    return emit(state.copyWith(status: LoginStatus.loading));
  }
}
