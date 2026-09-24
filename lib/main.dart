import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MalWDarahemApp());

class MalWDarahemApp extends StatefulWidget {
  const MalWDarahemApp({super.key});
  @override
  State<MalWDarahemApp> createState() => _MalWDarahemAppState();
}

class _MalWDarahemAppState extends State<MalWDarahemApp> {
  bool dark = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'مال ودراهم',
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
    darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
    home: HomePage(onToggleTheme: () => setState(() => dark = !dark)),
  );
}

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomePage({super.key, required this.onToggleTheme});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String currency = 'جنيه مصري';
  double income = 0, expense = 0;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> debts = [];
  List<Map<String, dynamic>> goals = [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      currency = p.getString('currency') ?? 'جنيه مصري';
      income = p.getDouble('income') ?? 0;
      expense = p.getDouble('expense') ?? 0;
      transactions = List<Map<String,dynamic>>.from(
        (jsonDecode(p.getString('transactions') ?? '[]') as List).map((e)=>Map<String,dynamic>.from(e)));
      debts = List<Map<String,dynamic>>.from(
        (jsonDecode(p.getString('debts') ?? '[]') as List).map((e)=>Map<String,dynamic>.from(e)));
      goals = List<Map<String,dynamic>>.from(
        (jsonDecode(p.getString('goals') ?? '[]') as List).map((e)=>Map<String,dynamic>.from(e)));
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('currency', currency);
    await p.setDouble('income', income);
    await p.setDouble('expense', expense);
    await p.setString('transactions', jsonEncode(transactions));
    await p.setString('debts', jsonEncode(debts));
    await p.setString('goals', jsonEncode(goals));
  }

  double get balance => income - expense;
  String money(num n) => '${n.toStringAsFixed(2)} $currency';

  void addTransaction() {
    final amount = TextEditingController();
    final note = TextEditingController();
    bool isIncome = true;
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (c, setD) => AlertDialog(
      title: const Text('إضافة معاملة'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<bool>(segments: const [
          ButtonSegment(value: true, label: Text('دخل')),
          ButtonSegment(value: false, label: Text('مصروف')),
        ], selected: {isIncome}, onSelectionChanged: (s)=>setD(()=>isIncome=s.first)),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'الوصف')),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final v = double.tryParse(amount.text) ?? 0;
          if (v <= 0) return;
          setState(() {
            if (isIncome) income += v; else expense += v;
            transactions.insert(0, {'amount': v, 'income': isIncome, 'note': note.text, 'date': DateTime.now().toIso8601String()});
          });
          save(); Navigator.pop(c);
        }, child: const Text('حفظ')),
      ],
    )));
  }

  void addDebt() {
    final person = TextEditingController(), amount = TextEditingController();
    final date = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('إضافة دين'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: person, decoration: const InputDecoration(labelText: 'اسم الشخص')),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
        TextField(controller: date, decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق')),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final v = double.tryParse(amount.text) ?? 0;
          if (person.text.trim().isEmpty || v <= 0) return;
          setState(()=>debts.insert(0, {'person':person.text.trim(),'amount':v,'date':date.text,'paid':false}));
          save(); Navigator.pop(context);
        }, child: const Text('حفظ')),
      ],
    ));
  }

  void addGoal() {
    final name = TextEditingController(), target = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('هدف ادخار'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الهدف')),
        TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المستهدف')),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () {
          final v = double.tryParse(target.text) ?? 0;
          if (name.text.trim().isEmpty || v <= 0) return;
          setState(()=>goals.insert(0, {'name':name.text.trim(),'target':v,'saved':0.0}));
          save(); Navigator.pop(context);
        }, child: const Text('حفظ')),
      ],
    ));
  }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const Text('الرصيد الحالي', style: TextStyle(fontSize: 18)),
      const SizedBox(height: 8),
      Text(money(balance), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
    ]))),
    Row(children: [
      Expanded(child: Card(child: ListTile(title: const Text('الدخل'), subtitle: Text(money(income))))),
      Expanded(child: Card(child: ListTile(title: const Text('المصروف'), subtitle: Text(money(expense)))),
    ]),
    const SizedBox(height: 8),
    FilledButton.icon(onPressed: addTransaction, icon: const Icon(Icons.add), label: const Text('إضافة دخل / مصروف')),
    const SizedBox(height: 12),
    const Text('آخر المعاملات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    ...transactions.take(8).map((t) => ListTile(
      leading: CircleAvatar(child: Icon(t['income'] == true ? Icons.arrow_downward : Icons.arrow_upward)),
      title: Text(t['note']?.toString().isEmpty == true ? 'معاملة' : t['note'].toString()),
      subtitle: Text(DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.parse(t['date']))),
      trailing: Text('${t['income'] == true ? '+' : '-'}${money(t['amount'])}'),
    )),
  ]);

  Widget debtsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    FilledButton.icon(onPressed: addDebt, icon: const Icon(Icons.person_add), label: const Text('إضافة دين')),
    const SizedBox(height: 10),
    ...debts.map((d) => Card(child: ListTile(
      leading: const Icon(Icons.account_balance_wallet),
      title: Text(d['person'].toString()),
      subtitle: Text('الاستحقاق: ${d['date'].toString()}'),
      trailing: Text(money(d['amount'])),
    ))),
    if (debts.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد ديون مسجلة'))),
  ]);

  Widget goalsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    FilledButton.icon(onPressed: addGoal, icon: const Icon(Icons.savings), label: const Text('إضافة هدف ادخار')),
    ...goals.map((g) {
      final target = (g['target'] as num).toDouble(), saved = (g['saved'] as num).toDouble();
      return Card(child: ListTile(title: Text(g['name'].toString()), subtitle: LinearProgressIndicator(value: (saved/target).clamp(0,1)), trailing: Text(money(target))));
    }),
    if (goals.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد أهداف ادخار'))),
  ]);

  @override
  Widget build(BuildContext context) {
    final pages = [dashboard(), debtsPage(), goalsPage()];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('مال ودراهم'), actions: [
        PopupMenuButton<String>(onSelected: (v) { if (v == 'theme') widget.onToggleTheme(); if (v == 'currency') showCurrency(); }, itemBuilder: (_) => const [
          PopupMenuItem(value: 'currency', child: Text('العملة')),
          PopupMenuItem(value: 'theme', child: Text('الوضع الداكن / الفاتح')),
        ]),
      ]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i)=>setState(()=>tab=i), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'الديون'),
        NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'الادخار'),
      ]),
    ));
  }

  void showCurrency() {
    final currencies = ['جنيه مصري','ريال سعودي','درهم إماراتي','دينار كويتي','دولار أمريكي','يورو'];
    showDialog(context: context, builder: (_) => SimpleDialog(title: const Text('اختر العملة'), children: currencies.map((c)=>SimpleDialogOption(
      onPressed: () { setState(()=>currency=c); save(); Navigator.pop(context); },
      child: Text(c),
    )).toList()));
  }
}
