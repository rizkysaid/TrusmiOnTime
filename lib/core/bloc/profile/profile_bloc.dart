import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {
    on<GetProfile>(_onGetProfile);
    on<InitialProfile>(_initialProfile);
  }

  Future<void> _onGetProfile(
      GetProfile event, Emitter<ProfileState> emit) async {
    ApiServices apiServices = ApiServices();
    try {
      final profile = await apiServices.profil(
          event.ip, event.userID, event.date, event.apiToken);
      // print('user_id: ' + profile['user_id'].toString());
      // print('nama: ' + profile['nama'].toString());
      // print('id_shift: ' + profile['id_shift'].toString());
      // print('foto_profil: ' + profile['foto_profil'].toString());
      // print('jabatan: ' + profile['jabatan'].toString());
      // print('photo_in: ' + profile['photo_in'].toString());
      // print('date_in: ' + profile['date_in'].toString());
      // print('clock_in: ' + profile['clock_in'].toString());
      // print('shift_in: ' + profile['shift_in'].toString());
      // print('photo_out: ' + profile['photo_out'].toString());
      // print('date_out: ' + profile['date_out'].toString());
      // print('clock_out: ' + profile['clock_out'].toString());
      // print('shift_out: ' + profile['shift_out'].toString());
      // print('total_work: ' + profile['total_work'].toString());
      // print('status_break: ' + profile['status_break'].toString());
      // print('break_out: ' + profile['break_out'].toString());
      // print('break_in: ' + profile['break_in'].toString());
      // print('department_id: ' + profile['department_id'].toString());
      // print('message: ' + profile['message'].toString());
      // print('response_time: ' + profile['response_time'].toString());
      return emit(state.copyWith(
        status: ProfileStatus.success,
        userId: profile['user_id'],
        nama: profile['nama'],
        idShift: profile['id_shift'],
        fotoProfil: profile['foto_profil'],
        jabatan: profile['jabatan'],
        photoIn: profile['photo_in'],
        dateIn: profile['date_in'],
        clockIn: profile['clock_in'],
        shiftIn: profile['shift_in'],
        photoOut: profile['photo_out'],
        dateOut: profile['date_out'],
        clockOut: profile['clock_out'],
        shiftOut: profile['shift_out'],
        totalWork: profile['total_work'],
        statusBreak: profile['status_break'],
        breakOut: profile['break_out'],
        breakIn: profile['break_in'],
        departmentId: profile['department_id'],
        message: profile['message'],
        responseTime: profile['response_time'],
      ));
    } catch (e) {
      if (e != 'cancel') {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          message: e.toString(),
        ));
      }
      emit(state.copyWith(status: ProfileStatus.failure));
      print('error');
      print(e.toString());
    }
  }

  Future<void> _initialProfile(
      InitialProfile event, Emitter<ProfileState> emit) async {
    return emit(state.copyWith(status: ProfileStatus.initial));
  }
}
