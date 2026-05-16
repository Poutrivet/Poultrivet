import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'api_service.dart';

class StatisticsScreen extends StatefulWidget{
const StatisticsScreen({super.key});
@override
State<StatisticsScreen> createState() => _StatisticsScreenState();
}
class _StatisticsScreenState extends State<StatisticsScreen> {
static const Color primaryGreen = Color(0xFF2ECC71);
static const Color lightGreen = Color(0xFFE8F8F0);
static const Color bgColor = Color(0xFFF0F2F0);
static const Color cardColor = Colors.white;
static const Color darkText = Color(0xFF1A1A1A);
static const Color greyText = Color(0xFF888888);
static const Color redRisk = Color(0xFFE74C3C);
static const Color orangeRisk = Color(0xFFF39C12);
bool _isLoading = true;
String? _error;
int _highRisk = 0;
int _mediumRisk = 0;
int _lowRisk = 0;
int _totalDistricts = 0;
String _mostCommonDisease = '';
int _touchedDonutIndex = -1;
List<dynamic> _top5Districts = [];
Map<String, dynamic> _diseaseFrequency = {};


@override
void initState() {
super.initState();
_loadData();
}
Future<void> _loadData() async {
try {
setState(() {
_isLoading = true;
_error = null;
});

final data = await ApiService.getSummary();

setState(() {
_highRisk = data['high_risk_count'] ?? 0;
_mediumRisk = data['medium_risk_count'] ?? 0;
_lowRisk = data['low_risk_count'] ?? 0;
_totalDistricts = data['total_monitored'] ?? 0;
_mostCommonDisease = data['most_common_disease'] ?? '';
_top5Districts = data['top5_risk_districts'] ?? [];
_diseaseFrequency =
Map<String, dynamic>.from(data['disease_frequency'] ?? {});
_isLoading = false;
});
} catch (e) {
setState(() {
_error = e.toString();
_isLoading = false;
});
}
}
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: bgColor,
appBar: AppBar(
backgroundColor: bgColor,
elevation: 0,
centerTitle: true,
leading: IconButton(
icon: const Icon(Icons.menu, color: darkText),
onPressed: () {},
),
title: const Text(
'PoulVet',
style: TextStyle(
color: primaryGreen,
fontWeight: FontWeight.bold,
fontSize: 20,
),
),


actions: [
Stack(
children: [
IconButton(
icon: const Icon(Icons.notifications_outlined, color: darkText),
onPressed: () {},
),
Positioned(
right: 8,
top: 8,
child: Container(
width: 16,
height: 16,
decoration: const BoxDecoration(
color: Colors.red,
shape: BoxShape.circle,
),
child: const Center(
child: Text(
'8',
style: TextStyle(
color: Colors.white,
fontSize: 9,
fontWeight: FontWeight.bold,
),
),
),
),
),
],
),
],
),

body: _isLoading
? _buildLoading()
: _error != null
? _buildError()
: _buildContent(),
);
}

Widget _buildLoading() {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const CircularProgressIndicator(color: primaryGreen),
const SizedBox(height: 20),
Text(
'Loading satellite data...',
style: TextStyle(color: greyText, fontSize: 14),
),
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
const Text(
'Could not load data',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 8),
Text(
'Check your internet connection',
style: TextStyle(color: greyText, fontSize: 14),
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
onPressed: _loadData,
child: const Text('Try Again'),
),
],
),
),
);
}

Widget _buildContent() {
return RefreshIndicator(
color: primaryGreen,
onRefresh: _loadData,
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Disease Risk Statistics',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 4),
Text(
'Powered by Sentinel-2 & MODIS satellite data',
style: TextStyle(fontSize: 13, color: greyText),
),
const SizedBox(height: 20),
_buildSummaryCards(),
const SizedBox(height: 24),
_buildSectionTitle(
'🌍 National Risk Distribution', '$_totalDistricts districts'),
const SizedBox(height: 12),
_buildDonutChart(),
const SizedBox(height: 24),
_buildSectionTitle('⚠️ Top 5 Highest Risk Districts', 'This week'),
const SizedBox(height: 12),
_buildTop5Chart(),
const SizedBox(height: 24),
_buildSectionTitle(
'🦠 Disease Frequency Across Uganda', 'Districts flagged'),
const SizedBox(height: 12),
_buildDiseaseChart(),
const SizedBox(height: 16),
_buildDataSourceBadge(),
],
),
),
);
}

Widget _buildSummaryCards() {
return Row(
children: [
_summaryCard(
'HIGH', _highRisk.toString(), redRisk, Icons.warning_amber_rounded),
const SizedBox(width: 10),
_summaryCard(
'MEDIUM', _mediumRisk.toString(), orangeRisk, Icons.info_outline),
const SizedBox(width: 10),
_summaryCard('LOW', _lowRisk.toString(), primaryGreen,
Icons.check_circle_outline),
],
);
}

Widget _summaryCard(String label, String value, Color color, IconData icon) {
return Expanded(
child: Container(
padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
children: [
Icon(icon, color: color, size: 24),
const SizedBox(height: 8),
Text(
value,
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: color,
),
),
const SizedBox(height: 4),
Text(
label,
style: const TextStyle(
fontSize: 10,
fontWeight: FontWeight.w600,
color: greyText,
letterSpacing: 1,
),
),
],
),
),
);
}

Widget _buildSectionTitle(String title, String subtitle) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
title,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: darkText,
),
),
Text(
subtitle,
style: const TextStyle(fontSize: 12, color: greyText),
),
],
);
}

