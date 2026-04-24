import 'dart:core';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InverntoryScreen extends StatefulWidget {
  const InverntoryScreen({super.key});

  @override
  State<InverntoryScreen> createState() => _InverntoryScreenState();
}

class _InverntoryScreenState extends State<InverntoryScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> sales = [];
  Map<String, int> prodTotal = {};

  String mostSeller = "";
  String leastSeller = "";

  static const Color bg = Color(0xFF0B0F14);
  static const Color card = Color(0xFF121A23);
  static const Color primary = Color(0xFF00F88A);

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  void fetchInventory() async {
    final response =
    await supabase.from('sales').select('product_name, quantity');

    final data = List<Map<String, dynamic>>.from(response);
    sales = data;

    prodTotal.clear();

    for (final row in sales) {
      final name = (row['product_name'] ?? 'Unknown').toString();
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;

      prodTotal[name] = (prodTotal[name] ?? 0) + qty;
    }

    final sellers = prodTotal.entries.toList();

    if (sellers.isNotEmpty) {
      sellers.sort((a, b) => b.value.compareTo(a.value));

      mostSeller = "${sellers.first.key} (${sellers.first.value})";
      leastSeller = "${sellers.last.key} (${sellers.last.value})";
    }

    setState(() => isLoading = false);
  }

  int get maxValue {
    if (prodTotal.isEmpty) return 1;
    return prodTotal.values.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: bg,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          /// 🔥 HEADER (SaaS Style)
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: const BoxDecoration(
              color: card,
              border: Border(
                bottom: BorderSide(color: Colors.white10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Inventory Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Track product performance & stock flow",
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// KPI CARDS
                  Row(
                    children: [
                      kpiCard("🔥 Most Selling", mostSeller),
                      const SizedBox(width: 12),
                      kpiCard("⚠️ Least Selling", leastSeller),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// SECTION TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Product Insights",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// PRODUCT LIST
                  Expanded(
                    child: ListView.builder(
                      itemCount: prodTotal.length,
                      itemBuilder: (context, index) {
                        final key =
                        prodTotal.keys.elementAt(index);
                        final value = prodTotal[key]!;

                        double progress = value / maxValue;

                        return Container(
                          margin:
                          const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius:
                            BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              /// TITLE ROW
                              Row(
                                children: [
                                  const Icon(Icons.inventory,
                                      color: primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      key,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                          FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    value.toString(),
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// PROGRESS BAR
                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor:
                                  Colors.white10,
                                  valueColor:
                                  const AlwaysStoppedAnimation(
                                      primary),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget kpiCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}