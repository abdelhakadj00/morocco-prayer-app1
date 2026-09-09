import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مواقيت الصلاة - المغرب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
        fontFamily: 'sans-serif', // استخدام خط النظام الافتراضي المضمون
      ),
      home: const PrayerTimesScreen(),
    );
  }
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});
  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final List<String> cities = [
    'Rabat', 'Casablanca', 'Fes', 'Marrakech', 'Tangier', 
    'Agadir', 'Oujda', 'Meknes', 'Laayoune', 'Dakhla', 'Tetouan'
  ];
  final Map<String, String> cityArabicNames = {
    'Rabat': 'الرباط', 'Casablanca': 'الدار البيضاء', 'Fes': 'فاس',
    'Marrakech': 'مراكش', 'Tangier': 'طنجة', 'Agadir': 'أكادير',
    'Oujda': 'وجدة', 'Meknes': 'مكناس', 'Laayoune': 'العيون',
    'Dakhla': 'الداخلة', 'Tetouan': 'تطوان'
  };

  String selectedCity = 'Rabat';
  Map<String, String> timings = {};
  String hijriDate = 'جاري التحميل...';
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCity = prefs.getString('selected_city') ?? 'Rabat';
    });
    await fetchPrayerTimes();
  }

  Future<void> fetchPrayerTimes() async {
    setState(() { 
      isLoading = true; 
      errorMessage = ''; 
    });
    
    try {
      // إضافة مهلة زمنية (15 ثانية) لمنع التعليق الأبدي
      final url = Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=$selectedCity&country=Morocco&method=21');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['code'] == 200 && jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          final times = data['timings'];
          final date = data['date']['hijri'];
          
          setState(() {
            timings = {
              'الفجر': times['Fajr'] ?? '--:--',
              'الشروق': times['Sunrise'] ?? '--:--',
              'الظهر': times['Dhuhr'] ?? '--:--',
              'العصر': times['Asr'] ?? '--:--',
              'المغرب': times['Maghrib'] ?? '--:--',
              'العشاء': times['Isha'] ?? '--:--',
            };
            hijriDate = '${date['weekday']['ar']} ${date['date']}';
            isLoading = false;
          });
          
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('selected_city', selectedCity);
        } else {
          setState(() { 
            errorMessage = 'فشل في جلب البيانات: ${jsonResponse['status']}'; 
            isLoading = false; 
          });
        }
      } else {
        setState(() { 
          errorMessage = 'خطأ في الخادم: ${response.statusCode}'; 
          isLoading = false; 
        });
      }
    } catch (e) {
      setState(() { 
        errorMessage = 'خطأ في الاتصال: $e\n\nتأكد من تفعيل الإنترنت في الهاتف.'; 
        isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('مواقيت الصلاة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00695C)))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: fetchPrayerTimes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('اختر المدينة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                value: selectedCity,
                                underline: const SizedBox(),
                                items: cities.map((String city) {
                                  return DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(cityArabicNames[city]!, style: const TextStyle(fontSize: 16)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => selectedCity = newValue);
                                    fetchPrayerTimes();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        cityArabicNames[selectedCity]!,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hijriDate,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          children: timings.entries.map((entry) {
                            return _buildPrayerCard(entry.key, entry.value);
                          }).toList(),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text('حسب توقيت وزارة الأوقاف والشؤون الإسلامية', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildPrayerCard(String name, String time) {
    IconData icon;
    switch (name) {
      case 'الفجر': icon = Icons.nightlight_round; break;
      case 'الشروق': icon = Icons.wb_sunny; break;
      case 'الظهر': icon = Icons.sunny; break;
      case 'العصر': icon = Icons.wb_cloudy; break;
      case 'المغرب': icon = Icons.nights_stay; break;
      case 'العشاء': icon = Icons.nightlight; break;
      default: icon = Icons.access_time;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00695C).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF00695C)),
        ),
        title: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        trailing: Text(time, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
      ),
    );
  }
}
