import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawiva/models/pet_profile.dart';
import '../l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';

class EditPetDetailPage extends StatefulWidget {
  final PetProfile profile;
  final int profileIndex;
  final Function(int, PetProfile) onSave;
  final Function(int) onDelete;

  const EditPetDetailPage({
    super.key,
    required this.profile,
    required this.profileIndex,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditPetDetailPage> createState() => _EditPetDetailPageState();
}

class _EditPetDetailPageState extends State<EditPetDetailPage> {
  late File? _selectedImage;
  late String _petType;
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.profile.image;
    _petType = widget.profile.type;
    _nameController = TextEditingController(text: widget.profile.name);
    _nameFocusNode = FocusNode();

    _nameController.addListener(_checkForChanges);
    _nameFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final bool changed = _selectedImage?.path != widget.profile.image?.path ||
        _nameController.text != widget.profile.name ||
        _petType != widget.profile.type;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  void _handleFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      if (_nameController.text.trim().isEmpty) {
        setState(() {
          _nameController.text = widget.profile.name;
        });
        _checkForChanges();
      }
    }
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
      _checkForChanges();
    }
  }

  void _showDeleteDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editPetProfile), // Or a more specific delete key if we had one
        content: const Text("Are you sure you want to delete this pet profile?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel ?? "CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              widget.onDelete(widget.profileIndex);
              Navigator.pop(context); // back to list
            },
            child: Text(l10n.delete ?? "DELETE", style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 63 * scaleH),
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
                        l10n.editPetProfile,
                        style: GoogleFonts.nunito(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(height: 80 * scaleH),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
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
                                        : Container(color: Colors.grey[200]),
                                  ),
                                ),
                                Container(
                                  width: 140 * scale,
                                  height: 149 * scale,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(40 * scale),
                                  ),
                                ),
                                Icon(Icons.edit, size: 24 * scale, color: Colors.white),
                              ],
                            ),
                          ),
                          SizedBox(height: 72 * scaleH),
                          Container(
                            width: 280 * scale,
                            height: 47 * scale,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAE3C6),
                              borderRadius: BorderRadius.circular(15 * scale),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 1),
                            ),
                            child: TextField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.done,
                              style: GoogleFonts.nunito(fontSize: 20 * scale, color: Colors.black),
                              decoration: const InputDecoration(border: InputBorder.none),
                              onEditingComplete: () {
                                if (_nameController.text.trim().isEmpty) {
                                  setState(() {
                                    _nameController.text = widget.profile.name;
                                  });
                                  _checkForChanges();
                                }
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
                    )
                  ],
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
                    flex: 2,
                    child: GestureDetector(
                      onTap: _hasChanges
                          ? () {
                              widget.onSave(widget.profileIndex, PetProfile(
                                name: _nameController.text,
                                type: _petType,
                                image: _selectedImage,
                              ));
                              Navigator.pop(context);
                            }
                          : null,
                      child: Opacity(
                        opacity: _hasChanges ? 1.0 : 0.3,
                        child: Center(
                          child: Text(
                            l10n.saveChanges,
                            style: GoogleFonts.staatliches(fontSize: 20 * scale, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showDeleteDialog,
                      child: Icon(Icons.delete_outline, size: 24 * scale, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, double scale) {
    bool isSelected = _petType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _petType = type);
        _checkForChanges();
      },
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
