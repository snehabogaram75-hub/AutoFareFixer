import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'fare_model.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const AutoFareFixerApp());

const brand = Color(0xFF087F5B);
const ink = Color(0xFF17352D);
const canvas = Color(0xFFF4F8F5);

class AutoFareFixerApp extends StatelessWidget {
  const AutoFareFixerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Fare Fixer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brand,
          primary: brand,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE7E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE7E0)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void login() {
    final identifier = email.text.trim();
    final secret = password.text;
    final isGmail = RegExp(
      r'^[A-Za-z0-9._%+-]+@gmail\.com$',
      caseSensitive: false,
    ).hasMatch(identifier);
    final digits = identifier.replaceAll(RegExp(r'[\s-]'), '');
    final phone = digits.startsWith('+91')
        ? digits.substring(3)
        : digits.startsWith('91') && digits.length == 12
        ? digits.substring(2)
        : digits;
    final isPhone = RegExp(r'^[6-9]\d{9}$').hasMatch(phone);

    String? error;
    if (!isGmail && !isPhone) {
      error = 'Enter a valid Gmail address or 10-digit Indian mobile number.';
    } else if (secret.length < 6) {
      error = 'Password must contain at least 6 characters.';
    }

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MainScreen(user: isGmail ? identifier.toLowerCase() : phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Auto Fare Fixer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Know your fare. Travel with confidence.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email or phone',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (minimum 6 characters)',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: login,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Demo mode: format is checked, but account ownership is not verified. '
                    'This is not secure account authentication.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;
  final distance = TextEditingController();
  final destination = TextEditingController();
  bool findingRoute = false;
  String? routeSummary;
  double? destinationLatitude;
  double? destinationLongitude;
  List<LatLng> routePoints = [];
  final MapController mapController = MapController();
  final plate = TextEditingController();
  final demanded = TextEditingController();
  bool rainNow = false;
  final waitCtrl = TextEditingController();
  double get waitNow => double.tryParse(waitCtrl.text.trim()) ?? 0.0;
  final notes = TextEditingController();
  double? fare;
  double? latitude;
  double? longitude;
  int points = 120;
  bool anonymous = false;
  bool fareNotifications = true;
  final List<Map<String, String>> complaints = [];
  static const String _complaintsStorageKey = 'aff_saved_complaints';
  static const String _trustedContactNameKey = 'aff_emergency_contact_name';
  static const String _trustedContactPhoneKey = 'aff_emergency_contact_phone';
  String trustedContactName = '';
  String trustedContactPhone = '';
  final AudioRecorder recorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isRecording = false;
  String? recordingPath;
  bool isPlayingRecording = false;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _loadEmergencyContact();
  }

  Future<void> _loadComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_complaintsStorageKey);
    if (saved == null || saved.isEmpty) return;

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;
      final loaded = decoded
          .map((item) => Map<String, String>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        complaints
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      await prefs.remove(_complaintsStorageKey);
    }
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      trustedContactName = prefs.getString(_trustedContactNameKey) ?? "";
      trustedContactPhone = prefs.getString(_trustedContactPhoneKey) ?? "";
    });
  }

  Future<void> _saveEmergencyContact(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trustedContactNameKey, name.trim());
    await prefs.setString(_trustedContactPhoneKey, phone.trim());
    if (!mounted) return;
    setState(() {
      trustedContactName = name.trim();
      trustedContactPhone = phone.trim();
    });
    message("Trusted contact saved on this device.");
  }

  Future<void> _saveComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_complaintsStorageKey, jsonEncode(complaints));
  }

  @override
  void dispose() {
    distance.dispose();
    distance.dispose();
    destination.dispose();
    plate.dispose();
    demanded.dispose();
    waitCtrl.dispose();
    notes.dispose();
    unawaited(recorder.dispose());
    unawaited(audioPlayer.dispose());
    super.dispose();
  }

  Future<void> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        message('Please enable Location/GPS on your device and try again.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        message('Location permission denied. Allow it to use GPS.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        message(
          'Location permission is blocked. Enable it in app/browser settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
      message(
        'Current location found: ${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)}. Enter your destination to estimate the road fare.',
      );
    } catch (e) {
      if (mounted) {
        message('Could not get location. Check permission and try again.');
      }
    }
  }

  Future<void> findRouteAndFare() async {
    if (latitude == null || longitude == null) {
      message('First tap Get Current Location.');
      return;
    }
    final place = destination.text.trim();
    if (place.isEmpty) {
      message('Enter your destination first.');
      return;
    }
    setState(() {
      findingRoute = true;
      routeSummary = null;
      routePoints = [];
      fare = null;
    });
    try {
      final searchUri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': place,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'in',
      });
      final searchResponse = await http
          .get(
            searchUri,
            headers: {
              'User-Agent': 'AutoFareFixer/1.0 (route-estimate prototype)',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (searchResponse.statusCode != 200) {
        throw Exception('Destination search unavailable.');
      }
      final results = jsonDecode(searchResponse.body) as List<dynamic>;
      if (results.isEmpty) {
        throw Exception('Destination not found. Try a nearby landmark.');
      }
      final result = results.first as Map<String, dynamic>;
      final destLat = double.parse(result['lat'].toString());
      final destLon = double.parse(result['lon'].toString());
      final routeUri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/$longitude,$latitude;$destLon,$destLat',
        {'overview': 'full', 'geometries': 'geojson'},
      );
      final routeResponse = await http
          .get(routeUri)
          .timeout(const Duration(seconds: 20));
      if (routeResponse.statusCode != 200) {
        throw Exception('Road routing service unavailable.');
      }
      final routeData = jsonDecode(routeResponse.body) as Map<String, dynamic>;
      final routes = routeData['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) {
        throw Exception('No driving route found for this destination.');
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates.map((point) {
        final pair = point as List<dynamic>;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();
      final km =
          ((routes.first as Map<String, dynamic>)['distance'] as num)
              .toDouble() /
          1000;
      if (!mounted) return;
      setState(() {
        destinationLatitude = destLat;
        destinationLongitude = destLon;
        routePoints = points;
        distance.text = km.toStringAsFixed(2);
        fare = km <= 1.6 ? 30 : 30 + (km - 1.6) * 14;
        routeSummary =
            'Road distance: ${km.toStringAsFixed(2)} km\\nDestination: ${result['display_name']}';
      });
      message('Road distance found and fare estimated.');
    } on http.ClientException {
      if (mounted) {
        message('Network connection issue. Check your internet and try again.');
      }
    } on FormatException {
      if (mounted) {
        message('Unexpected response from the map service. Please try again.');
      }
    } on Exception catch (e) {
      if (mounted) {
        final details = e.toString();
        final friendly = details.contains('Destination not found')
            ? 'Destination not found. Try a nearby landmark.'
            : details.contains('routing service unavailable')
            ? 'Road routing is temporarily unavailable. Try again shortly.'
            : details.contains('Destination search unavailable')
            ? 'Destination search is temporarily unavailable. Try again shortly.'
            : 'Could not find the route. Check your internet and destination.';
        message(friendly);
      }
    } catch (_) {
      if (mounted) {
        message(
          'Something went wrong while finding the route. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => findingRoute = false);
    }
  }

  void calculateFare() {
    final d = double.tryParse(distance.text.trim());
    if (d == null || !d.isFinite || d <= 0) {
      message('Enter a valid distance greater than zero.');
      return;
    }
    setState(() => fare = d <= 1.6 ? 30 : 30 + (d - 1.6) * 14);
  }

  Future<void> _editTrustedContact() async {
    final nameController = TextEditingController(text: trustedContactName);
    final phoneController = TextEditingController(text: trustedContactPhone);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Trusted emergency contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Contact name",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone number",
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text("Save contact"),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveEmergencyContact(nameController.text, phoneController.text);
    }
    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> _callEmergency112() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Call emergency services?"),
        content: const Text(
          "This opens your phone dialer for India's emergency number 112. "
          "Confirm only if you need emergency assistance.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Continue to call"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (kIsWeb) {
      message(
        "If your device does not open a dialer, open the phone app "
        "and dial 112 directly. This website cannot confirm an emergency call.",
      );
    }
    try {
      final uri = Uri(scheme: "tel", path: "112");
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        message(
          "This browser could not open the phone dialer. "
          "Please open your phone app and dial 112.",
        );
      }
    } catch (_) {
      if (mounted) {
        message(
          "Unable to open the dialer here. Please open your phone app "
          "and dial 112 directly.",
        );
      }
    }
  }

  Future<void> _shareEmergencyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        message("Please enable GPS to share your current location.");
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        message("Location permission is needed to share your location.");
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      final mapLink =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";
      final contactLine = trustedContactPhone.isNotEmpty
          ? "\nTrusted contact: $trustedContactName ($trustedContactPhone)"
          : "";
      await SharePlus.instance.share(
        ShareParams(text: "My current location: $mapLink$contactLine"),
      );
    } catch (_) {
      if (mounted) {
        message("Could not get or share location. Please try again.");
      }
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> startVoiceRecording() async {
    try {
      if (!await recorder.hasPermission()) {
        message('Microphone permission is required to record audio.');
        return;
      }

      String path;
      if (kIsWeb) {
        path = 'aff_recording_${DateTime.now().millisecondsSinceEpoch}.webm';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        path =
            '${dir.path}/aff_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        isRecording = true;
        recordingPath = null;
      });
      message('Recording started. Speak clearly, then tap Stop.');
    } catch (e) {
      message(
        'Could not start recording. Check microphone permission and try again.',
      );
    }
  }

  Future<void> stopVoiceRecording() async {
    try {
      final path = await recorder.stop();
      if (!mounted) return;
      setState(() {
        isRecording = false;
        recordingPath = path;
      });
      message(
        path == null
            ? 'Recording stopped, but no playable audio was returned.'
            : 'Voice recording ready to play and attach to your complaint.',
      );
    } catch (e) {
      if (mounted) message('Could not stop the recording. Please try again.');
    }
  }

  Future<void> playVoiceRecording() async {
    final path = recordingPath;
    if (path == null || path.isEmpty) {
      message('Record your voice first.');
      return;
    }
    try {
      setState(() => isPlayingRecording = true);
      await audioPlayer.play(kIsWeb ? UrlSource(path) : DeviceFileSource(path));
      audioPlayer.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => isPlayingRecording = false);
      });
    } catch (e) {
      if (mounted) {
        setState(() => isPlayingRecording = false);
        message('Could not play this recording on this device/browser.');
      }
    }
  }

  String _verdictLabel(double asked, double meter, double km) {
    final ml = FareModel.predict(distanceKm: km, rain: rainNow, waitMin: waitNow);
    final ref = meter > ml ? meter : ml;
    if (asked <= ref * 1.10) return 'Fair fare';
    if (asked <= ref * 1.30) return 'Slightly high';
    return 'Overcharged';
  }

  void addComplaint() {
    final d = double.tryParse(distance.text.trim());
    final requested = double.tryParse(demanded.text.trim());

    if (plate.text.trim().isEmpty) {
      message('Enter the auto registration number.');
      return;
    }
    if (fare == null) {
      message('Calculate the estimated fare first.');
      return;
    }
    if (d == null || d <= 0 || !d.isFinite) {
      message('Enter a valid trip distance.');
      return;
    }
    if (requested == null || requested < 0 || !requested.isFinite) {
      message('Enter a valid demanded fare.');
      return;
    }

    setState(() {
      complaints.insert(0, {
        'plate': plate.text.trim().toUpperCase(),
        'distance': d.toStringAsFixed(1),
        'fare': fare!.round().toString(),
        'demanded': requested.toStringAsFixed(0),
        'verdict': _verdictLabel(requested, fare!, d),
        'audioPath': recordingPath ?? '',
        'notes': notes.text.trim().isEmpty
            ? 'No statement provided.'
            : notes.text.trim(),
        'time': DateTime.now().toLocal().toString().substring(0, 16),
      });
      points += 50;
    });
    _saveComplaints();

    recordingPath = null;
    plate.clear();
    demanded.clear();
    notes.clear();
    message(
      'Complaint saved on this device. It has not been sent to authorities.',
    );
    setState(() => tab = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [homePage(), complaintsPage(), settingsPage()];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_taxi_rounded, color: brand),
            const SizedBox(width: 9),
            Text(
              'Auto Fare Fixer',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Safety information',
            onPressed: showSafety,
            icon: const Icon(Icons.shield_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget emergencyHelpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Emergency Help",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
              const Text(
                "112",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "In immediate danger? Call India's emergency number 112.",
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _callEmergency112,
              icon: const Icon(Icons.sos),
              label: const Text("SOS · Call 112"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _shareEmergencyLocation,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text("Share my current location"),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _editTrustedContact,
            icon: const Icon(Icons.contact_phone_outlined),
            label: Text(
              trustedContactName.isEmpty
                  ? "Add trusted contact"
                  : "Trusted contact: $trustedContactName",
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          if (trustedContactPhone.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              trustedContactPhone,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            "Location is shared only when you choose to share it. "
            "This app does not automatically contact emergency services.",
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: brand,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR JOURNEY, YOUR RIGHTS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Travel smarter.\nKnow your fare.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '$points civic points',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${complaints.length} reports',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        emergencyHelpCard(),
        const SizedBox(height: 22),
        sectionTitle('Fare estimator', Icons.calculate_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How Is Your Fare Calculated?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text('First 1.6 km: ₹30  •  Every additional km: ₹14'),
              const SizedBox(height: 12),
              const Text('Destination'),
              const SizedBox(height: 8),
              TextField(
                controller: destination,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Enter place, address or landmark',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                onSubmitted: (_) => findRouteAndFare(),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: findingRoute ? null : findRouteAndFare,
                icon: findingRoute
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.route),
                label: Text(
                  findingRoute ? 'Finding road route...' : 'Find Route & Fare',
                ),
              ),
              if (routePoints.isNotEmpty &&
                  latitude != null &&
                  longitude != null &&
                  destinationLatitude != null &&
                  destinationLongitude != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Your Road Route',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCameraFit: CameraFit.coordinates(
                          coordinates: routePoints,
                          padding: const EdgeInsets.all(36),
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.autofarefixer.app',
                        ),
                        if (routePoints.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 5,
                                color: brand,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(latitude!, longitude!),
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 34,
                              ),
                            ),
                            Marker(
                              point: LatLng(
                                destinationLatitude!,
                                destinationLongitude!,
                              ),
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 38,
                              ),
                            ),
                          ],
                        ),
                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              '© OpenStreetMap contributors',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Blue marker: your location • Red marker: destination',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (routeSummary != null) ...[
                const SizedBox(height: 8),
                Text(routeSummary!, style: const TextStyle(fontSize: 12)),
              ],
              const SizedBox(height: 12),
              const Text('Trip distance (kilometres)'),
              const SizedBox(height: 8),
              TextField(
                controller: distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. 4.5',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
                onChanged: (_) => setState(() => fare = null),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(
                  latitude == null
                      ? 'Get Current Location'
                      : 'Location Found (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})',
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Raining now?'),
                  value: rainNow,
                  onChanged: (v) => setState(() => rainNow = v),
                ),
              ),
              TextField(
                controller: waitCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Waiting time (minutes, optional)',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: calculateFare,
                child: const Text('Estimate fare'),
              ),
              if (fare != null) ...[
                const SizedBox(height: 18),
                Card(
                  color: const Color(0xFFE6F5EC),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Builder(
                      builder: (context) {
                        final km = double.tryParse(distance.text.trim()) ?? 0.0;
                        final extraKm = (km - 1.6).clamp(0.0, double.infinity);
                        final extraCharge = extraKm * 14.0;
                        final total = km <= 1.6 ? 30.0 : 30.0 + extraCharge;
                        Widget row(
                          String label,
                          String value, {
                          bool bold = false,
                        }) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: bold
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                value,
                                style: TextStyle(
                                  fontWeight: bold
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'FARE BREAKDOWN',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            row('Road distance', '${km.toStringAsFixed(2)} km'),
                            row('Base fare (first 1.6 km)', '₹30.00'),
                            row(
                              'Extra distance',
                              '${extraKm.toStringAsFixed(2)} km',
                            ),
                            row(
                              'Extra charge (₹14/km)',
                              '₹${extraCharge.toStringAsFixed(2)}',
                            ),
                            const Divider(),
                            row(
                              'Estimated total',
                              '₹${total.toStringAsFixed(2)}',
                              bold: true,
                            ),
                            const Divider(),
                            row(
                              'ML estimate (practice model)',
                              '₹${FareModel.predict(distanceKm: km, rain: rainNow, waitMin: waitNow).toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Estimate only; actual fare may vary.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        sectionTitle('Ride fare comparison', Icons.compare_arrows),
        const SizedBox(height: 12),
        RideFareComparisonCard(),
        const SizedBox(height: 22),
        const SizedBox(height: 22),
        sectionTitle('Fare & Trip History', Icons.history),
        const SizedBox(height: 12),
        TripHistoryCard(
          distanceKm: double.tryParse(distance.text.trim()),
          estimatedFare: fare,
          routeSummary: routeSummary,
          rain: rainNow,
          waitMin: waitNow,
        ),
        const SizedBox(height: 22),
        sectionTitle('Trip Analytics', Icons.analytics_outlined),
        const SizedBox(height: 12),
        const TripAnalyticsCard(),
        const SizedBox(height: 22),
        sectionTitle('Report an issue', Icons.campaign_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: plate,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Auto registration number',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: demanded,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fare demanded (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                onChanged: (_) => setState(() {}),
              ),
              Builder(
                builder: (context) {
                  final asked = double.tryParse(demanded.text.trim());
                  final km = double.tryParse(distance.text.trim());
                  if (asked == null || fare == null || km == null || km <= 0) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Estimate the fare first, then enter the demanded fare to see a verdict.',
                        style: TextStyle(fontSize: 11),
                      ),
                    );
                  }
                  final meter = fare!;
                  final ml = FareModel.predict(distanceKm: km, rain: rainNow, waitMin: waitNow);
                  final ref = meter > ml ? meter : ml;
                  final String label;
                  final Color color;
                  final IconData icon;
                  if (asked <= ref * 1.10) {
                    label = 'Fair fare';
                    color = Colors.green.shade700;
                    icon = Icons.check_circle_outline;
                  } else if (asked <= ref * 1.30) {
                    label = 'Slightly high';
                    color = Colors.orange.shade800;
                    icon = Icons.warning_amber_rounded;
                  } else {
                    label = 'Overcharged';
                    color = Colors.red.shade700;
                    icon = Icons.error_outline;
                  }
                  final diff = asked - meter;
                  final diffText = diff >= 0
                      ? '+₹${diff.toStringAsFixed(0)} over meter'
                      : '₹${(-diff).toStringAsFixed(0)} under meter';
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              Text(
                                'Meter ₹${meter.toStringAsFixed(0)} · ML ₹${ml.toStringAsFixed(0)} · Demanded ₹${asked.toStringAsFixed(0)} ($diffText)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Incident details (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: isRecording ? null : startVoiceRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('Record voice'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isRecording ? stopVoiceRecording : null,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop'),
                  ),
                  OutlinedButton.icon(
                    onPressed: recordingPath == null || isRecording
                        ? null
                        : playVoiceRecording,
                    icon: Icon(
                      isPlayingRecording ? Icons.volume_up : Icons.play_arrow,
                    ),
                    label: const Text('Play recording'),
                  ),
                ],
              ),
              if (isRecording)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Recording in progress… Tap Stop when finished.',
                    style: TextStyle(color: brand, fontWeight: FontWeight.w600),
                  ),
                ),
              if (recordingPath != null && !isRecording)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Voice recording is ready to attach to this complaint.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: addComplaint,
                icon: const Icon(Icons.description_outlined),
                label: const Text('Prepare complaint record'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complaint details are saved on this device. Recording availability may vary by browser. No authority is contacted.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF3D2CF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emergency_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Emergency help',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B2222),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'SOS is not connected to emergency services in this version.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: showSafety,
                  child: const Text('View safety information'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget complaintsPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        sectionTitle('Complaint history', Icons.history),
        const SizedBox(height: 8),
        Text('${complaints.length} saved complaint records'),
        const SizedBox(height: 16),
        if (complaints.isEmpty)
          emptyState(
            Icons.description_outlined,
            'No complaints yet',
            'Prepare a complaint record from the Home tab.',
          ),
        ...complaints.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['plate']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Share complaint',
                      icon: const Icon(Icons.share_outlined, color: brand),
                      onPressed: () {
                        final text =
                            'AutoFareFixer complaint\n'
                            'Auto: ${item['plate']}\n'
                            'Distance: ${item['distance']} km\n'
                            'App estimate: ₹${item['fare']}\n'
                            'Fare demanded: ₹${item['demanded']}\n'
                            'Verdict: ${item['verdict'] ?? 'Not available'}\n'
                            'Details: ${item['notes']}\n'
                            'Time: ${item['time']}\n'
                            '(Prepared with AutoFareFixer; not an official complaint.)';
                        unawaited(
                          SharePlus.instance.share(
                            ShareParams(
                              text: text,
                              subject: 'AutoFareFixer complaint',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Distance: ${item['distance']} km'),
                Text('App estimate: ₹${item['fare']}'),
                Text('Fare demanded: ₹${item['demanded']}'),
                Text('Verdict: ${item['verdict'] ?? 'Not available'}'),
                const SizedBox(height: 8),
                Text(item['notes']!),
                const SizedBox(height: 8),
                Text(
                  item['time']!,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Prepared locally; not submitted to authorities.',
                  style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        sectionTitle('Settings', Icons.tune),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFE1F2E8),
                child: Icon(Icons.person, size: 34, color: brand),
              ),
              const SizedBox(height: 12),
              const Text(
                'Signed-in session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(widget.user, style: const TextStyle(color: Colors.black54)),
              const Divider(height: 28),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fare notifications'),
                  subtitle: const Text('Local setting only; no push service'),
                  value: fareNotifications,
                  onChanged: (v) => setState(() => fareNotifications = v),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anonymous report label'),
                  subtitle: const Text('Controls the label shown on this screen'),
                  value: anonymous,
                  onChanged: (v) => setState(() => anonymous = v),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app currently uses demo login and session-only complaint storage.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showSafety() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.shield_outlined, color: brand, size: 38),
        title: const Text('Travel safety'),
        content: const Text(
          'This app does not place emergency calls or share your location. '
          'If you are in immediate danger in India, call 112 directly. '
          'Only share your location with people you trust.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: brand),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
      ],
    );
  }

  BoxDecoration cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE4ECE6)),
  );

  Widget emptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 42, color: brand),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class RideFareComparisonCard extends StatefulWidget {
  const RideFareComparisonCard({super.key});

  @override
  State<RideFareComparisonCard> createState() => _RideFareComparisonCardState();
}

class _RideFareComparisonCardState extends State<RideFareComparisonCard> {
  final List<TextEditingController> _controllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<String> _providers = ['Auto quote', 'Ride app 1', 'Ride app 2'];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotes = <MapEntry<String, double>>[];
    for (var i = 0; i < _controllers.length; i++) {
      final value = double.tryParse(_controllers[i].text.trim());
      if (value != null && value.isFinite && value >= 0) {
        quotes.add(MapEntry(_providers[i], value));
      }
    }
    quotes.sort((a, b) => a.value.compareTo(b.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Compare the fares you receive',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter quoted prices manually. These are not live provider prices.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _controllers.length; i++) ...[
            TextField(
              controller: _controllers[i],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _providers[i],
                prefixText: '₹ ',
                hintText: 'Enter quoted fare',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
          ],
          if (quotes.isNotEmpty) ...[
            const Divider(),
            for (var i = 0; i < quotes.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i + 1}. ${quotes[i].key}',
                        style: TextStyle(
                          fontWeight: i == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '₹${quotes[i].value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: i == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Lowest entered quote: ${quotes.first.key} '
              '(₹${quotes.first.value.toStringAsFixed(2)})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

class TripHistoryCard extends StatefulWidget {
  final double? distanceKm;
  final double? estimatedFare;
  final String? routeSummary;
  final bool rain;
  final double waitMin;

  const TripHistoryCard({
    super.key,
    required this.distanceKm,
    required this.estimatedFare,
    required this.routeSummary,
    this.rain = false,
    this.waitMin = 0,
  });

  @override
  State<TripHistoryCard> createState() => _TripHistoryCardState();
}

class _TripHistoryCardState extends State<TripHistoryCard> {
  static const _storageKey = 'aff_trip_history_v1';
  List<Map<String, dynamic>> _trips = [];
  bool _loading = true;
  bool _saving = false;
  final TextEditingController _actualCtrl = TextEditingController();

  @override
  void dispose() {
    _actualCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final loaded = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        for (final item in jsonDecode(raw) as List<dynamic>) {
          loaded.add(Map<String, dynamic>.from(item as Map));
        }
      } catch (_) {
        // Ignore malformed saved history instead of crashing the screen.
      }
    }
    if (!mounted) return;
    setState(() {
      _trips = loaded;
      _loading = false;
    });
  }

  Future<void> _saveTrip() async {
    final km = widget.distanceKm;
    final amount = widget.estimatedFare;
    if (km == null ||
        !km.isFinite ||
        km <= 0 ||
        amount == null ||
        !amount.isFinite ||
        amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimate a valid fare before saving a trip.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final trip = <String, dynamic>{
        'date': DateTime.now().toIso8601String(),
        'distance': km,
        'fare': amount,
        'route': widget.routeSummary ?? 'Manual distance estimate',
        'actual_fare': double.tryParse(_actualCtrl.text.trim()),
        'rain': widget.rain,
        'wait_min': widget.waitMin,
      };
      final updated = [trip, ..._trips];
      final saved = await prefs.setString(_storageKey, jsonEncode(updated));
      if (!mounted) return;
      if (saved) {
        setState(() => _trips = updated);
        _actualCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip saved on this device.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save trip history.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save trip history.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _csvCell(Object? value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<void> _exportCsv() async {
    if (_trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trips to export yet.')),
      );
      return;
    }
    try {
      final rows = <String>['date,distance_km,fare_inr,route,actual_fare_inr,rain,wait_min'];
      for (final t in _trips.reversed) {
        rows.add([
          _csvCell(t['date']),
          t['distance'],
          t['fare'],
          _csvCell(t['route']),
          t['actual_fare'] ?? '',
          t['rain'] == true ? 1 : 0,
          t['wait_min'] ?? 0,
        ].join(','));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/autofarefixer_trips.csv');
      await file.writeAsString(rows.join('\n'));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'AutoFareFixer trip history',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to export trip history.')),
        );
      }
    }
  }

  Future<void> _clearTrips() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear trip history?'),
        content: const Text('Saved trips on this device will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    if (mounted) setState(() => _trips = []);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Save trips and review previous estimates.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _actualCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Actual fare paid (optional, for AI training)',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _saveTrip,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save current trip'),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_trips.isEmpty)
            const Text('No saved trips yet.')
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_trips.length} saved trip(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Export CSV'),
                ),
                TextButton(
                  onPressed: _clearTrips,
                  child: const Text('Clear history'),
                ),
              ],
            ),
            for (final trip in _trips)
              Builder(
                builder: (context) {
                  final km = (trip['distance'] as num).toDouble();
                  final paid = trip['actual_fare'] as num?;
                  final when = DateTime.tryParse('${trip['date'] ?? ''}');
                  final expected = FareModel.predict(
                    distanceKm: km,
                    when: when,
                    rain: trip['rain'] == true,
                    waitMin: ((trip['wait_min'] ?? 0) as num).toDouble(),
                  );
                  final unusual =
                      paid != null && (paid - expected).abs() > expected * 0.25;
                  final paidLine = paid == null
                      ? ''
                      : '\nPaid ₹${paid.toStringAsFixed(0)} · expected ₹${expected.toStringAsFixed(0)}';
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.route_outlined),
                      title: Text(
                        '₹${(trip['fare'] as num).toStringAsFixed(2)} · '
                        '${km.toStringAsFixed(2)} km',
                      ),
                      subtitle: Text(
                        '${trip['date'] ?? ''}\n${trip['route'] ?? ''}$paidLine',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: unusual
                          ? Chip(
                              label: const Text(
                                'Unusual fare',
                                style: TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.orange.shade100,
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
          const SizedBox(height: 4),
          const Text(
            'History is stored locally on this device.',
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class TripAnalyticsCard extends StatefulWidget {
  const TripAnalyticsCard({super.key});

  @override
  State<TripAnalyticsCard> createState() => _TripAnalyticsCardState();
}

class _TripAnalyticsCardState extends State<TripAnalyticsCard> {
  static const _storageKey = 'aff_trip_history_v1';
  bool _loading = true;
  int _tripCount = 0;
  double _totalDistance = 0;
  double _totalFare = 0;
  List<Map<String, dynamic>> _monthlyStats = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    var count = 0;
    var distance = 0.0;
    var fare = 0.0;
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - 5 + i, 1);
      return <String, dynamic>{
        'date': date,
        'label': _monthLabel(date.month),
        'trips': 0,
        'distance': 0.0,
        'fare': 0.0,
      };
    });

    if (raw != null) {
      try {
        final items = jsonDecode(raw) as List<dynamic>;
        for (final item in items) {
          if (item is! Map) continue;
          final km = num.tryParse('${item['distance']}')?.toDouble();
          final amount = num.tryParse('${item['fare']}')?.toDouble();
          if (km == null || amount == null ||
              !km.isFinite || !amount.isFinite ||
              km < 0 || amount < 0) {
            continue;
          }
          count++;
          distance += km;
          fare += amount;

          final dateValue = DateTime.tryParse('${item['date'] ?? ''}');
          if (dateValue != null) {
            for (final month in months) {
              final monthDate = month['date'] as DateTime;
              if (dateValue.year == monthDate.year &&
                  dateValue.month == monthDate.month) {
                month['trips'] = (month['trips'] as int) + 1;
                month['distance'] =
                    (month['distance'] as double) + km;
                month['fare'] = (month['fare'] as double) + amount;
                break;
              }
            }
          }
        }
      } catch (_) {
        // Keep the dashboard usable if saved history is malformed.
      }
    }

    if (!mounted) return;
    setState(() {
      _tripCount = count;
      _totalDistance = distance;
      _totalFare = fare;
      _monthlyStats = months;
      _loading = false;
    });
  }

  String _monthLabel(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  Widget _monthlyChart() {
    final maxFare = _monthlyStats.fold<double>(
      0,
      (maximum, month) =>
          (month['fare'] as double) > maximum
              ? month['fare'] as double
              : maximum,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Monthly fare trend (last 6 months)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        for (final month in _monthlyStats) ...[
          Row(
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  month['label'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final amount = month['fare'] as double;
                    final fraction =
                        maxFare <= 0 ? 0.0 : (amount / maxFare);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 18,
                        width: constraints.maxWidth * fraction,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  '₹${(month['fare'] as double).toStringAsFixed(0)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        const Text(
          'Bars compare saved trip fares by calendar month.',
          style: TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 12),
        for (final month in _monthlyStats)
          if ((month['trips'] as int) > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${month['label']}: ${month['trips']} trips · '
                '${(month['distance'] as double).toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 12),
              ),
            ),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final averageFare = _tripCount == 0 ? 0.0 : _totalFare / _tripCount;
    final averagePerKm =
        _totalDistance == 0 ? 0.0 : _totalFare / _totalDistance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Insights based on trips saved on this device.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metric('Total trips', '$_tripCount', Icons.route_outlined),
                    const SizedBox(width: 10),
                    _metric(
                      'Distance',
                      '${_totalDistance.toStringAsFixed(1)} km',
                      Icons.route,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metric(
                      'Total fare',
                      '₹${_totalFare.toStringAsFixed(0)}',
                      Icons.currency_rupee,
                    ),
                    const SizedBox(width: 10),
                    _metric(
                      'Avg. fare/trip',
                      '₹${averageFare.toStringAsFixed(0)}',
                      Icons.analytics_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Average fare per km: ₹${averagePerKm.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                _monthlyChart(),
                if (_tripCount == 0) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Save a trip above to start building your analytics.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _loadAnalytics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh analytics'),
                  ),
                ),
              ],
            ),
    );
  }
}

