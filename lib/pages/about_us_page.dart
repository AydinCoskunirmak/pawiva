import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pawiva/l10n/app_localizations.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  bool _showConfirmation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _messageController.text.isNotEmpty;
  }

  Future<void> _sendMessage() async {
    if (!_isFormValid) return;

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'aydincoskunirmak@gmail.com',
      queryParameters: {
        'subject': 'Pawiva App - Message from ${_nameController.text}',
        'body':
        'From: ${_nameController.text}\nEmail: ${_emailController.text}\n\nMessage:\n${_messageController.text}',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }

    _nameController.clear();
    _emailController.clear();
    _messageController.clear();

    setState(() => _showConfirmation = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _showConfirmation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double navBar = bottomInset > 40 ? bottomInset : 0.0;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: navBar),
        height: 63 * scaleH + navBar,
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
      body: Stack(
        children: [
          // Layer 1: Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. ABOUT US HEADER
                  Container(
                    width: double.infinity,
                    height: 40 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAE3C6),
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    child: Center(
                      child: Text(
                        l10n.aboutUs,
                        style: GoogleFonts.nunito(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // 2. ABOUT TEXT
                  Padding(
                    padding: EdgeInsets.only(
                      left: 5 * scale,
                      right: 5 * scale,
                      top: 12 * scale,
                    ),
                    child: SizedBox(
                      width: 384 * scale,
                      child: Text(
                        l10n.aboutUsText,
                        style: GoogleFonts.nunito(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // 3. MESSAGE HEADER
                  Container(
                    width: double.infinity,
                    height: 40 * scale,
                    margin: EdgeInsets.only(top: 12 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAE3C6),
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    child: Center(
                      child: Text(
                        l10n.sendMessage,
                        style: GoogleFonts.nunito(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // 4. NAME INPUT
                  _buildInput(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    placeholder: l10n.yourName,
                    scale: scale,
                    topMargin: 12 * scale,
                    borderRadius: 15 * scale,
                  ),
                  // 5. EMAIL INPUT
                  _buildInput(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    placeholder: l10n.emailAddress,
                    scale: scale,
                    topMargin: 8 * scale,
                    borderRadius: 15 * scale,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  // 6. MESSAGE INPUT
                  _buildMessageInput(scale, l10n.textYourMessage),
                  // 7. SEND BUTTON
                  GestureDetector(
                    onTap: _isFormValid ? _sendMessage : null,
                    child: Opacity(
                      opacity: _isFormValid ? 1.0 : 0.5,
                      child: Container(
                        width: 124 * scale,
                        height: 40 * scale,
                        margin: EdgeInsets.only(top: 12 * scale, bottom: 16 * scaleH),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15 * scale),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 16 * scale),
                            SizedBox(width: 4 * scale),
                            Text(
                              l10n.send,
                              style: GoogleFonts.nunito(
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Layer 3: Confirmation Overlay
          if (_showConfirmation)
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showConfirmation ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: EdgeInsets.all(16 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAE3C6),
                      borderRadius: BorderRadius.circular(15 * scale),
                    ),
                    child: Text(
                      "your message has been sent.",
                      style: GoogleFonts.nunito(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required double scale,
    required double topMargin,
    double borderRadius = 10,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        bool hasFocus = focusNode.hasFocus;
        return Container(
          width: 280 * scale,
          height: 40 * scale,
          margin: EdgeInsets.only(top: topMargin),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.black.withValues(alpha: hasFocus ? 1.0 : 0.5),
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16 * scale,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.nunito(
                fontSize: 16 * scale,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(double scale, String placeholder) {
    return ListenableBuilder(
      listenable: Listenable.merge([_messageFocus, _messageController]),
      builder: (context, _) {
        bool hasFocus = _messageFocus.hasFocus;
        return Container(
          width: 280 * scale,
          height: 137 * scale,
          margin: EdgeInsets.only(top: 8 * scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15 * scale),
            border: Border.all(
              color: Colors.black.withValues(alpha: hasFocus ? 1.0 : 0.5),
            ),
          ),
          child: TextField(
            controller: _messageController,
            focusNode: _messageFocus,
            maxLines: null,
            minLines: 5,
            textAlignVertical: TextAlignVertical.top,
            style: GoogleFonts.nunito(
              fontSize: 16 * scale,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: "$placeholder..",
              hintStyle: GoogleFonts.nunito(
                fontSize: 16 * scale,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12 * scale),
            ),
            onChanged: (_) => setState(() {}),
          ),
        );
      },
    );
  }
}