import 'package:flutter/material.dart';

void main() {
  runApp(const MalWDarahemApp());
}

class MalWDarahemApp extends StatelessWidget {
  const MalWDarahemApp({super.key});

  static const emerald = Color(0xFF0F8B5F);
  static const gold = Color(0xFFD9A441);
  static const navy = Color(0xFF102A43);
  static const red = Color(0xFFD64545);
  static const blue = Color(0xFF2878D4);
  static const lightGray = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مال ودراهم',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: emerald,
          primary: emerald,
          secondary: gold,
        ),
        scaffoldBackgroundColor: lightGray,
        appBarTheme: const AppBarTheme(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: emerald,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
  static const emerald = Color(0xFF0F8B5F);
  static const gold = Color(0xFFD9A441);
  static const navy = Color(0xFF102A43);
  static const red = Color(0xFFD64545);
  static const blue = Color(0xFF2878D4);

  double balance = 0;
  double debts = 0;

  Color backgroundTint = Colors.white;
  bool darkMode = false;

  final List<Transaction> transactions = [];

  void showBackgroundColorPicker() {
    final colors = [
      Colors.white,
      const Color(0xFFF4F6F8),
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFFFF8E1),
      const Color(0xFFF3E5F5),
      const Color(0xFFECEFF1),
      const Color(0xFFE0F2F1),
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'مظهر التطبيق',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          backgroundTint = color;
                          darkMode = false;
                        });
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: color,
                        child: backgroundTint == color
                            ? const Icon(
                                Icons.check,
                                color: navy,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  value: darkMode,
                  onChanged: (value) {
                    setState(() => darkMode = value);
                    Navigator.pop(context);
                  },
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('الوضع الداكن'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<double?> askAmount(
    String title, {
    double? initialValue,
  }) async {
    final controller = TextEditingController(
      text: initialValue == null ? '' : initialValue.toString(),
    );

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'المبلغ',
            prefixIcon: Icon(Icons.attach_money),
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
            ),
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
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: blue),
              title: const Text('تعديل العملية'),
              onTap: () {
                Navigator.pop(context);
                editTransaction(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: red),
              title: const Text('حذف العملية'),
              onTap: () {
                Navigator.pop(context);
                deleteTransaction(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget moneyCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foreground = darkMode ? Colors.white : navy;
    final pageBackground =
        darkMode ? const Color(0xFF0B1724) : backgroundTint;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: darkMode ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: pageBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: emerald,
            brightness: darkMode ? Brightness.dark : Brightness.light,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  width: 42,
                  height: 42,
                  errorBuilder: (context, error, stackTrace) {
                    return const Image.asset('assets/images/app_icon.png', width: 34, height: 34);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'مال ودراهم',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'المظهر',
                icon: const Icon(Icons.palette_outlined),
                onPressed: showBackgroundColorPicker,
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/app_background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: pageBackground.withOpacity(
                    darkMode ? 0.82 : 0.35,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'إدارة أموالك بسهولة',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: foreground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'تابع أموالك وديونك في مكان واحد',
                          style: TextStyle(
                            fontSize: 14,
                            color: foreground.withOpacity(0.70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      moneyCard(
                        title: 'الرصيد الحالي',
                        value: balance.toStringAsFixed(2),
                        icon: Icons.account_balance_wallet,
                        color: emerald,
                      ),
                      moneyCard(
                        title: 'إجمالي الديون',
                        value: debts.toStringAsFixed(2),
                        icon: Icons.receipt_long,
                        color: red,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: addMoney,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('إضافة مال'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: navy,
                              ),
                              onPressed: addDebt,
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('إضافة دين'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'سجل العمليات',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: foreground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: transactions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 55,
                                      color: foreground.withOpacity(0.35),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'لا توجد عمليات حتى الآن',
                                      style: TextStyle(
                                        color: foreground.withOpacity(0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction =
                                      transactions[index];
                                  final isMoney =
                                      transaction.type == 'إضافة مال';

                                  return Card(
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            (isMoney ? emerald : red)
                                                .withOpacity(0.12),
                                        child: Icon(
                                          isMoney
                                              ? Icons.add_circle
                                              : Icons.receipt_long,
                                          color:
                                              isMoney ? emerald : red,
                                        ),
                                      ),
                                      title: Text(
                                        transaction.type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        formatDate(transaction.date),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            transaction.amount
                                                .toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isMoney
                                                  ? emerald
                                                  : red,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.more_vert,
                                            ),
                                            onPressed: () =>
                                                showTransactionOptions(
                                              index,
                                            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
