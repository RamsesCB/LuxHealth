import 'package:flutter/material.dart';

// Widget de Cabecera (Hola Paciente / Consultor IA)
class HeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  const HeaderWidget({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    );
  }
}

// Tarjeta de Estadísticas (Glucosa / Actividad)
class StatCard extends StatelessWidget {
  final String title, value, unit;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            "$unit • $title",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Etiquetas pequeñas (Bajo en Sodio, etc)
class TagItem extends StatelessWidget {
  final String text;
  final Color color, textColor;
  const TagItem({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Item de lista de alimentos (Sí/No)
class FoodCheckItem extends StatelessWidget {
  final String name;
  final bool isAllowed;
  const FoodCheckItem({super.key, required this.name, required this.isAllowed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isAllowed ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isAllowed ? Colors.green[800] : Colors.red[800],
            ),
          ),
          Icon(
            isAllowed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isAllowed ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}

// Barra para el gráfico
class ChartBar extends StatelessWidget {
  final double height;
  final bool isActive;
  final Color? color; // NUEVO: Color dinámico opcional

  const ChartBar({
    super.key,
    required this.height,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Usar color personalizado o el color default
    Color barColor = color ?? const Color(0xFF66BB6A);
    if (!isActive && color == null) {
      barColor = const Color(0xFFE0E0E0);
    }

    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
