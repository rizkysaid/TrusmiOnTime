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
      print(profile);
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
        dateOut: profile['date_out'],
        clockOut: profile['clock_out'],
        shiftOut: profile['shift_out'],
        totalWork: profile['total_work'],
        statusBreak: profile['status_break'],
        breakOut: profile['break_out'],
        breakIn: profile['break_in'],
        message: profile['message'],
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
