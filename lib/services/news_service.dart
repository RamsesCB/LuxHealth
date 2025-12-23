import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';

class NewsService {
  // Base URL de Google News RSS para Latinoamérica
  final String _baseUrl = "https://news.google.com/rss/search";

  Future<List<RssItem>> getNewsByPlan(String planType) async {
    String query = "salud+bienestar";

    // Lógica para personalizar la búsqueda según el plan del usuario
    String plan = planType.toLowerCase();

    if (plan.contains("cirrosis") && plan.contains("diabetes")) {
      query = "cirrosis+diabetes+cuidados+alimentacion";
    } else if (plan.contains("cirrosis")) {
      query = "cirrosis+hepatica+higado+graso+noticias";
    } else if (plan.contains("diabetes")) {
      query = "diabetes+control+glucosa+avances";
    } else {
      query = "nutricion+saludable+enfermedades+cronicas";
    }

    // Construimos la URL con parámetros para español latino (Perú/Latam)
    final url = Uri.parse('$_baseUrl?q=$query&hl=es-419&gl=PE&ceid=PE:es-419');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parseamos el XML
        var rssFeed = RssFeed.parse(response.body);
        // Retornamos la lista de items (noticias)
        return rssFeed.items ?? [];
      } else {
        debugPrint("Error API: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error buscando noticias: $e");
      return [];
    }
  }
}
