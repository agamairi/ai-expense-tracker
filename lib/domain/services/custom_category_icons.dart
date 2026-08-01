import 'package:flutter/material.dart';

const List<IconData> customCategoryIconPresets = [
  Icons.category, Icons.shopping_bag, Icons.fastfood, Icons.directions_car,
  Icons.home, Icons.movie, Icons.favorite, Icons.pets,
  Icons.flight, Icons.fitness_center, Icons.school, Icons.build,
  Icons.card_giftcard, Icons.local_hospital, Icons.music_note, Icons.more_horiz,
];

IconData iconForCustomCategory(int iconCodePoint) {
  for (final icon in customCategoryIconPresets) {
    if (icon.codePoint == iconCodePoint) return icon;
  }
  return Icons.category;
}
