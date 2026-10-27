/// Linear-regression fare model.
/// NOTE: trained on SYNTHETIC practice data. Replace the coefficients
/// after retraining on real trip data.
class FareModel {
  static const double _intercept = 2.1354;
  static const double _perKm = 15.1596;
  static const double _perHour = -0.0516;
  static const double _night = 23.3513;
  static const double _peak = 4.8794;
  static const double _rain = 9.9116;
  static const double _perWaitMin = 1.4024;

  /// Night = 22:00-04:59, peak = 08:00-10:59 and 17:00-20:59.
  static double predict({
    required double distanceKm,
    DateTime? when,
    bool rain = false,
    double waitMin = 0,
  }) {
    final t = when ?? DateTime.now();
    final h = t.hour;
    final isNight = (h >= 22 || h < 5) ? 1.0 : 0.0;
    final isPeak = ((h >= 8 && h <= 10) || (h >= 17 && h <= 20)) ? 1.0 : 0.0;
    final fare = _intercept +
        _perKm * distanceKm +
        _perHour * h +
        _night * isNight +
        _peak * isPeak +
        (rain ? _rain : 0.0) +
        _perWaitMin * waitMin;
    return fare < 30 ? 30 : fare;
  }
}
