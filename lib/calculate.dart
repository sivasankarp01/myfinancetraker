import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class Calculate extends StatefulWidget {
  final String id;    // box name
  final String title; // category name

  const Calculate({super.key, required this.id, required this.title});

  @override
  State<Calculate> createState() => _CalculateState();
}

class _CalculateState extends State<Calculate> {
  Box? itemsBox; // nullable until opened

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    itemsBox = await Hive.openBox(widget.id);
    setState(() {});
  }

  String _generateId() {
    final random = Random();
    return List.generate(10, (_) => random.nextInt(10).toString()).join();
  }

  void _addItem(String title, double amount) {
    final newItem = {
      'id': _generateId(),
      'title': title,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    };
    itemsBox?.add(newItem);
    setState(() {});
  }

  void _editItem(int index, String title, double amount) {
    final existing = itemsBox?.getAt(index);
    final updatedItem = {
      'id': existing?['id'] ?? _generateId(),
      'title': title,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    };
    itemsBox?.putAt(index, updatedItem);
    setState(() {});
  }

  void _deleteItem(int index) {
    if (index < (itemsBox?.length ?? 0)) {
      itemsBox?.deleteAt(index);
      setState(() {});
    }
  }

  void _showAddEditDialog({int? index}) {
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();

    if (index != null && index < (itemsBox?.length ?? 0)) {
      final item = itemsBox?.getAt(index);
      titleCtrl.text = item?['title'] ?? '';
      amountCtrl.text = (item?['amount'] ?? '').toString();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? "Add Item" : "Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              if (title.isNotEmpty && amount > 0) {
                if (index == null) {
                  _addItem(title, amount);
                } else {
                  _editItem(index, title, amount);
                }
              }
              Navigator.pop(context);
            },
            child: Text(index == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  double _getTotalAmount() {
    double total = 0;
    for (var item in itemsBox?.values ?? []) {
      total += (item?['amount'] ?? 0).toDouble();
    }
    return total;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Unknown";
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
    } catch (_) {
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (itemsBox == null) {
      // box not yet opened
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = itemsBox!.values.toList().reversed.toList(); // latest first

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Total: ${_getTotalAmount().toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                "No items yet. Tap + to add something!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final realIndex = itemsBox!.length - 1 - index;
                final item = items[index] ?? {};
                final title = item['title'] ?? "Untitled";
                final amount = NumberFormat.currency(
                  locale: "en_IN",
                  symbol: "₹",
                ).format(item['amount'] ?? 0);
                final createdAt = _formatDate(item['created_at']);

                return Dismissible(
                  key: Key(item['id']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteItem(realIndex),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    child: ListTile(
                     leading: const Icon(color: Colors.green, Icons.currency_rupee_sharp),
                      title: Text(title),
                      subtitle: Text("Amount: $amount\n$createdAt"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showAddEditDialog(index: realIndex),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(realIndex),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
