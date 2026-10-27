# AutoFareFixer: Project Report

A Flutter app that estimates auto-rickshaw fares, checks whether a driver's demanded fare is fair, and collects trip data for a fare-prediction ML model.

## 1. App features

- Auto fare estimation (rule-based meter formula: ₹30 for the first 1.6 km, then ₹14 per km)
- GPS / route support and ride fare comparison
- **ML fare estimate** shown next to the meter fare (accounts for night, peak hours, rain, waiting time)
- **Fare verdict**: Fair / Slightly high / Overcharged, based on the demanded fare vs the higher of meter and ML estimate (limits: +10% and +30%, assumed values to be tuned)
- Complaint records (verdict stored, voice note, share via any app) and SOS / trusted contact
- Trip history saved on the device, with an optional "actual fare paid" field
- Analytics dashboard (totals, averages, last six months)
- CSV export of trip history (date, distance_km, fare_inr, route, actual_fare_inr, rain, wait_min)

## 2. Data science work

| Step | Detail |
|---|---|
| Data | 1,500-row **synthetic practice dataset** (data_science/autofarefixer_practice_data.csv) generated from the app's meter formula plus assumed night / peak / rain / waiting effects and noise |
| Features | distance_km, hour, is_night, is_peak, rain, wait_min |
| Target | actual_fare |
| Split | 80% train / 20% test (random_state=42) |
| Notebook | data_science/AutoFareFixer_EDA_Model.ipynb (EDA, plots, model comparison, feature importance) |

### Results (test set, synthetic data)

| Model | MAE (₹) | RMSE (₹) | R² |
|---|---|---|---|
| Baseline (meter fare only) | 14.84 | 21.07 | 0.904 |
| Linear Regression | 7.12 | 9.69 | 0.980 |
| Random Forest | 6.24 | 8.38 | 0.985 |

**Chosen for the app:** Linear Regression. Its coefficients are copied into lib/fare_model.dart, so no server or extra package is needed, and the result is easy to explain.

## 3. Important limitation

The model is trained on **synthetic data built on assumptions** (e.g. a 25% night surcharge), not on real auto fares. The numbers above show that the pipeline works; they do not measure accuracy on real trips. The ML estimate and the verdict limits should be treated as a demo until real data replaces them.

## 4. Real data collection and retraining

1. In the app, enter the **Actual fare paid** when saving a trip (rain and waiting time are saved too).
2. Use **Export CSV** to get the trip file.
3. Run the retrain script (it refuses to train with fewer than 50 rows with an actual fare):

        python3 flutter_app/tools/retrain_fare_model.py path/to/autofarefixer_trips.csv

4. It prints MAE / RMSE / R² (baseline vs Linear Regression) and the constants to paste into flutter_app/lib/fare_model.dart.

## 5. Release notes

- Release builds are signed with a private keystore kept **outside** the repository (key.properties and *.jks are git-ignored).
- The release manifest includes the INTERNET, location and microphone permissions.
- Trip and complaint data stays on the device; nothing is sent to authorities.

## 6. Future work

- Collect 100+ real trips and retrain; tune verdict limits
- Verify trip saving and CSV export on all platforms
- Per-city fare rules and a settings screen for the meter formula
