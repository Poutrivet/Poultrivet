class ResponseBuilder {
  // =========================
  // PUBLIC ENTRY POINT
  // =========================
  static String buildResponse(
    Map<String, dynamic> disease,
    String intent,
  ) {
    final name = disease["name"] ?? "This disease";

    switch (intent) {
      case "general":
        return _buildGeneral(name, disease);

      case "causes":
        return _buildCauses(name, disease);

      case "transmission":
        return _buildTransmission(name, disease);

      case "symptoms":
        return _buildSymptoms(name, disease);

      case "treatment":
        return _buildTreatment(name, disease);

      case "prevention":
        return _buildPrevention(name, disease);

      case "vaccination":
        return _buildVaccination(name, disease);

      case "mortality":
        return _buildMortality(name, disease);

      case "severity":
        return _buildSeverity(name, disease);

      case "complications":
        return _buildComplications(name, disease);

      case "diagnosis_methods":
        return _buildDiagnosis(name, disease);

      default:
        return "I'm not sure I understood that. You can ask me about symptoms, "
            "treatment, prevention, causes, or how a disease spreads. What would you like to know?";
    }
  }

  // =========================
  // FORMAT HELPERS
  // =========================
  static String _formatList(String title, dynamic items) {
    if (items == null) {
      return "$title: No information available for this right now.";
    }

    if (items is List) {
      return "$title:\n• ${items.join("\n• ")}";
    }

    return "$title: $items";
  }

  // =========================
  // GENERAL RESPONSE
  // =========================
  static String _buildGeneral(
    String name,
    Map<String, dynamic> disease,
  ) {
    return "Here's a quick overview of $name:\n\n"
        "${disease["description"] ?? ""}\n\n"
        "Feel free to ask me anything more specific — like symptoms to watch for, "
        "how to treat it, how it spreads, or how to prevent it.";
  }

  // =========================
  // CAUSES
  // =========================
  static String _buildCauses(
    String name,
    Map<String, dynamic> disease,
  ) {
    final causes = disease["causes"];
    if (causes == null) {
      return "I don't have specific cause information for $name right now.";
    }
    return "Here's what causes $name:\n\n"
        "${_formatList("Main causes", causes)}\n\n"
        "Understanding the root cause can help you take the right steps to protect your flock.";
  }

  // =========================
  // TRANSMISSION
  // =========================
  static String _buildTransmission(
    String name,
    Map<String, dynamic> disease,
  ) {
    final transmission = disease["transmission"];

    return "$name can spread between birds fairly easily, so it's important to act quickly "
        "if you spot any signs.\n\n"
        "${_formatList("It spreads through", transmission)}\n\n"
        "Isolating affected birds early is one of the best things you can do to protect the rest of your flock.";
  }

  // =========================
  // SYMPTOMS
  // =========================
  static String _buildSymptoms(
    String name,
    Map<String, dynamic> disease,
  ) {
    final symptoms = disease["symptoms"] ?? {};

    return "Here's what to watch out for with $name:\n\n"
        "${_formatList("Early signs", symptoms["early"])}\n\n"
        "${_formatList("Advanced signs", symptoms["advanced"])}\n\n"
        "Catching it at the early stage gives you the best chance of a good outcome. "
        "If you're seeing advanced signs, please act right away.";
  }

  // =========================
  // TREATMENT
  // =========================
  static String _buildTreatment(
    String name,
    Map<String, dynamic> disease,
  ) {
    final t = disease["treatment"] ?? {};
    final medication = t["medication"] ?? "N/A";
    final dosage = t["dosage"] ?? "N/A";
    final duration = t["duration"] ?? "N/A";
    final supportive = t["supportive_care"];

    String response = "Here's how to treat $name:\n\n"
        "• Medication: $medication\n"
        "• Dosage: $dosage\n"
        "• Duration: $duration\n";

    if (supportive != null && supportive is List && supportive.isNotEmpty) {
      response += "\nAlongside the medication, it also helps to:\n"
          "• ${supportive.join("\n• ")}";
    }

    if (medication == "No cure") {
      response += "\n\nUnfortunately there's no direct cure for $name, "
          "so prevention through vaccination is really the most important step. "
          "Focus on supporting the healthy birds and stopping the spread.";
    } else {
      response += "\n\nMake sure to complete the full course even if your birds "
          "start looking better — stopping early can let the disease come back.";
    }

    return response;
  }

  // =========================
  // PREVENTION
  // =========================
  static String _buildPrevention(
    String name,
    Map<String, dynamic> disease,
  ) {
    final prevention = disease["prevention"];
    return "Preventing $name is much easier than dealing with an outbreak. Here's what you can do:\n\n"
        "${_formatList("Key prevention steps", prevention)}\n\n"
        "A little effort on these regularly goes a long way in keeping your flock safe.";
  }

  // =========================
  // VACCINATION
  // =========================
  static String _buildVaccination(
    String name,
    Map<String, dynamic> disease,
  ) {
    final vaccination = disease["vaccination"];
    if (vaccination == null ||
        (vaccination is List && vaccination.isEmpty)) {
      return "I don't have vaccination information for $name at the moment. "
          "It's worth checking with your local vet or supplier for the latest options in your area.";
    }
    return "Here's what's available for vaccinating against $name:\n\n"
        "${_formatList("Vaccines", vaccination)}\n\n"
        "Talk to your vet about the right schedule for your flock — timing really matters with vaccines.";
  }

  // =========================
  // MORTALITY
  // =========================
  static String _buildMortality(
    String name,
    Map<String, dynamic> disease,
  ) {
    final mortality = disease["mortality_rate"] ?? "unknown";

    return "$name is something to take seriously.\n\n"
        "It has a mortality rate described as \"$mortality\", which means birds can die "
        "if the disease isn't caught and treated in time.\n\n"
        "The sooner you act, the better the chances for your flock.";
  }

  // =========================
  // SEVERITY
  // =========================
  static String _buildSeverity(
    String name,
    Map<String, dynamic> disease,
  ) {
    final severity = disease["severity"] ?? "unknown";
    return "$name is considered a $severity disease.\n\n"
        "Don't wait for things to get worse — if you're seeing symptoms, it's best to start "
        "treatment or speak to a vet as soon as you can.";
  }

  // =========================
  // COMPLICATIONS
  // =========================
  static String _buildComplications(
    String name,
    Map<String, dynamic> disease,
  ) {
    final complications = disease["complications"];
    return "If $name isn't managed properly, things can get worse. Here's what to watch out for:\n\n"
        "${_formatList("Possible complications", complications)}\n\n"
        "This is why catching it early and following through with treatment really matters.";
  }

  // =========================
  // DIAGNOSIS
  // =========================
  static String _buildDiagnosis(
    String name,
    Map<String, dynamic> disease,
  ) {
    final methods = disease["diagnosis_methods"];
    return "Here are the common ways to diagnose $name:\n\n"
        "${_formatList("Diagnosis methods", methods)}\n\n"
        "If you're unsure, it's always a good idea to get a vet involved — "
        "an accurate diagnosis means faster, more effective treatment.";
  }
}
