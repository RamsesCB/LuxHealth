import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_widgets.dart';

class ConsultantScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Function(int) onPointsUpdated;
  final int currentPoints;
  final Function(String) onRecommendationAdded;

  const ConsultantScreen({
    super.key,
    required this.userProfile,
    required this.onPointsUpdated,
    required this.currentPoints,
    required this.onRecommendationAdded,
  });

  @override
  State<ConsultantScreen> createState() => _ConsultantScreenState();
}

class _ConsultantScreenState extends State<ConsultantScreen> {
  bool _isChatActive = false;
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  late ChatUser currentUser;
  late ChatUser geminiUser;
  late String _systemInstruction;

  Timer? _quizTimer;
  Map<String, dynamic>? _currentQuestion;
  bool _hasAnswered = false;
  int? _selectedOptionIndex;
  bool _isLoadingQuiz = false;

  @override
  void initState() {
    super.initState();
    _setupChat();
    _generateNewQuizQuestion();

    _quizTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (mounted) _generateNewQuizQuestion();
    });
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    super.dispose();
  }

  void _setupChat() {
    String name = widget.userProfile['username'] ?? 'Paciente';
    String plan = widget.userProfile['planType'] ?? 'General';
    Map<String, dynamic> data = widget.userProfile['medicalData'] ?? {};

    currentUser = ChatUser(id: '1', firstName: name);
    geminiUser = ChatUser(
      id: '2',
      firstName: 'Dr. Zenith',
      profileImage: "https://cdn-icons-png.flaticon.com/512/387/387561.png",
    );

    // SYSTEM PROMPT TÉCNICO - DOCTOR ZENITH (ALTA SEGURIDAD CLÍNICA)
    _systemInstruction = """
    IDENTIDAD:
    Eres el Doctor Zenith, Consultor IA especializado EXCLUSIVAMENTE en planes de salud clínicos.
    
    PLANES SOPORTADOS: Cirrosis, Diabetes, Cirrosis + Diabetes.
    
    PLAN ACTIVO DEL PACIENTE: $plan
    DATOS CLÍNICOS DEL PACIENTE: $data
    
    REGLAS SUPREMAS (HARD CONSTRAINTS):
    
    1. RESTRICCIÓN DE DOMINIO ABSOLUTA:
       - Tu conocimiento existe SOLO dentro del contexto del plan: $plan
       - Si la pregunta es sobre fútbol, política, chistes, películas, programación o CUALQUIER tema fuera de salud nutricional: 
         RESPONDE EXACTAMENTE: "Lo siento, solo puedo ayudarte con tu plan de salud seleccionado: $plan"
       - NO des explicaciones adicionales sobre por qué no puedes responder
    
    2. USO OBLIGATORIO DE DATOS CLÍNICOS:
       - SIEMPRE considera los datos del paciente: $data
       - Personaliza cada respuesta basándote en edad, peso, condiciones médicas, alergias y restricciones
       - Si falta información crítica, solicítala de forma breve
    
    3. ESTILO DE COMUNICACIÓN:
       - Respuestas BREVES: 2-6 líneas máximo (el usuario no lee textos largos)
       - Tono: Clínico, empático, serio, profesional
       - SIN tecnicismos médicos innecesarios (lenguaje accesible para pacientes)
       - Primera persona: "Te recomiendo", "Sugiero que"
    
    4. FORMATO DE TEXTO PLANO ESTRICTO:
       - PROHIBIDO: asteriscos (**), guiones bajos (_), numerales (#), comillas dobles (")
       - Listas: usar guión simple "- Elemento"
       - NO uses markdown ni formato especial
    
    5. ANÁLISIS DE IMÁGENES DE ALIMENTOS (FORMATO OBLIGATORIO):
       Cuando recibas una imagen de comida, responde EXACTAMENTE en este formato:
       
       Plato: [Nombre del plato identificado]
       Ingredientes: [Lista breve de ingredientes visibles]
       Calorías estimadas: [Rango aproximado, ej: 400-500 kcal]
       Comentario clínico: [1-2 líneas sobre si es apropiado para el plan $plan]
    
    6. CONTEXTO AUTOMÁTICO:
       - Si el usuario dice "Recomiéndame", "Ayuda", "Qué debo comer": asume que se refiere al plan $plan
       - NUNCA preguntes "¿A qué te refieres?" - infiere el contexto de salud
    
    OBJETIVO PRIMARIO:
    Ser un asistente clínico confiable que ayude al paciente a gestionar su plan de salud con recomendaciones nutricionales precisas, seguras y personalizadas.
    """;
  }

  Future<void> _generateNewQuizQuestion() async {
    if (!mounted) return;
    setState(() {
      _isLoadingQuiz = true;
      _hasAnswered = false;
      _selectedOptionIndex = null;
    });

    String plan = widget.userProfile['planType'] ?? 'Salud';

    String prompt = """
    Genera una pregunta de trivia de selección múltiple sobre nutrición para un paciente con $plan.
    Responde ÚNICAMENTE con este formato JSON estricto:
    {
      "question": "Pregunta...",
      "options": ["Opción A", "Opción B", "Opción C"],
      "correct_index": 0
    }
    """;

    try {
      final value = await gemini.text(prompt);
      String? responseText = value?.output;

      if (responseText != null) {
        responseText =
            responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        Map<String, dynamic> rawData = jsonDecode(responseText);

        List<String> options = List<String>.from(rawData['options']);
        int correctIdx = rawData['correct_index'];
        String correctValue = options[correctIdx];

        options.shuffle();
        int newCorrectIdx = options.indexOf(correctValue);

        setState(() {
          _currentQuestion = {
            "question": rawData['question'],
            "options": options,
            "correct_index": newCorrectIdx,
          };
          _isLoadingQuiz = false;
        });
      }
    } catch (e) {
      debugPrint("Error generando quiz: $e");
      setState(() => _isLoadingQuiz = false);
    }
  }

  void _handleQuizAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _hasAnswered = true;
      _selectedOptionIndex = index;
    });

    int correctIndex = _currentQuestion?['correct_index'] ?? 0;

    if (index == correctIndex) {
      widget.onPointsUpdated(10);
    } else {
      widget.onPointsUpdated(-10);
    }
  }

  void _parseAndSaveRecommendations(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          trimmed.startsWith('• ')) {
        final recommendation = trimmed.substring(2).trim();
        if (recommendation.isNotEmpty) {
          widget.onRecommendationAdded(recommendation);
        }
      }
    }
  }

  void _onSend(ChatMessage message) {
    String trimmedText = message.text.trim();

    if (trimmedText.isEmpty) {
      return;
    }

    message = ChatMessage(
      user: message.user,
      createdAt: message.createdAt,
      text: trimmedText,
      medias: message.medias,
    );

    setState(() {
      messages = [message, ...messages];
    });

    try {
      String promptToSend =
          "$_systemInstruction\n\nCONSULTA USUARIO: $trimmedText";

      List<Uint8List>? images;
      if (message.medias != null && message.medias!.isNotEmpty) {
        images = [File(message.medias!.first.url).readAsBytesSync()];
      }

      gemini.streamGenerateContent(promptToSend, images: images).listen((
        event,
      ) {
        if (!mounted) return;
        ChatMessage? lastMessage = messages.firstOrNull;
        String response = event.output ?? "";

        if (response.isEmpty) return;

        response = response
            .replaceAll('*', '')
            .replaceAll('**', '')
            .replaceAll('_', '')
            .replaceAll('#', '')
            .replaceAll('"', '')
            .replaceAll('`', '')
            .replaceAll('##', '')
            .replaceAll('###', '')
            .trim();

        _parseAndSaveRecommendations(response);

        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          setState(() {
            messages = [
              ChatMessage(
                user: geminiUser,
                createdAt: DateTime.now(),
                text: response,
              ),
              ...messages,
            ];
          });
        }
      });
    } catch (e) {
      debugPrint("Error en chat: $e");
    }
  }

  Future<void> _sendMediaMessage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      _onSend(
        ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: "Adjunto imagen para análisis",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isChatActive) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => setState(() => _isChatActive = false),
          ),
          title: Text(
            "Dr. Zenith",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontFamily: 'Comic Sans MS',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: DashChat(
          currentUser: currentUser,
          onSend: _onSend,
          messages: messages,
          inputOptions: InputOptions(
            trailing: [
              IconButton(
                icon: const Icon(Icons.image, color: Color(0xFF66BB6A)),
                onPressed: _sendMediaMessage,
              ),
            ],
            inputDecoration: InputDecoration(
              hintText: "Escribe tu consulta...",
              hintStyle: TextStyle(
                fontFamily: 'Comic Sans MS',
                color: isDark ? Colors.grey[400] : Colors.grey,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            inputTextStyle: TextStyle(
              fontFamily: 'Comic Sans MS',
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          messageOptions: MessageOptions(
            currentUserContainerColor: const Color(0xFF66BB6A),
            containerColor:
                isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]!,
            textColor: isDark ? Colors.white : Colors.black87,
            messageTextBuilder: (message, previousMessage, nextMessage) {
              return Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'Comic Sans MS',
                  fontSize: 15,
                  color: message.user.id == currentUser.id
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              );
            },
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        HeaderWidget(
          title: "Consultor IA",
          subtitle: "Puntos Saludables: ${widget.currentPoints}",
        ),
        const SizedBox(height: 20),
        if (_currentQuestion != null && !_isLoadingQuiz)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors
                        .transparent // Sin borde en modo oscuro si el contraste es bueno
                    : const Color(0xFF66BB6A).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF66BB6A).withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Trivia Rápida",
                      style: TextStyle(
                        color: const Color(0xFF66BB6A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.timer, size: 16, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _currentQuestion!['question'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                ...List.generate(
                  (_currentQuestion!['options'] as List).length,
                  (index) {
                    String option = _currentQuestion!['options'][index];
                    bool isCorrect =
                        index == _currentQuestion!['correct_index'];

                    Color backgroundColor =
                        isDark ? const Color(0xFF2C2C2C) : Colors.white;
                    Color borderColor =
                        isDark ? const Color(0xFF424242) : Colors.grey.shade200;
                    IconData? icon;
                    Color iconColor = Colors.transparent;
                    TextStyle textStyle = TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    );

                    if (_hasAnswered) {
                      if (index == _selectedOptionIndex) {
                        if (isCorrect) {
                          backgroundColor = Colors.green;
                          borderColor = Colors.green;
                          icon = Icons.check_circle;
                          iconColor = Colors.white;
                          textStyle = const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          );
                        } else {
                          backgroundColor = Colors.redAccent;
                          borderColor = Colors.red;
                          icon = Icons.cancel;
                          iconColor = Colors.white;
                          textStyle = const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          );
                        }
                      } else if (isCorrect) {
                        backgroundColor = Colors.green.withOpacity(0.1);
                        borderColor = Colors.green;
                        icon = Icons.check_circle_outline;
                        iconColor = Colors.green;
                      }
                    }

                    return GestureDetector(
                      onTap: () => _handleQuizAnswer(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(option, style: textStyle)),
                            if (icon != null)
                              Icon(icon, color: iconColor, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF66BB6A)),
          ),
        const SizedBox(height: 30),
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _isChatActive = true;
                if (messages.isEmpty) {
                  messages.add(
                    ChatMessage(
                      user: geminiUser,
                      createdAt: DateTime.now(),
                      text:
                          "Hola ${currentUser.firstName}, soy el Dr. Zenith, tu asistente nutricional especializado en ${widget.userProfile['planType']}. En que puedo ayudarte hoy?",
                    ),
                  );
                }
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF66BB6A).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 50,
                    color: Colors.white,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Consultar al Dr. Zenith",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Comic Sans MS',
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Asistente nutricional especializado",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Comic Sans MS',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
