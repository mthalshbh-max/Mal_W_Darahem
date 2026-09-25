import 'package:flutter/material.dart';

void main() {
  runApp(const MalWDarahemApp());
}

class MalWDarahemApp extends StatelessWidget {
  const MalWDarahemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مال ودراهم',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Transaction {
  final String type;
  final double amount;
  final DateTime date;

  Transaction({
    required this.type,
    required this.amount,
    required this.date,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double balance = 0;
  double debts = 0;

  final List<Transaction> transactions = [];

  void addMoney() async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مال'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'المبلغ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (amount != null) {
      setState(() {
        balance += amount;
        transactions.insert(
          0,
          Transaction(
            type: 'إضافة مال',
            amount: amount,
            date: DateTime.now(),
          ),
        );
      });
    }
  }

  void addDebt() async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دين'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'المبلغ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (amount != null) {
      setState(() {
        debts += amount;
        transactions.insert(
          0,
          Transaction(
            type: 'إضافة دين',
            amount: amount,
            date: DateTime.now(),
          ),
        );
      });
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مال ودراهم'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'إدارة أموالك بسهولة',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('الرصيد'),
                subtitle: Text(
                  balance.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.money_off),
                title: const Text('الديون'),
                subtitle: Text(
                  debts.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addMoney,
                icon: const Icon(Icons.add),
                label: const Text('إضافة مال'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: addDebt,
                icon: const Icon(Icons.receipt_long),
                label: const Text('إضافة دين'),
              ),
            ),
            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'سجل العمليات',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                      child: Text('لا توجد عمليات حتى الآن'),
                    )
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              transaction.type == 'إضافة مال'
                                  ? Icons.add_circle
                                  : Icons.receipt_long,
                            ),
                            title: Text(transaction.type),
                            subtitle: Text(formatDate(transaction.date)),
                            trailing: Text(
                              transaction.amount.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
