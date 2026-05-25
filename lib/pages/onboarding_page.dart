import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:pawiva/models/pet_profile.dart';
import 'package:pawiva/pages/timer_page.dart';
import 'package:pawiva/pages/add_pet_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late List<VideoPlayerController> _videoControllers;
  final Set<int> _playedOnce = {};

  final List<String> _videoAssets = [
    'assets/onboarding/video1.MOV',
    'assets/onboarding/video2.MOV',
    'assets/onboarding/video3.MOV',
  ];

  @override
  void initState() {
    super.initState();
    _videoControllers = _videoAssets.map((asset) {
      return VideoPlayerController.asset(asset);
    }).toList();
    _initializeVideo(0);
  }

  Future<void> _initializeVideo(int index) async {
    if (_videoControllers[index].value.isInitialized) {
      await _videoControllers[index].seekTo(Duration.zero);
      await _videoControllers[index].play();
      return;
    }
    await _videoControllers[index].initialize();
    _videoControllers[index].setLooping(false);
    _videoControllers[index].setVolume(0);
    await _videoControllers[index].seekTo(Duration.zero);
    await Future.delayed(const Duration(milliseconds: 300));
    await _videoControllers[index].play();
    _playedOnce.add(index);
    setState(() {});

    // Sonraki videoyu arkaplanda hazırla
    if (index + 1 < _videoControllers.length) {
      _videoControllers[index + 1].initialize().then((_) {
        _videoControllers[index + 1].setLooping(false);
        _videoControllers[index + 1].setVolume(0);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    for (int i = 0; i < _videoControllers.length; i++) {
      if (i != index) {
        _videoControllers[i].pause();
      }
    }

    _initializeVideo(index);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;

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
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _videoControllers.length,
              itemBuilder: (context, index) {
                final controller = _videoControllers[index];
                if (controller.value.isInitialized) {
                  return SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  );
                } else {
                  return Container(color: Colors.black);
                }
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20 * scale,
            child: GestureDetector(
              onTap: _completeOnboarding,
              child: Text(
                'skip',
                style: GoogleFonts.nunito(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120 * scaleH,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDot(index, scale)),
            ),
          ),
          Positioned(
            bottom: 50 * scaleH,
            left: 0,
            right: 0,
            child: Center(
              child: _currentIndex == 2
                  ? _buildGetStartedButton(scale)
                  : _buildNextButton(scale),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, double scale) {
    bool isActive = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4 * scale),
      width: isActive ? 24 * scale : 8 * scale,
      height: 8 * scale,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF8146) : Colors.grey,
        borderRadius: BorderRadius.circular(4 * scale),
      ),
    );
  }

  Widget _buildNextButton(double scale) {
    return GestureDetector(
      onTap: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 48 * scale,
        height: 48 * scale,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildGetStartedButton(double scale) {
    return GestureDetector(
      onTap: _completeOnboarding,
      child: Container(
        width: 200 * scale,
        height: 48 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFFAE3C6),
          borderRadius: BorderRadius.circular(15 * scale),
          border: Border.all(color: Colors.black, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          'get started',
          style: GoogleFonts.nunito(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}