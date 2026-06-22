import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/pet_profile.dart';
import 'timer_page.dart';
import 'package:path_provider/path_provider.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final List<PetProfile> profiles = [];
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  
  File? _selectedImage;
  String? _selectedPetType;
  bool _isNameFocused = false;
  bool _isNameConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _nameFocusNode.addListener(() {
      setState(() {
        _isNameFocused = _nameFocusNode.hasFocus;
        if (_isNameFocused) {
          _isNameConfirmed = false;
        }
      });
    });
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString('pet_profiles');
    if (json != null && json != '[]') {
      final List<dynamic> decoded = jsonDecode(json);
      setState(() {
        profiles.clear();
        profiles.addAll(decoded.map((item) => PetProfile(
          name: item['name'],
          type: item['type'],
          image: item['imagePath'] != null ? File(item['imagePath']) : null,
        )));
      });
    }
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = profiles.map((p) => {
      'name': p.name,
      'type': p.type,
      'imagePath': p.image?.path,
    }).toList();
    await prefs.setString('pet_profiles', jsonEncode(jsonList));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${directory.path}/$fileName');
      setState(() {
        _selectedImage = savedImage;
      });
    }
  }

  void _addProfile() {
    if (_nameController.text.isNotEmpty && _selectedPetType != null) {
      setState(() {
        profiles.add(PetProfile(
          name: _nameController.text,
          type: _selectedPetType!,
          image: _selectedImage,
        ));
        _saveProfiles();
        // Reset form
        _selectedImage = null;
        _nameController.clear();
        _isNameConfirmed = false;
        _selectedPetType = null;
        _nameFocusNode.unfocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scaleW = screenWidth / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    bool isFormValid = _nameController.text.isNotEmpty && _selectedPetType != null;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      extendBody: false,
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 63 * scaleH),
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 63 * scaleH),
                      // Title
                      Text(
                        l10n.addYourPets,
                        style: GoogleFonts.nunito(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 40 * scaleH),
                      // Photo Upload Card
                      GestureDetector(
                        onTap: _pickImage,
                        child: Opacity(
                          opacity: _selectedImage == null ? 0.7 : 1.0,
                          child: Container(
                            width: 140 * scale,
                            height: 149 * scale,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40 * scale),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.5),
                                width: 1 * scale,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: Offset(0, 4 * scale),
                                  blurRadius: 4 * scale,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40 * scale),
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                  : Center(
                                child: Text(
                                  "+ ${l10n.petPhoto}",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                        ),
                      ),
                      ),
                      SizedBox(height: 72 * scaleH),
                      // Pet Name Input
                      Container(
                        width: 280 * scale,
                        height: 48 * scale,
                        decoration: BoxDecoration(
                          color: _isNameConfirmed
                              ? const Color(0xFFFAE3C6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15 * scale),
                          border: Border.all(
                            color: Colors.black.withValues(
                                alpha: _nameFocusNode.hasFocus ? 1.0 : 0.5),
                            width: 1 * scale,
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          style: GoogleFonts.nunito(
                            fontSize: 20 * scale,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: l10n.yourPetName,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 14 * scale,
                            ),
                            hintStyle: GoogleFonts.nunito(
                              fontSize: 20 * scale,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                          onSubmitted: (_) {
                            setState(() {
                              _isNameConfirmed = true;
                            });
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                      SizedBox(height: 30 * scaleH),
                      // Pet Type Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                          _buildTypeButton('cat', l10n.cat, scale),
                          SizedBox(width: 30 * scale),
                          _buildTypeButton('dog', l10n.dog, scale),
                        ],
                      ),
                      SizedBox(height: 30 * scaleH),
                      // Add Profile Button
                      GestureDetector(
                        onTap: isFormValid ? _addProfile : null,
                        child: Opacity(
                          opacity: isFormValid ? 1.0 : 0.3,
                          child: Container(
                            width: 125 * scale,
                            height: 40 * scale,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15 * scale),
                              border: Border.all(color: Colors.black, width: 1 * scale),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.addProfile,
                                style: GoogleFonts.nunito(
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                )
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Profile list area takes remaining space
                      Expanded(
                        child: profiles.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                children: [
                                  SizedBox(height: 30 * scaleH),
                                  // Divider
                                  Container(
                                    width: 200 * scale,
                                    height: 1 * scale,
                                    color: Colors.black,
                                  ),
                                  SizedBox(height: 20 * scaleH),
                                  // Profile List
                                  SizedBox(
                                    height: 100 * scale,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        padding: EdgeInsets.symmetric(horizontal: 20 * scaleW),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(minWidth: screenWidth - 40 * scaleW),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: profiles.asMap().entries.map((entry) {
                                              return Padding(
                                                padding: EdgeInsets.only(right: entry.key == profiles.length - 1 ? 0 : 30 * scale),
                                                child: _buildProfileItem(entry.value, scale, l10n),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
              width: double.infinity,
              height: 63 * scaleH,
              decoration: BoxDecoration(
                color: const Color(0xFFFAE3C6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x40000000),
                    offset: Offset(0, -2 * scaleH),
                    blurRadius: 4 * scale,
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: profiles.isNotEmpty
                    ? () {
                  _saveProfiles();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimerPage(profiles: profiles)),
                  );
                }
                    : null,
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: profiles.isEmpty ? 0.25 : 1.0,
                    child: Text(
                      l10n.startTiming,
                      style: GoogleFonts.staatliches(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
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

  Widget _buildTypeButton(String type, String label, double scale) {
    bool isSelected = _selectedPetType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPetType = isSelected ? null : type;
        });
      },
      child: Container(
        width: 125 * scale,
        height: 40 * scale,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAE3C6) : Colors.transparent,
          borderRadius: BorderRadius.circular(15 * scale),
          border: Border.all(
            color: Colors.black.withValues(alpha: isSelected ? 1.0 : 0.5),
            width: 1 * scale,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 20 * scale,
            color: Colors.black.withValues(alpha: isSelected ? 1.0 : 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(PetProfile profile, double scale, AppLocalizations l10n) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18 * scale),
              child: Container(
                width: 50 * scale,
                height: 50 * scale,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: profile.image != null
                    ? Image.file(profile.image!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          profile.type == 'cat' ? l10n.cat : l10n.dog,
                          style: GoogleFonts.nunito(
                            fontSize: 12 * scale,
                            color: Colors.black,
                          ),
                        ),
                      ),
              ),
            ),
            Container(
              width: 50 * scale,
              height: 50 * scale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * scale),
                border: Border.all(color: Colors.black, width: 1 * scale),
              ),
            ),
          ],
        ),
        Text(
          profile.name,
          style: GoogleFonts.nunito(
            fontSize: 20 * scale,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
