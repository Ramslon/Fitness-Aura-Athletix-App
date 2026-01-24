/// Represents volume load calculations for exercises
class VolumeLoadData {
  final String exerciseName;
  final String bodyPart;
  final double todayVolume;
  final double lastSessionVolume;
  final double weekVolume;
  final double lastWeekVolume;
  final double monthVolume;
  final double lastMonthVolume;

  VolumeLoadData({
    required this.exerciseName,
    required this.bodyPart,
    required this.todayVolume,
    required this.lastSessionVolume,
    required this.weekVolume,
    required this.lastWeekVolume,
    required this.monthVolume,
    required this.lastMonthVolume,
  });

  /// Calculate today vs last session change
  double get todayVsLastChange => todayVolume - lastSessionVolume;
  double get todayVsLastPercent => lastSessionVolume > 0 
      ? ((todayVolume - lastSessionVolume) / lastSessionVolume * 100) 
      : 0;

  /// Calculate week vs week change
  double get weekVsWeekChange => weekVolume - lastWeekVolume;
  double get weekVsWeekPercent => lastWeekVolume > 0 
      ? ((weekVolume - lastWeekVolume) / lastWeekVolume * 100) 
      : 0;

  /// Calculate month vs month change
  double get monthVsMonthChange => monthVolume - lastMonthVolume;
  double get monthVsMonthPercent => lastMonthVolume > 0 
      ? ((monthVolume - lastMonthVolume) / lastMonthVolume * 100) 
      : 0;

  bool get isTodayIncreased => todayVsLastChange > 0;
  bool get isWeekIncreased => weekVsWeekChange > 0;
  bool get isMonthIncreased => monthVsMonthChange > 0;
}

/// Overall body load summary
class BodyLoadSummary {
  final double totalTodayVolume;
  final double totalYesterdayVolume;
  final double totalWeekVolume;
  final double totalLastWeekVolume;
  final double totalMonthVolume;
  final double totalLastMonthVolume;
  final Map<String, double> volumeByMuscle;

  BodyLoadSummary({
    required this.totalTodayVolume,
    required this.totalYesterdayVolume,
    required this.totalWeekVolume,
    required this.totalLastWeekVolume,
    required this.totalMonthVolume,
    required this.totalLastMonthVolume,
    required this.volumeByMuscle,
  });

  double get todayVsYesterdayPercent => totalYesterdayVolume > 0
      ? ((totalTodayVolume - totalYesterdayVolume) / totalYesterdayVolume * 100)
      : 0;

  double get weekVsWeekPercent => totalLastWeekVolume > 0
      ? ((totalWeekVolume - totalLastWeekVolume) / totalLastWeekVolume * 100)
      : 0;

  double get monthVsMonthPercent => totalLastMonthVolume > 0
      ? ((totalMonthVolume - totalLastMonthVolume) / totalLastMonthVolume * 100)
      : 0;
}
