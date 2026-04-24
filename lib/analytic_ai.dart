import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final TextEditingController controller = TextEditingController();
  final supabase = Supabase.instance.client;

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: dotenv.env['APIKEY'].toString(),
    generationConfig: GenerationConfig(responseMimeType: "application/json"),
  );

  static const Color bg = Color(0xFF0B0F14);
  static const Color card = Color(0xFF121A23);
  static const Color primary = Color(0xFF00F88A);
  static const Color secondary = Color(0xFF2A874D);

  Map<String, dynamic> buildSnapshot(List orders) {
    double totalRevenue = 0;
    int totalUnits = 0;
    Map<String, int> productSales = {};

    for (var item in orders) {
      totalRevenue += (item['amount'] as num).toDouble();
      totalUnits += (item['quantity'] as num).toInt();

      String name = item['product_name'];
      productSales[name] =
          (productSales[name] ?? 0) + (item['quantity'] as num).toInt();
    }

    var sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      "total_revenue": totalRevenue,
      "total_units": totalUnits,
      "top_products": sorted
          .take(5)
          .map((e) => {"name": e.key, "units": e.value})
          .toList(),
    };
  }

  String buildPrompt(String userMessage, Map snapshot) {
    return """
You are a retail AI assistant.

Use ONLY this data:
${jsonEncode(snapshot)}

User question:
$userMessage

Return JSON:
{
  "insight": "...",
  "why_it_matters": "...",
  "action_plan": ["...", "..."],
  "follow_up_questions": ["...", "..."]
}
""";
  }

  Future<void> sendMessage() async {
    String userText = controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": userText});
      isLoading = true;
    });

    controller.clear();

    try {
      final res = await supabase.from('sales').select();
      final snapshot = buildSnapshot(res);
      final prompt = buildPrompt(userText, snapshot);
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "{}";

      Map<String, dynamic> aiData;

      try {
        aiData = jsonDecode(text);
      } catch (e) {
        aiData = {"insight": text};
      }

      String formatted =
          "${aiData["insight"] ?? ""}\n\n${aiData["why_it_matters"] ?? ""}\n\n${(aiData["action_plan"] as List?)?.join("\n") ?? ""}";

      setState(() {
        messages.add({"role": "ai", "text": formatted});
      });
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "text": "Error: $e"});
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget messageBubble(Map<String, String> msg) {
    bool isUser = msg["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? primary : card,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: Colors.white10),
        ),
        child: Text(
          msg["text"] ?? "",
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget inputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask about your business...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: bg,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.send, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(Icons.auto_graph, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            "AI SALES ASSISTANT",
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget typingLoader() {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            header(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return messageBubble(messages[index]);
                },
              ),
            ),
            if (isLoading) typingLoader(),
            inputBar(),
          ],
        ),
      ),
    );
  }
}