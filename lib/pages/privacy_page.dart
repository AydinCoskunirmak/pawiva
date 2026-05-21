import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pawiva/l10n/app_localizations.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    final String privacyText = l10n.privacyText;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Layer 1: Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER
                  Container(
                    width: double.infinity,
                    height: 40 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAE3C6),
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    child: Center(
                      child: Text(
                        l10n.privacy,
                        style: GoogleFonts.nunito(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // BODY TEXT
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16 * scale,
                      right: 16 * scale,
                      top: 16 * scale,
                      bottom: 63 * scaleH,
                    ),
                    child: Text(
                      privacyText,
                      style: GoogleFonts.nunito(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Layer 2: Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 63 * scaleH,
              decoration: BoxDecoration(
                color: const Color(0xFFFAE3C6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x40000000),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back,
                    size: 24 * scale,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
