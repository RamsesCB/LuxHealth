import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final int healthPoints; // NUEVO: Puntos de salud

  const ProfileScreen({
    super.key,
    required this.userProfile,
    this.isDarkMode = false,
    required this.onThemeChanged,
    required this.healthPoints,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error al seleccionar imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo cargar la imagen")),
        );
      }
    }
  }

  // LÓGICA DE COLOR SEMÁFORO
  Color _getHealthColor() {
    if (widget.healthPoints < 30) return Colors.redAccent;
    if (widget.healthPoints < 70) return Colors.amber;
    return const Color(0xFF66BB6A);
  }

  String _getHealthStatus() {
    if (widget.healthPoints < 30) return "Necesitas mejorar";
    if (widget.healthPoints < 70) return "En progreso";
    return "¡Excelente!";
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE0F2F1),
            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
            child: _imageFile == null
                ? const Icon(Icons.person, size: 50, color: Color(0xFF66BB6A))
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Configuración",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text("Modo Oscuro"),
                    value: widget.isDarkMode,
                    activeColor: const Color(0xFF66BB6A),
                    onChanged: (bool value) {
                      widget.onThemeChanged(value);
                      setStateDialog(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Cerrar",
                    style: TextStyle(color: Color(0xFF66BB6A)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String username = widget.userProfile['username'] ?? 'Usuario';
    String planType = widget.userProfile['planType'] ?? 'General';
    Color healthColor = _getHealthColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 15),
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Plan: $planType",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // TARJETA DE PUNTOS DE SALUD CON SEMÁFORO
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      healthColor.withOpacity(0.3),
                      healthColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: healthColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: healthColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Puntos de Salud",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: healthColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${widget.healthPoints}/100",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value: widget.healthPoints / 100,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getHealthStatus(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: healthColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // TARJETA DE GRÁFICO (con color dinámico)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Actividad Semanal:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ChartBar(height: 40, color: healthColor),
                          ChartBar(height: 60, color: healthColor),
                          ChartBar(height: 35, color: healthColor),
                          ChartBar(
                            height: 80,
                            isActive: true,
                            color: healthColor,
                          ),
                          ChartBar(height: 50, color: healthColor),
                          ChartBar(height: 70, color: healthColor),
                          ChartBar(height: 45, color: healthColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Botón de configuración
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).iconTheme.color ?? Colors.grey[700],
              ),
              onPressed: _showSettingsDialog,
            ),
          ),
        ],
      ),
    );
  }
}
