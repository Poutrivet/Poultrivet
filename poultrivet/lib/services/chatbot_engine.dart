import 'kb_loader.dart';
import 'kb_query.dart';
import 'response_builder.dart';
import 'intent_mapper.dart';

class ChatbotEngine {
  static Map<String, dynamic>? _kb;

  // 1. Load the KB
  static Future<void> init() async {
    _kb = await KBLoader.loadKB();
  }

  static Map<String, dynamic> processInput(
      String input, String? currentContext) {
    if (_kb == null ||
        _kb!['diseases'] == null ||
        (_kb!['diseases'] as List).isEmpty) {
      return {
        "text": "Hmm, it looks like I couldn't load my knowledge base. "
            "Please try restarting the app.",
        "newContext": null
      };
    }

    final cleanInput = input.trim().toLowerCase();

    // 2. Handle greetings first — before any disease logic
    final greeting = _handleGreeting(cleanInput);
    if (greeting != null) {
      return {"text": greeting, "newContext": currentContext};
    }

    // 3. Handle gratitude, farewells, and simple small talk
    final smallTalk = _handleSmallTalk(cleanInput);
    if (smallTalk != null) {
      return {"text": smallTalk, "newContext": currentContext};
    }

    // 4. Check if input is clearly out of scope before doing disease lookup
    if (_isOutOfScope(cleanInput)) {
      return {
        "text": "That's a bit outside what I can help with, I'm afraid.\n\n"
            "I'm a poultry health assistant, so I'm best at answering questions about "
            "Coccidiosis, Newcastle Disease, and Salmonella — things like symptoms, "
            "treatment, prevention, and how diseases spread.\n\n"
            "Is there anything along those lines I can help you with?",
        "newContext": currentContext
      };
    }

    // 5. Figure out which disease the user is talking about
    String? targetDiseaseId =
        IntentMapper.mapToDisease(input) ?? currentContext;

    if (targetDiseaseId == null) {
      return {
        "text": _kb!['system_constraints']?['unsupported_response'] ??
            "I'm not quite sure what you're asking about.\n\n"
                "I can help you with Coccidiosis, Newcastle Disease, and Salmonella. "
                "Try asking something like:\n"
                "• \"What are the symptoms of Newcastle Disease?\"\n"
                "• \"How do I treat Coccidiosis?\"\n"
                "• \"How does Salmonella spread?\"",
        "newContext": null
      };
    }

    // 6. Fetch the disease data
    final diseaseData = KBQuery.getDisease(_kb!, targetDiseaseId);

    if (diseaseData == null) {
      return {
        "text": "I couldn't find information on that disease. "
            "Try asking about Coccidiosis, Newcastle Disease, or Salmonella.",
        "newContext": null
      };
    }

    // 7. Determine the intent of the question
    String intent = _determineIntent(cleanInput);

    // 8. Build the response
    String responseText = ResponseBuilder.buildResponse(diseaseData, intent);

    // If no specific intent was found but the context changed, give a friendly intro
    if (intent == "general" && targetDiseaseId != currentContext) {
      responseText =
          "Sure! Let's talk about ${diseaseData['name']}. What would you like to know?\n\n"
          "You can ask me about symptoms, treatment, prevention, causes, "
          "how it spreads, or how serious it is.";
    }

    return {"text": responseText, "newContext": targetDiseaseId};
  }

  // =========================
  // GREETING HANDLER
  // =========================
  static String? _handleGreeting(String input) {
    const greetings = [
      "hi",
      "hello",
      "hey",
      "hiya",
      "howdy",
      "good morning",
      "good afternoon",
      "good evening",
      "greetings",
      "sup",
      "what's up",
      "whats up",
      "yo"
    ];

    for (final g in greetings) {
      // Match whole phrase to avoid false positives (e.g. "history" matching "hi")
      if (input == g || input.startsWith("$g ") || input.startsWith("$g,")) {
        return "Hello! 👋 Welcome to the Poultry Health Assistant.\n\n"
            "I'm here to help you with information about common poultry diseases. "
            "You can ask me about:\n"
            "• 🐔 Coccidiosis\n"
            "• 🐔 Newcastle Disease\n"
            "• 🐔 Salmonella\n\n"
            "Just type the name of a disease or describe what you're seeing "
            "in your flock, and I'll do my best to help!";
      }
    }
    return null;
  }

