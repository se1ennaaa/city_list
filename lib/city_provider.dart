import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/city.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final citiesProvider = StateNotifierProvider<CitiesNotifier, List<City>>((ref) {
  return CitiesNotifier();
});

class CitiesNotifier extends StateNotifier<List<City>> {
  CitiesNotifier() : super([]);

  Future<void> fetchCities({String searchQuery = ''}) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // Если интернет отсутствует, загружаем данные из локального хранилища
      final prefs = await SharedPreferences.getInstance();
      final cachedCities = prefs.getStringList('cachedCities') ?? [];
      state = cachedCities.map((city) {
        final cityParts = city.split('|');
        return City(name: cityParts[0], slug: cityParts[1]);
      }).toList();
    } else {
      // Если интернет есть, выполняем запрос к API
      try {
        final response = await Dio().get('https://odigital.pro/locations/cities/', queryParameters: {
          'search': searchQuery,
        });
        state = (response.data as List).map((city) => City.fromJson(city)).toList();

        // Кешируем данные
        final cachedCities = state.map((city) => '${city.name}|${city.slug}').toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('cachedCities', cachedCities);
      } catch (e) {
        // Обработка ошибок
      }
    }
  }
}
