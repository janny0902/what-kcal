const mealTypes = ['아침', '아점', '점심', '점저', '저녁', '야식'];
const categories = ['한식', '양식', '중식', '일식', '분식', '구내식당', '패스트푸드', '디저트/카페'];

class MealItem {
  MealItem({
    required this.id,
    required this.name,
    required this.portion,
    required this.calories,
    required this.description,
  });

  final String id;
  String name;
  String portion;
  int calories;
  String description;

  MealItem copy() => MealItem(id: id, name: name, portion: portion, calories: calories, description: description);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'portion': portion,
        'calories': calories,
        'description': description,
      };

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        portion: json['portion'] as String? ?? '',
        calories: (json['calories'] as num?)?.round() ?? 0,
        description: json['description'] as String? ?? '',
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
