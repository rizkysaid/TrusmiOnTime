part of 'profile_bloc.dart';

enum ProfileStatus { initial, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile = const <ProfileModel>[],
    this.errorMessage = '',
  });

  final ProfileStatus status;
  final List<ProfileModel> profile;
  final String errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    List<ProfileModel>? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return '''ProfileState { status: $status, profile.length: ${profile.length} }''';
  }

  @override
  List<Object> get props => [this.status, this.profile, this.errorMessage];
}
