import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:login_absen/core/models/ProfileModel.dart';
import 'package:login_absen/core/services/ApiService.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {
    on<GetProfile>(_onGetProfile);
  }

  Future<void> _onGetProfile(
      GetProfile event, Emitter<ProfileState> emit) async {
    ApiServices apiServices = ApiServices();
    try {
      if (state.status == ProfileStatus.initial) {
        final profile = await apiServices.profil(
            event.ip, event.userID, event.date, event.apiToken);
        return emit(state.copyWith(
          status: ProfileStatus.success,
          profile: List.of(state.profile)..addAll(profile),
        ));
      }
    } catch (e) {
      if (e != 'cancel') {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: e.toString(),
        ));
      }
      emit(state.copyWith(status: ProfileStatus.failure));
      print(e.toString());
    }
  }
}
