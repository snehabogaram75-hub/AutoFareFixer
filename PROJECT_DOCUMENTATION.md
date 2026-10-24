# AUTO FARE FIXER
## Project and Release Documentation

### 1. Project Overview
Auto Fare Fixer is a React Native application built using Expo. It is designed to help users estimate auto fares, capture GPS coordinates, prepare complaint reports, and access basic passenger-safety features.

### 2. Technology Stack
- React Native
- Expo SDK
- JavaScript
- Node.js and npm
- Expo Location for GPS access
- Expo Print for report generation
- Expo Sharing for sharing reports
- EAS Build for Android APK builds

### 3. Project Structure
- App.js — Main application screens and logic
- app.json — Expo application configuration
- eas.json — EAS build profiles
- index.js — Application entry point
- assets/ — Application assets
- AutoFareFixerWeb/ — Web-related project files
- App.js.backup — Backup of the application source
- app.json.backup — Backup of Expo configuration
- eas.json.backup — Backup of EAS configuration

### 4. Android Application Configuration
- Application name: Auto Fare Fixer
- Android package: com.snehabogaram.autofarefixer
- Version: 1.0.0
- Build platform: Android
- Build profile: preview
- Distribution: Internal testing
- Output type: APK

### 5. Main Features
1. Login-style user interface.
2. Auto-fare estimation.
3. GPS permission and coordinate capture.
4. Complaint report generation.
5. Civic points interface.
6. SOS-style safety interface.
7. Settings screen.
8. Report sharing support.

### 6. Fare Estimation
The current fare calculation uses an estimated base fare of ₹20 and ₹12 per kilometre after the first 1.5 kilometres.

Important: These are application estimates, not verified official or current government-approved fare rates. Confirm the applicable local tariff before presenting the result as an official fare.

### 7. GPS and Location
The application requests location permission and can capture GPS coordinates. The current implementation does not automatically calculate the actual road distance between a pickup point and destination. The distance input should therefore be treated as manually supplied unless routing functionality is added.

### 8. Complaint and Safety Features
- Complaint reports can be generated using the report functionality.
- Native report generation uses Expo Print.
- Sharing functionality is included.
- The SOS interface currently displays an alert; it does not automatically contact emergency services.
- The voice complaint interaction currently uses a predefined sample message and requires real speech-recognition integration.

### 9. Data Storage and Authentication
The current login-style screen validates non-empty email and password fields. It is not connected to a production authentication service.

Complaints and civic points are currently maintained in application state. Persistent storage or a backend database is required to retain this information after the application restarts.

### 10. Validation and Build
- Expo project configured.
- EAS authentication completed.
- Expo Doctor validation: 20/20 checks passed.
- Android preview build completed successfully.
- EAS generated an Android build artifact.

### 11. EAS Build Command
Run the following command from the project directory to create another Android preview build:

npx eas-cli build --platform android --profile preview

### 12. Build Reference
EAS build page:
https://expo.dev/accounts/snehabogaram/projects/AutoFareFixer/builds/1b883eb4-f79e-4512-a5c3-dae5107cc1ce

### 13. Recommended Next Steps
1. Install and test the APK on a physical Android device.
2. Test GPS permission and coordinate accuracy.
3. Verify complaint report generation and sharing.
4. Implement secure authentication.
5. Store complaints and civic points persistently.
6. Integrate genuine speech recognition.
7. Connect the SOS feature to an explicitly configured emergency workflow.
8. Add verified fare rules and road-distance calculation.
9. Test all screens and error cases before public release.
10. Review privacy, location permissions, and emergency-feature limitations.

### 14. Release Status
The Android preview build has completed successfully. This confirms build generation, not full production readiness. Real-device testing, feature verification, security review, and release checks remain necessary before public distribution.

---
Document: Auto Fare Fixer Project and Release Documentation
Format: Markdown
