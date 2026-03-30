import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../domain/questions_tree.dart';
import '../providers/chatbot_provider.dart';
import 'widgets/bot_message.dart';
import 'widgets/option_button.dart';
import 'widgets/progress_indicator.dart' as ci;

class ChatbotScreen extends ConsumerWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatbotNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // deep navy
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: switch (state.status) {
            ChatbotStatus.inProgress => _QuestionView(state: state, ref: ref),
            ChatbotStatus.submitting => const _SubmittingView(),
            ChatbotStatus.submitted => const _ConfirmedView(),
            ChatbotStatus.error => _ErrorView(state: state),
          },
        ),
      ),
    );
  }
}

// ── Question view ──────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final ChatbotState state;
  final WidgetRef ref;

  const _QuestionView({required this.state, required this.ref});

  // Decides circle size based on how many options exist
  CircleSize _sizeFor(int count) {
    if (count <= 2) return CircleSize.large;
    if (count == 3) return CircleSize.medium;
    return CircleSize.small;
  }

  // Splits options list into rows for the circle grid
  List<List<Option>> _rows(List<Option> opts) {
    if (opts.length <= 2) return [opts];
    if (opts.length == 3) return [opts.sublist(0, 2), opts.sublist(2)];
    // 4 options → 2x2
    return [opts.sublist(0, 2), opts.sublist(2, 4)];
  }

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final sz = _sizeFor(question.options.length);
    final rows = _rows(question.options);

    return Column(
      children: [
        // ── Top half — question ─────────────────────────────
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 28.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ci.ChatProgressIndicator(currentIndex: state.currentIndex),
                SizedBox(height: 24.h),

                // Previous answer shown above question
                if (state.answers.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Text(
                      state.answers.values.last,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.sp,
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.35),
                      ),
                    ),
                  ),

                const Spacer(),

                // The question — large, bottom-anchored in top half
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    key: ValueKey(question.id),
                    question.botMessage,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFFFFFFF),
                      height: 1.35,
                    ),
                  ),
                ),

                // GPS tag — only on location question
                if (question.id == QuestionId.location)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Row(
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFFFFFFF,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Fetching location...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            color: const Color(
                              0xFFFFFFFF,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Divider ─────────────────────────────────────────
        Container(
          height: 1,
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
        ),

        // ── Bottom half — circle options ─────────────────────
        SizedBox(
          height: 280.h,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(question.id),
                mainAxisSize: MainAxisSize.min,
                children: rows
                    .map(
                      (row) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row
                              .map(
                                (option) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                  ),
                                  child: OptionButton(
                                    label: option.label,
                                    size: sz,
                                    onTap: () => ref
                                        .read(chatbotNotifierProvider.notifier)
                                        .answer(question.id, option.value),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// ── Submitting view ─────────────────────────────────────────

class _SubmittingView extends StatelessWidget {
  const _SubmittingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFFFFFFF),
            strokeWidth: 1.5, // thin line — matches your line aesthetic
          ),
          SizedBox(height: 24.h),
          Text(
            "Filing your report...",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16.sp,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confirmed view ──────────────────────────────────────────

class _ConfirmedView extends StatelessWidget {
  const _ConfirmedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Line-style checkmark — matches your aesthetic
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
              borderRadius: BorderRadius.circular(36.r),
            ),
            child: Icon(
              Icons.check,
              color: const Color(0xFFFFFFFF),
              size: 32.sp,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            "Report filed.",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Your evidence is being secured.",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15.sp,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ──────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final ChatbotState state;
  const _ErrorView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        state.errorMessage ?? "Something went wrong.",
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16.sp,
          color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
