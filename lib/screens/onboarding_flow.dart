import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../theme/app_theme.dart';

// --- PASO 1: SELECCIÓN DE PLAN ---
class PlanSelectionScreen extends StatelessWidget {
  final String username;
  const PlanSelectionScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Bienvenido, $username",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              const Text(
                "Elige tu camino",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              _PlanCard(
                title: "Plan Cirrosis",
                description: "Enfoque en salud hepática.",
                icon: Icons.medical_services_outlined,
                color: const Color(0xFF66BB6A),
                onTap: () => _goToQuestionnaire(context, 'Cirrosis'),
              ),
              const SizedBox(height: 20),
              _PlanCard(
                title: "Plan Diabetes",
                description: "Control glucémico y conteo de carbos.",
                icon: Icons.water_drop_outlined,
                color: Colors.blueAccent,
                onTap: () => _goToQuestionnaire(context, 'Diabetes'),
              ),
              const SizedBox(height: 20),
              _PlanCard(
                title: "Integral",
                description: "Cuidado mixto avanzado.",
                icon: Icons.healing_outlined,
                color: Colors.teal,
                onTap: () => _goToQuestionnaire(
                  context,
                  'Integral (Cirrosis + Diabetes)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToQuestionnaire(BuildContext context, String plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QuestionnaireScreen(planType: plan, username: username),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PlanCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// --- PASO 2: CUESTIONARIO DINÁMICO ---
class QuestionnaireScreen extends StatefulWidget {
  final String planType;
  final String username;

  const QuestionnaireScreen({
    super.key,
    required this.planType,
    required this.username,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentStep = 0;
  final Map<int, String> _answers = {}; // Guardamos texto directo
  final TextEditingController _otherController = TextEditingController();
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    if (widget.planType == 'Diabetes') {
      _questions = _diabetesQuestions;
    } else if (widget.planType.contains('Integral')) {
      _questions = _integralQuestions;
    } else {
      _questions = _cirrosisQuestions;
    }
  }

  // --- 1. BASE DE DATOS: CIRROSIS (Actualizada) ---
  final List<Map<String, dynamic>> _cirrosisQuestions = [
    // NUEVAS PREGUNTAS AGREGADAS AL INICIO
    {
      'category': '1. Información general del paciente',
      'question': 'Edad',
      'type': 'text',
      'hint': 'Ej: 55 años',
    },
    {
      'category': '1. Información general del paciente',
      'question': 'Género',
      'type': 'single',
      'options': ['Masculino', 'Femenino', 'Prefiero no decir', 'Otro'],
    },
    // PREGUNTAS EXISTENTES
    {
      'category': '2. Estado de la enfermedad',
      'question': '¿En qué fase de cirrosis se encuentra usted?',
      'type': 'single',
      'options': ['Compensada', 'Descompensada', 'No lo sé', 'Otro'],
    },
    {
      'category': '2. Estado de la enfermedad',
      'question': '¿Tiene diagnóstico de ascitis (retención de líquidos)?',
      'type': 'single',
      'options': ['Sí', 'No', 'No estoy seguro'],
    },
    {
      'category': '2. Estado de la enfermedad',
      'question': '¿Ha tenido episodios de encefalopatía hepática?',
      'type': 'single',
      'options': ['Sí', 'No', 'No lo sé'],
    },
    {
      'category': '2. Estado de la enfermedad',
      'question': '¿Le han diagnosticado várices esofágicas?',
      'type': 'single',
      'options': ['Sí', 'No', 'No lo sé'],
    },
    {
      'category': '3. Datos médicos',
      'question': '¿Cuál es la causa principal de su cirrosis?',
      'type': 'single',
      'options': [
        'Hígado graso (NAFLD/NASH)',
        'Alcohol',
        'Hepatitis B',
        'Hepatitis C',
        'Autoinmune',
        'Criptogénica (desconocida)',
        'Otra',
      ],
    },
    {
      'category': '3. Datos médicos',
      'question': '¿Tiene otras enfermedades diagnosticadas?',
      'type': 'text',
      'hint': 'Escriba aquí sus enfermedades...',
    },
    {
      'category': '3. Datos médicos',
      'question': '¿Tiene hipertensión arterial?',
      'type': 'single',
      'options': ['Sí', 'No'],
    },
    {
      'category': '3. Datos médicos',
      'question': '¿Tiene problemas renales diagnosticados?',
      'type': 'single',
      'options': ['Sí', 'No', 'No lo sé'],
    },
    {
      'category': '4. Alergias y restricciones',
      'question': '¿A qué es alérgico usted?',
      'type': 'text',
      'hint': 'Escriba sus alergias...',
    },
    {
      'category': '4. Alergias y restricciones',
      'question': '¿Tiene alguna intolerancia alimentaria?',
      'type': 'multi',
      'options': [
        'Lactosa',
        'Gluten',
        'Mariscos',
        'Frutos secos',
        'Ninguna',
        'Otra',
      ],
    },
    {
      'category': '5. Medicación actual',
      'question': '¿Qué medicamentos está tomando actualmente?',
      'type': 'text',
      'hint': 'Liste sus medicamentos...',
    },
    {
      'category': '5. Medicación actual',
      'question': '¿Toma diuréticos (furosemida, espironolactona)?',
      'type': 'single',
      'options': ['Sí', 'No', 'No lo sé'],
    },
    {
      'category': '6. Hábitos y estilo de vida',
      'question': '¿Consume alcohol actualmente?',
      'type': 'single',
      'options': ['Nunca', 'Sí', 'Dejé de consumir', 'Prefiero no responder'],
    },
    {
      'category': '10. Objetivos del plan',
      'question': '¿Cuál es su principal objetivo con este plan?',
      'type': 'single',
      // ELIMINADA LA OPCIÓN 'Controlar diabetes'
      'options': [
        'Mejorar alimentación',
        'Reducir síntomas',
        'Manejar peso',
        'Otro',
      ],
    },
  ];

  // --- 2. BASE DE DATOS: DIABETES (Actualizada) ---
  final List<Map<String, dynamic>> _diabetesQuestions = [
    // NUEVAS PREGUNTAS AGREGADAS AL INICIO
    {
      'category': '1. Información general del paciente',
      'question': 'Edad',
      'type': 'text',
      'hint': 'Ej: 55 años',
    },
    {
      'category': '1. Información general del paciente',
      'question': 'Género',
      'type': 'single',
      'options': ['Masculino', 'Femenino', 'Prefiero no decir', 'Otro'],
    },
    // PREGUNTAS EXISTENTES
    {
      'category': '2. Tipo y diagnóstico',
      'question': '¿Qué tipo de diabetes tiene usted?',
      'type': 'single',
      'options': [
        'Diabetes tipo 1',
        'Diabetes tipo 2',
        'Diabetes gestacional',
        'Prediabetes',
        'No estoy seguro',
      ],
    },
    {
      'category': '2. Tipo y diagnóstico',
      'question': '¿Hace cuánto tiempo fue diagnosticado?',
      'type': 'single',
      'options': ['Menos de 1 año', '1–5 años', '5–10 años', 'Más de 10 años'],
    },
    {
      'category': '2. Tipo y diagnóstico',
      'question': '¿Con qué frecuencia controla su glucosa?',
      'type': 'single',
      'options': [
        'Varias veces al día',
        'Una vez al día',
        'Varias veces a la semana',
        'Rara vez',
        'Nunca',
      ],
    },
    {
      'category': '3. Tratamiento actual',
      'question': '¿Qué tratamiento utiliza actualmente?',
      'type': 'multi',
      'options': [
        'Insulina',
        'Metformina',
        'Inhibidores SGLT2 (ej. dapagliflozina)',
        'Inhibidores DPP-4 (ej. sitagliptina)',
        'Agonistas GLP-1 (ej. semaglutida)',
        'Sulfonilureas',
        'Otro medicamento',
        'No estoy usando tratamiento',
      ],
    },
    {
      'category': '3. Tratamiento actual',
      'question': '¿Ha tenido problemas con su tratamiento?',
      'type': 'single',
      'options': ['Sí', 'No'],
      'triggerInput': 'Sí',
      'inputHint': 'Especifique el problema...',
    },
    {
      'category': '4. Glucosa y control',
      'question': '¿Cuáles suelen ser sus niveles de glucosa en ayunas?',
      'type': 'single',
      'options': [
        'Menos de 90 mg/dL',
        '90–130 mg/dL',
        '131–180 mg/dL',
        'Más de 180 mg/dL',
        'No lo sé',
      ],
    },
    {
      'category': '4. Glucosa y control',
      'question': '¿Sufre episodios de hipoglucemia (glucosa baja)?',
      'type': 'single',
      'options': ['Sí', 'No', 'No lo sé'],
    },
    {
      'category': '4. Glucosa y control',
      'question': '¿Ha tenido glucosa muy elevada recientemente?',
      'type': 'single',
      'options': ['Sí', 'No', 'No lo sé'],
    },
    {
      'category': '5. Complicaciones relacionadas',
      'question': '¿Tiene alguna de estas condiciones?',
      'type': 'multi',
      'options': [
        'Hipertensión arterial',
        'Colesterol alto',
        'Problemas renales',
        'Neuropatía (pies)',
        'Retinopatía (visión)',
        'Enfermedad hepática',
        'Enfermedad cardiovascular',
        'Ninguna',
        'Otra',
      ],
    },
    {
      'category': '6. Alergias o restricciones',
      'question': '¿A qué es alérgico usted?',
      'type': 'text',
      'hint': 'Escriba sus alergias...',
    },
    {
      'category': '6. Alergias o restricciones',
      'question': '¿Tiene intolerancias alimentarias?',
      'type': 'multi',
      'options': [
        'Lactosa',
        'Gluten',
        'Mariscos',
        'Frutos secos',
        'Otra',
        'Ninguna',
      ],
    },
    {
      'category': '6. Alergias o restricciones',
      'question': '¿Existen alimentos que NO desea consumir?',
      'type': 'text',
      'hint': 'Liste los alimentos...',
    },
    {
      'category': '7. Alimentación y hábitos',
      'question': '¿Cuántas comidas al día suele hacer?',
      'type': 'single',
      'options': ['2', '3', '4 o más'],
    },
    {
      'category': '7. Alimentación y hábitos',
      'question': '¿Consume alimentos con azúcar regularmente?',
      'type': 'single',
      'options': ['Sí', 'A veces', 'Rara vez', 'Nunca'],
    },
    {
      'category': '7. Alimentación y hábitos',
      'question': '¿Qué tipo de alimentos consume con más frecuencia?',
      'type': 'multi',
      'options': [
        'Carnes rojas',
        'Carnes blancas',
        'Vegetales',
        'Frutas',
        'Cereales integrales',
        'Comida rápida',
        'Ultraprocesados',
        'Snacks dulces',
        'Snacks salados',
        'Otro',
      ],
    },
    {
      'category': '8. Actividad física',
      'question': '¿Realiza actividad física regularmente?',
      'type': 'single',
      'options': ['Sí', 'No'],
      'triggerInput': 'Sí',
      'inputHint': '¿Qué tipo de actividad realiza?',
    },
    {
      'category': '8. Actividad física',
      'question': '¿Cuántos días a la semana hace ejercicio?',
      'type': 'single',
      'options': ['1–2 días', '3–4 días', '5–7 días', 'Ninguno'],
    },
    {
      'category': '9. Estilo de vida',
      'question': '¿Fuma cigarrillos?',
      'type': 'single',
      'options': ['Sí', 'No', 'Ocasionalmente'],
    },
    {
      'category': '9. Estilo de vida',
      'question': '¿Consume alcohol?',
      'type': 'single',
      'options': ['Sí', 'No', 'Ocasionalmente'],
    },
    {
      'category': '9. Estilo de vida',
      'question': '¿Cuántas horas duerme por noche?',
      'type': 'single',
      'options': ['Menos de 5', '5–7', '7–9', 'Más de 9'],
    },
    {
      'category': '10. Datos antropométricos',
      'question': '¿Cuál es su peso actual?',
      'type': 'text',
      'hint': 'Ej: 70kg',
    },
    {
      'category': '10. Datos antropométricos',
      'question': '¿Cuál es su estatura?',
      'type': 'text',
      'hint': 'Ej: 1.75m',
    },
    {
      'category': '10. Datos antropométricos',
      'question': '¿Ha tenido cambios de peso recientes sin intentarlo?',
      'type': 'single',
      'options': ['Sí, aumenté', 'Sí, bajé', 'No'],
    },
    {
      'category': '11. Objetivos del plan',
      'question': '¿Cuál es su principal objetivo con el plan alimenticio?',
      'type': 'single',
      'options': [
        'Bajar de peso',
        'Controlar glucosa',
        'Mejorar energía',
        'Ganar masa muscular',
        'Reducir complicaciones',
        'Otro',
      ],
    },
    {
      'category': '11. Objetivos del plan',
      'question': '¿En qué comidas necesita más ayuda?',
      'type': 'single',
      'options': ['Desayuno', 'Almuerzo', 'Cena', 'Snacks', 'Todas'],
    },
  ];

  // --- 3. BASE DE DATOS: INTEGRAL (Cirrosis + Diabetes) ---
  final List<Map<String, dynamic>> _integralQuestions = [
    // 1. Información general
    {
      'category': '1. Información general del paciente',
      'question': 'Edad',
      'type': 'text',
      'hint': 'Ej: 55 años',
    },
    {
      'category': '1. Información general del paciente',
      'question': 'Género',
      'type': 'single',
      'options': ['Masculino', 'Femenino', 'Prefiero no decir', 'Otro'],
    },
    // 2. Estado Cirrosis
    {
      'category': '2. Estado de la Cirrosis',
      'question': '¿En qué fase de cirrosis se encuentra usted?',
      'type': 'single',
      'options': ['Compensada', 'Descompensada', 'No lo sé', 'Otro'],
    },
    {
      'category': '2. Estado de la Cirrosis',
      'question': '¿Presenta ascitis (retención de líquido en abdomen)?',
      'type': 'single',
      'options': ['Sí', 'No', 'No estoy seguro'],
    },
    {
      'category': '2. Estado de la Cirrosis',
      'question': '¿Ha tenido episodios de encefalopatía hepática?',
      'type': 'single',
      'options': ['Sí', 'No', 'No sé'],
    },
    {
      'category': '2. Estado de la Cirrosis',
      'question': '¿Le han detectado várices esofágicas?',
      'type': 'single',
      'options': ['Sí', 'No', 'No estoy seguro'],
    },
    {
      'category': '2. Estado de la Cirrosis',
      'question': '¿Cuál es la causa principal de su cirrosis?',
      'type': 'single',
      'options': [
        'Hígado graso (NAFLD/NASH)',
        'Alcohol',
        'Hepatitis B',
        'Hepatitis C',
        'Autoinmune',
        'Criptogénica',
        'Otra',
      ],
    },
    // 3. Estado Diabetes
    {
      'category': '3. Estado de la Diabetes',
      'question': '¿Qué tipo de diabetes tiene?',
      'type': 'single',
      'options': [
        'Tipo 1',
        'Tipo 2',
        'Gestacional',
        'Prediabetes',
        'No estoy seguro',
      ],
    },
    {
      'category': '3. Estado de la Diabetes',
      'question': '¿Hace cuánto fue diagnosticado?',
      'type': 'single',
      'options': ['Menos de 1 año', '1–5 años', '5–10 años', 'Más de 10 años'],
    },
    {
      'category': '3. Estado de la Diabetes',
      'question': '¿Con qué frecuencia controla su glucosa?',
      'type': 'single',
      'options': [
        'Varias veces al día',
        'Una vez al día',
        'Varias veces a la semana',
        'Rara vez',
        'Nunca',
      ],
    },
    {
      'category': '3. Estado de la Diabetes',
      'question': '¿Cuáles suelen ser sus niveles de glucosa en ayunas?',
      'type': 'single',
      'options': [
        '< 90 mg/dL',
        '90–130 mg/dL',
        '131–180 mg/dL',
        '> 180 mg/dL',
        'No lo sé',
      ],
    },
    {
      'category': '3. Estado de la Diabetes',
      'question': '¿Tiene hipoglucemias frecuentes?',
      'type': 'single',
      'options': ['Sí', 'No', 'No estoy seguro'],
    },
    // 4. Complicaciones
    {
      'category': '4. Complicaciones y condiciones',
      'question': '¿Tiene alguna de estas condiciones?',
      'type': 'multi',
      'options': [
        'Hipertensión',
        'Problemas renales',
        'Colesterol alto',
        'Neuropatía (pies)',
        'Retinopatía (visión)',
        'Enfermedad cardiovascular',
        'Ninguna',
        'Otra',
      ],
    },
    {
      'category': '4. Complicaciones y condiciones',
      'question':
          '¿Ha tenido hospitalizaciones recientes por cirrosis o diabetes?',
      'type': 'single',
      'options': ['Sí', 'No'],
      'triggerInput': 'Sí',
      'inputHint': 'Especifique motivo...',
    },
    // 5. Medicación
    {
      'category': '5. Medicación actual',
      'question': '¿Qué medicamentos toma actualmente (general)?',
      'type': 'text',
      'hint': 'Liste sus medicamentos...',
    },
    {
      'category': '5. Medicación actual',
      'question': '¿Usa alguno de estos medicamentos para diabetes?',
      'type': 'multi',
      'options': [
        'Insulina',
        'Metformina',
        'SGLT2 (ej. dapagliflozina)',
        'DPP-4 (ej. sitagliptina)',
        'GLP-1 (ej. semaglutida)',
        'Sulfonilureas',
        'Otro',
        'No uso medicación',
      ],
    },
    {
      'category': '5. Medicación actual',
      'question': '¿Está tomando medicamentos para la cirrosis?',
      'type': 'multi',
      'options': [
        'Lactulosa',
        'Rifaximina',
        'Espironolactona',
        'Furosemida',
        'Betabloqueadores',
        'Otro',
      ],
    },
    // 6. Alergias
    {
      'category': '6. Alergias y restricciones',
      'question': '¿Es alérgico a algún alimento o medicamento?',
      'type': 'text',
      'hint': 'Especifique alergias...',
    },
    {
      'category': '6. Alergias y restricciones',
      'question': '¿Intolerancias alimentarias?',
      'type': 'multi',
      'options': [
        'Lactosa',
        'Gluten',
        'Mariscos',
        'Frutos secos',
        'Otra',
        'Ninguna',
      ],
    },
    {
      'category': '6. Alergias y restricciones',
      'question': '¿Alimentos que NO desea consumir?',
      'type': 'text',
      'hint': 'Especifique alimentos...',
    },
    // 7. Alimentación
    {
      'category': '7. Alimentación actual',
      'question': '¿Cuántas comidas hace al día?',
      'type': 'single',
      'options': ['2', '3', '4 o más'],
    },
    {
      'category': '7. Alimentación actual',
      'question': '¿Consume alimentos muy salados?',
      'type': 'single',
      'options': ['Sí, frecuentemente', 'A veces', 'Rara vez', 'Nunca'],
    },
    {
      'category': '7. Alimentación actual',
      'question': '¿Consume alimentos con azúcar?',
      'type': 'single',
      'options': ['Sí', 'A veces', 'Rara vez', 'Nunca'],
    },
    {
      'category': '7. Alimentación actual',
      'question': '¿Qué alimentos consume más?',
      'type': 'multi',
      'options': [
        'Carne roja',
        'Carne blanca',
        'Vegetales',
        'Frutas',
        'Cereales integrales',
        'Ultraprocesados',
        'Comida rápida',
        'Snacks dulces',
        'Snacks salados',
        'Otro',
      ],
    },
    {
      'category': '7. Alimentación actual',
      'question': '¿Qué alimentos no le gustan?',
      'type': 'text',
      'hint': 'Respuesta libre...',
    },
    // 8. Hidratación
    {
      'category': '8. Hidratación',
      'question': '¿Cuánta agua bebe al día?',
      'type': 'single',
      'options': ['< 1 L', '1–2 L', '> 2 L', 'No lo sé'],
    },
    {
      'category': '8. Hidratación',
      'question': '¿Consume bebidas azucaradas o gaseosas?',
      'type': 'single',
      'options': ['Sí', 'A veces', 'No'],
    },
    // 9. Actividad física
    {
      'category': '9. Actividad física',
      'question': '¿Realiza actividad física?',
      'type': 'single',
      'options': ['Sí', 'No'],
      'triggerInput': 'Sí',
      'inputHint': '¿Qué actividad realiza?',
    },
    {
      'category': '9. Actividad física',
      'question': '¿Cuántos días a la semana hace ejercicio?',
      'type': 'single',
      'options': ['1–2', '3–4', '5–7', 'Ninguno'],
    },
    // 10. Hábitos
    {
      'category': '10. Hábitos de vida',
      'question': '¿Consume alcohol actualmente?',
      'type': 'single',
      'options': ['Sí', 'No', 'Dejé de beber', 'Prefiero no responder'],
    },
    {
      'category': '10. Hábitos de vida',
      'question': '¿Fuma cigarrillos?',
      'type': 'single',
      'options': ['Sí', 'No', 'Ocasionalmente'],
    },
    {
      'category': '10. Hábitos de vida',
      'question': '¿Cuántas horas duerme por noche?',
      'type': 'single',
      'options': ['< 5', '5–7', '7–9', '> 9'],
    },
    // 11. Antropometría
    {
      'category': '11. Datos antropométricos',
      'question': 'Peso actual',
      'type': 'text',
      'hint': 'Ej: 75kg',
    },
    {
      'category': '11. Datos antropométricos',
      'question': 'Estatura',
      'type': 'text',
      'hint': 'Ej: 1.70m',
    },
    {
      'category': '11. Datos antropométricos',
      'question': '¿Ha tenido cambios de peso recientes sin intentarlo?',
      'type': 'single',
      'options': ['Subí de peso', 'Bajé de peso', 'Me mantengo igual'],
    },
    // 12. Objetivos
    {
      'category': '12. Objetivos del plan',
      'question': '¿Cuál es su objetivo principal?',
      'type': 'single',
      'options': [
        'Controlar glucosa',
        'Mejorar función hepática',
        'Disminuir síntomas',
        'Manejar peso',
        'Aumentar energía',
        'Prevenir complicaciones',
        'Otro',
      ],
    },
    {
      'category': '12. Objetivos del plan',
      'question': '¿En qué comidas necesita más ayuda?',
      'type': 'single',
      'options': ['Desayuno', 'Almuerzo', 'Cena', 'Snacks', 'Todas'],
    },
  ];

  void _nextQuestion() {
    // Guardar respuesta texto libre si aplica
    if (_questions[_currentStep]['type'] == 'text' &&
        _otherController.text.isNotEmpty) {
      _answers[_currentStep] = _otherController.text;
    }

    if (_currentStep < _questions.length - 1) {
      setState(() {
        _currentStep++;
        _otherController.clear();
      });
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    // 1. Recopilar datos para el perfil
    Map<String, String> medicalData = {};
    _answers.forEach((index, value) {
      String questionTitle = _questions[index]['question'];
      medicalData[questionTitle] = value;
    });

    // 2. Guardar en SharedPreferences (Persistencia)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('planType', widget.planType);
    await prefs.setString('medicalData', jsonEncode(medicalData));

    // 3. Crear el objeto de perfil completo
    Map<String, dynamic> userProfile = {
      'username': widget.username,
      'planType': widget.planType,
      'medicalData': medicalData,
    };

    if (context.mounted) {
      // 4. Navegar al Home pasando el perfil
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainLayout(userProfile: userProfile),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lógica visual del cuestionario (Igual a tu versión anterior)
    final questionData = _questions[_currentStep];
    final double progress = (_currentStep + 1) / _questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGreen,
            ),
            minHeight: 6,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questionData['category'],
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              questionData['question'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: SingleChildScrollView(
                child: _buildAnswerOptions(questionData),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == _questions.length - 1
                      ? "Finalizar"
                      : "Siguiente",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(Map<String, dynamic> data) {
    String type = data['type'];
    List<String> options = data['options'] != null
        ? List<String>.from(data['options'])
        : [];

    // Verificamos si esta pregunta tiene un trigger especial para mostrar input (ej: "Sí" o "Otro")
    String specialTrigger = data['triggerInput'] ?? '';

    if (type == 'text') {
      return TextField(
        controller: _otherController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: data['hint'],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppTheme.primaryGreen),
          ),
          fillColor: Colors.grey[50],
          filled: true,
        ),
      );
    }

    return Column(
      children: options.map((option) {
        // En una app real, para multi-selección, _answers debería ser una List<String> o un Set.
        // Aquí, para simplificar y mantener la compatibilidad con el código anterior que era 'single',
        // usamos la misma estructura. Si fuera multi real, cambiaríamos la lógica de isSelected.
        bool isSelected = _answers[_currentStep] == option;

        bool showInput =
            option.contains("Otro") ||
            option.contains("Otra") ||
            (specialTrigger.isNotEmpty && option == specialTrigger);

        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _answers[_currentStep] = option;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.softGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryGreen,
                      ),
                  ],
                ),
              ),
            ),
            if (isSelected && showInput)
              Padding(
                padding: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
                child: TextField(
                  controller: _otherController,
                  decoration: InputDecoration(
                    hintText: data['inputHint'] ?? "Especifique por favor...",
                    border: const UnderlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
