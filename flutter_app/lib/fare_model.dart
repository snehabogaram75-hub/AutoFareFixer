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

/// Telangana auto-rickshaw tariff (Government Order of 2 Oct 2026):
/// 30 INR for the first 1.6 km, 14 INR per extra km, night (23:00-05:00) = 1.5x.
/// The waiting charge of 0.75 INR/min comes from the committee proposal;
/// verify it against the final order before relying on it.
class OfficialTariff {
  static const double baseFare = 30;
  static const double baseKm = 1.6;
  static const double perKm = 14;
  static const double nightMultiplier = 1.5;
  static const double waitPerMin = 0.75;

  static bool isNight(DateTime t) => t.hour >= 23 || t.hour < 5;

  static double fare({
    required double distanceKm,
    DateTime? when,
    double waitMin = 0,
  }) {
    final t = when ?? DateTime.now();
    var f = distanceKm <= baseKm
        ? baseFare
        : baseFare + (distanceKm - baseKm) * perKm;
    if (isNight(t)) f *= nightMultiplier;
    return f + waitMin * waitPerMin;
  }
}
