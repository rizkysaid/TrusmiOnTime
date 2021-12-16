part of 'profile_bloc.dart';

@immutable
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class GetProfile extends ProfileEvent {
  final String ip, userID, date;
  final apiToken;

  GetProfile({
    required this.ip,
    required this.userID,
    required this.date,
    required this.apiToken,
  });
}
