import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchProvider {
  static const _key = 'recent_searches';
  static const _max = 10;

  Future<List<String>> all() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> add(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.remove(q);
    list.insert(0, q);
    final truncated = list.take(_max).toList();
    await prefs.setStringList(_key, truncated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
