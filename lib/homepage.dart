import 'dart:core';
import 'package:finclcik/inverntory_screen.dart';
import 'package:finclcik/message_to_buyers.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytic_ai.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  int selectedIndex = 0;

  bool isLoading = true;

  double totalRevenue = 0;
  double profit = 0;
  double retention = 0;

  List<Map<String, dynamic>> salesOverTime = [];
  List<Map<String, dynamic>> products = [];

  static const Color bg = Color(0xFF0B0F14);
  static const Color card = Color(0xFF121A23);
  static const Color primary = Color(0xFF00F88A);

  @override
  void initState() {
    super.initState();
    fetchAndProcessData();
  }

  Future<void> fetchAndProcessData() async {
    try {
      final response = await supabase.from('sales').select();
      List data = response;

      if (data.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      totalRevenue = data.fold(0.0, (sum, item) {
        return sum + ((item['amount'] ?? 0) as num).toDouble();
      });

      profit = totalRevenue * 0.2;

      final buyers = data.map((e) => e['buyer']).toSet();
      retention = (data.length / buyers.length) * 100;
      if (retention > 100) retention = 100;

      Map<String, double> dailySales = {};

      for (var item in data) {
        String date = item['date'].toString().split("T")[0];
        double amount = ((item['amount'] ?? 0) as num).toDouble();
        dailySales[date] = (dailySales[date] ?? 0) + amount;
      }

      salesOverTime = dailySales.entries.map((e) {
        return {"date": e.key, "sales": e.value};
      }).toList();

      salesOverTime.sort((a, b) => a["date"].compareTo(b["date"]));

      Map<String, double> productMap = {};

      for (var item in data) {
        String name = item['product_name'] ?? "unknown";
        double amount = ((item['amount'] ?? 0) as num).toDouble();
        productMap[name] = (productMap[name] ?? 0) + amount;
      }

      products = productMap.entries.map((e) {
        return {"name": e.key, "growth": e.value};
      }).toList();

      products.sort((a, b) => b["growth"].compareTo(a["growth"]));

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<FlSpot> getChartSpots() {
    if (salesOverTime.isEmpty) {
      return [const FlSpot(0, 0)];
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < salesOverTime.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), salesOverTime[i]['sales']),
      );
    }
    return spots;
  }

  String format(double val) => val.toStringAsFixed(0);

  void onNavTap(int index) {
    setState(() => selectedIndex = index);

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MessageToBuyers()),
      );
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatBot()));
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InverntoryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Row(
          children: const [
            Text("FIN ",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            Text("CLICK",
                style: TextStyle(
                    color: primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// BUSINESS HEALTH
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("BUSINESS HEALTH",
                      style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 8),
                  Text(
                    "${retention.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: retention / 100,
                      backgroundColor: Colors.white10,
                      valueColor:
                      const AlwaysStoppedAnimation(primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// STATS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                statCard("Revenue", "₹${format(totalRevenue)}"),
                statCard("Profit", "₹${format(profit)}"),
                statCard("Retention", "${format(retention)}%"),
              ],
            ),

            const SizedBox(height: 25),

            /// CHART
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sales Over Time",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: getChartSpots(),
                            color: primary,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// PRODUCTS
            const Text(
              "Top Products",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length > 5 ? 5 : products.length,
              itemBuilder: (context, index) {
                var p = products[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory, color: primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p["name"],
                          style:
                          const TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        "₹${format(p["growth"])}",
                        style:
                        const TextStyle(color: Colors.white70),
                      )
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),

      /// 🔥 MODERN BOTTOM NAV BAR
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, 0),
            navItem(Icons.message, 1),
            navItem(Icons.auto_graph, 2),
            navItem(Icons.inventory_2, 3),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, int index) {
    bool isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive ? primary : Colors.white54,
        ),
      ),
    );
  }

  Widget statCard(String title, String value) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}