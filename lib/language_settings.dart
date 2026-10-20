
import 'app_language.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() =>
      _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  final search = TextEditingController();
  String selected = 'ar';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    if (!mounted || saved == null || !languages.containsKey(saved)) return;
    setState(() => selected = saved);
  }

  final languages = const {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'hi': 'हिन्दी',
    'ur': 'اردو',
    'tr': 'Türkçe',
    'fa': 'فارسی',
    'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu',
    'bn': 'বাংলা',
    'sw': 'Kiswahili',
    'nl': 'Nederlands',
    'pl': 'Polski',
    'uk': 'Українська',
    'el': 'Ελληνικά',
    'he': 'עברית',
    'th': 'ไทย',
    'vi': 'Tiếng Việt',
    'sv': 'Svenska',
    'no': 'Norsk',
    'da': 'Dansk',
    'fi': 'Suomi',
    'ro': 'Română',
    'hu': 'Magyar',
    'cs': 'Čeština',
    'sr': 'Српски',
    'am': 'አማርኛ',
    'ta': 'தமிழ்',
    'fil': 'Filipino',
  };

  final languageFlags = const {
    'ar': '🇸🇦', 'en': '🇬🇧', 'fr': '🇫🇷',
    'es': '🇪🇸', 'de': '🇩🇪', 'it': '🇮🇹',
    'pt': '🇵🇹', 'ru': '🇷🇺', 'zh': '🇨🇳',
    'ja': '🇯🇵', 'ko': '🇰🇷', 'hi': '🇮🇳',
    'ur': '🇵🇰', 'tr': '🇹🇷', 'fa': '🇮🇷',
    'id': '🇮🇩', 'ms': '🇲🇾', 'bn': '🇧🇩',
    'sw': '🇰🇪', 'nl': '🇳🇱', 'pl': '🇵🇱',
    'uk': '🇺🇦', 'el': '🇬🇷', 'he': '🇮🇱',
    'th': '🇹🇭', 'vi': '🇻🇳', 'sv': '🇸🇪',
    'no': '🇳🇴', 'da': '🇩🇰', 'fi': '🇫🇮',
    'ro': '🇷🇴', 'hu': '🇭🇺', 'cs': '🇨🇿',
    'sr': '🇷🇸', 'am': '🇪🇹', 'ta': '🇮🇳',
    'fil': '🇵🇭',
  };

  Future<void> choose(String code) async {
    if (!languages.containsKey(code)) return;

    setState(() => selected = code);

    try {
      await saveAppLanguage(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ اللغة: ${languages[code]}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ اللغة')),
      );
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = languages.entries.where((entry) =>
      entry.value.toLowerCase().contains(search.text.toLowerCase()) ||
      entry.key.toLowerCase().contains(search.text.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اللغات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث عن لغة',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return RadioListTile<String>(
                  value: item.key,
                  groupValue: selected,
                  title: Row(
                    children: [
                      Text(languageFlags[item.key] ?? '🌐',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.value)),
                    ],
                  ),
                  subtitle: Text(item.key),
                  secondary: selected == item.key
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.language),
                  onChanged: (value) {
                    if (value != null) choose(value);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
