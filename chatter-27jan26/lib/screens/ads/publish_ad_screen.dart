import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumosocial/common/api_service/post_service.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/extensions/string_extension.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/screens/wallet_screen/wallet_controller.dart';
import 'package:lumosocial/screens/extra_views/back_button.dart';
import 'package:lumosocial/screens/extra_views/top_bar.dart';
import 'package:lumosocial/utilities/const.dart';

class PublishAdScreen extends StatefulWidget {
  const PublishAdScreen({Key? key}) : super(key: key);

  @override
  State<PublishAdScreen> createState() => _PublishAdScreenState();
}

class _PublishAdScreenState extends State<PublishAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  final _quantityController = TextEditingController(text: "50");

  final WalletController _walletController = Get.put(WalletController());
  final ImagePicker _picker = ImagePicker();

  String _mediaType = 'video'; // 'video' or 'image'
  File? _selectedFile;
  bool _isUploading = false;
  String _pricingType = 'view'; // 'view', 'click', or 'both'
  double _calculatedCost = 10.0;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_recalculateCost);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _recalculateCost() {
    final int qty = int.tryParse(_quantityController.text) ?? 0;
    setState(() {
      if (_pricingType == 'view') {
        _calculatedCost = (qty / 50) * 10.0;
      } else if (_pricingType == 'click') {
        _calculatedCost = qty * 2.0;
      } else {
        // Both: 10 LC per 50 views + 2 LC per click
        _calculatedCost = ((qty / 50) * 10.0) + (qty * 2.0);
      }
    });
  }

  void _pickMedia() async {
    if (_mediaType == 'video') {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        final duration = await file.path.getVideoDurationInSecond;
        if (duration < 5 || duration > 120) {
          Get.snackbar(
            "Invalid Duration",
            "Video must be between 5 seconds and 2 minutes long.",
            backgroundColor: Colors.orange,
          );
          return;
        }
        setState(() {
          _selectedFile = File(file.path);
        });
      }
    } else {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _selectedFile = File(file.path);
        });
      }
    }
  }

  void _publishAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      Get.snackbar("Media Required", "Please select an ad video or image file.");
      return;
    }

    _walletController.fetchWalletDetails();
    if (_walletController.balance.value < _calculatedCost) {
      Get.snackbar("Insufficient Balance", "You need $_calculatedCost Lc, but only have ${_walletController.balance.value} Lc.");
      return;
    }

    // Prompt for PIN to confirm wallet transfer
    final pinController = TextEditingController();
    final pinConfirmed = await Get.defaultDialog<bool>(
      title: "Authorize Payment",
      titleStyle: MyTextStyle.gilroyBold(size: 18, color: cBlack),
      backgroundColor: cWhite,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Text(
              "Spend $_calculatedCost Lc to publish this ad campaign?",
              style: MyTextStyle.gilroyMedium(size: 14, color: cLightText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              style: const TextStyle(fontSize: 18, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: "Enter Transaction PIN",
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cPrimary)),
              ),
            ),
          ],
        ),
      ),
      textConfirm: "Confirm",
      textCancel: "Cancel",
      confirmTextColor: Colors.black,
      cancelTextColor: cLightText,
      buttonColor: cPrimary,
      onConfirm: () async {
        final verified = await _walletController.verifyTransactionPin(pinController.text.trim());
        if (verified) {
          Get.back(result: true);
        } else {
          Get.snackbar("Failed", "Incorrect Transaction PIN", backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );

    if (pinConfirmed != true) return;

    setState(() {
      _isUploading = true;
    });

    // 1. Pay with Lumo Coins (Send to admin/ad system account)
    final paymentSuccess = await _walletController.sendCoins(
      recipientIdentity: 'admin',
      amount: _calculatedCost,
    );

    if (!paymentSuccess) {
      setState(() {
        _isUploading = false;
      });
      return;
    }

    // 2. Upload Ad file
    PostService.shared.uploadFile(XFile(_selectedFile!.path), (url) async {
      if (url.isEmpty) {
        Get.snackbar("Upload Failed", "Could not upload ad media file.");
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // 3. Write Ad metadata to Firestore ads collection
      final qty = int.tryParse(_quantityController.text) ?? 50;
      final docRef = FirebaseFirestore.instance.collection('ads').doc();

      final adData = {
        'id': docRef.id,
        'userId': SessionManager.shared.getUserID(),
        'campaign_name': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'target_link': _linkController.text.trim(),
        'media_url': jsonEncode([url]),
        'mediaType': _mediaType,
        'pricingType': _pricingType,
        'budget': _calculatedCost,
        'remainingViews': _pricingType == 'view' || _pricingType == 'both' ? qty : 999999,
        'remainingClicks': _pricingType == 'click' || _pricingType == 'both' ? qty : 999999,
        'viewsCount': 0,
        'clicksCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'ad_type': 'Skippable Video',
      };

      await docRef.set(adData);

      setState(() {
        _isUploading = false;
      });

      Get.back();
      Get.snackbar(
        "Ad Published!",
        "Your ad has been successfully scheduled and paid.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cWhite,
      body: Stack(
        children: [
          Column(
            children: [
              const TopBarForInView(title: "Publish Lumo Ad"),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ad Center Header Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cBlack,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: cPrimary,
                                radius: 24,
                                child: Icon(Icons.campaign_rounded, color: Colors.black),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Publish Campaigns",
                                      style: MyTextStyle.gilroyBold(color: Colors.white, size: 16),
                                    ),
                                    Obx(() => Text(
                                          "Wallet Balance: ${_walletController.balance.value.toStringAsFixed(2)} Lc",
                                          style: MyTextStyle.gilroyMedium(color: cPrimary, size: 13),
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Fields
                        TextFormField(
                          controller: _titleController,
                          style: MyTextStyle.gilroyMedium(size: 15),
                          decoration: const InputDecoration(
                            labelText: "Campaign Title",
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cPrimary)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? "Please enter campaign title" : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _descController,
                          style: MyTextStyle.gilroyMedium(size: 15),
                          decoration: const InputDecoration(
                            labelText: "Description / Caption",
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cPrimary)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _linkController,
                          style: MyTextStyle.gilroyMedium(size: 15),
                          decoration: const InputDecoration(
                            labelText: "Action Link URL (Learn More)",
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cPrimary)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? "Please enter action link URL" : null,
                        ),
                        const SizedBox(height: 20),

                        // Media Type Selector
                        Text("Ad Media Type", style: MyTextStyle.gilroyBold(size: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'video',
                              groupValue: _mediaType,
                              activeColor: cPrimary,
                              onChanged: (val) {
                                setState(() {
                                  _mediaType = val!;
                                  _selectedFile = null;
                                });
                              },
                            ),
                            Text("Video Ad (5s - 2m)", style: MyTextStyle.gilroyMedium(size: 14)),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: 'image',
                              groupValue: _mediaType,
                              activeColor: cPrimary,
                              onChanged: (val) {
                                setState(() {
                                  _mediaType = val!;
                                  _selectedFile = null;
                                });
                              },
                            ),
                            Text("Image Ad", style: MyTextStyle.gilroyMedium(size: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // File Selector Button
                        InkWell(
                          onTap: _pickMedia,
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cLightBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                            ),
                            child: _selectedFile == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_rounded, size: 40, color: cLightText),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Select Ad File (${_mediaType.toUpperCase()})",
                                        style: MyTextStyle.gilroyMedium(color: cLightText, size: 13),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _mediaType == 'image'
                                        ? Image.file(_selectedFile!, fit: BoxFit.cover)
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.video_file_rounded, size: 40, color: cPrimary),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _selectedFile!.path.split('/').last,
                                                  style: MyTextStyle.gilroyBold(size: 13),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Campaign Budget Type Selector
                        Text("Campaign Objective", style: MyTextStyle.gilroyBold(size: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _pricingType,
                          style: MyTextStyle.gilroyMedium(size: 15, color: cBlack),
                          decoration: const InputDecoration(
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cPrimary)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'view', child: Text("Pay per 50 Views (10 Lc)")),
                            DropdownMenuItem(value: 'click', child: Text("Pay per Click (2 Lc)")),
                            DropdownMenuItem(value: 'both', child: Text("Both Views & Clicks (12 Lc)")),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _pricingType = val!;
                            });
                            _recalculateCost();
                          },
                        ),
                        const SizedBox(height: 16),

                        // Quantity selector
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          style: MyTextStyle.gilroyMedium(size: 15),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: "Target Count (Views or Clicks)",
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cPrimary)),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Please enter target count";
                            final num = int.tryParse(val) ?? 0;
                            if (num < 1) return "Count must be at least 1";
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Cost Card & Publish Button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cLightBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Total Campaign Cost", style: MyTextStyle.gilroyMedium(size: 13, color: cLightText)),
                                  Text("${_calculatedCost.toStringAsFixed(2)} Lc", style: MyTextStyle.gilroyBold(size: 20, color: cBlack)),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cPrimary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                onPressed: _publishAd,
                                child: Text("Publish Campaign", style: MyTextStyle.gilroyBold(size: 14)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: cPrimary),
                        SizedBox(height: 16),
                        Text("Publishing Campaign...", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
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
