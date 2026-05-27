import 'package:flutter/material.dart';
import 'api_service.dart';

class MapsScreen extends StatefulWidget {
const MapsScreen({super.key});

@override
State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
static const Color primaryGreen = Color(0xFF2ECC71);
static const Color lightGreen = Color(0xFFE8F8F0);
static const Color bgColor = Color(0xFFF0F2F0);
static const Color cardColor = Colors.white;
static const Color darkText = Color(0xFF1A1A1A);
static const Color greyText = Color(0xFF888888);
static const Color redRisk = Color(0xFFE74C3C);
static const Color orangeRisk = Color(0xFFF39C12);

final TextEditingController _searchController = TextEditingController();
bool _isLoading = false;
bool _hasSearched = false;
String? _error;
Map<String, dynamic>? _districtData;

final List<String> _quickDistricts = [
'Kampala',
'Wakiso',
'Mukono',
'Jinja',
'Gulu',
'Mbarara',
'Masaka',
'Mbale',
'Ntenjeru',
'Bugabula',
'Mityana',
'Oyam',
];

@override
void dispose() {
_searchController.dispose();
super.dispose();
}
Future<void> _searchDistrict(String name) async {
if (name.trim().isEmpty) return;
FocusScope.of(context).unfocus();
setState(() {
_isLoading = true;
_hasSearched = true;
_error = null;
_districtData = null;
});
try {
final data = await ApiService.getDistrict(name.trim());
setState(() {
_districtData = data;
_isLoading = false;
});
} catch (e) {
setState(() {
_error = e.toString().contains('not found')
? 'District "$name" not found.\nCheck spelling and try again.'
: 'Connection error. Check your internet.';
_isLoading = false;
});
}
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
case 'LOW':
return Icons.check_circle_outline;
default:
return Icons.help_outline;
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
'3',
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

body: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'District Risk Lookup',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 4),
Text(
'Search any Uganda district for satellite risk data',
style: TextStyle(fontSize: 13, color: greyText),
),
const SizedBox(height: 20),

// Search bar
Container(
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
child: TextField(
controller: _searchController,
onSubmitted: _searchDistrict,
textCapitalization: TextCapitalization.words,
style: const TextStyle(
fontSize: 15,
color: darkText,
fontWeight: FontWeight.w500,
),
decoration: InputDecoration(
hintText: 'Type district name e.g. Kampala',
hintStyle: TextStyle(
color: greyText,
fontSize: 14,
fontWeight: FontWeight.normal,
),
prefixIcon: const Icon(Icons.search, color: primaryGreen),
suffixIcon: _searchController.text.isNotEmpty
? IconButton(
icon: Icon(Icons.close, color: greyText),
onPressed: () {
_searchController.clear();
setState(() {
_hasSearched = false;
_districtData = null;
_error = null;
});
},
)

: null,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide.none,
),
filled: true,
fillColor: cardColor,
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 16,
),
),
),
),
const SizedBox(height: 12),

// Search button
SizedBox(
width: double.infinity,
child: ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: primaryGreen,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
elevation: 0,
),
onPressed: _isLoading
? null
: () => _searchDistrict(_searchController.text),
child: _isLoading
? const SizedBox(
height: 20,
width: 20,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 2,
),
)
: const Text(
'CHECK RISK LEVEL',
style: TextStyle(
fontWeight: FontWeight.bold,
letterSpacing: 1,
fontSize: 14,
),
),
),
),
const SizedBox(height: 24),

// Result
if (_hasSearched && !_isLoading) ...[
if (_error != null)
_buildErrorCard()
else if (_districtData != null)
_buildResultCard(),
const SizedBox(height: 24),
],

// Quick search
if (!_hasSearched || _districtData == null) ...[
const Text(
'Quick Search',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: darkText,
),
),
const SizedBox(height: 4),
Text(
'Tap a district to check its risk level',
style: TextStyle(fontSize: 13, color: greyText),
),
const SizedBox(height: 12),
_buildQuickSearch(),
const SizedBox(height: 24),
],
_buildInfoCard(),
],
),
),
);
}

Widget _buildResultCard() {
final district = _districtData!;
final riskLevel = district['risk_level'] ?? 'UNKNOWN';
final riskColor = _getRiskColor(riskLevel);
final env = district['environmental_conditions'] ?? {};

return Column(
children: [
Container(
width: double.infinity,
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
border: Border.all(
color: riskColor.withOpacity(0.3),
width: 1.5,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Text(
district['district'] ?? '',
style: const TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: darkText,
),
),
),

Container(
padding:
const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
decoration: BoxDecoration(
color: riskColor.withOpacity(0.12),
borderRadius: BorderRadius.circular(20),
),
child: Row(
children: [
Icon(_getRiskIcon(riskLevel),
    color: riskColor, size: 16),
const SizedBox(width: 6),
Text(
  riskLevel,
  style: TextStyle(
    color: riskColor,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  ),
),
],
),
),
],
),
const SizedBox(height: 6),
Text('District · Uganda',
style: TextStyle(fontSize: 13, color: greyText)),
const SizedBox(height: 16),
Row(
children: [
Text('Risk Score: ',
style: TextStyle(fontSize: 13, color: greyText)),
Text(
'${district['risk_score'] ?? 0}/10',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.bold,
color: riskColor,
),
),
],
),
const SizedBox(height: 8),
ClipRRect(
borderRadius: BorderRadius.circular(6),
child: LinearProgressIndicator(
value: ((district['risk_score'] ?? 0) as num) / 10,
backgroundColor: riskColor.withOpacity(0.12),
valueColor: AlwaysStoppedAnimation<Color>(riskColor),
minHeight: 10,
),
),
const SizedBox(height: 16),
Container(
width: double.infinity,
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: riskColor.withOpacity(0.06),
borderRadius: BorderRadius.circular(12),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'⚠️ Diseases to Watch',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: riskColor,
),
),
const SizedBox(height: 6),
Text(
district['diseases_flagged'] ?? 'None detected',
style: const TextStyle(
  fontSize: 13, color: darkText, height: 1.5),
),
],
),
),
],
),
),
const SizedBox(height: 12),

// Environmental conditions
Container(
width: double.infinity,
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
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
  const Icon(Icons.satellite_alt,
      color: primaryGreen, size: 18),
  const SizedBox(width: 8),
  const Text(
    'Satellite Environmental Data',
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: darkText,
    ),
  ),
],
),
const SizedBox(height: 16),
Row(
children: [
  _envItem('🌿', 'Vegetation', '${env['vegetation_ndvi'] ?? 0}',
      'NDVI'),
  _envItem('💧', 'Moisture', '${env['moisture_index'] ?? 0}',
      'NDMI'),
],
),
const SizedBox(height: 12),
Row(
children: [
  _envItem('🌡️', 'Temperature',
      '${env['temperature_celsius'] ?? 0}°C', 'LST'),
  _envItem('🌊', 'Water',
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
const Text('💡', style: TextStyle(fontSize: 20)),
const SizedBox(width: 12),
Expanded(
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Text(
      'Farmer Advice',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      district['farmer_advice'] ?? '',
      style: TextStyle(
        fontSize: 13,
        color: Colors.green[800],
        height: 1.5,
      ),
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

Widget _envItem(String emoji, String label, String value, String source) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText)),
            Text(label, style: TextStyle(fontSize: 11, color: greyText)),
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
Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: redRisk.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: redRisk, size: 40),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: darkText, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Try: Kampala, Ntenjeru, Gulu, Mbarara',
            style: TextStyle(
                fontSize: 12, color: greyText, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
