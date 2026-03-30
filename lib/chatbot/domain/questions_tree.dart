enum QuestionId { incidentType, location, surroundings, alertChoice }

class Option {
  final String label;
  final String value;
  const Option({required this.label, required this.value});
}

class Question {
  final QuestionId id;
  final String botMessage;
  final List<Option> options;

  const Question({
    required this.id,
    required this.botMessage,
    required this.options,
  });
}

// Change the questions here without touching any widget
const List<Question> questionFlow = [
  Question(
    id: QuestionId.incidentType,
    botMessage: "What happened?",
    options: [
      Option(label: "Harassment", value: "harassment"),
      Option(label: "Assault",    value: "assault"),
      Option(label: "Stalking",   value: "stalking"),
      Option(label: "Other",      value: "other"),
    ],
  ),
  Question(
    id: QuestionId.location,
    botMessage: "Where are you now?",
    options: [
      // GPS auto-fills — user just confirms or denies
      Option(label: "Confirm my location", value: "gps_confirmed"),
      Option(label: "Skip location",       value: "location_skipped"),
    ],
  ),
  Question(
    id: QuestionId.surroundings,
    botMessage: "Who else is around?",
    options: [
      Option(label: "Alone",               value: "alone"),
      Option(label: "In a crowd",          value: "in_crowd"),
      Option(label: "With someone I trust",value: "trusted_person"),
    ],
  ),
  Question(
    id: QuestionId.alertChoice,
    botMessage: "Do you want to alert someone?",
    options: [
      Option(label: "Yes, silently",  value: "alert_silent"),
      Option(label: "No, just record",value: "record_only"),
    ],
  ),
];