import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'bottom_nav.dart';
import 'alerts_page.dart';
import '../services/auth_service.dart';
import '../models/farmer_model.dart';
import 'widgets/live_strip/live_indicator_strip.dart';
import 'widgets/live_strip/trajectory_chart.dart';
import 'widgets/live_strip/regional_pulse.dart';
import 'widgets/live_strip/top5_districts_live.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const Color primaryGreen = Color.fromARGB(255, 19, 97, 39);
  static const Color lightGreen   = Color.fromARGB(255, 232, 248, 240);
  static const Color bgColor      = Color.fromARGB(255, 246, 248, 247);
  static const Color cardColor    = Colors.white;
  static const Color darkText     = Color.fromARGB(255, 26, 26, 26);
  static const Color greyText     = Color.fromARGB(255, 136, 136, 136);
  static const Color redRisk      = Color.fromARGB(255, 231, 76, 60);
  static const Color orangeRisk   = Color.fromARGB(255, 243, 156, 18);

  // ── Farmer district ────────────────────────────────────────────────────────
  FarmerModel? _farmer;
  Map<String, dynamic>? _districtData;
  bool _districtLoading = true;
  String? _districtError;

  // ── National summary ───────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  int _highRisk = 0;
  int _mediumRisk = 0;
  int _lowRisk = 0;
  int _totalDistricts = 0;

  @override
  void initState() {
    super.initState();
    _loadFarmerDistrict();
    _loadNationalData();
  }

  // ── Load farmer district from Firestore then fetch satellite data ──────────
  Future<void> _loadFarmerDistrict() async {
    setState(() {
      _districtLoading = true;
      _districtError = null;
    });
    try {
      User? user = FirebaseAuth.instance.currentUser;
      user ??= await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null, orElse: () => null);
      if (user == null) {
        setState(() {
          _districtError = 'Not logged in';
          _districtLoading = false;
        });
        return;
      }
      FarmerModel? farmer = await AuthService().getFarmerProfile(user.uid);
      if (farmer == null) {
        await Future.delayed(const Duration(seconds: 2));
        farmer = await AuthService().getFarmerProfile(user.uid);
      }
      if (farmer == null || farmer.district.trim().isEmpty) {
        setState(() {
          _districtError = 'No district set on your profile';
          _districtLoading = false;
        });
        return;
      }
      final data = await ApiService.getDistrict(farmer.district.trim());
      setState(() {
        _farmer      = farmer;
        _districtData = data;
        _districtLoading = false;
      });
    } catch (e) {
      setState(() {
        _districtError   = 'Could not load district data';
        _districtLoading = false;
      });
    }
  }

  // ── Load national summary ──────────────────────────────────────────────────
  Future<void> _loadNationalData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ApiService.getSummary();
      setState(() {
        _highRisk       = data['high_risk_count'] ?? 0;
        _mediumRisk     = data['medium_risk_count'] ?? 0;
        _lowRisk        = data['low_risk_count'] ?? 0;
        _totalDistricts = data['total_monitored'] ?? 0;
        _isLoading      = false;
      });
    } catch (e) {
      setState(() {
        _error     = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadFarmerDistrict(), _loadNationalData()]);
  }

  Color _getRiskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH':   return redRisk;
      case 'MEDIUM': return orangeRisk;
      case 'LOW':    return primaryGreen;
      default:       return greyText;
    }
  }

  IconData _getRiskIcon(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH':   return Icons.warning_amber_rounded;
      case 'MEDIUM': return Icons.info_outline;
      default:       return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'PoulVet',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 20),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: Text('3',
                      style: TextStyle(color: Theme.of(context).cardColor, fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── YOUR DISTRICT ────────────────────────────────────────────
              _buildDistrictHeader(),
              const SizedBox(height: 14),
              _buildDistrictSection(),

              const SizedBox(height: 32),

              // ── NATIONAL STATS ────────────────────────────────────────────
              const Text(
                'Disease Risk Statistics',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
              ),
              const SizedBox(height: 4),
              Text(
                'Powered by Sentinel-2 & MODIS satellite data',
                style: TextStyle(fontSize: 13, color: greyText),
              ),
              const SizedBox(height: 24),

              // ── Live indicator strip ──────────────────────────────────────
              const LiveIndicatorStrip(),
              const SizedBox(height: 28),

              // ── Summary cards ─────────────────────────────────────────────
              if (!_isLoading && _error == null) ...[
                _buildSummaryCards(),
                const SizedBox(height: 24),
              ],

              // ── Trajectory chart ──────────────────────────────────────────
              _buildSectionTitle(
                  '📈 National Risk & Disease Trend', 'Last 30 days'),
              const SizedBox(height: 12),
              const TrajectoryChart(),
              const SizedBox(height: 24),

              // ── Regional pulse ────────────────────────────────────────────
              _buildSectionTitle(
                  '🌍 Regional Pulse',
                  '$_totalDistricts districts · 4 regions'),
              const SizedBox(height: 12),
              const RegionalPulse(),
              const SizedBox(height: 24),

              // ── Top 5 districts ───────────────────────────────────────────
              _buildSectionTitle(
                  '⚠️ Top 5 Highest Risk Districts', 'This week'),
              const SizedBox(height: 12),
              const Top5DistrictsLive(),
              const SizedBox(height: 16),

              _buildDataSourceBadge(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  // ── District header ────────────────────────────────────────────────────────
  Widget _buildDistrictHeader() {
    return Row(
      children: [
        const Icon(Icons.location_on, color: primaryGreen, size: 18),
        const SizedBox(width: 6),
        Text(
          _farmer != null
              ? '${_farmer!.district} District'
              : 'Your District',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
        ),
      ],
    );
  }

  // ── District section ───────────────────────────────────────────────────────
  Widget _buildDistrictSection() {
    if (_districtLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
        child: const Center(
            child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (_districtError != null || _districtData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: greyText, size: 36),
            const SizedBox(height: 10),
            Text(
              _districtError ?? 'Could not load district data',
              textAlign: TextAlign.center,
              style: const TextStyle(color: greyText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadFarmerDistrict,
              child: const Text('Retry',
                  style: TextStyle(color: primaryGreen)),
            ),
          ],
        ),
      );
    }

    final riskLevel =
        (_districtData!['risk_level'] ?? '').toString().toUpperCase();
    final riskColor  = _getRiskColor(riskLevel);
    final riskScore  = (_districtData!['risk_score'] ?? 0) as num;
    final diseases   = _districtData!['diseases_flagged'] ?? 'None detected';
    final env        = _districtData!['environmental_conditions'] ?? {};

    return Column(
      children: [
        // Risk card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: riskColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Risk Level',
                      style: TextStyle(fontSize: 13, color: greyText)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(_getRiskIcon(riskLevel),
                            color: riskColor, size: 15),
                        const SizedBox(width: 5),
                        Text(riskLevel,
                            style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Risk Score: ',
                      style: TextStyle(fontSize: 13, color: greyText)),
                  Text('$riskScore/10',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: riskColor)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: riskScore / 10,
                  backgroundColor: riskColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️ Diseases to Watch',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: riskColor)),
                    const SizedBox(height: 4),
                    Text(diseases,
                        style: const TextStyle(
                            fontSize: 13, color: darkText, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Environmental tiles
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.satellite_alt, color: primaryGreen, size: 16),
                  SizedBox(width: 6),
                  Text('Satellite Environmental Data',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: darkText)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _envTile('🌿', 'Vegetation',
                      '${env['vegetation_ndvi'] ?? 0}', 'NDVI'),
                  const SizedBox(width: 10),
                  _envTile('💧', 'Moisture',
                      '${env['moisture_index'] ?? 0}', 'NDMI'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _envTile('🌡️', 'Temperature',
                      '${env['temperature_celsius'] ?? 0}°C', 'LST'),
                  const SizedBox(width: 10),
                  _envTile('🌊', 'Water',
                      '${env['water_presence_percent'] ?? 0}%', 'JRC'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Farmer advice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Farmer Advice',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen)),
                    const SizedBox(height: 4),
                    Text(
                      _districtData!['farmer_advice'] ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[800],
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _envTile(String emoji, String label, String value, String source) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkText)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: greyText)),
            Text(source,
                style: const TextStyle(
                    fontSize: 9,
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  // ── Summary cards ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Row(
      children: [
        _summaryCard('HIGH', _highRisk.toString(), redRisk,
            Icons.warning_amber_rounded),
        const SizedBox(width: 10),
        _summaryCard(
            'MEDIUM', _mediumRisk.toString(), orangeRisk, Icons.info_outline),
        const SizedBox(width: 10),
        _summaryCard('LOW', _lowRisk.toString(), primaryGreen,
            Icons.check_circle_outline),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: greyText,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: darkText)),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: greyText)),
      ],
    );
  }

  Widget _buildDataSourceBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.satellite_alt, color: primaryGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data Source',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        letterSpacing: 1)),
                Text(
                  'Sentinel-2 · MODIS NASA · JRC Water · GAUL 2024',
                  style: TextStyle(fontSize: 11, color: Colors.green[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
