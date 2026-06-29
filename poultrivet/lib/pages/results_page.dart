import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';
import 'home_page.dart';
import 'ui/chat_screen.dart';

class ResultsPage extends StatelessWidget {
  final File image;
  final String label;
  final double confidence;

  const ResultsPage({
    super.key,
    required this.image,
    required this.label,
    required this.confidence,
  });

  // ── Dynamic content per diagnosis ────────────────────────────────────────
  _DiagnosisInfo get _info => _getDiagnosisInfo(label);

  static _DiagnosisInfo _getDiagnosisInfo(String label) {
    switch (label) {
      case 'Coccidiosis':
        return _DiagnosisInfo(
          color: const Color(0xFFE74C3C),
          icon: Icons.warning_amber_rounded,
          severity: 'HIGH RISK',
          headline: 'Coccidiosis Detected',
          description:
              'Coccidiosis is a parasitic disease caused by Eimeria protozoa '
              'that damages the intestinal lining. It spreads rapidly through '
              'contaminated litter and water in crowded conditions.',
          immediateActions: [
            'Isolate affected birds from the rest of the flock immediately',
            'Treat with Amprolium (0.024%) in drinking water for 5–7 days',
            'Remove and replace wet or contaminated litter',
            'Disinfect feeders, drinkers, and housing thoroughly',
            'Reduce stocking density to prevent further spread',
          ],
          prevention:
              'Maintain dry litter, use coccidiostats in starter feed, '
              'and vaccinate young birds in high-risk areas.',
          chatPrompt:
              'My flock was diagnosed with Coccidiosis. Confidence: ${0}%. '
              'What are the best treatment options and how do I prevent it from spreading to my other birds?',
        );

      case 'Newcastle Disease':
        return _DiagnosisInfo(
          color: const Color(0xFF8E44AD),
          icon: Icons.coronavirus,
          severity: 'CRITICAL',
          headline: 'Newcastle Disease Detected',
          description:
              'Newcastle Disease is a highly contagious viral infection '
              'affecting the respiratory, nervous, and digestive systems. '
              'It can wipe out an entire flock within days. There is no cure.',
          immediateActions: [
            'ISOLATE ALL AFFECTED BIRDS IMMEDIATELY — this is critical',
            'Notify your local veterinary or agriculture office',
            'Do NOT move birds or equipment off the farm',
            'Vaccinate all unaffected birds as an emergency measure',
            'Disinfect all surfaces, tools, clothing, and footwear',
            'Do not sell or transport any birds until cleared',
          ],
          prevention:
              'Regular vaccination is the only reliable protection. '
              'Use La Sota or Hitchner B1 vaccine at day-old and boosters at 3–4 weeks.',
          chatPrompt:
              'My flock has been diagnosed with Newcastle Disease. '
              'What emergency steps should I take right now and how do I protect my unaffected birds?',
        );

      case 'Salmonella':
        return _DiagnosisInfo(
          color: const Color(0xFFF39C12),
          icon: Icons.science,
          severity: 'MODERATE RISK',
          headline: 'Salmonella Detected',
          description:
              'Salmonella is a bacterial infection that causes diarrhoea, '
              'lethargy, and reduced weight gain in poultry. It also poses '
              'a significant human health risk through contaminated eggs and meat.',
          immediateActions: [
            'Isolate visibly sick birds from the healthy flock',
            'Consult a vet about antibiotic treatment options',
            'Use gloves and wash hands thoroughly after handling birds',
            'Disinfect water sources, feeders, and housing',
            'Do not consume eggs from affected birds until cleared',
            'Avoid spreading litter from affected areas',
          ],
          prevention:
              'Source chicks from Salmonella-free hatcheries, maintain '
              'strict biosecurity, and use competitive exclusion products.',
          chatPrompt:
              'My flock tested positive for Salmonella. '
              'What treatment should I use and how do I handle the food safety risks for my eggs?',
        );

      case 'Healthy':
        return _DiagnosisInfo(
          color: const Color(0xFF19e16c),
          icon: Icons.check_circle_outline,
          severity: 'ALL CLEAR',
          headline: 'Flock Appears Healthy',
          description:
              'No signs of Coccidiosis, Newcastle Disease, or Salmonella '
              'were detected in this sample. Your flock\'s fecal appearance '
              'is consistent with healthy birds.',
          immediateActions: [
            'Continue your regular feeding and watering schedule',
            'Maintain clean, dry litter — change every 6–8 weeks',
            'Keep your vaccination schedule up to date',
            'Monitor birds daily for any behavioural changes',
            'Scan again in 3 days as part of your routine health check',
          ],
          prevention:
              'Regular scanning every 3 days catches disease early '
              'before it can spread through your flock.',
          chatPrompt:
              'My flock scan came back healthy. '
              'What routine care and prevention measures should I maintain to keep my flock disease-free?',
        );

      default: // No Detection or unknown
        return _DiagnosisInfo(
          color: const Color(0xFF6b7280),
          icon: Icons.help_outline,
          severity: 'INCONCLUSIVE',
          headline: 'No Clear Detection',
          description:
              'The model could not confidently identify a disease from this '
              'sample. This may be due to image quality, lighting, or the '
              'sample not being clearly visible in the frame.',
          immediateActions: [
            'Retake the image in good natural lighting',
            'Ensure the fecal sample fills most of the frame',
            'Avoid shadows or blurred images',
            'If birds appear unwell despite this result, consult a vet',
          ],
          prevention:
              'For best results, photograph fresh samples on a clean '
              'white surface in bright natural light.',
          chatPrompt:
              'My flock scan was inconclusive. The birds have been showing '
              'some unusual signs. Can you help me figure out what might be wrong?',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color lightBg = Color(0xFFf6f8f7);
    final info = _info;
    final confidencePct = (confidence * 100).toStringAsFixed(1);

    // Build the chat prompt with the actual confidence
    final chatPrompt = _getDiagnosisInfo(label)
        .chatPrompt
        .replaceAll('${0}%', '$confidencePct%');

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Scan Results',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [

            // ── Scanned image ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: DecorationImage(
                        image: FileImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: info.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        info.severity,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  // Confidence pill top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$confidencePct% confidence',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).cardColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Diagnosis card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: info.color.withValues(alpha: 0.3),
                      width: 1.5),
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
                    // Headline row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(info.icon,
                              color: info.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            info.headline,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: info.color),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Confidence bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Model Confidence',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF6b7280))),
                        Text('$confidencePct%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: info.color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: confidence,
                        backgroundColor:
                            info.color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            info.color),
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      info.description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444444),
                          height: 1.6),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Immediate actions ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          label == 'Healthy'
                              ? Icons.checklist
                              : Icons.medical_services_outlined,
                          color: info.color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label == 'Healthy'
                              ? 'Keep Doing This'
                              : 'Immediate Actions',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: info.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...info.immediateActions.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(
                                      right: 10, top: 1),
                                  decoration: BoxDecoration(
                                    color: info.color
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: info.color),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF333333),
                                        height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Prevention tip ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prevention',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF19e16c))),
                          const SizedBox(height: 4),
                          Text(
                            info.prevention,
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
            ),

            const SizedBox(height: 24),

            // ── Ask PouliPal button ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF19e16c).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🐥',
                            style: TextStyle(fontSize: 20)),
                        SizedBox(width: 10),
                        Text(
                          'Have more questions?',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1a2e)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PouliPal can give you more specific advice about treatment, dosage, and what to watch for next.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6b7280),
                          height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.smart_toy_outlined,
                            size: 18),
                        label: const Text('Ask PouliPal About This'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF19e16c),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                initialMessage: chatPrompt,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Back to home ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.home,
                      color: Color(0xFF19e16c)),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF19e16c)
                        .withValues(alpha: 0.08),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class for diagnosis content ─────────────────────────────────────────
class _DiagnosisInfo {
  final Color color;
  final IconData icon;
  final String severity;
  final String headline;
  final String description;
  final List<String> immediateActions;
  final String prevention;
  final String chatPrompt;

  const _DiagnosisInfo({
    required this.color,
    required this.icon,
    required this.severity,
    required this.headline,
    required this.description,
    required this.immediateActions,
    required this.prevention,
    required this.chatPrompt,
  });
}