  // =========================
  // SMALL TALK HANDLER
  // =========================
  static String? _handleSmallTalk(String input) {
    // Gratitude
    if (input.contains("thank") || input.contains("thanks") || input == "ty") {
      return "You're welcome! 😊 I hope that was helpful. "
          "Feel free to ask anytime if you have more questions about your flock.";
    }

    // Farewell
    if (input == "bye" ||
        input == "goodbye" ||
        input == "see you" ||
        input == "see ya" ||
        input.startsWith("bye ") ||
        input.startsWith("goodbye ")) {
      return "Take care! 👋 Wishing you and your flock good health. "
          "Come back anytime you need help.";
    }

    // How are you
    if (input.contains("how are you") ||
        input.contains("how r u") ||
        input == "hru") {
      return "I'm doing great, thanks for asking! 😄 "
          "Ready to help with any poultry health questions you have. "
          "What would you like to know?";
    }

    // What can you do / help
    if (input.contains("what can you do") ||
        input.contains("what do you do") ||
        input.contains("who are you") ||
        (input.contains("help") && input.length < 10)) {
      return "I'm a poultry health assistant! Here's what I can help with:\n\n"
          "• Symptoms of common poultry diseases\n"
          "• Treatment and medication guidance\n"
          "• How to prevent disease outbreaks\n"
          "• How diseases spread and how to stop them\n"
          "• Vaccination recommendations\n\n"
          "The diseases I currently cover are Coccidiosis, Newcastle Disease, "
          "and Salmonella. Just ask away!";
    }

    return null;
  }

  // =========================
  // OUT-OF-SCOPE DETECTOR
  // =========================
  static bool _isOutOfScope(String input) {
    const outOfScopeKeywords = [
      // Other animals
      "dog", "cat", "cow", "goat", "pig", "sheep", "fish", "rabbit",
      "horse", "cattle",
      // Human health
      "human", "person", "people", "myself", "my body", "headache",
      "i am sick", "i feel sick",
      // Completely unrelated topics
      "weather", "news", "politics", "football", "soccer", "music",
      "movie", "recipe", "sport", "game", "joke",
      "president", "government", "phone", "computer", "internet",
      "school", "homework", "price of"
    ];

    for (final keyword in outOfScopeKeywords) {
      if (input.contains(keyword)) return true;
    }

    return false;
  }

  // =========================
  // INTENT DETECTOR
  // =========================
  static String _determineIntent(String cleanInput) {
    if (cleanInput.contains('symptom') ||
        cleanInput.contains('sign') ||
        cleanInput.contains('look like') ||
        cleanInput.contains('notice') ||
        cleanInput.contains('showing')) return "symptoms";

    if (cleanInput.contains('treat') ||
        cleanInput.contains('cure') ||
        cleanInput.contains('medicine') ||
        cleanInput.contains('medication') ||
        cleanInput.contains('drug') ||
        cleanInput.contains('help my bird')) return "treatment";

    if (cleanInput.contains('prevent') ||
        cleanInput.contains('avoid') ||
        cleanInput.contains('stop') ||
        cleanInput.contains('protect')) return "prevention";

    if (cleanInput.contains('cause') ||
        cleanInput.contains('why') ||
        cleanInput.contains('where does it come from')) return "causes";

    if (cleanInput.contains('transmit') ||
        cleanInput.contains('spread') ||
        cleanInput.contains('catch') ||
        cleanInput.contains('contagious') ||
        cleanInput.contains('pass')) return "transmission";

    if (cleanInput.contains('vaccin')) return "vaccination";

    if (cleanInput.contains('severe') ||
        cleanInput.contains('deadly') ||
        cleanInput.contains('dangerous') ||
        cleanInput.contains('bad')) return "severity";

    if (cleanInput.contains('mortality') ||
        cleanInput.contains('death') ||
        cleanInput.contains('kill') ||
        cleanInput.contains('die') ||
        cleanInput.contains('fatal')) return "mortality";

    if (cleanInput.contains('complication') ||
        cleanInput.contains('what happen') ||
        cleanInput.contains('if untreated')) return "complications";

    if (cleanInput.contains('diagnos') ||
        cleanInput.contains('test') ||
        cleanInput.contains('confirm') ||
        cleanInput.contains('check')) return "diagnosis_methods";

    return "general";
  }
}
