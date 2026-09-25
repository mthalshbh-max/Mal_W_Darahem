
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double balance = 0;
  double debts = 0;

  void addMoney() {
    setState(() {
      balance += 100;
    });
  }

  void addDebt() {
    setState(() {
      debts += 100;
    });
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
                leading: const Icon(Icons.account_balance_wallet, size: 40),
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
                leading: const Icon(Icons.money_off, size: 40),
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
          ],
        ),
      ),
    );
  }
}
