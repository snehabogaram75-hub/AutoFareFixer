import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email/phone and PIN.')),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainScreen(user: email.text.trim())),
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
                      labelText: 'PIN or password',
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
                    'Demo login: enter any non-empty email/phone and PIN. '
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
  final plate = TextEditingController();
  final demanded = TextEditingController();
  final notes = TextEditingController();
  double? fare;
  double? latitude;
  double? longitude;
  int points = 120;
  bool anonymous = false;
  bool fareNotifications = true;
  final List<Map<String, String>> complaints = [];
  static const String _complaintsStorageKey = 'aff_saved_complaints';
  final AudioRecorder recorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isRecording = false;
  String? recordingPath;
  bool isPlayingRecording = false;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
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

  Future<void> _saveComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_complaintsStorageKey, jsonEncode(complaints));
  }

  @override
  void dispose() {
    distance.dispose();
    plate.dispose();
    demanded.dispose();
    notes.dispose();
    unawaited(recorder.dispose());
    unawaited(audioPlayer.dispose());
    super.dispose();
  }

  void calculateFare() {
    final d = double.tryParse(distance.text.trim());
    if (d == null || !d.isFinite || d <= 0) {
      message('Enter a valid distance greater than zero.');
      return;
    }
    setState(() => fare = d <= 1.5 ? 20 : 20 + (d - 1.5) * 12);
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
        const SizedBox(height: 22),
        sectionTitle('Fare estimator', Icons.calculate_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                onPressed: () => message(
                  'GPS routing is not connected yet. Enter trip distance manually.',
                ),
                icon: const Icon(Icons.my_location),
                label: const Text('Location / GPS (setup pending)'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: calculateFare,
                child: const Text('Estimate fare'),
              ),
              if (fare != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5EC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Estimated fare',
                        style: TextStyle(color: ink),
                      ),
                      Text(
                        '₹${fare!.round()}',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: brand,
                        ),
                      ),
                      const Text(
                        'Illustrative app formula, not an official tariff.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
                  ],
                ),
                const Divider(height: 24),
                Text('Distance: ${item['distance']} km'),
                Text('App estimate: ₹${item['fare']}'),
                Text('Fare demanded: ₹${item['demanded']}'),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fare notifications'),
                subtitle: const Text('Local setting only; no push service'),
                value: fareNotifications,
                onChanged: (v) => setState(() => fareNotifications = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Anonymous report label'),
                subtitle: const Text('Controls the label shown on this screen'),
                value: anonymous,
                onChanged: (v) => setState(() => anonymous = v),
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
