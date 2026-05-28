import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pawiva/models/pet_profile.dart';
import 'package:pawiva/pages/edit_pet_list_page.dart';
import 'package:pawiva/pages/alert_page.dart';
import 'package:pawiva/pages/about_us_page.dart';
import 'package:pawiva/pages/terms_of_use_page.dart';
import 'package:pawiva/pages/privacy_page.dart';
import '../l10n/app_localizations.dart';
import 'language_page.dart';

class EditMenuOverlay extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final List<PetProfile> profiles;
  final Function(List<PetProfile>) onProfilesChanged;

  const EditMenuOverlay({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.profiles,
    required this.onProfilesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = screenHeight / 852;
    final double scale = (scaleW + scaleH) / 2;
    double safeAreaTop = MediaQuery.of(context).padding.top;
    double footerHeight = 63 * scaleH;
    double panelHeight = screenHeight - footerHeight - safeAreaTop;

    return Stack(
      children: [
        // Full screen white overlay
        IgnorePointer(
          ignoring: !isOpen,
          child: GestureDetector(
            onTap: onClose,
            child: AnimatedOpacity(
              opacity: isOpen ? 0.8 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          left: isOpen ? 0 : -240 * scale,
          top: safeAreaTop,
          child: GestureDetector(
            onTap: () {}, // absorb taps, do nothing
            child: Container(
              width: 240 * scale,
              height: panelHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFFAE3C6),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30 * scale),
                  bottomRight: Radius.circular(30 * scale),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10 * scale,
                    offset: Offset(2 * scale, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 40 * scale),
                  _buildMenuItem(l10n.editPetProfile, scale, onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => EditPetListPage(
                        profiles: profiles,
                        onProfilesChanged: onProfilesChanged,
                      ),
                    ));
                  }),
                  _buildMenuDivider(scale),
                  _buildMenuItem(l10n.reminders, scale, onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => AlertPage(profiles: profiles),
                    ));
                  }),
                  _buildMenuDivider(scale),
                  _buildMenuItem(l10n.language, scale, onTap: () {
                    Navigator.push(context, PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.transparent,
                      pageBuilder: (context, unusedA, unusedB) => LanguagePage(
                        onCloseAll: onClose,
                      ),
                    ));
                  }),
                  _buildMenuDivider(scale),
                  _buildMenuItem(l10n.aboutUs, scale, onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const AboutUsPage(),
                    ));
                  }),
                  _buildMenuDivider(scale),
                  _buildMenuItem(l10n.rateTheApp, scale, onTap: () => _rateApp(context)),
                  _buildMenuDivider(scale),
                  _buildMenuItem(l10n.shareTheApp, scale, onTap: () => _shareApp()),
                  _buildMenuDivider(scale),
                  _buildMenuItem(l10n.termsOfUse, scale, onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const TermsOfUsePage(),
                    ));
                  }),
                  _buildMenuDivider(scale),
                  _buildMenuItem(l10n.privacy, scale, onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const PrivacyPage(),
                    ));
                  }),
                  const Spacer(),
                  _buildMenuDivider(scale),
                  SizedBox(height: 10 * scale),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.arrow_back,
                      size: 24 * scale,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 40 * scale),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(String title, double scale, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 40 * scale),
        padding: EdgeInsets.symmetric(
          vertical: 6 * scale,
          horizontal: 8 * scale,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider(double scale) {
    return Container(
      width: 106 * scale,
      height: 1,
      color: Colors.black,
      margin: EdgeInsets.symmetric(vertical: 10 * scale),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final Uri url = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID')
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=com.example.pawiva');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareApp() async {
    const String message = 'Check out Pawiva - Pet Activity & Time Tracker!\n\n'
        'iOS: https://apps.apple.com/app/idYOUR_APP_ID\n'
        'Android: https://play.google.com/store/apps/details?id=com.example.pawiva';
    await Share.share(message);
  }
}
