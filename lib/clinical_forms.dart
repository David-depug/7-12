import 'package:flutter/foundation.dart';

/// Option on the 4-point Likert scale (0–3) used by GAD‑7 and PHQ‑9.
@immutable
class ClinicalOption {
  final String label;
  final int value;

  const ClinicalOption({
    required this.label,
    required this.value,
  });
}

/// Single question in a clinical form.
@immutable
class ClinicalQuestion {
  /// Question id within the form, e.g. '1', '2', ...
  final String id;

  /// Question text shown to the user.
  final String text;

  /// Whether this question is considered a risk flag (e.g. PHQ‑9 item 9).
  final bool riskFlag;

  const ClinicalQuestion({
    required this.id,
    required this.text,
    this.riskFlag = false,
  });
}

/// Clinical form definition (e.g. GAD‑7, PHQ‑9).
@immutable
class ClinicalForm {
  final String id;
  final String title;
  final String instructions;
  final List<ClinicalOption> optionsScale;
  final List<ClinicalQuestion> questions;

  const ClinicalForm({
    required this.id,
    required this.title,
    required this.instructions,
    required this.optionsScale,
    required this.questions,
  });
}

/// Shared 4-point options scale used by both GAD‑7 and PHQ‑9.
const List<ClinicalOption> kFourPointScale = [
  ClinicalOption(label: 'Not at all', value: 0),
  ClinicalOption(label: 'Several days', value: 1),
  ClinicalOption(label: 'More than half the days', value: 2),
  ClinicalOption(label: 'Nearly every day', value: 3),
];

/// GAD‑7 form definition (7 anxiety items).
const ClinicalForm gad7Form = ClinicalForm(
  id: 'gad7',
  title: 'GAD-7 Anxiety Questionnaire',
  instructions:
      'Over the last 2 weeks, how often have you been bothered by the following problems?',
  optionsScale: kFourPointScale,
  questions: [
    ClinicalQuestion(
      id: '1',
      text: 'Feeling nervous, anxious, or on edge',
    ),
    ClinicalQuestion(
      id: '2',
      text: 'Not being able to stop or control worrying',
    ),
    ClinicalQuestion(
      id: '3',
      text: 'Worrying too much about different things',
    ),
    ClinicalQuestion(
      id: '4',
      text: 'Trouble relaxing',
    ),
    ClinicalQuestion(
      id: '5',
      text: 'Being so restless that it is hard to sit still',
    ),
    ClinicalQuestion(
      id: '6',
      text: 'Becoming easily annoyed or irritable',
    ),
    ClinicalQuestion(
      id: '7',
      text: 'Feeling afraid as if something awful might happen',
    ),
  ],
);

/// PHQ‑9 form definition (9 depression items).
const ClinicalForm phq9Form = ClinicalForm(
  id: 'phq9',
  title: 'PHQ-9 Depression Questionnaire',
  instructions:
      'Over the last 2 weeks, how often have you been bothered by any of the following problems?',
  optionsScale: kFourPointScale,
  questions: [
    ClinicalQuestion(
      id: '1',
      text: 'Little interest or pleasure in doing things',
    ),
    ClinicalQuestion(
      id: '2',
      text: 'Feeling down, depressed, or hopeless',
    ),
    ClinicalQuestion(
      id: '3',
      text:
          'Trouble falling or staying asleep, or sleeping too much',
    ),
    ClinicalQuestion(
      id: '4',
      text:
          'Feeling tired or having little energy',
    ),
    ClinicalQuestion(
      id: '5',
      text:
          'Poor appetite or overeating',
    ),
    ClinicalQuestion(
      id: '6',
      text:
          'Feeling bad about yourself — or that you are a failure or have let yourself or your family down',
    ),
    ClinicalQuestion(
      id: '7',
      text:
          'Trouble concentrating on things, such as reading the newspaper or watching television',
    ),
    ClinicalQuestion(
      id: '8',
      text:
          'Moving or speaking so slowly that other people could have noticed? Or the opposite — being so fidgety or restless that you have been moving around a lot more than usual',
    ),
    ClinicalQuestion(
      id: '9',
      text:
          'Thoughts that you would be better off dead, or of hurting yourself in some way',
      riskFlag: true,
    ),
  ],
);


