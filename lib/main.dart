import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/consultant_screen.dart';
import 'screens/profile_screen.dart';

/// Punto de entrada de la aplicación.
/// Inicializa la configuración global, carga variables de entorno y gestiona la sesión del usuario.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga de variables de entorno para configuración segura
  await dotenv.load(fileName: ".env");

  // Inicialización del servicio Gemini con la clave API segura
  // Se maneja el caso de clave nula para evitar excepciones en tiempo de ejecución
  Gemini.init(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');

  // Configuración de la barra de estado del sistema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Verificación de sesión de usuario existente
  final prefs = await SharedPreferences.getInstance();
  final String? savedUsername = prefs.getString('username');
  final String? savedPlan = prefs.getString('planType');
  final String? savedMedicalData = prefs.getString('medicalData');

  Widget initialScreen;

  if (savedUsername != null && savedPlan != null) {
    // Reconstrucción del perfil de usuario desde almacenamiento local
    Map<String, dynamic> medicalDataMap = {};
    if (savedMedicalData != null) {
      try {
        medicalDataMap = jsonDecode(savedMedicalData);
      } catch (e) {
        debugPrint("Error al decodificar datos médicos: $e");
      }
    }

    Map<String, dynamic> userProfile = {
      'username': savedUsername,
      'planType': savedPlan,
      'medicalData': medicalDataMap,
    };

    initialScreen = MainLayout(userProfile: userProfile);
  } else {
    initialScreen = const LoginScreen();
  }

  runApp(LuxHealthApp(initialScreen: initialScreen));
}

/// Widget principal que configura el tema y la navegación base.
class LuxHealthApp extends StatefulWidget {
  final Widget initialScreen;
  const LuxHealthApp({super.key, required this.initialScreen});

  @override
  State<LuxHealthApp> createState() => _LuxHealthAppState();
}

class _LuxHealthAppState extends State<LuxHealthApp> {
  bool _isDarkMode = false;

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definición del tema oscuro personalizado
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: const Color(0xFF66BB6A),
      canvasColor: const Color(0xFF2C2C2C),
      dividerColor: const Color(0xFF424242),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF66BB6A),
        brightness: Brightness.dark,
        primary: const Color(0xFF66BB6A),
        surface: const Color(0xFF1E1E1E),
      ),
      fontFamily: 'Sans-Serif',
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
      ),
    );

    return MaterialApp(
      title: 'LuxHealth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: widget.initialScreen,
    );
  }
}

/// Layout principal que gestiona la navegación entre pantallas (Home, Consultor, Perfil).
class MainLayout extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const MainLayout({super.key, required this.userProfile});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  int _healthPoints = 50;
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carga los datos persistentes del usuario (puntos y recomendaciones).
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _healthPoints = prefs.getInt('healthPoints') ?? 50;
      _recommendations = prefs.getStringList('recommendations') ?? [];
    });
  }

  /// Guarda el estado actual del usuario en SharedPreferences.
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('healthPoints', _healthPoints);
    await prefs.setStringList('recommendations', _recommendations);
  }

  /// Actualiza los puntos de salud y persiste los cambios.
  void _updatePoints(int amount) {
    setState(() {
      _healthPoints = (_healthPoints + amount).clamp(0, 100);
    });
    _saveUserData();
  }

  /// Reemplaza la lista completa de recomendaciones.
  void _updateRecommendationsList(List<String> newList) {
    setState(() {
      _recommendations = newList;
    });
    _saveUserData();
  }

  /// Agrega una nueva recomendación a la lista, formateándola y evitando duplicados.
  void _addRecommendation(String item) {
    setState(() {
      String cleanItem = item.trim();
      if (!cleanItem.startsWith('•') && !cleanItem.startsWith('-')) {
        cleanItem = "• $cleanItem";
      }
      if (cleanItem.isNotEmpty && !_recommendations.contains(cleanItem)) {
        _recommendations.insert(0, cleanItem);
      }
    });
    _saveUserData();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.findAncestorStateOfType<_LuxHealthAppState>();
    bool isDark = appState?._isDarkMode ?? false;
    Function(bool) onThemeChanged = appState?._toggleTheme ?? (val) {};

    final List<Widget> screens = [
      HomeScreen(
        userProfile: widget.userProfile,
        recommendations: _recommendations,
        onUpdateList: _updateRecommendationsList,
      ),
      ConsultantScreen(
        userProfile: widget.userProfile,
        onPointsUpdated: _updatePoints,
        currentPoints: _healthPoints,
        onRecommendationAdded: _addRecommendation,
      ),
      ProfileScreen(
        userProfile: widget.userProfile,
        isDarkMode: isDark,
        onThemeChanged: onThemeChanged,
        healthPoints: _healthPoints,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: const Color(0xFF66BB6A),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_dining_rounded),
              label: 'Consultor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
