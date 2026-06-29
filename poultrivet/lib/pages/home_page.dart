import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import '../models/farmer_model.dart';
import '../services/auth_service.dart';
import '../services/scan_queue_service.dart';
import 'api_service.dart';
import 'results_page.dart';
import 'records_page.dart';
import 'statistics_page.dart';
import 'maps_page.dart';
import 'alerts_page.dart';
import 'ui/chat_screen.dart';
import 'settings_page.dart';
import 'bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primary = const Color.fromARGB(255, 19, 97, 39);
  final Color lightBg = const Color(0xFFf6f8f7);

  final ImagePicker _picker = ImagePicker();
  final ScanQueueService _scanQueue = ScanQueueService();

  Interpreter? interpreter;
  File? selectedImage;

  bool modelLoaded = false;
  bool analyzing = false;

  FarmerModel? _farmer;

  // ── District risk state ─────────────────────────────────────────────────────
  Map<String, dynamic>? _districtData;
  bool _districtLoading = false;

  // Order must match training: class 0, 1, 2, 3
  List<String> labels = [
    "Coccidiosis",
    "Newcastle Disease",
    "Salmonella",
    "Healthy"
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
    _loadFarmerProfile();
    _scanQueue.purgeExpired();
    _scanQueue.flushQueue();
  }

  // ── Load farmer profile — retries once if Firebase Auth isn't ready yet ──────
  // After a reinstall Firebase Auth can take a moment to restore the session.
  // We wait on authStateChanges and retry Firestore once if it cold-starts.
  Future<void> _loadFarmerProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    user ??= await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((u) => u != null, orElse: () => null);

    if (user == null) return;

    FarmerModel? farmer = await AuthService().getFarmerProfile(user.uid);

    // Retry once after short delay for Firestore cold-start
    if (farmer == null) {
      await Future.delayed(const Duration(seconds: 2));
      farmer = await AuthService().getFarmerProfile(user.uid);
    }

    if (mounted) {
      setState(() => _farmer = farmer);
      if (farmer != null && farmer.district.trim().isNotEmpty) {
        _fetchDistrictRisk(farmer.district.trim());
      }
    }
  }

  // ── Fetch district risk from satellite API ──────────────────────────────────
  Future<void> _fetchDistrictRisk(String district) async {
    setState(() => _districtLoading = true);
    try {
      final data = await ApiService.getDistrict(district);
      if (mounted) setState(() {
        _districtData = data;
        _districtLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _districtLoading = false);
    }
  }

  // ── First name only ─────────────────────────────────────────────────────────
  String get _firstName {
    if (_farmer == null || _farmer!.fullName.trim().isEmpty) return 'Farmer';
    return _farmer!.fullName.trim().split(' ').first;
  }

  // ── Time-aware greeting ─────────────────────────────────────────────────────
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── LOAD MODEL ──────────────────────────────────────────────────────────────
  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset("assets/model/model.tflite");

      // Debug: print all output tensor shapes so you can confirm nms=True format
      for (int i = 0; i < interpreter!.getOutputTensors().length; i++) {
        debugPrint("OUTPUT $i shape: ${interpreter!.getOutputTensor(i).shape}");
      }
      debugPrint("INPUT shape: ${interpreter!.getInputTensor(0).shape}");

      setState(() => modelLoaded = true);
    } catch (e) {
      debugPrint("MODEL LOAD ERROR: $e");
    }
  }

  // ── CAMERA ──────────────────────────────────────────────────────────────────
  Future<void> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      selectedImage = File(image.path);
      showPreview();
    }
  }

  // ── GALLERY ─────────────────────────────────────────────────────────────────
  Future<void> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage = File(image.path);
      showPreview();
    }
  }

  // ── IMAGE PREVIEW ────────────────────────────────────────────────────────────
  void showPreview() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Preview Image"),
          content: Image.file(selectedImage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: const Text("Analyze"),
              onPressed: () async {
                if (!modelLoaded || interpreter == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Model still loading")),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => analyzing = true);

                final result = await runModel(selectedImage!);

                setState(() => analyzing = false);

                // Queue scan for upload — works offline, uploads when online
                if (result["label"] != "Error") {
                  await _scanQueue.enqueueScan(
                    imageFile: selectedImage!,
                    label: result["label"],
                    confidence: result["confidence"],
                  );
                }

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResultsPage(
                      image: selectedImage!,
                      label: result["label"],
                      confidence: result["confidence"],
                    ),
                  ),
                );
              },
            )
          ],
        );
      },
    );
  }

  // ── MODEL INFERENCE — YOLOv8 exported with nms=True ─────────────────────────
  //
  // Output tensor: [1, 300, 6]
  // Each of the 300 rows contains: [x1, y1, x2, y2, confidence, class_id]
  // NMS is already applied — we just find the row with the highest confidence.
  Future<Map<String, dynamic>> runModel(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception("Image decode failed");

      img.Image resized = img.copyResize(image, width: 640, height: 640);

      // Build NHWC float32 input [1, 640, 640, 3] normalised 0–1
      var input = List.generate(
        1,
        (_) => List.generate(
          640,
          (y) => List.generate(640, (x) {
            var pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }),
        ),
      );

      // Output tensor shape: [1, 300, 6]
      // Each row = [x1, y1, x2, y2, confidence, class_id]
      var output = List.generate(
        1,
        (_) => List.generate(300, (_) => List.filled(6, 0.0)),
      );

      interpreter!.run(input, output);

      double bestScore = 0;
      int bestClass = -1;
      const double confThreshold = 0.25;

      for (int i = 0; i < 300; i++) {
        final double score   = output[0][i][4];
        final int    classId = output[0][i][5].toInt();

        if (score > confThreshold && score > bestScore) {
          bestScore = score;
          bestClass = classId;
          debugPrint("  Det $i: class=$classId score=${score.toStringAsFixed(3)}");
        }
      }

      if (bestClass < 0 || bestClass >= labels.length) {
        return {"label": "No Detection", "confidence": 0.0};
      }

      debugPrint("Best: ${labels[bestClass]} (${bestScore.toStringAsFixed(3)})");

      return {
        "label": labels[bestClass],
        "confidence": bestScore,
      };
    } catch (e) {
      debugPrint("MODEL ERROR: $e");
      return {"label": "Error", "confidence": 0.0};
    }
  }

  // ── CAMERA OPTIONS ───────────────────────────────────────────────────────────
  void openCameraOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Scan Poultry Sample",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take Picture"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: primary,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  pickFromCamera();
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("Upload Image"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  pickFromGallery();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,

      // ── Drawer ───────────────────────────────────────────────────────────────
      drawer: Drawer(
        child: ListView(
          children: [
           DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 19, 97, 39)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset("assets/images/logo.png", width: 40, height: 40,fit: BoxFit.contain,),
                  SizedBox(height: 10),
                  Text(
                    "PoultriVet",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Hello, ${_firstName}!",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text("Records"),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RecordsPage())),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Statistics"),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StatisticsPage())),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Maps"),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MapsPage())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text("Notifications"),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AlertsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
      ),

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: lightBg,
        elevation: 1,
        title: const Text(
          "PoultriVet",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Color.fromARGB(255, 19, 97, 39)),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AlertsScreen()),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: const Text(
                    "3",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          )
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────────────────
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Personalised greeting using farmer's first name
                  Text(
                    '$_greeting, $_firstName 👋',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Everything looks healthy today.",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 40),

                  // Scan button
                  GestureDetector(
                    onTap: openCameraOptions,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              size: 60, color: Colors.white),
                          SizedBox(height: 5),
                          Text(
                            "SCAN NOW",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Live district risk card ──────────────────────────
                  _buildDistrictRiskCard(),
                ],
              ),
            ),
          ),

          // Analyzing overlay
          if (analyzing)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ChatPage())),
        child: const Icon(Icons.chat),
      ),

      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }


  // ── District risk card ──────────────────────────────────────────────────────
  Widget _buildDistrictRiskCard() {
    if (_districtLoading) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(color: Color.fromARGB(255, 19, 97, 39)),
          ),
        ),
      );
    }

    // No data yet — show placeholder
    if (_districtData == null) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.satellite_alt, size: 36, color: primary),
              const SizedBox(height: 8),
              Text(
                _farmer?.district ?? 'Your District',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('Fetching satellite data...',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final riskLevel =
        (_districtData!['risk_level'] ?? '').toString().toUpperCase();
    final riskScore = (_districtData!['risk_score'] ?? 0) as num;
    final diseases  = _districtData!['diseases_flagged'] ?? 'None detected';
    final district  = _districtData!['district'] ?? _farmer?.district ?? '';

    Color riskColor;
    IconData riskIcon;
    switch (riskLevel) {
      case 'HIGH':
        riskColor = const Color.fromARGB(255, 231, 76, 60);
        riskIcon  = Icons.warning_amber_rounded;
        break;
      case 'MEDIUM':
        riskColor = const Color.fromARGB(255, 243, 156, 18);
        riskIcon  = Icons.info_outline;
        break;
      default:
        riskColor = primary;
        riskIcon  = Icons.check_circle_outline;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatisticsPage()),
      ),
      child: Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        district,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a1a2e)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(riskIcon, color: riskColor, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          riskLevel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: riskColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Score bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Risk Score',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('$riskScore/10',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: riskColor)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: riskScore / 10,
                  backgroundColor: riskColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),

              // Diseases
              Text(
                '⚠️ $diseases',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('View full stats →',
                      style: TextStyle(
                          fontSize: 11,
                          color: primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }
}
