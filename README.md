# AutoFareFixer

An Android-first Flutter app that checks what an auto-rickshaw ride should cost under the Telangana official tariff, tells you whether the driver's demanded fare is fair, and drafts a complaint letter with an LLM. It also records trips so a fare-prediction model can be retrained on real data.

Latest build: see the [v1.1.0 release](https://github.com/snehabogaram75-hub/AutoFareFixer/releases/tag/v1.1.0) (signed APK). A longer write-up is in [PROJECT_REPORT.md](PROJECT_REPORT.md).

## Features

- **Official-tariff fare estimate**: 30 INR for the first 1.6 km, 14 INR per extra km, night (11 pm to 5 am) at 1.5x, optional waiting charge, with a fare breakdown
- **Fare verdict**: compares the demanded fare with the official fare and answers Fair / Slightly high / Overcharged
- **ML fare estimate**: shown as a reference only (see Limitations)
- **AI complaint letter**: a short formal letter drafted by an LLM from the complaint details, plus share to any app
- **Trip history and analytics**: local trip log, totals, averages, last six months, an Unusual fare flag, and CSV export
- **GPS / route support, ride fare comparison, SOS and trusted contact**

## How it works

    Flutter app  --->  Flask proxy (Render)  --->  Groq LLM
        |                (token + rate limit)
        +-- OfficialTariff (fare, verdict)
        +-- FareModel (linear regression coefficients, on-device)

The LLM key lives only on the backend. The app only knows the backend URL and a shared token, and the backend limits requests per IP and per day.

## Repository layout

- flutter_app/ : the Flutter app (lib/main.dart, lib/fare_model.dart, tools/retrain_fare_model.py)
- backend/ : Flask proxy for the complaint letter (app.py, requirements.txt)
- data_science/ : EDA and model notebook plus the synthetic practice dataset
- render.yaml : Render blueprint for the backend

## Run it

App:

    cd flutter_app
    flutter pub get
    flutter run

Release build wired to a deployed backend:

    flutter build apk --release \
      --dart-define=LETTER_API_URL=https://your-backend.example.com \
      --dart-define=LETTER_API_TOKEN=your-token

Backend (needs a Groq API key, never commit it):

    cd backend
    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
    GROQ_API_KEY=your-key APP_TOKEN=your-token .venv/bin/python app.py

Optional backend settings: GROQ_MODEL (default openai/gpt-oss-20b), PER_IP_LIMIT (default 10 per hour), GLOBAL_LIMIT (default 300 per day).

Retrain the fare model on real trips (export the CSV from the app first; it needs at least 50 trips with an actual fare):

    python3 flutter_app/tools/retrain_fare_model.py path/to/autofarefixer_trips.csv

## Data science

The notebook in data_science/ compares a baseline, Linear Regression and Random Forest on a 1,500-row synthetic dataset (MAE, RMSE, R2). Linear Regression is used in the app because its coefficients can be embedded in Dart without a server.

## Limitations (please read)

- The ML model is trained on **synthetic data built on assumptions**, so its scores show the pipeline works, not that it predicts real fares. The verdict does not depend on it.
- Verdict limits (+10% and +30%) and the Unusual fare limit (25%) are assumed values to be tuned on real trips.
- The tariff follows the Telangana Government Order of 2 Oct 2026 as reported in the press. The waiting charge (0.75 INR per minute) comes from a committee proposal and is not verified against the final order. Tariffs can change.
- Complaint letters are drafts for the user; nothing is sent to any authority.
- The free Render backend sleeps when idle, so the first letter request can take up to a minute.
