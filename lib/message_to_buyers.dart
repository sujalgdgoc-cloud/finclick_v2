import 'package:finclcik/analytic_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageToBuyers extends StatefulWidget {
  const MessageToBuyers({super.key});

  @override
  State<MessageToBuyers> createState() => _MessageToBuyersState();
}

final supabase = Supabase.instance.client;
final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: (dotenv.env['APIKEY'].toString()));


Future<String?> returnSmS() async {
  String promt = '''Write 1 re-engagement SMS for customers inactive for 30+ days.
  Constraints:
 - Max 160 characters
 - Friendly, not pushy
 - Mention: Visit Today
  - Offer: [OFFER] (optional)
  - Include 1 clear CTA (reply/call/visit)
  - No emojis, no hashtags
  - Output ONLY the SMS text (no quotes, no extra lines)''';
  final response = await model.generateContent(
    [Content.text(promt)]
  );
  final sms = response.text?.trim();
  print(sms);
  return sms;
}
Future<String?> returnGeneralStoreMessage() async {
  String promt = '''Write 1 general promotional message to ask people to check out my store.
Constraints:
- Max 200 characters
- Friendly and inviting tone
- Mention: check out the store today
- Include: [STORE_LINK]
- Include 1 clear CTA (visit now / explore now / check it out)
- No emojis, no hashtags
- Output ONLY the message text (no quotes, no extra lines)''';

  final response = await model.generateContent(
      [Content.text(promt)]
  );
  final message = response.text?.trim();
  print(message);
  return message;
}
Future<String> returnTable() async {
  final res = await supabase.from('sales').select('phone');
  final data = res.map((item) => item['phone']);
  final list = data.toList();
  final phones = list.map((n) => n.toString().trim()).join(",");
  return phones;
}

Future<Uri> SmsForOne() async {
  final phones = await returnDate();
  final body = await returnSmS();
  return Uri(
    scheme: 'sms',
    path: phones,
    queryParameters: {
      "body": body ?? "Gemini-error",
    },
  );
}

Future<Uri> SmsForAll() async {
  final phones = await returnTable();
  final body = await returnGeneralStoreMessage();
  return Uri(
    scheme: 'sms',
    path: phones,
    queryParameters: {"body": body?? "Gemini-error"},
  );
}

Future<String> returnDate() async {
  List inactivePhones = [];
  final res = await supabase.from('sales').select('phone, date');
  Map<String, dynamic> latestByPhone = {};

  for (var data in res) {
    String phone = data['phone'].toString();
    DateTime date = DateTime.parse(data['date']);

    if (!latestByPhone.containsKey(phone) ||
        date.isAfter(latestByPhone[phone]!)) {
      latestByPhone[phone] = date;
    }
  }

  DateTime cutoff = DateTime.now().subtract(const Duration(days: 30));

  latestByPhone.forEach((phone, lastDate) {
    if (lastDate.isBefore(cutoff)) {
      inactivePhones.add(phone);
    }
  });

  print(inactivePhones);
  final phones = inactivePhones.map((n) => n.toString().trim()).join(",");
  return phones;
}

Future<List> returnNames() async {
  List inactiveCustomers = [];
  final res = await supabase.from('sales').select('buyer, date');
  Map<String, dynamic> lastestbyName = {};

  for (var data in res) {
    String name = data['buyer'].toString();
    DateTime date = DateTime.parse(data['date']);

    if (!lastestbyName.containsKey(name) ||
        date.isAfter(lastestbyName[name]!)) {
      lastestbyName[name] = date;
    }
  }

  DateTime cutoff = DateTime.now().subtract(const Duration(days: 30));

  lastestbyName.forEach((name, lastDate) {
    if (lastDate.isBefore(cutoff)) {
      inactiveCustomers.add(name);
    }
  });

  return inactiveCustomers;
}

// ===== UI =====

class _MessageToBuyersState extends State<MessageToBuyers> {
  static const Color bg = Color(0xFF0B0F14);
  static const Color card = Color(0xFF121A23);
  static const Color primary = Color(0xFF00F88A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: const [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text(
              "FIN CLICK",
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatBot()));
          }, icon: Icon(Icons.chat))
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.flash_on, color: primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "AI PRIORITY",
                        style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Reach inactive customers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Detect users inactive for 30+ days and send offers.",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final uri = await SmsForOne();
                        await launchUrl(uri);
                        returnDate();
                      },
                      child: const Text("REACH OUT"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  SmsForAll();
                },
                child: const Text(
                  "Reach out to all Customers",
                  style: TextStyle(color: primary),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "INACTIVE CUSTOMERS",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: FutureBuilder(
                future: returnNames(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final name = data[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey,
                              child: Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
