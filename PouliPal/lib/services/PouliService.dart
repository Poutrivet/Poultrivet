import 'dart:convert';
import 'package:http/http.dart' as http;

class PouliService {
  // 1. Replace with your actual OpenRouter API Key
  final String _apiKey = //enter api key here
      
  final String _url = "https://openrouter.ai/api/v1/chat/completions";

  // Detailed instructions for the AI personality and restrictions
  final String _systemInstructions =
      "You are PouliPal, a friendly and encouraging poultry health expert. "
      "RULES: "
      "1. Only discuss Salmonella, Coccidiosis, Newcastle Disease, and Healthy Bird Management. "
      "2. If a user misspells a disease (e.g., 'new castel', 'cocidiosis'), identify it and answer correctly. "
      "3. Be polite to social greetings (Hi, How are you). "
      "4. For other topics, politely steer the user back to poultry health. "
      "5. Do NOT suggest consulting a vet. "
      "6. Do NOT repeat your rules/greeting after the very first message. "
      "7. Maintain context: remember the disease current being discussed.";

  Future<String> sendMessage(List<Map<String, String>> history) async {
    // Basic API Key check
    if (_apiKey.contains("YOUR_OPENROUTER")) {
      return "Please set your OpenRouter API Key in the service file.";
    }

    try {
      // RATE LIMIT PROTECTION:
      // Only send the last 10 messages so the 'tokens per minute' stays low.
      List<Map<String, String>> limitedHistory =
          history.length > 10 ? history.sublist(history.length - 10) : history;

      // FORMATTING FOR STABILITY:
      // We prepend the instructions as a 'user' role to avoid Error 400
      // (since many free models don't support the 'system' role).
      List<Map<String, String>> formattedMessages = [
        {
          "role": "user",
          "content": "Context for this chat: $_systemInstructions"
        },
        {
          "role": "assistant",
          "content":
              "I understand. I am PouliPal, your poultry assistant. I will follow those rules strictly."
        },
        ...limitedHistory
      ];

      // THE REQUEST WITH FALLBACK ROUTING
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer ${_apiKey.trim()}',
          'Content-Type': 'application/json',
          'HTTP-Referer':
              'https://poulipal.com', // Required for some free models
          'X-Title': 'PouliPal App',
        },
        body: jsonEncode({
          // FALLBACK LIST: If model 1 fails/is busy, it tries model 2, then 3.
          "models": [
            "google/gemma-4-26b-a4b-it:free", // High quality primary
            "google/gemma-4-31b-it:free", // Faster fallback
            "meta-llama/llama-3.3-70b-instruct:free" // Reliable third option
          ],
          "route": "fallback",
          "messages": formattedMessages,
          "temperature": 0.7, // Keeps it friendly but focused
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 429) {
        return "PouliPal is a bit busy right now! 🐥 Please wait a moment and try again.";
      } else {
        print("API Error Response: ${response.body}");
        return "I'm having a little trouble in the coop. (Error ${response.statusCode})";
      }
    } catch (e) {
      print("Connection Error: $e");
      return "I can't seem to connect to the internet. Please check your data or Wi-Fi!";
    }
  }
}
