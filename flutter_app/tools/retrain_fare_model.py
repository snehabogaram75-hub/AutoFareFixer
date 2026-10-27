import sys
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

MIN_ROWS = 50
path = sys.argv[1] if len(sys.argv) > 1 else 'autofarefixer_trips.csv'
df = pd.read_csv(path)
if 'actual_fare_inr' not in df.columns:
    print('Ee CSV lo actual_fare_inr column ledu (paata export). App lo kotha trips save chesi, Export CSV tho kotha file teesuko.')
    sys.exit(0)
df = df.dropna(subset=['actual_fare_inr']).copy()
print(f'Rows with actual fare: {len(df)}')
if len(df) < MIN_ROWS:
    print(f'Inka data kavali: kanisam {MIN_ROWS} real trips (actual fare tho) kavali, ippudu {len(df)} matrame.')
    sys.exit(0)

dt = pd.to_datetime(df['date'])
df['hour'] = dt.dt.hour
df['is_night'] = ((df.hour >= 22) | (df.hour < 5)).astype(int)
df['is_peak'] = (((df.hour >= 8) & (df.hour <= 10)) | ((df.hour >= 17) & (df.hour <= 20))).astype(int)
for c in ['rain', 'wait_min']:
    if c not in df: df[c] = 0
    df[c] = df[c].fillna(0)

feats = ['distance_km', 'hour', 'is_night', 'is_peak', 'rain', 'wait_min']
X, y = df[feats], df['actual_fare_inr']
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, random_state=42)
m = LinearRegression().fit(Xtr, ytr)
pred = m.predict(Xte)

def rep(name, p):
    print(f'{name:<22} MAE={mean_absolute_error(yte, p):6.2f}  RMSE={np.sqrt(mean_squared_error(yte, p)):6.2f}  R2={r2_score(yte, p):.3f}')
rep('Baseline (meter fare)', df.loc[yte.index, 'fare_inr'])
rep('Linear Regression', pred)

m = LinearRegression().fit(X, y)
print('\nPaste into lib/fare_model.dart:')
print(f'  static const double _intercept = {m.intercept_:.4f};')
for n, c in zip(['_perKm', '_perHour', '_night', '_peak', '_rain', '_perWaitMin'], m.coef_):
    print(f'  static const double {n} = {c:.4f};')
