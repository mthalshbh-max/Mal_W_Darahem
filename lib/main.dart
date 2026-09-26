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
  String type;
  double amount;
  DateTime date;

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

  Future<double?> askAmount(String title, {double? initialValue}) async {
    final controller = TextEditingController(
      text: initialValue == null ? '' : initialValue.toString(),
    );

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void addMoney() async {
    final amount = await askAmount('إضافة مال');

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
    final amount = await askAmount('إضافة دين');

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

  void deleteTransaction(int index) {
    final transaction = transactions[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العملية'),
        content: const Text('هل تريد حذف هذه العملية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (transaction.type == 'إضافة مال') {
                  balance -= transaction.amount;
                } else {
                  debts -= transaction.amount;
                }

                transactions.removeAt(index);

                if (balance < 0) balance = 0;
                if (debts < 0) debts = 0;
              });

              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void editTransaction(int index) async {
    final transaction = transactions[index];

    final newAmount = await askAmount(
      'تعديل العملية',
      initialValue: transaction.amount,
    );

    if (newAmount != null) {
      setState(() {
        if (transaction.type == 'إضافة مال') {
          balance = balance - transaction.amount + newAmount;
        } else {
          debts = debts - transaction.amount + newAmount;
        }

        transaction.amount = newAmount;
        transaction.date = DateTime.now();
      });
    }
  }

  void showTransactionOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل العملية'),
              onTap: () {
                Navigator.pop(context);
                editTransaction(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('حذف العملية'),
              onTap: () {
                Navigator.pop(context);
                deleteTransaction(index);
              },
            ),
          ],
        ),
      ),
    );
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  transaction.amount.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () =>
                                      showTransactionOptions(index),
                                ),
                              ],
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
