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
  final String shiftIn;
  final String dateOut;
  final String clockOut;
  final String photoOut;
  final String shiftOut;
  final String totalWork;
  final String statusBreak;
  final String breakOut;
  final String breakIn;
  final String departmentId;
  final String departmentName;
  final String message;
  final String quizStatus;
  final String quizRequired;
  final String fcmToken;
  final List<dynamic> allDepartments;
  final int responseTime;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.userId = '',
    this.nama = '',
    this.idShift = '',
    this.fotoProfil = '',
    this.jabatan = '',
    this.photoIn = '',
    this.dateIn = '',
    this.clockIn = '',
    this.shiftIn = '',
    this.dateOut = '',
    this.clockOut = '',
    this.photoOut = '',
    this.shiftOut = '',
    this.totalWork = '',
    this.statusBreak = '',
    this.breakOut = '',
    this.breakIn = '',
    this.departmentId = '',
    this.departmentName = '',
    this.message = '',
    this.quizStatus = '',
    this.quizRequired = '',
    this.fcmToken = '',
    this.allDepartments = const [],
    this.responseTime = 10,
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
    String? shiftIn,
    String? dateOut,
    String? clockOut,
    String? photoOut,
    String? shiftOut,
    String? totalWork,
    String? statusBreak,
    String? breakOut,
    String? breakIn,
    String? departmentId,
    String? departmentName,
    String? message,
    String? quizStatus,
    String? quizRequired,
    String? fcmToken,
    List<dynamic>? allDepartments,
    int? responseTime,
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
      shiftIn: shiftIn ?? this.shiftIn,
      dateOut: dateOut ?? this.dateOut,
      clockOut: clockOut ?? this.clockOut,
      photoOut: photoOut ?? this.photoOut,
      shiftOut: shiftOut ?? this.shiftOut,
      totalWork: totalWork ?? this.totalWork,
      statusBreak: statusBreak ?? this.statusBreak,
      breakOut: breakOut ?? this.breakOut,
      breakIn: breakIn ?? this.breakIn,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      message: message ?? this.message,
      quizStatus: quizStatus ?? this.quizStatus,
      quizRequired: quizRequired ?? this.quizRequired,
      fcmToken: fcmToken ?? this.fcmToken,
      allDepartments: allDepartments ?? this.allDepartments,
      responseTime: responseTime ?? this.responseTime,
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
        this.photoOut,
        this.dateOut,
        this.clockOut,
        this.shiftOut,
        this.totalWork,
        this.statusBreak,
        this.breakOut,
        this.breakIn,
        this.departmentId,
        this.departmentName,
        this.message,
        this.quizStatus,
        this.quizRequired,
        this.fcmToken,
        this.allDepartments,
        this.responseTime
      ];
}