Widget _buildDonutChart() {
final total = (_highRisk + _mediumRisk + _lowRisk).toDouble();
if (total == 0) return const SizedBox();

return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Row(
children: [
SizedBox(
height: 160,
width: 160,
child: PieChart(
PieChartData(
pieTouchData: PieTouchData(
touchCallback: (event, response) {
setState(() {
if (!event.isInterestedForInteractions ||
    response == null ||
    response.touchedSection == null) {
  _touchedDonutIndex = -1;
  return;
}
_touchedDonutIndex =
    response.touchedSection!.touchedSectionIndex;
});
},
),
sectionsSpace: 3,
centerSpaceRadius: 45,
sections: [
PieChartSectionData(
value: _highRisk.toDouble(),
color: redRisk,
title: '${(_highRisk / total * 100).toStringAsFixed(0)}%',
radius: _touchedDonutIndex == 0 ? 55 : 48,
titleStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
PieChartSectionData(
value: _mediumRisk.toDouble(),
color: orangeRisk,
title: '${(_mediumRisk / total * 100).toStringAsFixed(0)}%',
radius: _touchedDonutIndex == 1 ? 55 : 48,
titleStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
PieChartSectionData(
value: _lowRisk.toDouble(),
color: primaryGreen,
title: '${(_lowRisk / total * 100).toStringAsFixed(0)}%',
radius: _touchedDonutIndex == 2 ? 55 : 48,
titleStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
],
),
),
),
const SizedBox(width: 24),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
mainAxisAlignment: MainAxisAlignment.center,
children: [
_donutLegendItem('HIGH Risk', _highRisk, redRisk),
const SizedBox(height: 16),
_donutLegendItem('MEDIUM Risk', _mediumRisk, orangeRisk),
const SizedBox(height: 16),
_donutLegendItem('LOW Risk', _lowRisk, primaryGreen),
],
),
),
],
),
);
}

Widget _donutLegendItem(String label, int value, Color color) {
return Row(
children: [
Container(
width: 12,
height: 12,
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(3),
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
label,
style: const TextStyle(fontSize: 12, color: greyText),
),
),
Text(
value.toString(),
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: color,
),
),
],
);
}

Widget _buildTop5Chart() {
if (_top5Districts.isEmpty) return const SizedBox();

return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
children: _top5Districts.asMap().entries.map((entry) {
final index = entry.key;
final district = entry.value;
final name = district['district'] ?? '';
final score = (district['risk_score'] ?? 0).toDouble();
final level = district['risk'] ?? district['risk_level'] ?? 'HIGH';
final color = level == 'HIGH'
? redRisk
: level == 'MEDIUM'
? orangeRisk
: primaryGreen;

return Padding(
padding: EdgeInsets.only(
bottom: index < _top5Districts.length - 1 ? 16 : 0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(
  '${index + 1}. $name',
  style: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: darkText,
  ),
  overflow: TextOverflow.ellipsis,
),
),
Container(
padding: const EdgeInsets.symmetric(
    horizontal: 8, vertical: 3),
decoration: BoxDecoration(
  color: color.withOpacity(0.12),
  borderRadius: BorderRadius.circular(8),
),
child: Text(
  '${score.toInt()}/10',
  style: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: color,
  ),
),
),
],
),
const SizedBox(height: 6),
ClipRRect(
borderRadius: BorderRadius.circular(6),
child: LinearProgressIndicator(
value: score / 10.0,
backgroundColor: color.withOpacity(0.12),
valueColor: AlwaysStoppedAnimation<Color>(color),
minHeight: 10,
),
),
const SizedBox(height: 4),
Text(
district['diseases'] ?? '',
style: const TextStyle(fontSize: 11, color: greyText),
overflow: TextOverflow.ellipsis,
),
],
),
);
}).toList(),
),
);
}

Widget _buildDiseaseChart() {
if (_diseaseFrequency.isEmpty) return const SizedBox();

final sorted = _diseaseFrequency.entries.toList()
..sort((a, b) => (b.value as int).compareTo(a.value as int));

final colors = [
redRisk,
orangeRisk,
primaryGreen,
const Color(0xFF3498DB),
const Color(0xFF9B59B6),
];

return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.06),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Column(
children: sorted.asMap().entries.map((entry) {
final index = entry.key;
final item = entry.value;
final color = colors[index % colors.length];
final maxVal = sorted.first.value as int;
final val = item.value as int;

return Padding(
padding:
EdgeInsets.only(bottom: index < sorted.length - 1 ? 16 : 0),
child: Row(
children: [
SizedBox(
width: 110,
child: Text(
item.key,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w500,
color: darkText,
),
overflow: TextOverflow.ellipsis,
),
),
const SizedBox(width: 10),
Expanded(
child: ClipRRect(
borderRadius: BorderRadius.circular(6),
child: LinearProgressIndicator(
value: val / maxVal,
backgroundColor: color.withOpacity(0.1),
valueColor: AlwaysStoppedAnimation<Color>(color),
minHeight: 14,
),
),
),
const SizedBox(width: 10),
Text(
'$val',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.bold,
color: color,
),
),
],
),
);
}).toList(),
),
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
const Text(
'Data Source',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.bold,
color: primaryGreen,
letterSpacing: 1,
),
),
Text(
'Sentinel-2 · MODIS NASA · JRC Water Data · Last updated Feb 2025',
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

