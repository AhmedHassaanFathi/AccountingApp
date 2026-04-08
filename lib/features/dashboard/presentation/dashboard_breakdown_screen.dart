import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardBreakdownScreen extends StatelessWidget {
  final String title;
  final Map<String, double> data;

  const DashboardBreakdownScreen({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    double total = 0;
    for (final amount in data.values) {
      total += amount;
    }

    final sortedKeys = data.keys.toList()..sort((a, b) => data[b]!.compareTo(data[a]!));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: data.isEmpty 
          ? const Center(child: Text('لا توجد بيانات لهذه الفترة', style: TextStyle(fontSize: 18)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final name = sortedKeys[index];
                      final amount = data[name]!;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          trailing: Text(currency.format(amount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(currency.format(total), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
