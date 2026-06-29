import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';
import 'api_service.dart';
import 'bottom_nav.dart';
import '../services/alert_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const Color primaryGreen = Color.fromARGB(255, 19, 97, 39);
  static const Color lightGreen = Color.fromARGB(255, 232, 248, 240);
  static const Color bgColor = Color.fromARGB(255, 246, 248, 247);
  static const Color cardColor = Colors.white;
  static const Color darkText = Color.fromARGB(255, 26, 26, 26);
  static const Color greyText = Color.fromARGB(255, 136, 136, 136);
  static const Color redRisk = Color.fromARGB(255, 231, 76, 60);
  static const Color orangeRisk = Color.fromARGB(255, 243, 156, 18);

  // ── Farmer district alert ──────────────────────────────────────────────────
  Map<String, dynamic>? _districtData;
  bool _districtLoading = true;
  String? _districtError;

  // ── National alerts ────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<dynamic> _top5Districts = [];
  String _mostCommonDisease = '';
  int _highRiskCount = 0;
  int _totalDistricts = 0;
  String _selectedFilter = 'ALL';

  final List<String> _filters = ['ALL', 'HIGH', 'MEDIUM'];

  @override
  void initState() {
    super.initState();
    _loadDistrictAlert();
    _loadAlerts();
  }

  // ── Load farmer district alert via AlertService ───────────────────────────
  Future<void> _loadDistrictAlert() async {
    setState(() {
      _districtLoading = true;
      _districtError = null;
    });
    final data = await AlertService.forceCheckAndNotify();
    if (mounted) {
      setState(() {
        _districtData = data;
        _districtError = data == null ? 'Could not load your district data' : null;
        _districtLoading = false;
      });
    }
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ApiService.getSummary();
      setState(() {
        _top5Districts = List<dynamic>.from(data['top5_risk_districts'] ?? []);
        _mostCommonDisease = data['most_common_disease'] ?? '';
        _highRiskCount = data['high_risk_count'] ?? 0;
        _totalDistricts = data['total_monitored'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load alerts. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadDistrictAlert(), _loadAlerts()]);
  }

  Color _getRiskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH':
        return redRisk;
      case 'MEDIUM':
        return orangeRisk;
      case 'LOW':
        return primaryGreen;
      default:
        return greyText;
    }
  }

  IconData _getRiskIcon(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH':
        return Icons.warning_amber_rounded;
      case 'MEDIUM':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getRiskMessage(String? level, String diseases) {
    switch (level?.toUpperCase()) {
      case 'HIGH':
        return 'Satellite data shows dangerous environmental conditions. '
            'Immediate action recommended. Watch for: $diseases';
      case 'MEDIUM':
        return 'Environmental conditions are concerning. '
            'Monitor your flock closely. Watch for: $diseases';
      default:
        return 'Conditions are within safe range. '
            'Continue standard biosecurity practices.';
    }
  }

  List<dynamic> get _filteredDistricts {
    if (_selectedFilter == 'ALL') return _top5Districts;
    return _top5Districts
        .where((d) => (d['risk_level'] ?? '').toUpperCase() == _selectedFilter)
        .toList();
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
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
              // ── YOUR DISTRICT ALERT ──────────────────────────────────────
              const Text(
                'Your District Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
              ),
              const SizedBox(height: 4),
              const Text(
                'Real-time satellite risk for your farm location',
                style: TextStyle(fontSize: 13, color: greyText),
              ),
              const SizedBox(height: 14),
              _buildDistrictAlertCard(),
              const SizedBox(height: 28),
              // ── NATIONAL ALERTS ──────────────────────────────────────────
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: primaryGreen),
                  ),
                )
              else if (_error != null)
                _buildError()
              else
                _buildNationalContent(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }


  // ── Farmer's district alert card ───────────────────────────────────────────
  Widget _buildDistrictAlertCard() {
    if (_districtLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (_districtError != null || _districtData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
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
              onPressed: _loadDistrictAlert,
              child: const Text('Retry', style: TextStyle(color: primaryGreen)),
            ),
          ],
        ),
      );
    }

    final riskLevel = (_districtData!['risk_level'] ?? '').toString().toUpperCase();
    final riskColor = _getRiskColor(riskLevel);
    final districtName = _districtData!['district'] ?? 'Your District';
    final diseases = _districtData!['diseases_flagged'] ?? 'None detected';
    final riskScore = (_districtData!['risk_score'] ?? 0) as num;
    final isWarning = riskLevel == 'HIGH' || riskLevel == 'MEDIUM';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: riskColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Coloured top banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(_getRiskIcon(riskLevel), color: riskColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(districtName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText)),
                      Text(
                        isWarning
                            ? riskLevel == 'HIGH'
                                ? '⚠️ High Risk — Immediate attention needed'
                                : '🔔 Moderate Risk — Monitor your flock'
                            : '✅ Your district is currently safe',
                        style: TextStyle(fontSize: 12, color: riskColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(riskLevel,
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Risk Score', style: TextStyle(fontSize: 12, color: greyText)),
                    Text('$riskScore / 10',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: riskColor)),
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
                      Text('Diseases to Watch',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskColor)),
                      const SizedBox(height: 4),
                      Text(diseases, style: const TextStyle(fontSize: 13, color: darkText, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _districtData!['farmer_advice'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.green[800], height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.access_time, size: 11, color: greyText),
                    SizedBox(width: 4),
                    Text('Checked just now',
                        style: TextStyle(fontSize: 10, color: greyText, fontStyle: FontStyle.italic)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primaryGreen),
          const SizedBox(height: 20),
          Text('Loading satellite alerts...',
              style: TextStyle(color: greyText, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 15, color: darkText, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _loadAlerts,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNationalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disease Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Satellite-based risk warnings across Uganda',
          style: TextStyle(fontSize: 13, color: greyText),
        ),
        const SizedBox(height: 20),
        _buildNationalBanner(),
        const SizedBox(height: 20),
        _buildFilterChips(),
        const SizedBox(height: 16),
        if (_filteredDistricts.isEmpty)
          _buildEmptyState()
        else
          ..._filteredDistricts.asMap().entries.map(
                (entry) => _buildAlertCard(entry.value, entry.key),
              ),
        const SizedBox(height: 20),
        if (_mostCommonDisease.isNotEmpty) _buildMostCommonCard(),
        const SizedBox(height: 16),
        _buildSatelliteBadge(),
      ],
    );
  }

  Widget _buildNationalBanner() {
    final isHighAlert = _highRiskCount > 50;
    final bannerColor = isHighAlert ? redRisk : orangeRisk;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHighAlert
                  ? Icons.warning_amber_rounded
                  : Icons.notifications_active,
              color: bannerColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHighAlert
                      ? 'High Alert — National Level'
                      : 'Moderate Alert — Watch Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_highRiskCount of $_totalDistricts districts are currently HIGH risk',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        Color chipColor;
        switch (filter) {
          case 'HIGH':
            chipColor = redRisk;
            break;
          case 'MEDIUM':
            chipColor = orangeRisk;
            break;
          default:
            chipColor = primaryGreen;
        }
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? chipColor.withValues(alpha: 0.15) : cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? chipColor : Colors.grey.withValues(alpha: 0.2),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? chipColor : greyText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlertCard(dynamic district, int index) {
    final riskLevel = district['risk_level'] ?? 'HIGH';
    final riskColor = _getRiskColor(riskLevel);
    final diseases = district['diseases'] ?? district['diseases_flagged'] ?? '';
    final name = district['district'] ?? '';
    final score = district['risk_score'] ?? 0;

    final timeLabels = [
      '2 hours ago',
      '5 hours ago',
      '1 day ago',
      '1 day ago',
      '2 days ago',
    ];
    final timeLabel =
        index < timeLabels.length ? timeLabels[index] : '2 days ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(left: BorderSide(color: riskColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: darkText)),
                ),
                Text(timeLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: greyText,
                        fontStyle: FontStyle.italic)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_getRiskIcon(riskLevel), color: riskColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '$riskLevel RISK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('Score: $score/10',
                    style: TextStyle(fontSize: 11, color: greyText)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _getRiskMessage(riskLevel, diseases),
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 10),
            if (diseases.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: diseases
                    .toString()
                    .split('·')
                    .map((d) => d.trim())
                    .where((d) => d.isNotEmpty)
                    .map(
                      (disease) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(disease,
                            style:
                                const TextStyle(fontSize: 11, color: darkText)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: primaryGreen, size: 48),
          const SizedBox(height: 12),
          const Text('No alerts for this filter',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 6),
          Text(
            'All districts in this category are within safe range',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: greyText),
          ),
        ],
      ),
    );
  }

  Widget _buildMostCommonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: redRisk.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: redRisk.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('🦠', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Most Prevalent Disease This Week',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: redRisk,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(_mostCommonDisease,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText)),
                const SizedBox(height: 2),
                Text(
                  'Detected across the highest number of Uganda districts',
                  style: TextStyle(fontSize: 11, color: greyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteBadge() {
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
                const Text(
                  'Powered by Satellite Intelligence',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      letterSpacing: 0.5),
                ),
                Text(
                  'Sentinel-2 · MODIS NASA · JRC Water · Updated Feb 2025',
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
