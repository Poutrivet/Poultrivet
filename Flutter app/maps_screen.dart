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
