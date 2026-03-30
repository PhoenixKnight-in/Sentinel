import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/questions_tree.dart';
import '../domain/report_model.dart';

part 'chatbot_provider.g.dart';

enum ChatbotStatus { inProgress, submitting, submitted, error }

class ChatbotState {
  final int currentIndex; // which question we're on
  final Map<QuestionId, String> answers;
  final ChatbotStatus status;
  final String? errorMessage;

  const ChatbotState({
    this.currentIndex = 0,
    this.answers = const {},
    this.status = ChatbotStatus.inProgress,
    this.errorMessage,
  });

  bool get isComplete => currentIndex >= questionFlow.length;

  Question get currentQuestion => questionFlow[currentIndex];

  ChatbotState copyWith({
    int? currentIndex,
    Map<QuestionId, String>? answers,
    ChatbotStatus? status,
    String? errorMessage,
  }) => ChatbotState(
    currentIndex: currentIndex ?? this.currentIndex,
    answers: answers ?? this.answers,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

@riverpod
class ChatbotNotifier extends _$ChatbotNotifier {
  @override
  ChatbotState build() => const ChatbotState();

  void answer(QuestionId questionId, String value) {
    final updated = Map<QuestionId, String>.from(state.answers)
      ..[questionId] = value;

    state = state.copyWith(
      answers: updated,
      currentIndex: state.currentIndex + 1,
    );

    // All questions answered — trigger submit
    if (state.isComplete) _submit(updated);
  }

  Future<void> _submit(Map<QuestionId, String> answers) async {
    state = state.copyWith(status: ChatbotStatus.submitting);
    try {
      final report = ReportModel(
        incidentType: answers[QuestionId.incidentType]!,
        surroundings: answers[QuestionId.surroundings]!,
        alertChoice: answers[QuestionId.alertChoice]!,
        timestamp: DateTime.now(),
        // STUB: replace with actual GPS coordinates
        // latitude:  _locationService.current.lat,
        // longitude: _locationService.current.lng,
      );

      // STUB: Firestore write goes here
      // await ref.read(reportRepositoryProvider).submit(report);

      state = state.copyWith(status: ChatbotStatus.submitted);
    } catch (e) {
      state = state.copyWith(
        status: ChatbotStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
