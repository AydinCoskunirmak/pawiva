import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawiva/l10n/app_localizations.dart';
import 'package:pawiva/l10n/locale_provider.dart';

class LanguagePage extends StatefulWidget {
  final VoidCallback? onCloseAll;

  const LanguagePage({super.key, this.onCloseAll});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  bool _isOpening = true;
  bool _isClosing = false;
  
  @override
  void initState() {
    super.initState();
    // opening animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isOpening = false);
    });
  }

  Future<void> _closePage() async {
    setState(() => _isClosing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;
    final l10n = AppLocalizations.of(context);

    final Map<String, String> localizedLanguageMap = {
      l10n.english: 'en',
      l10n.turkish: 'tr',
      l10n.spanish: 'es',
      l10n.portuguese: 'pt',
      l10n.french: 'fr',
      l10n.german: 'de',
      l10n.italian: 'it',
      l10n.korean: 'ko',
      l10n.japanese: 'ja',
      l10n.russian: 'ru',
      l10n.chinese: 'zh',
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Transparent tap area to go back
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePage,
              child: AnimatedOpacity(
                opacity: _isClosing ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(color: const Color(0x01000000)),
              ),
            ),
          ),
          // Language panel on the left
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: _isOpening ? -240 * scale : (_isClosing ? -240 * scale : 0),
            top: MediaQuery.of(context).padding.top,
            bottom: 63 * scaleH,
            child: Container(
              width: 240 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFFFAE3C6),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30 * scale),
                  bottomRight: Radius.circular(30 * scale),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 40 * scale),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...localizedLanguageMap.entries.toList().asMap().entries.map((entry) {
                            int idx = entry.key;
                            var langEntry = entry.value;
                            String langName = langEntry.key;
                            String langCode = langEntry.value;
                            bool isLast = idx == localizedLanguageMap.length - 1;
                            
                            final isSelected = LocaleProvider().languageCode == langCode;

                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    LocaleProvider().setLanguage(langCode);
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 40 * scale,
                                    color: Colors.transparent,
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Text(
                                            langName,
                                            style: GoogleFonts.nunito(
                                              fontSize: 20 * scale,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 8 * scale,
                                          top: 0,
                                          bottom: 0,
                                          child: isSelected
                                              ? Center(child: Icon(Icons.check, size: 16 * scale, color: Colors.black))
                                              : const SizedBox(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isLast) _buildMenuDivider(scale),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // Back section always at bottom centered
                  Container(
                    width: 106 * scale,
                    height: 1,
                    color: Colors.black,
                    margin: EdgeInsets.symmetric(vertical: 20 * scale),
                  ),
                  GestureDetector(
                    onTap: _closePage,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back,
                        size: 24 * scale,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 40 * scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuDivider(double scale) {
    return Column(
      children: [
        SizedBox(height: 10 * scale),
        Center(
          child: Container(
            width: 106 * scale,
            height: 1,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10 * scale),
      ],
    );
  }
}
