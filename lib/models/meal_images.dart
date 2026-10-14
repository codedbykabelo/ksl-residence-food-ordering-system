class MealImages {
  static const String fallback = 'assets/images/residence_favourite_1.png';

  static const Map<String, String> byMealName = {
    'chicken burger': 'assets/images/food/chicken-burger.webp',
    'chicken and chips': 'assets/images/food/chicken-and-chips.webp',
    'beef burger': 'assets/images/food/beef-burger.webp',
    'pizza': 'assets/images/food/pizza.webp',
    'sandwich': 'assets/images/food/sandwich.webp',
    'pasta': 'assets/images/food/pasta.webp',
    'rice and chicken': 'assets/images/food/rice-and-chicken.webp',
    'breakfast meal': 'assets/images/food/breakfast-meal.webp',
    'vegetarian meal': 'assets/images/food/vegetarian-meal.webp',
  };

  static String forMealName(String name) =>
      byMealName[name.trim().toLowerCase()] ?? fallback;
}
