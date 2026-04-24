import 'package:finclcik/homepage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');
  await Supabase.initialize(
    url: "https://dkxvoneldkoletwpuqfu.supabase.co",
    anonKey: "sb_publishable_QeTE3yDBWE-ol4cRwVHIwQ_5TuVhpAl",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const UploadCSV(),
    );
  }
}

class UploadCSV extends StatefulWidget {
  const UploadCSV({super.key});

  @override
  State<UploadCSV> createState() => _UploadCSVState();
}

class _UploadCSVState extends State<UploadCSV> {
  bool isLoading = false;

  Future<PlatformFile?> pickCSVFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) return result.files.first;
    return null;
  }

  Future<void> uploadToBackend(PlatformFile file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:8000/upload/'),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ),
    );

    var response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Upload successful")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Upload failed")),
      );
    }

    print(resBody);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),

      // 🔥 APP BAR (LIKE YOUR DESIGN)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: "FIN ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextSpan(
                text: "CLICK",
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.trending_up, color: Colors.grey),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 HEADER TEXT
            const Text(
              "Upload Sales Data",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Upload your CSV to analyze revenue, trends and product performance.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // 📂 UPLOAD CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.upload_file,
                      size: 50, color: Color(0xFF00FF88)),

                  const SizedBox(height: 10),

                  const Text(
                    "Upload CSV File",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF88),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                      setState(() => isLoading = true);

                      final file = await pickCSVFile();

                      if (file != null) {
                        await uploadToBackend(file);
                      }

                      setState(() => isLoading = false);
                    },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("Select & Upload"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 📊 DASHBOARD BUTTON
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00FF88), Color(0xFF2A874D)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomePage()),
                  );
                },
                icon: const Icon(Icons.analytics, color: Colors.black),
                label: const Text(
                  "Open Dashboard",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}