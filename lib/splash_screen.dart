import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawiva/models/pet_profile.dart';
import 'package:pawiva/pages/timer_page.dart';
import 'package:pawiva/pages/add_pet_page.dart';
import 'package:pawiva/pages/onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }
  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Check if onboarding is done
    final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;
    
    if (!onboardingDone) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
      return;
    }

    final String? profilesJson = prefs.getString('pet_profiles');

    if (profilesJson != null && profilesJson != '[]' && profilesJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(profilesJson);
      final List<PetProfile> profiles = decoded
          .map((item) => PetProfile.fromJson(item as Map<String, dynamic>))
          .toList();
      
      if (profiles.isNotEmpty && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimerPage(profiles: profiles),
          ),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddPetPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive scaling based on 393x852 (iPhone 14 Pro size)
    final Size size = MediaQuery.of(context).size;
    final double scaleW = size.width / 393;
    final double scaleH = size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFFFAE3C6),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'PAWIVA',
                style: GoogleFonts.nanumBrushScript(
                  fontSize: 56 * scale,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                'pet activity and time tracker',
                style: GoogleFonts.nunito(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
