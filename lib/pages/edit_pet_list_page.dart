import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawiva/models/pet_profile.dart';
import '../l10n/app_localizations.dart';
import 'edit_pet_detail_page.dart';
import 'add_new_pet_page.dart';

class EditPetListPage extends StatefulWidget {
  final List<PetProfile> profiles;
  final Function(List<PetProfile>) onProfilesChanged;

  const EditPetListPage({
    super.key,
    required this.profiles,
    required this.onProfilesChanged,
  });

  @override
  State<EditPetListPage> createState() => _EditPetListPageState();
}

class _EditPetListPageState extends State<EditPetListPage> {
  late List<PetProfile> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = List.from(widget.profiles);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_profiles.map((p) => {
      'name': p.name,
      'type': p.type,
      'imagePath': p.image?.path,
    }).toList());
    await prefs.setString('pet_profiles', encoded);
    widget.onProfilesChanged(_profiles);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double scaleW = MediaQuery.of(context).size.width / 393;
    final double scaleH = MediaQuery.of(context).size.height / 852;
    final double scale = (scaleW + scaleH) / 2;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double navBar = bottomInset > 40 ? bottomInset : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 63 * scaleH + navBar),
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
                        padding: EdgeInsets.symmetric(vertical: 24 * scale),
                        child: Column(
                          children: [
                            ..._profiles.asMap().entries.map((entry) {
                              int idx = entry.key;
                              PetProfile profile = entry.value;
                              bool isLast = idx == _profiles.length - 1;

                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditPetDetailPage(
                                            profile: profile,
                                            profileIndex: idx,
                                            onSave: (index, updated) {
                                              setState(() => _profiles[index] = updated);
                                              _saveToPrefs();
                                            },
                                            onDelete: (index) {
                                              setState(() => _profiles.removeAt(index));
                                              _saveToPrefs();
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 80 * scale,
                                          height: 80 * scale,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18 * scale),
                                            border: Border.all(color: Colors.black, width: 1),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(18 * scale),
                                            child: profile.image != null
                                                ? Image.file(profile.image!, fit: BoxFit.cover)
                                                : Container(
                                                    color: Colors.grey[200],
                                                    child: Icon(Icons.pets, size: 32 * scale, color: Colors.grey),
                                                  ),
                                          ),
                                        ),
                                        SizedBox(height: 8 * scale),
                                        Text(
                                          profile.name,
                                          style: GoogleFonts.nunito(
                                            fontSize: 20 * scale,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16 * scale),
                                  if (!isLast) ...[
                                    Container(
                                      width: 106 * scale,
                                      height: 1,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 16 * scale),
                                  ],
                                ],
                              );
                            }),
                            if (_profiles.isNotEmpty) ...[
                              Container(
                                width: 106 * scale,
                                height: 1,
                                color: Colors.black,
                              ),
                              SizedBox(height: 16 * scale),
                            ],
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddNewPetPage(
                                      onAdd: (newProfile) {
                                        setState(() => _profiles.add(newProfile));
                                        _saveToPrefs();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.add,
                                size: 32 * scale,
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
          ),
        ],
      ),
    );
  }
}
