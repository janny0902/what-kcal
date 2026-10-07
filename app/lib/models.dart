const mealTypes = ['아침', '아점', '점심', '점저', '저녁', '야식'];
const categories = ['한식', '양식', '중식', '일식', '분식', '구내식당', '패스트푸드', '디저트/카페'];

class FoodChoice {
  const FoodChoice({
    required this.label,
    required this.name,
    required this.portion,
    required this.calories,
    required this.description,
  });

  final String label;
  final String name;
  final String portion;
  final int calories;
  final String description;

  Map<String, dynamic> toJson() => {
        'label': label,
        'name': name,
        'portion': portion,
        'calories': calories,
        'description': description,
      };

  factory FoodChoice.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final label = json['label'] as String? ?? '';
    return FoodChoice(
      label: label.isEmpty ? name : label,
      name: name,
      portion: json['portion'] as String? ?? '',
      calories: (json['calories'] as num?)?.round() ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}

class MealItem {
  MealItem({
    required this.id,
    required this.name,
    required this.portion,
    required this.calories,
    required this.description,
    this.question = '',
    this.choices = const [],
    this.choiceIndex = 0,
  });

  /// 인식 후보 중 하나를 골라 이름·분량·칼로리를 그 후보 값으로 채운다.
  factory MealItem.recognized(String id, String question, List<FoodChoice> choices) {
    final first = choices.first;
    return MealItem(
      id: id,
      name: first.name,
      portion: first.portion,
      calories: first.calories,
      description: first.description,
      question: question,
      choices: choices,
    );
  }

  final String id;
  String name;
  String portion;
  int calories;
  String description;
  final String question;
  final List<FoodChoice> choices;
  int choiceIndex;

  bool get recognized => choices.isNotEmpty;

  void choose(int index) {
    if (index < 0 || index >= choices.length) return;
    final choice = choices[index];
    choiceIndex = index;
    name = choice.name;
    portion = choice.portion;
    calories = choice.calories;
    description = choice.description;
  }

  MealItem copy() => MealItem(
        id: id,
        name: name,
        portion: portion,
        calories: calories,
        description: description,
        question: question,
        choices: choices,
        choiceIndex: choiceIndex,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'portion': portion,
        'calories': calories,
        'description': description,
        'question': question,
        'choices': choices.map((choice) => choice.toJson()).toList(),
        'choiceIndex': choiceIndex,
      };

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        portion: json['portion'] as String? ?? '',
        calories: (json['calories'] as num?)?.round() ?? 0,
        description: json['description'] as String? ?? '',
        question: json['question'] as String? ?? '',
        choices: ((json['choices'] as List?) ?? const [])
            .map((choice) => FoodChoice.fromJson(Map<String, dynamic>.from(choice as Map)))
            .toList(),
        choiceIndex: (json['choiceIndex'] as num?)?.round() ?? 0,
      );
}

class MealRecord {
  MealRecord({
    required this.id,
    required this.mealDate,
    required this.mealTime,
    required this.mealType,
    required this.category,
    required this.items,
    required this.servingOptions,
    required this.servingIndex,
    required this.macroFeedback,
    required this.foodStory,
    required this.imagePath,
    required this.recordedLabel,
    required this.updatedAt,
    this.formEpoch = 0,
  });

  final String id;
  String mealDate;
  String mealTime;
  String mealType;
  String category;
  List<MealItem> items;
  List<List<int>> servingOptions;
  int servingIndex;
  String macroFeedback;
  String foodStory;
  String imagePath;
  String recordedLabel;
  int updatedAt;
  int formEpoch;

  MealRecord copy() => MealRecord(
        id: id,
        mealDate: mealDate,
        mealTime: mealTime,
        mealType: mealType,
        category: category,
        items: items.map((item) => item.copy()).toList(),
        servingOptions: servingOptions.map((option) => List<int>.from(option)).toList(),
        servingIndex: servingIndex,
        macroFeedback: macroFeedback,
        foodStory: foodStory,
        imagePath: imagePath,
        recordedLabel: recordedLabel,
        updatedAt: updatedAt,
        formEpoch: formEpoch,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mealDate': mealDate,
        'mealTime': mealTime,
        'mealType': mealType,
        'category': category,
        'items': items.map((item) => item.toJson()).toList(),
        'servingOptions': servingOptions,
        'servingIndex': servingIndex,
        'macroFeedback': macroFeedback,
        'foodStory': foodStory,
        'imagePath': imagePath,
        'recordedLabel': recordedLabel,
        'updatedAt': updatedAt,
        'formEpoch': formEpoch,
      };

  factory MealRecord.fromJson(Map<String, dynamic> json) => MealRecord(
        id: json['id'] as String,
        mealDate: json['mealDate'] as String? ?? '',
        mealTime: json['mealTime'] as String? ?? '',
        mealType: json['mealType'] as String? ?? '점심',
        category: json['category'] as String? ?? '한식',
        items: ((json['items'] as List?) ?? const [])
            .map((item) => MealItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        servingOptions: ((json['servingOptions'] as List?) ?? const [
          [1],
          [2, 3],
        ])
            .map((option) => (option as List).map((value) => (value as num).round()).toList())
            .toList(),
        servingIndex: (json['servingIndex'] as num?)?.round() ?? 0,
        macroFeedback: json['macroFeedback'] as String? ?? '',
        foodStory: json['foodStory'] as String? ?? '',
        imagePath: json['imagePath'] as String? ?? '',
        recordedLabel: json['recordedLabel'] as String? ?? '',
        updatedAt: (json['updatedAt'] as num?)?.round() ?? 0,
        formEpoch: (json['formEpoch'] as num?)?.round() ?? 0,
      );
}
