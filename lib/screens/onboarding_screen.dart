import 'package:flutter/material.dart';
import 'package:rfid/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> texts = [
    "Selamat datang di RFID App!",
    "Scan dan kelola data dengan mudah.",
    "Ayo mulai sekarang!",
  ];

  void finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("lib/assets/images/bg.png", fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha((0.7 * 255).toInt())),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemCount: texts.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mobile_friendly,
                            size: 120,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 40),
                          Text(
                            texts[index],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(texts.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentPage == index ? Colors.orange : Colors.grey,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    _currentPage == texts.length - 1
                        ? finishOnboarding
                        : () => _controller.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  _currentPage == texts.length - 1 ? "Mulai" : "Lanjut",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}
