part of 'profile_bloc.dart';

enum ProfileStatus { initial, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final String userId;
  final String nama;
  final String idShift;
  final String fotoProfil;
  final String jabatan;
  final String photoIn;
  final String dateIn;
  final String clockIn;
  final String fotoIn;
  final String shiftIn;
  final String dateOut;
  final String clockOut;
  final String fotoOut;
  final String shiftOut;
  final String totalWork;
  final String statusBreak;
  final String breakOut;
  final String breakIn;
  final String message;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.userId = '',
    this.nama = '',
    this.idShift = '',
    this.fotoProfil = '',
    this.jabatan = '',
    this.photoIn = '',
    this.fotoIn = '',
    this.dateIn = '',
    this.clockIn = '',
    this.shiftIn = '',
    this.dateOut = '',
    this.clockOut = '',
    this.fotoOut = '',
    this.shiftOut = '',
    this.totalWork = '',
    this.statusBreak = '',
    this.breakOut = '',
    this.breakIn = '',
    this.message = '',
  });

  ProfileState copyWith({
    ProfileStatus? status,
    String? userId,
    String? nama,
    String? idShift,
    String? fotoProfil,
    String? jabatan,
    String? photoIn,
    String? dateIn,
    String? clockIn,
    String? fotoIn,
    String? shiftIn,
    String? dateOut,
    String? clockOut,
    String? fotoOut,
    String? shiftOut,
    String? totalWork,
    String? statusBreak,
    String? breakOut,
    String? breakIn,
    String? message,
  }) {
    return ProfileState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      idShift: idShift ?? this.idShift,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      jabatan: jabatan ?? this.jabatan,
      photoIn: photoIn ?? this.photoIn,
      dateIn: dateIn ?? this.dateIn,
      clockIn: clockIn ?? this.clockIn,
      fotoIn: fotoIn ?? this.fotoIn,
      shiftIn: shiftIn ?? this.shiftIn,
      dateOut: dateOut ?? this.dateOut,
      clockOut: clockOut ?? this.clockOut,
      fotoOut: fotoOut ?? this.fotoOut,
      shiftOut: shiftOut ?? this.shiftOut,
      totalWork: totalWork ?? this.totalWork,
      statusBreak: statusBreak ?? this.statusBreak,
      breakOut: breakOut ?? this.breakOut,
      breakIn: breakIn ?? this.breakIn,
      message: message ?? this.message,
    );
  }

  @override
  List<Object> get props => [
        this.status,
        this.userId,
        this.nama,
        this.idShift,
        this.fotoProfil,
        this.jabatan,
        this.photoIn,
        this.dateIn,
        this.clockIn,
        this.shiftIn,
        this.dateOut,
        this.clockOut,
        this.shiftOut,
        this.totalWork,
        this.statusBreak,
        this.breakOut,
        this.breakIn,
        this.message
      ];
}
