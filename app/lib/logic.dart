import 'models.dart';

class SeoulStamp {
  const SeoulStamp({required this.date, required this.mealDate, required this.mealTime});

  final DateTime date;
  final String mealDate;
  final String mealTime;
}

DateTime seoulNow() => DateTime.now().toUtc().add(const Duration(hours: 9));

String formatYmd(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String formatHms(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

SeoulStamp seoulStamp([DateTime? when]) {
  final date = when ?? seoulNow();
  return SeoulStamp(date: date, mealDate: formatYmd(date), mealTime: formatHms(date));
}

const _weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

String formatKoreanDate(DateTime date) => '${date.month}월 ${date.day}일 ${_weekdays[date.weekday - 1]}';

String detectMealType(String time) {
  final parts = time.split(':');
  final mins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
  if (mins >= 5 * 60 && mins < 9 * 60) return '아침';
  if (mins >= 9 * 60 && mins < 11 * 60) return '아점';
  if (mins >= 11 * 60 && mins < 14 * 60 + 30) return '점심';
  if (mins >= 14 * 60 + 30 && mins < 17 * 60) return '점저';
  if (mins >= 17 * 60 && mins < 21 * 60) return '저녁';
  return '야식';
}

String recordedLabel(String mealDate, String mealTime, String mealType) => '$mealDate $mealTime(KR) $mealType';

String comma(int value) {
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

String servingText(List<int> option) {
  if (option.length <= 1) return '${option.isEmpty ? 1 : option.first}인분';
  final sorted = [...option]..sort();
  return '${sorted.first}~${sorted.last}인분';
}

double servingDivisor(List<int> option) {
  if (option.isEmpty) return 1;
  return option.reduce((a, b) => a + b) / option.length;
}

int baseCalories(MealRecord meal) => meal.items.fold(0, (sum, item) => sum + item.calories);

int eatenCalories(MealRecord meal) {
  final option = meal.servingIndex >= 0 && meal.servingIndex < meal.servingOptions.length
      ? meal.servingOptions[meal.servingIndex]
      : const [1];
  final divisor = servingDivisor(option);
  if (divisor == 0) return baseCalories(meal);
  return (baseCalories(meal) / divisor).round();
}

bool hasValidItem(MealRecord meal) => meal.items.any((item) => item.name.trim().isNotEmpty && item.calories > 0);

String mealTitle(MealRecord meal) {
  final names = meal.items.map((item) => item.name.trim()).where((name) => name.isNotEmpty);
  return names.isEmpty ? '이 식사' : names.join(', ');
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

class Preset {
  const Preset({
    required this.name,
    required this.portion,
    required this.calories,
    required this.category,
    required this.description,
    required this.macro,
    required this.story,
  });

  final String name;
  final String portion;
  final int calories;
  final String category;
  final String description;
  final String macro;
  final String story;
}

const presets = [
  Preset(
    name: '흰쌀밥',
    portion: '1공기',
    calories: 300,
    category: '한식',
    description: '쌀밥 한 공기',
    macro: '탄수화물 비중이 커요. 계란, 두부, 생선처럼 단백질을 곁들이면 한 끼가 더 든든해져요.',
    story: '쌀밥은 한국 밥상의 중심이에요. 김이 오르는 밥을 주식으로 삼는 문화는 농경 사회에서 오래 이어졌어요.',
  ),
  Preset(
    name: '김치찌개',
    portion: '1인분',
    calories: 200,
    category: '한식',
    description: '밥 제외, 국물 위주 1인분',
    macro: '국물 요리라 포만감이 있어도 밥까지 더하면 탄수화물이 올라가요. 밥 양을 먼저 정하면 총량이 안정돼요.',
    story: '신김치와 돼지고기를 끓여 먹는 찌개예요. 김치가 익으면 국물을 내어 나눠 먹던 밥상 문화와 닿아 있어요.',
  ),
  Preset(
    name: '비빔밥',
    portion: '1그릇',
    calories: 680,
    category: '한식',
    description: '나물과 고추장을 비빈 한 그릇',
    macro: '나물이 들어가 채소는 풍부하고, 고추장과 밥 때문에 탄수화물이 커요. 계란이나 고기를 올리면 단백질이 보완돼요.',
    story: '나물과 고추장을 밥에 비벼 먹는 한식이에요. 궁중의 골동반에서 왔다는 이야기와, 남은 음식을 한데 모으던 풍습이 함께 전해져요.',
  ),
  Preset(
    name: '백반',
    portion: '1상',
    calories: 700,
    category: '구내식당',
    description: '밥, 국, 반찬이 함께 있는 한 상',
    macro: '반찬 구성에 따라 균형이 달라져요. 국은 남기고 단백질 반찬을 먼저 먹으면 탄수화물 비율을 낮추기 쉬워요.',
    story: '밥과 국, 몇 가지 반찬을 한상에 올리는 상차림이에요. 구내식당과 백반집에서 매일의 식사로 오래 남아 있어요.',
  ),
  Preset(
    name: '김밥',
    portion: '1줄',
    calories: 450,
    category: '분식',
    description: '단무지와 달걀이 들어간 한 줄',
    macro: '한 줄은 간편하지만 밥 비중이 커요. 반 줄만 먹고 계란, 우유처럼 단백질을 더하면 균형이 좋아져요.',
    story: '김에 밥과 속재료를 말아 먹기 좋게 만든 분식이에요. 김초밥의 영향을 받아 소풍과 도시락의 대표 메뉴가 되었어요.',
  ),
  Preset(
    name: '라면',
    portion: '1개',
    calories: 500,
    category: '분식',
    description: '국물 라면 한 개',
    macro: '면과 국물 나트륨이 함께 있어요. 국물을 반만 마시고 계란을 넣으면 같은 면으로도 구성이 나아져요.',
    story: '면을 뜨거운 국물에 빨리 익혀 먹는 분식이에요. 한국에서는 야식과 간편식의 상징처럼 자리 잡았어요.',
  ),
  Preset(
    name: '짜장면',
    portion: '1그릇',
    calories: 780,
    category: '중식',
    description: '춘장 소스를 비빈 면 한 그릇',
    macro: '면과 소스가 탄수화물·지방을 많이 가져가요. 양파와 채소를 더 남기고 단무지로 양을 조절해 보세요.',
    story: '춘장에 볶은 채소와 고기를 면에 비벼 먹는 한국식 중국 요리예요. 인천 차이나타운을 거치며 달콤한 한국의 짜장면으로 자리 잡았다는 이야기가 있어요.',
  ),
  Preset(
    name: '초밥',
    portion: '8피스',
    calories: 500,
    category: '일식',
    description: '생선 초밥 여덟 피스',
    macro: '생선에서 단백질이 나오고 밥에서 탄수화물이 나와요. 간장은 찍는 정도로만 쓰면 나트륨을 줄일 수 있어요.',
    story: '식초에 버무린 밥 위에 생선이나 재료를 올린 일식이에요. 밥을 오래 두려고 식초를 더하던 방식에서 지금의 초밥이 자랐다고 전해져요.',
  ),
  Preset(
    name: '햄버거 세트',
    portion: '1세트',
    calories: 980,
    category: '패스트푸드',
    description: '버거와 감자튀김이 있는 한 세트',
    macro: '빵, 패티, 소스, 튀김이 함께 있어 한 끼 열량이 커요. 음료를 물로 바꾸면 세트 칼로리를 바로 낮출 수 있어요.',
    story: '빵 사이에 패티를 넣은 패스트푸드예요. 손으로 들고 빠르게 먹는 식사로 널리 퍼졌어요.',
  ),
  Preset(
    name: '카페라떼',
    portion: '1잔',
    calories: 180,
    category: '디저트/카페',
    description: '우유를 넣은 따뜻한 라떼 한 잔',
    macro: '식사 대용은 아니고 우유에서 약간의 단백질과 지방이 나와요. 시럽을 빼면 같은 잔으로도 열량이 내려가요.',
    story: '에스프레소에 우유를 더한 카페 메뉴예요. 식사 사이에 가볍게 마시는 음료로 익숙해졌어요.',
  ),
];

class CompareRef {
  const CompareRef({required this.label, required this.kcal, required this.note});
  final String label;
  final int kcal;
  final String note;
}

const compareRefs = {
  '남성': CompareRef(label: '성인 남성', kcal: 2500, note: '활동량에 따라 달라지는 하루 참고치예요.'),
  '여성': CompareRef(label: '성인 여성', kcal: 2000, note: '활동량에 따라 달라지는 하루 참고치예요.'),
  '아이': CompareRef(label: '아이', kcal: 1700, note: '학령기 전후를 넓게 잡은 참고치예요.'),
  '노인': CompareRef(label: '노인', kcal: 1800, note: '65세 전후를 넓게 잡은 참고치예요.'),
};
