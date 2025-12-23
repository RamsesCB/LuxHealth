import 'package:flutter/material.dart';
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_widgets.dart';
import '../services/news_service.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final List<String> recommendations;
  final Function(List<String>) onUpdateList;

  const HomeScreen({
    super.key,
    required this.userProfile,
    required this.recommendations,
    required this.onUpdateList,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  late int _dailyCalories;
  late String _username;
  late String _planType;

  late TextEditingController _notesController;

  // Base de datos de recetas
  final Map<String, List<Map<String, dynamic>>> _allRecipes = {
    "Desayuno": [
      {
        "title": "Pudín de Chía y Frutos Rojos",
        "desc": "Energía estable.",
        "cal": 180,
        "tags": ["Omega-3", "Fibra"],
        "ingredients": [
          "3 cdas Chía",
          "1 taza Leche almendras",
          "Frutos rojos"
        ],
        "steps": ["Mezclar.", "Reposar.", "Servir."]
      },
      {
        "title": "Tostada de Aguacate",
        "desc": "Grasas saludables.",
        "cal": 320,
        "tags": ["Saciante"],
        "ingredients": ["Pan integral", "Aguacate", "Huevo"],
        "steps": ["Tostar pan.", "Servir."]
      },
      {
        "title": "Avena con Manzana",
        "desc": "Fibra soluble.",
        "cal": 250,
        "tags": ["Cardio"],
        "ingredients": ["Avena", "Manzana", "Canela"],
        "steps": ["Cocinar avena.", "Añadir manzana."]
      }
    ],
    "Almuerzo": [
      {
        "title": "Salmón al Horno",
        "desc": "Rico en Omega-3.",
        "cal": 450,
        "tags": ["Proteína"],
        "ingredients": ["Salmón", "Espárragos"],
        "steps": ["Hornear 15 min."]
      },
      {
        "title": "Ensalada Quinoa",
        "desc": "Ligero.",
        "cal": 380,
        "tags": ["Energía"],
        "ingredients": ["Quinoa", "Pollo"],
        "steps": ["Mezclar todo."]
      },
      {
        "title": "Lentejas Estofadas",
        "desc": "Hierro vegetal.",
        "cal": 350,
        "tags": ["Vegano"],
        "ingredients": ["Lentejas", "Verduras"],
        "steps": ["Estofar."]
      }
    ],
    "Cena": [
      {
        "title": "Crema Calabacín",
        "desc": "Digestivo.",
        "cal": 220,
        "tags": ["Detox"],
        "ingredients": ["Calabacín", "Cúrcuma"],
        "steps": ["Hervir y triturar."]
      },
      {
        "title": "Tacos de Lechuga",
        "desc": "Bajo carb.",
        "cal": 310,
        "tags": ["Ligero"],
        "ingredients": ["Lechuga", "Pavo"],
        "steps": ["Servir en hojas."]
      },
      {
        "title": "Pescado al Vapor",
        "desc": "Suave.",
        "cal": 200,
        "tags": ["Cena"],
        "ingredients": ["Pescado blanco", "Brocoli"],
        "steps": ["Vapor 10 min."]
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _username = widget.userProfile['username'] ?? 'Paciente';
    _planType = widget.userProfile['planType'] ?? 'General';
    _dailyCalories = _calculateDailyCalories();
    _notesController =
        TextEditingController(text: widget.recommendations.join('\n'));
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recommendations != oldWidget.recommendations) {
      if (!FocusScope.of(context).hasFocus) {
        _notesController.text = widget.recommendations.join('\n');
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    final String text = _notesController.text;
    final List<String> newList =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    widget.onUpdateList(newList);
  }

  // --- MÉTODOS AUXILIARES ---

  List<Map<String, dynamic>> _getRecipesByTime() {
    DateTime now = DateTime.now();
    double currentTime = now.hour + (now.minute / 60.0);
    if (currentTime >= 4.0 && currentTime <= 11.5) {
      return _allRecipes["Desayuno"]!;
    }
    if (currentTime > 11.5 && currentTime <= 16.0) {
      return _allRecipes["Almuerzo"]!;
    }
    return _allRecipes["Cena"]!;
  }

  String _getTimeTitle() {
    DateTime now = DateTime.now();
    double currentTime = now.hour + (now.minute / 60.0);
    if (currentTime >= 4.0 && currentTime <= 11.5) {
      return "Desayuno Saludable";
    }
    if (currentTime > 11.5 && currentTime <= 16.0) {
      return "Almuerzo Balanceado";
    }
    return "Cena Ligera";
  }

  int _calculateDailyCalories() {
    try {
      Map<String, dynamic> data = widget.userProfile['medicalData'] ?? {};
      double weight = double.tryParse(data['Peso actual']
                  ?.toString()
                  .replaceAll(RegExp(r'[^0-9.]'), '') ??
              '70') ??
          70;
      return (weight * 30).round();
    } catch (e) {
      return 2000;
    }
  }

  // Lógica de lanzamiento de URL
  Future<void> _launchURL(String? link) async {
    if (link == null || link.trim().isEmpty) return;
    String urlString = link.trim();
    if (!urlString.startsWith('http')) {
      urlString = 'https://$urlString';
    }

    debugPrint('Intentando abrir URL: $urlString');

    final Uri? url = Uri.tryParse(urlString);
    if (url == null) return;

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error lanzando URL: $e');
    }
  }

  // Modal de detalle de receta
  void _showRecipeDetail(BuildContext context, Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Center(
                child: Icon(Icons.restaurant_menu,
                    size: 80, color: Colors.green[200]),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(recipe['title'],
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text("Ingredientes",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...(recipe['ingredients'] as List)
                      .map((ing) => Text('• $ing'))
                      .toList(),
                  const SizedBox(height: 20),
                  const Text("Preparación",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...(recipe['steps'] as List)
                      .map((step) => Text(step))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentRecipes = _getRecipesByTime();
    String sectionTitle = _getTimeTitle();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores dinámicos
    final Color cardBackgroundColor =
        isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color newsCardColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F9F6);
    final Color primaryTextColor = isDark ? Colors.white : Colors.black87;
    final Color secondaryTextColor =
        isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color borderColor =
        isDark ? Colors.transparent : Colors.grey.shade200;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          HeaderWidget(
              title: "Hola, $_username", subtitle: "Plan Activo: $_planType"),
          const SizedBox(height: 30),
          Row(
            children: [
              Icon(Icons.article_outlined, color: secondaryTextColor, size: 20),
              const SizedBox(width: 8),
              Text("Novedades Médicas",
                  style: TextStyle(
                      color: secondaryTextColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          FutureBuilder<List<RssItem>>(
            future: _newsService.getNewsByPlan(_planType),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  height: 180,
                  decoration: BoxDecoration(
                      color: newsCardColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF66BB6A))),
                );
              }
              final noticias = snapshot.data!;
              final noticia = noticias.isNotEmpty
                  ? noticias.first
                  : RssItem(title: "No hay noticias recientes", link: "");
              return Card(
                elevation: 0,
                color: newsCardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: isDark
                        ? BorderSide.none
                        : const BorderSide(color: Color(0xFFE0F2F1))),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  onTap: () => _launchURL(noticia.link),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text("Google News",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Icon(Icons.share,
                                size: 18, color: Colors.grey[500]),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(noticia.title ?? "Información no disponible",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        Text("Toque para leer el artículo completo...",
                            style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                                height: 1.5)),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Text("Leer artículo completo",
                                style: TextStyle(
                                    color: Color(0xFF66BB6A),
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward_ios,
                                size: 12, color: Color(0xFF66BB6A)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          Text("Recomendaciones",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 160),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03), blurRadius: 10)
                ]),
            child: TextField(
              controller: _notesController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              onChanged: (_) => _saveNotes(),
              style:
                  TextStyle(fontSize: 14, height: 1.5, color: primaryTextColor),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "• Escribe notas aquí...",
                  hintStyle: TextStyle(color: Colors.grey[500])),
            ),
          ),
          const SizedBox(height: 30),
          Text("Resumen Diario (Meta)",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor)),
          const SizedBox(height: 15),
          Row(children: [
            const Expanded(
                child: StatCard(
                    title: "Glucosa Meta",
                    value: "< 100",
                    unit: "mg/dL",
                    icon: Icons.water_drop,
                    color: Colors.blueAccent)),
            const SizedBox(width: 15),
            Expanded(
                child: StatCard(
                    title: "Calorías/Día",
                    value: "$_dailyCalories",
                    unit: "kcal",
                    icon: Icons.local_fire_department,
                    color: Colors.orangeAccent)),
          ]),
          const SizedBox(height: 30),
          Row(children: [
            Icon(Icons.restaurant, color: secondaryTextColor, size: 20),
            const SizedBox(width: 8),
            Text(sectionTitle,
                style: TextStyle(
                    color: secondaryTextColor, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentRecipes.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final recipe = currentRecipes[index];
              return Container(
                decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.lunch_dining, color: Colors.orange),
                  title: Text(recipe['title'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryTextColor)),
                  subtitle: Text("${recipe['cal']} kcal",
                      style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold)),
                  trailing: ElevatedButton(
                    onPressed: () => _showRecipeDetail(context, recipe),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A)),
                    child: const Text("Ver",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
