import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawiva/models/pet_profile.dart';
import '../l10n/app_localizations.dart';

class AddNewPetPage extends StatefulWidget {
  final Function(PetProfile) onAdd;

  const AddNewPetPage({super.key, required this.onAdd});

  @override
  State<AddNewPetPage> createState() => _AddNewPetPageState();
}

class _AddNewPetPageState extends State<AddNewPetPage> {
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  String? _selectedPetType;
  bool _isNameConfirmed = false;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        setState(() {
          _isNameConfirmed = _nameController.text.isNotEmpty;
        });
      }
    });
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
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    bool isFormValid = _nameController.text.isNotEmpty && _selectedPetType != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 63 * scaleH),
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 50 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAE3C6),
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.addYourPet,
                          style: GoogleFonts.nunito(
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 140 * scale,
                                height: 149 * scale,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40 * scale),
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      offset: const Offset(0, 4),
                                      blurRadius: 4,
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
                x"x"                    style: GoogleFonts.nunito(
                                      fontSize: 16 * scale,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ),
                            SizedBox(height: 72 * scaleH),
                            Container(
                              width: 280 * scale,
                              height: 47 * scale,
                              decoration: BoxDecoration(
                                color: _isNameConfirmed ? const Color(0xFFFAE3C6) : Colors.transparent,
                                borderRadius: BorderRadius.circular(15 * scale),
                                border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 1),
                              ),
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                textAlign: TextAlign.center,
                                textInputAction: TextInputAction.done,
                                style: GoogleFonts.nunito(fontSize: 20 * scale, color: Colors.black),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: l10n.yourPetName,
                                  hintStyle: GoogleFonts.nunito(
                                      fontSize: 20 * scale, color: Colors.black.withValues(alpha: 0.5)),
                                ),
                                onSubmitted: (_) {
                                  setState(() => _isNameConfirmed = _nameController.text.isNotEmpty);
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                            SizedBox(height: 30 * scaleH),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTypeButton('cat', l10n.cat, scale),
                                SizedBox(width: 30 * scale),
                                _buildTypeButton('dog', l10n.dog, scale),
                              ],
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
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, size: 24 * scale, color: Colors.black),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: isFormValid
                          ? () {
                              widget.onAdd(PetProfile(
                                name: _nameController.text,
                                type: _selectedPetType!,
                                image: _selectedImage,
                              ));
                              Navigator.pop(context);
                            }
                          : null,
                      child: Opacity(
                        opacity: isFormValid ? 1.0 : 0.3,
                        child: Center(
                          child: Text(
                            l10n.add,
                            style: GoogleFonts.staatliches(fontSize: 20 * scale, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
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
      onTap: () => setState(() => _selectedPetType = type),
      child: Container(
        width: 125 * scale,
        height: 40 * scale,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAE3C6) : Colors.transparent,
          borderRadius: BorderRadius.circular(15 * scale),
          border: Border.all(color: Colors.black.withValues(alpha: isSelected ? 1.0 : 0.5), width: 1),
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
}
