import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, SafeAreaView, ScrollView, Platform, ActivityIndicator, Switch } from 'react-native';
import * as Print from 'expo-print';
import * as Sharing from 'expo-sharing';
import * as Location from 'expo-location';

export default function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  
  const [currentTab, setCurrentTab] = useState('home'); // 'home' | 'settings'

  const [distance, setDistance] = useState('');
  const [fare, setFare] = useState(null);
  const [plateNumber, setPlateNumber] = useState('');
  const [driverDemanded, setDriverDemanded] = useState('');
  const [notes, setNotes] = useState('');
  const [loadingLocation, setLoadingLocation] = useState(false);
  const [gpsCoordinates, setGpsCoordinates] = useState(null);
  const [isListening, setIsListening] = useState(false);
  const [sosActive, setSosActive] = useState(false);
  
  const [civicPoints, setCivicPoints] = useState(120);
  const [complaints, setComplaints] = useState([]);

  // Settings state
  const [trafficAlerts, setTrafficAlerts] = useState(true);
  const [fareHikeNotifications, setFareHikeNotifications] = useState(true);
  const [anonymousReporting, setAnonymousReporting] = useState(false);
  const [sosContact, setSosContact] = useState('9490617346');

  const handleLogin = () => {
    if (!email || !password) {
      alert('Please enter commuter ID and PIN');
      return;
    }
    setIsLoggedIn(true);
  };

  const fetchLiveGPSDistance = async () => {
    try {
      setLoadingLocation(true);
      const { status } = await Location.requestForegroundPermissionsAsync();

      if (status !== 'granted') {
        alert('Location permission denied. Enter trip distance manually.');
        return;
      }

      const location = await Location.getCurrentPositionAsync({});
      const coordinates = {
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
      };

      setGpsCoordinates(coordinates);
      alert(
        `Current location captured\\nLatitude: ${coordinates.latitude.toFixed(5)}\\nLongitude: ${coordinates.longitude.toFixed(5)}\\nEnter trip distance manually. GPS alone cannot calculate road distance.`
      );
    } catch (error) {
      alert('Could not fetch GPS location. Please try again.');
    } finally {
      setLoadingLocation(false);
    }
  };

  const calculateFare = () => {
    const dist = parseFloat(distance);
    if (isNaN(dist) || dist <= 0) {
      alert('Enter valid distance');
      return;
    }
    let totalFare = 20;
    if (dist > 1.5) {
      totalFare += (dist - 1.5) * 12;
    }
    setFare(Math.round(totalFare));
  };

  const handleVoiceRecording = () => {
    setIsListening(true);
    setTimeout(() => {
      setNotes('Driver refused meter and misbehaved near Ameerpet.');
      setIsListening(false);
    }, 2000);
  };

  const handleSOSAlert = () => {
    setSosActive(true);
    alert(
      `SOS is a demo feature only. No emergency call or location sharing has occurred.\n\nConfigured contact: ${sosContact}\n\nIf you are in immediate danger in India, call 112 directly.`
    );
    setTimeout(() => setSosActive(false), 3000);
  };

  const generateAndSaveComplaint = async () => {
    if (!plateNumber.trim()) {
      alert('Enter Auto License Plate Number');
      return;
    }

    if (distance.trim() && (!Number.isFinite(Number(distance)) || Number(distance) <= 0)) {
      alert('Enter a valid trip distance greater than zero.');
      return;
    }

    if (driverDemanded.trim() && (!Number.isFinite(Number(driverDemanded)) || Number(driverDemanded) < 0)) {
      alert('Enter a valid demanded fare (zero or greater).');
      return;
    }

    if (fare === null || !Number.isFinite(Number(fare)) || Number(fare) < 0) {
      alert('Calculate the estimated fare before creating the complaint report.');
      return;
    }

    const newComplaint = {
      id: Date.now().toString(),
      plate: plateNumber.toUpperCase(),
      distance: distance || '0',
      fare: fare || 0,
      demanded: driverDemanded || '0',
      timestamp: new Date().toLocaleString(),
    };

    setComplaints([newComplaint, ...complaints]);
    setCivicPoints(prev => prev + 50);

    const reporterIdentity = anonymousReporting ? 'ANONYMOUS COMMUTER' : email;

    const htmlContent = `
      <html>
        <head>
          <title>Hyderabad Traffic Police Complaint</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 30px; color: #333; max-width: 600px; margin: auto; }
            h2 { color: #d32f2f; border-bottom: 2px solid #d32f2f; padding-bottom: 10px; }
            .box { background: #fffde7; padding: 20px; border-radius: 8px; margin-top: 20px; border: 1px solid #fbc531; }
            .field { margin-bottom: 12px; font-size: 16px; }
            .label { font-weight: bold; }
            .badge { background: #fbc531; padding: 4px 8px; border-radius: 4px; font-weight: bold; }
          </style>
        </head>
        <body>
          <h2>Hyderabad Traffic Police Complaint Report</h2>
          <p><strong>Reporter:</strong> ${reporterIdentity}</p>
          <p><strong>Incident Timestamp:</strong> ${newComplaint.timestamp}</p>
          <div class="box">
            <div class="field"><span class="label">Auto Number:</span> <span class="badge">${newComplaint.plate}</span></div>
            <div class="field"><span class="label">Distance Traveled:</span> ${newComplaint.distance} KM</div>
            <div class="field"><span class="label">Govt Approved Fare:</span> ₹${newComplaint.fare}</div>
            <div class="field"><span class="label">Driver Demanded Fare:</span> ₹${newComplaint.demanded}</div>
          </div>
          <h3>Evidence & Statement</h3>
          <p><em>"${notes || 'Driver refused meter and demanded exorbitant fare.'}"</em></p>
          <hr />
          <p style="font-size: 12px; color: #777;">Prepared by Auto Fare Fixer | This report has not been submitted to any authority</p>
        </body>
      </html>
    `;

    try {
      if (Platform.OS === 'web') {
        const blob = new Blob([htmlContent], { type: 'text/html' });
        const url = URL.createObjectURL(blob);
        window.open(url, '_blank');
        setPlateNumber('');
        setDriverDemanded('');
        setNotes('');
        return;
      }
      const { uri } = await Print.printToFileAsync({ html: htmlContent });
      await Sharing.shareAsync(uri);
    } catch (error) {
      alert('Error generating preview');
    }
  };

  if (!isLoggedIn) {
    return (
      <SafeAreaView style={styles.authContainer}>
        <View style={styles.transitCard}>
          <View style={styles.logoBadge}>
            <Text style={{ fontSize: 36 }}>🛺</Text>
          </View>
          <Text style={styles.transitTitle}>Auto Fare Fixer</Text>
          <Text style={styles.transitSub}>Hyderabad Commuter Meter & Safety Guard</Text>
          
          <TextInput 
            style={styles.transitInput} 
            placeholder="Commuter Email or Phone" 
            placeholderTextColor="#888"
            value={email} 
            onChangeText={setEmail} 
            autoCapitalize="none" 
          />
          
          <TextInput 
            style={styles.transitInput} 
            placeholder="Secure PIN" 
            placeholderTextColor="#888"
            secureTextEntry 
            value={password} 
            onChangeText={setPassword} 
          />

          <TouchableOpacity style={styles.transitButton} onPress={handleLogin}>
            <Text style={styles.transitButtonText}>Get Started</Text>
          </TouchableOpacity>

          <Text style={styles.footerNote}>Telangana Transport Dept Govt Guidelines</Text>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        {/* Top Header Bar */}
        <View style={styles.topBar}>
          <Text style={styles.header}>🛺 AutoFixer Hyd</Text>
          <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            <TouchableOpacity onPress={() => setCurrentTab(currentTab === 'home' ? 'settings' : 'home')} style={{ marginRight: 15 }}>
              <Text style={styles.navText}>{currentTab === 'home' ? '⚙️ Settings' : '🏠 Home'}</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={() => setIsLoggedIn(false)}>
              <Text style={styles.logoutText}>Log out</Text>
            </TouchableOpacity>
          </View>
        </View>

        {currentTab === 'settings' ? (
          /* SETTINGS SCREEN */
          <View style={styles.card}>
            <Text style={styles.sectionTitle}>⚙️ Notification & Privacy Controls</Text>
            
            <View style={styles.settingRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.settingLabel}>Traffic Police Anti-Special Squad Alerts</Text>
                <Text style={styles.settingSub}>Push alerts when entering high-enforcement zones</Text>
              </View>
              <Switch value={trafficAlerts} onValueChange={setTrafficAlerts} />
            </View>

            <View style={styles.settingRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.settingLabel}>Telangana Tariff Revision Alerts</Text>
                <Text style={styles.settingSub}>Notifies when Govt updates base rates</Text>
              </View>
              <Switch value={fareHikeNotifications} onValueChange={setFareHikeNotifications} />
            </View>

            <View style={styles.settingRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.settingLabel}>Anonymous Commuter Reporting</Text>
                <Text style={styles.settingSub}>Hide identity on traffic police PDFs</Text>
              </View>
              <Switch value={anonymousReporting} onValueChange={setAnonymousReporting} />
            </View>

            <View style={{ marginTop: 15 }}>
              <Text style={styles.settingLabel}>Emergency SOS Helpline Contact</Text>
              <TextInput 
                style={[styles.input, { marginTop: 5 }]} 
                value={sosContact} 
                onChangeText={setSosContact} 
                keyboardType="phone-pad"
              />
            </View>
          </View>
        ) : (
          /* MAIN DASHBOARD SCREEN */
          <>
            <TouchableOpacity style={[styles.sosButton, sosActive && { backgroundColor: '#b71c1c' }]} onPress={handleSOSAlert}>
              <Text style={styles.sosText}>🚨 EMERGENCY SOS PANIC BUTTON</Text>
            </TouchableOpacity>

            <View style={styles.badgeBanner}>
              <Text style={styles.badgeText}>🏅 Civic Rank: Traffic Guardian</Text>
              <Text style={styles.pointsText}>{civicPoints} PTS</Text>
            </View>

            <View style={styles.card}>
              <Text style={styles.sectionTitle}>1. Fare Estimate (app formula: ₹20 base + ₹12/km after 1.5 km)</Text>
              <TouchableOpacity style={styles.secondaryButton} onPress={fetchLiveGPSDistance} disabled={loadingLocation}>
                {loadingLocation ? <ActivityIndicator color="#d35400" /> : <Text style={styles.secondaryButtonText}>📍 Fetch Live GPS Location</Text>}
              </TouchableOpacity>

              <TextInput style={styles.input} placeholder="Distance in KM (e.g. 4)" placeholderTextColor="#888" keyboardType="numeric" value={distance} onChangeText={setDistance} />
              {gpsCoordinates && (
                <Text style={styles.resultLabel}>
                  GPS: {gpsCoordinates.latitude.toFixed(5)}, {gpsCoordinates.longitude.toFixed(5)}
                </Text>
              )}

              <TouchableOpacity style={styles.primaryButton} onPress={calculateFare}>
                <Text style={styles.primaryButtonText}>Calculate Govt Fare</Text>
              </TouchableOpacity>
              {fare !== null && (
                <View style={styles.resultBox}>
                  <Text style={styles.resultLabel}>Estimated fare (verify official tariff):</Text>
                  <Text style={styles.resultText}>₹{fare}</Text>
                </View>
              )}
            </View>

            <View style={styles.card}>
              <Text style={styles.sectionTitle}>2. Log Violation</Text>
              <TextInput style={styles.input} placeholder="Auto Number (e.g., TS09UB1234)" placeholderTextColor="#888" autoCapitalize="characters" value={plateNumber} onChangeText={setPlateNumber} />
              <TextInput style={styles.input} placeholder="Driver Demanded Amount (₹)" placeholderTextColor="#888" keyboardType="numeric" value={driverDemanded} onChangeText={setDriverDemanded} />
              
              <TouchableOpacity style={styles.voiceButton} onPress={handleVoiceRecording} disabled={isListening}>
                <Text style={styles.voiceButtonText}>{isListening ? '🎙️ Listening to Voice Note...' : '🎙️ Tap for Voice Note'}</Text>
              </TouchableOpacity>

              <TextInput style={[styles.input, { height: 50, textAlignVertical: 'top' }]} placeholder="Incident notes..." placeholderTextColor="#888" multiline value={notes} onChangeText={setNotes} />
              
              <TouchableOpacity style={styles.primaryButton} onPress={generateAndSaveComplaint}>
                <Text style={styles.primaryButtonText}>Generate & View Report (+50 PTS)</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.card}>
              <Text style={styles.sectionTitle}>3. Complaint History ({complaints.length})</Text>
              {complaints.length === 0 ? (
                <Text style={{ color: '#888', fontSize: 13, fontStyle: 'italic' }}>No complaints filed yet.</Text>
              ) : (
                complaints.map((item) => (
                  <View key={item.id} style={styles.historyRow}>
                    <View>
                      <Text style={{ fontWeight: '600', color: '#333', fontSize: 13 }}>Auto: {item.plate}</Text>
                      <Text style={{ color: '#888', fontSize: 11, marginTop: 2 }}>{item.timestamp}</Text>
                    </View>
                    <View style={{ alignItems: 'flex-end' }}>
                      <Text style={{ color: '#d35400', fontWeight: 'bold', fontSize: 13 }}>₹{item.demanded}</Text>
                      <Text style={{ color: '#27ae60', fontSize: 11 }}>Govt: ₹{item.fare}</Text>
                    </View>
                  </View>
                ))
              )}
            </View>
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fdfbf7' },
  authContainer: { flex: 1, backgroundColor: '#f9f6f0', justifyContent: 'center', alignItems: 'center' },
  transitCard: { width: '90%', maxWidth: 360, backgroundColor: '#fff', borderWidth: 2, borderColor: '#fbc531', borderRadius: 12, padding: 30, alignItems: 'center', shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.1, shadowRadius: 6, elevation: 4 },
  logoBadge: { width: 70, height: 70, backgroundColor: '#fffde7', borderRadius: 35, justifyContent: 'center', alignItems: 'center', marginBottom: 15, borderWidth: 1, borderColor: '#fbc531' },
  transitTitle: { fontSize: 24, fontWeight: 'bold', color: '#2c3e50', marginBottom: 5 },
  transitSub: { fontSize: 12, color: '#7f8c8d', marginBottom: 25, textAlign: 'center' },
  transitInput: { width: '100%', height: 45, backgroundColor: '#fcfcfc', borderWidth: 1, borderColor: '#ddd', borderRadius: 8, paddingHorizontal: 15, fontSize: 14, marginBottom: 12, color: '#333' },
  transitButton: { width: '100%', height: 45, backgroundColor: '#f39c12', borderRadius: 8, justifyContent: 'center', alignItems: 'center', marginTop: 10, shadowColor: '#f39c12', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.3, shadowRadius: 4 },
  transitButtonText: { color: '#fff', fontSize: 15, fontWeight: 'bold' },
  footerNote: { fontSize: 10, color: '#95a5a6', marginTop: 20 },
  content: { padding: 15, maxWidth: 500, alignSelf: 'center', width: '100%' },
  topBar: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15, paddingHorizontal: 5 },
  header: { fontSize: 20, fontWeight: 'bold', color: '#2c3e50' },
  navText: { color: '#2c3e50', fontWeight: '600', fontSize: 13 },
  logoutText: { color: '#e74c3c', fontWeight: '600', fontSize: 13 },
  sosButton: { backgroundColor: '#c0392b', padding: 14, borderRadius: 8, alignItems: 'center', marginBottom: 15, borderWidth: 1, borderColor: '#962d22' },
  sosText: { color: '#fff', fontSize: 13, fontWeight: 'bold', letterSpacing: 0.5 },
  badgeBanner: { backgroundColor: '#fef9e7', borderWidth: 1, borderColor: '#f9e79f', padding: 12, borderRadius: 8, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 15 },
  badgeText: { fontSize: 12, fontWeight: 'bold', color: '#b7950b' },
  pointsText: { fontSize: 12, fontWeight: 'bold', color: '#7d6608' },
  card: { backgroundColor: '#fff', borderWidth: 1, borderColor: '#e0e0e0', borderRadius: 8, padding: 15, marginBottom: 15, shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2 },
  sectionTitle: { fontSize: 15, fontWeight: 'bold', color: '#2c3e50', marginBottom: 12 },
  input: { width: '100%', height: 44, backgroundColor: '#fafafa', borderWidth: 1, borderColor: '#ddd', borderRadius: 6, paddingHorizontal: 12, fontSize: 13, marginBottom: 10, color: '#333' },
  primaryButton: { width: '100%', height: 42, backgroundColor: '#2c3e50', borderRadius: 6, justifyContent: 'center', alignItems: 'center', marginTop: 5 },
  primaryButtonText: { color: '#fff', fontSize: 14, fontWeight: '600' },
  secondaryButton: { width: '100%', height: 40, backgroundColor: '#fef9e7', borderWidth: 1, borderColor: '#f9e79f', borderRadius: 6, justifyContent: 'center', alignItems: 'center', marginBottom: 10 },
  secondaryButtonText: { color: '#b7950b', fontSize: 13, fontWeight: '600' },
  voiceButton: { width: '100%', height: 38, backgroundColor: '#fdf2e9', borderWidth: 1, borderColor: '#f5b041', borderRadius: 6, justifyContent: 'center', alignItems: 'center', marginBottom: 10 },
  voiceButtonText: { color: '#d35400', fontSize: 12, fontWeight: '600' },
  resultBox: { marginTop: 12, alignItems: 'center', borderTopWidth: 1, borderTopColor: '#f1f1f1', paddingTop: 10 },
  resultLabel: { fontSize: 12, color: '#888' },
  resultText: { fontSize: 22, fontWeight: 'bold', color: '#d35400', marginTop: 2 },
  historyRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#fafafa', padding: 10, borderRadius: 6, borderWidth: 1, borderColor: '#eee', marginBottom: 8 },
  settingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#f1f1f1' },
  settingLabel: { fontSize: 13, fontWeight: '600', color: '#333' },
  settingSub: { fontSize: 11, color: '#888', marginTop: 2 }
});
