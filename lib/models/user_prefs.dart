class UserPrefs {
  final String workStart;
  final String workEnd;
  final int    breakMins;

  const UserPrefs({
    this.workStart = '09:00',
    this.workEnd   = '18:00',
    this.breakMins = 15,
  });

  UserPrefs copyWith({String? workStart, String? workEnd, int? breakMins}) => UserPrefs(
        workStart: workStart ?? this.workStart,
        workEnd:   workEnd   ?? this.workEnd,
        breakMins: breakMins ?? this.breakMins,
      );

  Map<String, dynamic> toJson() => {
        'workStart': workStart,
        'workEnd':   workEnd,
        'breakMins': breakMins,
      };

  factory UserPrefs.fromJson(Map<String, dynamic> j) => UserPrefs(
        workStart: j['workStart'] as String? ?? '09:00',
        workEnd:   j['workEnd']   as String? ?? '18:00',
        breakMins: j['breakMins'] as int?    ?? 15,
      );
}