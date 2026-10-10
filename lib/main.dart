import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class Customer {
  String name;
  String phone;
  String country;
  String currency;

  Customer({
    this.name = '',
    this.phone = '',
    this.country = '',
    this.currency = '',
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "phone": phone,
    "country": country,
    "currency": currency,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    name: json["name"] as String? ?? '',
    phone: json["phone"] as String? ?? '',
    country: json["country"] as String? ?? '',
    currency: json["currency"] as String? ?? '',
  );
}

class Wallet {
  Map<String, dynamic> toJson() => {
    "name": name,
    "country": country,
    "currency": currency,
    "flag": flag,
    "balance": balance,
    "customerPhone": customerPhone,
  };

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    name: json["name"] as String,
    country: json["country"] as String,
    currency: json["currency"] as String,
    flag: json["flag"] as String,
    balance: (json["balance"] as num?)?.toDouble() ?? 0,
    customerPhone: json["customerPhone"] as String? ?? '',
  );

  String name;
  String country;
  String currency;
  String flag;
  double balance;
  String customerPhone;

  Wallet({
    required this.name,
    required this.country,
    required this.currency,
    required this.flag,
    this.balance = 0,
    this.customerPhone = '',
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeAppData();
  }

  Future<void> _initializeAppData() async {
    await _loadWalletSecurity();
    await _loadCustomer();
    await _loadWallets();
    await _loadTransactions();
  }

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
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
  final List<Wallet> wallets = [];
  Customer customer = Customer();
  bool _walletsUnlocked = false;
  bool _hasWalletPin = false;



  Future<void> _loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("customer");

    if (saved == null || saved.isEmpty) return;

    final loaded =
        Customer.fromJson(jsonDecode(saved) as Map<String, dynamic>);

    if (!mounted) return;

    setState(() {
      customer = loaded;
    });
  }

  Future<void> _saveCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "customer",
      jsonEncode(customer.toJson()),
    );
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList("transactions");

    if (saved == null) return;

    final loaded = <Transaction>[];

    for (final item in saved) {
      try {
        final json = jsonDecode(item) as Map<String, dynamic>;

        loaded.add(
          Transaction(
            type: json["type"] as String? ?? '',
            amount: (json["amount"] as num?)?.toDouble() ?? 0,
            date: DateTime.tryParse(
                  json["date"] as String? ?? '',
                ) ??
                DateTime.now(),
          ),
        );
      } catch (_) {
        // تجاهل أي معاملة قديمة غير صالحة بدل تعطيل التطبيق.
      }
    }

    if (!mounted) return;

    setState(() {
      transactions
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = transactions
        .map(
          (transaction) => jsonEncode({
            "type": transaction.type,
            "amount": transaction.amount,
            "date": transaction.date.toIso8601String(),
          }),
        )
        .toList();

    await prefs.setStringList("transactions", saved);
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList("wallets");
    if (saved == null) return;
    final loaded = saved.map((item) {
      return Wallet.fromJson(jsonDecode(item) as Map<String, dynamic>);
    }).toList();

    if (customer.phone.isNotEmpty) {
      for (final wallet in loaded) {
        if (wallet.customerPhone.isEmpty) {
          wallet.customerPhone = customer.phone;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      wallets
        ..clear()
        ..addAll(loaded);
    });

    await _saveWallets();
  }

  Future<void> _saveWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = wallets
        .map((wallet) => jsonEncode(wallet.toJson()))
        .toList();
    await prefs.setStringList("wallets", saved);
  }


  Future<void> _loadWalletSecurity() async {
    final hash = await _secureStorage.read(key: 'wallet_pin_hash');
    final salt = await _secureStorage.read(key: 'wallet_pin_salt');

    if (!mounted) return;
    setState(() {
      _hasWalletPin =
          hash != null &&
          hash.isNotEmpty &&
          salt != null &&
          salt.isNotEmpty;
    });
  }

  String _hashWalletPin(String pin, String salt) {
    return sha256.convert(
      utf8.encode('$salt:$pin'),
    ).toString();
  }

  String _generateWalletSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );
    return base64UrlEncode(bytes);
  }

  Future<void> _saveWalletPin(String pin) async {
    final salt = _generateWalletSalt();
    final hash = _hashWalletPin(pin, salt);

    await _secureStorage.write(
      key: 'wallet_pin_salt',
      value: salt,
    );
    await _secureStorage.write(
      key: 'wallet_pin_hash',
      value: hash,
    );

    if (!mounted) return;
    setState(() {
      _hasWalletPin = true;
      _walletsUnlocked = true;
    });
  }

  Future<bool> _verifyWalletPin(String pin) async {
    final salt = await _secureStorage.read(
      key: 'wallet_pin_salt',
    );
    final savedHash = await _secureStorage.read(
      key: 'wallet_pin_hash',
    );

    if (salt == null || savedHash == null) {
      return false;
    }

    return _hashWalletPin(pin, salt) == savedHash;
  }


  void showCustomerData() {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final countryController = TextEditingController(text: customer.country);
    final currencyController = TextEditingController(text: customer.currency);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('بيانات العميل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل',
                    hintText: 'مثال: محمود',
                  ),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: 'مثال: 01xxxxxxxxx',
                  ),
                ),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    labelText: 'الدولة',
                    hintText: 'مثال: مصر',
                  ),
                ),
                TextField(
                  controller: currencyController,
                  decoration: const InputDecoration(
                    labelText: 'العملة الأساسية',
                    hintText: 'مثال: EGP',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final country = countryController.text.trim();
                final currency =
                    currencyController.text.trim().toUpperCase();

                if (name.isEmpty ||
                    phone.isEmpty ||
                    country.isEmpty ||
                    currency.isEmpty) {
                  return;
                }

                setState(() {
                  customer = Customer(
                    name: name,
                    phone: phone,
                    country: country,
                    currency: currency,
                  );
                });

                await _saveCustomer();

                if (!mounted) return;
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _ensureWalletUnlocked() async {
    if (_walletsUnlocked) return true;

    // اقرأ إعدادات الحماية قبل عرض إنشاء رمز جديد.
    try {
      await _loadWalletSecurity();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّرت قراءة إعدادات حماية المحافظ. حاول مجددًا.'),
          ),
        );
      }
      return false;
    }

    if (!mounted) return false;

    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;
    int attempts = 0;

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(
                  _hasWalletPin
                      ? 'فتح المحافظ'
                      : 'إنشاء رمز حماية للمحافظ',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _hasWalletPin
                            ? 'أدخل رمز الحماية المكوّن من 6 أرقام.'
                            : 'أنشئ رمزًا من 6 أرقام لحماية محافظك.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'رمز الحماية',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (!_hasWalletPin)
                        TextField(
                          controller: confirmController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'تأكيد رمز الحماية',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final pin = pinController.text.trim();

                      if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
                        setDialogState(() {
                          errorMessage = 'أدخل 6 أرقام صحيحة.';
                        });
                        return;
                      }

                      try {
                        if (!_hasWalletPin) {
                          if (confirmController.text.trim() != pin) {
                            setDialogState(() {
                              errorMessage = 'الرمزان غير متطابقين.';
                            });
                            return;
                          }

                          await _saveWalletPin(pin);
                          if (!mounted) return;
                          Navigator.of(dialogContext).pop(true);
                          return;
                        }

                        final valid = await _verifyWalletPin(pin);

                        if (valid) {
                          if (!mounted) return;
                          setState(() {
                            _walletsUnlocked = true;
                          });
                          Navigator.of(dialogContext).pop(true);
                        } else {
                          attempts++;
                          if (attempts >= 5) {
                            Navigator.of(dialogContext).pop(false);
                          } else {
                            setDialogState(() {
                              errorMessage =
                                  'الرمز غير صحيح. المحاولة '
                                  '$attempts من 5.';
                            });
                          }
                        }
                      } catch (_) {
                        setDialogState(() {
                          errorMessage =
                              'تعذّر التحقق من الرمز. حاول مرة أخرى.';
                        });
                      }
                    },
                    child: Text(
                      _hasWalletPin ? 'فتح' : 'حفظ الرمز',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      return result == true && _walletsUnlocked;
    } finally {
      pinController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> showWithdrawDialog(Wallet wallet) async {
    if (!_walletsUnlocked && !(await _ensureWalletUnlocked())) return;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('سحب من ${wallet.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'مبلغ السحب',
              suffixText: wallet.currency,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final amount = double.tryParse(
                  amountController.text.trim().replaceAll(',', '.'),
                );

                if (amount == null || amount <= 0) {
                  return;
                }

                if (amount > wallet.balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الرصيد غير كافٍ لإتمام عملية السحب'),
                    ),
                  );
                  return;
                }

                setState(() {
                  wallet.balance -= amount;

                  transactions.insert(
                    0,
                    Transaction(
                      type: 'سحب من ${wallet.name} - ${wallet.currency}',
                      amount: amount,
                      date: DateTime.now(),
                    ),
                  );
                });

                await _saveWallets();
                await _saveTransactions();

                if (!mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم سحب ${amount.toStringAsFixed(2)} ${wallet.currency}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.remove),
              label: const Text('سحب'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showDepositDialog(Wallet wallet) async {
    if (!_walletsUnlocked && !(await _ensureWalletUnlocked())) return;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('إيداع في ${wallet.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'مبلغ الإيداع',
              suffixText: wallet.currency,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final amount = double.tryParse(
                  amountController.text.trim().replaceAll(',', '.'),
                );

                if (amount == null || amount <= 0) {
                  return;
                }

                setState(() {
                  wallet.balance += amount;

                  transactions.insert(
                    0,
                    Transaction(
                      type: 'إيداع في ${wallet.name} - ${wallet.currency}',
                      amount: amount,
                      date: DateTime.now(),
                    ),
                  );
                });

                await _saveWallets();
                await _saveTransactions();

                if (!mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم إيداع ${amount.toStringAsFixed(2)} ${wallet.currency}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('إيداع'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showPersonTransferDialog() async {
    if (!_walletsUnlocked && !(await _ensureWalletUnlocked())) return;
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف محفظة أولًا لإجراء التحويل'),
        ),
      );
      return;
    }

    Wallet sourceWallet = wallets.first;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تحويل إلى شخص آخر'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Wallet>(
                      value: sourceWallet,
                      decoration: const InputDecoration(
                        labelText: 'المحفظة المرسلة',
                      ),
                      items: wallets.map(
                        (wallet) => DropdownMenuItem<Wallet>(
                          value: wallet,
                          child: Text(
                            '${wallet.flag} ${wallet.name} (${wallet.currency})',
                          ),
                        ),
                      ).toList(),
                      onChanged: (wallet) {
                        if (wallet == null) return;
                        setDialogState(() {
                          sourceWallet = wallet;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستلم',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم هاتف المستلم',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'مبلغ التحويل',
                        suffixText: sourceWallet.currency,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أدخل اسم المستلم'),
                        ),
                      );
                      return;
                    }

                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أدخل رقم هاتف المستلم'),
                        ),
                      );
                      return;
                    }

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أدخل مبلغًا صحيحًا للتحويل'),
                        ),
                      );
                      return;
                    }

                    if (amount > sourceWallet.balance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'الرصيد غير كافٍ لإتمام التحويل',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      sourceWallet.balance -= amount;
                      transactions.insert(
                        0,
                        Transaction(
                          type: 'تحويل إلى $name - $phone',
                          amount: amount,
                          date: DateTime.now(),
                        ),
                      );
                    });

                    await _saveWallets();
                    await _saveTransactions();

                    if (!mounted) return;
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تسجيل تحويل $amount ${sourceWallet.currency} إلى $name',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('تحويل'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showTransferDialog(Wallet sourceWallet) async {
    if (!_walletsUnlocked && !(await _ensureWalletUnlocked())) return;
    final amountController = TextEditingController();
    Wallet? destinationWallet;

    final availableWallets = wallets
        .where((wallet) => !identical(wallet, sourceWallet))
        .toList();

    if (availableWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف محفظة أخرى أولًا لإجراء التحويل'),
        ),
      );
      return;
    }

    destinationWallet = availableWallets.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('تحويل من ${sourceWallet.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Wallet>(
                    value: destinationWallet,
                    decoration: const InputDecoration(
                      labelText: 'المحفظة المستقبلة',
                    ),
                    items: availableWallets.map(
                      (wallet) => DropdownMenuItem<Wallet>(
                        value: wallet,
                        child: Text(
                          '${wallet.flag} ${wallet.name} (${wallet.currency})',
                        ),
                      ),
                    ).toList(),
                    onChanged: (wallet) {
                      setDialogState(() {
                        destinationWallet = wallet;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'مبلغ التحويل',
                      suffixText: sourceWallet.currency,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );

                    if (destinationWallet == null) {
                      return;
                    }

                    if (amount == null || amount <= 0) {
                      return;
                    }

                    if (amount > sourceWallet.balance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرصيد غير كافٍ لإتمام التحويل'),
                        ),
                      );
                      return;
                    }

                    if (sourceWallet.currency !=
                        destinationWallet!.currency) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'التحويل بين عملات مختلفة يحتاج إلى سعر صرف',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      sourceWallet.balance -= amount;
                      destinationWallet!.balance += amount;

                      transactions.insert(
                        0,
                        Transaction(
                          type:
                              'تحويل من ${sourceWallet.name} إلى ${destinationWallet!.name} - ${sourceWallet.currency}',
                          amount: amount,
                          date: DateTime.now(),
                        ),
                      );
                    });

                    await _saveWallets();
                    await _saveTransactions();

                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('تحويل'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showWallets() async {
    if (!_walletsUnlocked && !(await _ensureWalletUnlocked())) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'المحافظ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_outline),
                            SizedBox(width: 8),
                            Text(
                              'بيانات العميل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          customer.name.isEmpty
                              ? 'لم يتم إدخال اسم العميل'
                              : 'الاسم: ${customer.name}',
                        ),
                        if (customer.phone.isNotEmpty)
                          Text('الهاتف: ${customer.phone}'),
                        if (customer.country.isNotEmpty)
                          Text('الدولة: ${customer.country}'),
                        if (customer.currency.isNotEmpty)
                          Text('العملة الأساسية: ${customer.currency}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                if (wallets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لا توجد محافظ مضافة حاليًا',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                else
                  ...wallets.map((wallet) {
                    double deposits = 0;
                    double withdrawals = 0;
                    int count = 0;

                    for (final transaction in transactions) {
                      final type = transaction.type;

                      if (type ==
                          'إيداع في ${wallet.name} - ${wallet.currency}') {
                        deposits += transaction.amount;
                        count++;
                      } else if (type ==
                          'سحب من ${wallet.name} - ${wallet.currency}') {
                        withdrawals += transaction.amount;
                        count++;
                      } else if (type.startsWith(
                          'تحويل من ${wallet.name} إلى ')) {
                        withdrawals += transaction.amount;
                        count++;
                      } else if (type.startsWith('تحويل من ') &&
                          type.contains(' إلى ${wallet.name} -')) {
                        deposits += transaction.amount;
                        count++;
                      }
                    }

                    final netMovement = deposits - withdrawals;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  wallet.flag,
                                  style: const TextStyle(fontSize: 30),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wallet.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${wallet.country} • ${wallet.currency}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${wallet.balance.toStringAsFixed(2)} ${wallet.currency}',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: (darkMode ? Colors.white : navy)
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.spaceAround,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    'الإيداعات: ${deposits.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: emerald,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'السحوبات: ${withdrawals.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'صافي الحركة: ${netMovement.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: netMovement < 0 ? red : emerald,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$count عملية',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final buttonWidth =
                                    (constraints.maxWidth - 16) / 3;

                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    SizedBox(
                                      width: buttonWidth,
                                      child: FilledButton.tonal(
                                        onPressed: () =>
                                            showDepositDialog(wallet),
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_circle_outline),
                                            SizedBox(height: 4),
                                            Text(
                                              'إيداع',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: buttonWidth,
                                      child: FilledButton.tonal(
                                        onPressed: () =>
                                            showWithdrawDialog(wallet),
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.remove_circle_outline),
                                            SizedBox(height: 4),
                                            Text(
                                              'سحب',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: buttonWidth,
                                      child: FilledButton.tonal(
                                        onPressed: () =>
                                            showTransferDialog(wallet),
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.swap_horiz),
                                            SizedBox(height: 4),
                                            Text(
                                              'تحويل',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: (darkMode ? Colors.white : navy)
                                      .withOpacity(0.12),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 19,
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        'شرح العمليات',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '• الإيداع: يضيف مبلغًا إلى رصيد هذه '
                                    'المحفظة داخل التطبيق.',
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    '• السحب: يخصم مبلغًا من الرصيد '
                                    'المتاح في المحفظة.',
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    '• التحويل: ينقل مبلغًا بين المحافظ '
                                    'المضافة، وفق العملة المدعومة.',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ملاحظة: العمليات الحالية داخلية؛ '
                                    'ولا ترسل أموالًا حقيقية إلى بنك أو '
                                    'شخص أو ماكينة ATM أو شبكة Bitcoin.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: darkMode
                                          ? Colors.amber.shade200
                                          : Colors.brown.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: showPersonTransferDialog,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('تحويل لشخص'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: showAddWalletDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة محفظة'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showAddWalletDialog() async {
    if (!_walletsUnlocked && !(await _ensureWalletUnlocked())) return;
    final nameController = TextEditingController();
    final countryController = TextEditingController();
    final currencyController = TextEditingController();
    final flagController = TextEditingController(text: '🇪🇬');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إضافة محفظة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المحفظة',
                    hintText: 'مثال: محفظتي',
                  ),
                ),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    labelText: 'الدولة',
                    hintText: 'مثال: مصر',
                  ),
                ),
                TextField(
                  controller: currencyController,
                  decoration: const InputDecoration(
                    labelText: 'العملة',
                    hintText: 'مثال: EGP',
                  ),
                ),
                TextField(
                  controller: flagController,
                  decoration: const InputDecoration(
                    labelText: 'العلم',
                    hintText: 'مثال: 🇪🇬',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final country = countryController.text.trim();
                final currency = currencyController.text.trim();
                final flag = flagController.text.trim();

                if (name.isEmpty ||
                    country.isEmpty ||
                    currency.isEmpty ||
                    flag.isEmpty) {
                  return;
                }

                if (wallets.any(
                  (wallet) =>
                      wallet.name.toLowerCase() == name.toLowerCase(),
                )) {
                  return;
                }

                final wallet = Wallet(
                  name: name,
                  country: country,
                  currency: currency.toUpperCase(),
                  flag: flag,
                  balance: 0,
                  customerPhone: customer.phone,
                );

                setState(() {
                  wallets.add(wallet);
                });

                await _saveWallets();

                if (!mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

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

      await _saveTransactions();
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

      await _saveTransactions();
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> deleteTransaction(int index) async {
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
            onPressed: () async {
              setState(() {
                if (transaction.type == 'إضافة مال') {
                  balance -= transaction.amount;
                  if (balance < 0) balance = 0;
                } else if (transaction.type == 'إضافة دين') {
                  debts -= transaction.amount;
                  if (debts < 0) debts = 0;
                }

                transactions.removeAt(index);

                if (balance < 0) balance = 0;
                if (debts < 0) debts = 0;
              });

              await _saveTransactions();
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
          if (balance < 0) balance = 0;
        } else if (transaction.type == 'إضافة دين') {
          debts = debts - transaction.amount + newAmount;
          if (debts < 0) debts = 0;
        }

        transaction.amount = newAmount;
        transaction.date = DateTime.now();
      });

      await _saveTransactions();
    }
  }

  void showTransactionDetails(Transaction transaction) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تفاصيل العملية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detailRow('نوع العملية', transaction.type),
              _detailRow(
                'المبلغ',
                transaction.amount.toStringAsFixed(2),
              ),
              _detailRow(
                'التاريخ',
                formatDate(transaction.date),
              ),
              _detailRow(
                'الوقت',
                TimeOfDay.fromDateTime(transaction.date)
                    .format(dialogContext),
              ),
              const SizedBox(height: 12),
              const Text(
                'هذه التفاصيل محفوظة داخل التطبيق، '
                'ولا تُعد إثباتًا لتحويل مالي حقيقي.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
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
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                  ),
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
                tooltip: 'بيانات العميل',
                icon: const Icon(Icons.person_outline),
                onPressed: showCustomerData,
              ),
              IconButton(
                tooltip: 'المحافظ',
                icon: const Icon(Icons.account_balance_wallet_outlined),
                onPressed: showWallets,
              ),
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
                    darkMode ? 0.72 : 0.18,
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

                                  final type = transaction.type;

                                  final bool isDeposit =
                                      type == 'إضافة مال' ||
                                      type.startsWith('إيداع في ');

                                  final bool isWithdrawal =
                                      type.startsWith('سحب من ');

                                  final bool isTransfer =
                                      type.startsWith('تحويل من ');

                                  final bool isPersonTransfer =
                                      type.startsWith('تحويل إلى ');

                                  final bool isDebt =
                                      type == 'إضافة دين';

                                  final Color operationColor =
                                      isDeposit
                                          ? emerald
                                          : isWithdrawal || isDebt
                                              ? red
                                              : isPersonTransfer
                                                  ? gold
                                                  : isTransfer
                                                      ? blue
                                                      : navy;

                                  final IconData operationIcon =
                                      isDeposit
                                          ? Icons.arrow_downward_rounded
                                          : isWithdrawal
                                              ? Icons.arrow_upward_rounded
                                              : isPersonTransfer
                                                  ? Icons.person_add_alt_1_rounded
                                                  : isTransfer
                                                      ? Icons.swap_horiz_rounded
                                                      : isDebt
                                                          ? Icons.receipt_long_rounded
                                                          : Icons.receipt_long_outlined;

                                  final String amountPrefix =
                                      isDeposit
                                          ? '+'
                                          : isWithdrawal || isDebt
                                              ? '−'
                                              : '';

                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: ListTile(
onTap: () => showTransactionDetails(transaction),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            operationColor.withOpacity(0.12),
                                        child: Icon(
                                          operationIcon,
                                          color: operationColor,
                                        ),
                                      ),
                                      title: Text(
                                        type,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 5),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 15,
                                              color:
                                                  foreground.withOpacity(0.55),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                formatDate(
                                                  transaction.date,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: operationColor,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'خيارات العملية',
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
