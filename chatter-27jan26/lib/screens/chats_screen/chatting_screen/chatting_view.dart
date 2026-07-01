import 'package:detectable_text_field/widgets/detectable_text_field.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lumosocial/screens/wallet_screen/wallet_controller.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumosocial/common/extensions/font_extension.dart';
import 'package:lumosocial/common/extensions/int_extension.dart';
import 'package:lumosocial/common/widgets/functions.dart';
import 'package:lumosocial/common/widgets/menu.dart';
import 'package:lumosocial/common/widgets/my_cached_image.dart';
import 'package:lumosocial/localization/languages.dart';
import 'package:lumosocial/models/chat.dart';
import 'package:lumosocial/models/registration.dart';
import 'package:lumosocial/models/room_model.dart';
import 'package:lumosocial/screens/chats_screen/chat_room_view/room_menu/room_menu.dart';
import 'package:lumosocial/screens/chats_screen/chat_view/chat_tag.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/chatting_controller.dart';
import 'package:lumosocial/screens/chats_screen/chatting_screen/image_video_chat_picker.dart';
import 'package:lumosocial/screens/extra_views/back_button.dart';
import 'package:lumosocial/screens/post/comment/comment_screen.dart';
import 'package:lumosocial/screens/profile_screen/profile_screen.dart';
import 'package:lumosocial/screens/report_screen/report_sheet.dart';
import 'package:lumosocial/screens/rooms_screen/room_controller.dart';
import 'package:lumosocial/screens/rooms_screen/room_sheet.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/firebase_const.dart';

class ChattingView extends StatelessWidget {
  final Room? room;
  final User? user;
  final ChatUserRoom? chatUserRoom;

  const ChattingView({Key? key, this.room, this.user, this.chatUserRoom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Functions.changStatusBar(StatusBarStyle.white);
    ChattingController controller = ChattingController(room: room, user: user, chatUserRoom: chatUserRoom);
    return Scaffold(
      backgroundColor: cWhite,
      body: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            Get.back(result: controller.room);
          }
        },
        child: GetBuilder(
            init: controller,
            builder: (context) {
              return Column(
                children: [
                  top(controller),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: controller.messages.length,
                      padding: const EdgeInsets.all(10),
                      controller: controller.scrollController,
                      itemBuilder: (context, index) {
                        return ChatTag(
                          controller: controller,
                          index: index,
                          message: controller.messages[index],
                          isFromRoom: controller.chatUserRoom?.type == 2,
                        );
                      },
                    ),
                  ),
                  (controller.chatUserRoom?.iAmBlocked ?? false)
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
                          decoration: const ShapeDecoration(
                            color: cLightBg,
                            shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 5, cornerSmoothing: cornerSmoothing))),
                          ),
                          child: Text(
                            LKeys.youAreBlocked.tr,
                            style: MyTextStyle.gilroyRegular(color: cLightText),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Container(),
                  controller.chatUserRoom?.type == 0 ? requestBottom(controller) : bottom(controller),
                ],
              );
            }),
      ),
    );
  }

  Widget bottom(ChattingController controller) {
    return Obx(() {
      if (controller.isRecording.value) {
        return Container(
          padding: const EdgeInsets.all(7),
          color: cLightBg,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: controller.cancelRecording,
                  child: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.delete_forever_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: const ShapeDecoration(
                      color: Colors.white12,
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 20, cornerSmoothing: cornerSmoothing)),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: AudioWaveforms(
                      size: const Size(double.infinity, 30),
                      recorderController: controller.recorderController,
                      enableGesture: false,
                      waveStyle: const WaveStyle(
                        waveColor: cPrimary,
                        showDurationLabel: true,
                        durationLinesColor: cBlack,
                        extendWaveform: true,
                        showMiddleLine: false,
                        spacing: 6,
                        waveThickness: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: controller.stopAndSendVoiceNote,
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF00FF87),
                    child: Icon(Icons.send_rounded, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(7),
        color: cLightBg,
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: ShapeDecoration(
                    color: cLightText.withValues(alpha: 0.15),
                    shape: const SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius.all(
                        SmoothRadius(cornerRadius: 20, cornerSmoothing: cornerSmoothing),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 2, top: 2, right: 2, bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: DetectableTextField(
                            controller: controller.messageTextController,
                            maxLines: 5,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: LKeys.writeHere.tr,
                              hintStyle: MyTextStyle.gilroyRegular(color: cLightText.withValues(alpha: 0.6)),
                              border: InputBorder.none,
                              counterText: '',
                              isDense: true,
                              contentPadding: const EdgeInsets.all(0),
                            ),
                            cursorColor: cPrimary,
                            style: MyTextStyle.gilroyRegular(color: cLightText),
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                      ),
                      GestureDetector(onTap: controller.sendMsg, child: const SendBtn()),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: controller.startRecording,
                      child: const Icon(
                        Icons.mic_none_rounded,
                        color: cLightText,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        _openSendCoinsDirectSheet(Get.context!, controller);
                      },
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: Color(0xFF00FF87),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 5),
                    contentButton(iconData: Icons.add_circle_rounded, source: ImageSource.gallery, controller: controller),
                    const SizedBox(width: 5),
                    contentButton(iconData: Icons.camera_alt_rounded, source: ImageSource.camera, controller: controller),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget contentButton({required IconData iconData, required ImageSource source, required ChattingController controller}) {
    return GestureDetector(
      onTap: () {
        if (controller.chatUserRoom?.iAmBlocked == true) {
          return;
        }
        if (controller.chatUserRoom?.iBlocked == true) {
          controller.unblockUser(controller.user, () {});
          return;
        }
        final imagePicker = ImagePicker();
        Get.bottomSheet(ImageVideoOptionPicker(
          onImageTap: () async {
            XFile? file = await imagePicker.pickImage(source: source);
            print(file?.path);
            if (file != null) {
              Get.back();
              Get.bottomSheet(
                  WriteDescriptionSheet(
                    file: file,
                    controller: controller,
                    type: MessageType.image,
                  ),
                  isScrollControlled: true,
                  ignoreSafeArea: false);
            }
          },
          onVideoTap: () async {
            XFile? file = await imagePicker.pickVideo(source: source);
            print(file?.path);
            if (file != null) {
              Get.back();
              Get.bottomSheet(
                  WriteDescriptionSheet(
                    file: file,
                    controller: controller,
                    type: MessageType.video,
                  ),
                  isScrollControlled: true,
                  ignoreSafeArea: false);
            }
          },
        ));
      },
      child: Icon(
        iconData,
        color: cLightText,
        size: 28,
      ),
    );
  }

  Widget requestBottom(ChattingController controller) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: cLightBg,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Text(
              '${controller.user?.fullName ?? ''} ${LKeys.requestDesc.tr}',
              style: MyTextStyle.gilroyLight(color: cDarkText, size: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChatButton(
                    title: controller.chatUserRoom?.iBlocked ?? false ? LKeys.unBlock.tr : LKeys.block.tr,
                    color: cBlack,
                    onTap: () {
                      if (controller.chatUserRoom?.iBlocked ?? false) {
                        controller.unblockUser(controller.user, () {
                          controller.chatUserRoom?.iBlocked = false;
                        });
                      } else {
                        controller.blockUser(controller.user, () {
                          controller.chatUserRoom?.iBlocked = true;
                        });
                      }
                      controller.update();
                    }),
                ChatButton(
                  title: LKeys.reject,
                  color: cRed,
                  onTap: controller.rejectMessageRequest,
                ),
                ChatButton(
                  title: LKeys.accept,
                  color: cGreen,
                  onTap: controller.acceptMessageRequest,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget top(ChattingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      color: cDarkBG,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              child: const Icon(
                Icons.chevron_left_rounded,
                color: cWhite,
                size: 35,
              ),
              onTap: () {
                Get.back(result: controller.room);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (controller.user != null) {
                    Get.to(() => ProfileScreen(
                          userId: controller.user?.id ?? 0,
                        ));
                  } else if (controller.room != null) {
                    Get.bottomSheet(
                        RoomSheet(
                          room: controller.room!,
                          isFromInfo: true,
                          controller: RoomController(controller.room ?? Room()),
                        ),
                        isScrollControlled: true);
                  }
                },
                child: Row(
                  children: [
                    MyCachedProfileImage(
                      fullName: controller.chatUserRoom?.title,
                      imageUrl: controller.chatUserRoom?.profileImage,
                      width: 40,
                      height: 40,
                      cornerRadius: 100,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                controller.chatUserRoom?.title ?? '',
                                style: MyTextStyle.gilroyBold(size: 18, color: cWhite),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 1),
                              VerifyIcon(user: controller.user)
                            ],
                          ),
                          Row(
                            children: [
                              controller.chatUserRoom?.type == 2
                                  ? Row(
                                      children: [
                                        Text(
                                          controller.room?.totalMember?.makeToString() ?? '',
                                          style: MyTextStyle.gilroyBold(size: 14, color: cPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 5),
                                      ],
                                    )
                                  : Container(),
                              Text(
                                controller.chatUserRoom?.type == 2 ? LKeys.members.tr : "@${controller.user?.username ?? ''}",
                                style: MyTextStyle.gilroyLight(size: 15, color: cPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.chatUserRoom?.type != 2) ...[
              GestureDetector(
                onTap: controller.startVoiceCall,
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: Color(0xFF00FF87),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
            ],
            controller.chatUserRoom?.type == 2
                ? RoomMenu(controller: controller)
                : Menu(
                    items: [
                      PopupMenuItem(
                        textStyle: MyTextStyle.gilroyMedium(),
                        child: Text(
                          LKeys.report.tr,
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 1), () {
                            Get.bottomSheet(ReportSheet(user: controller.user), isScrollControlled: true);
                          });
                        },
                      ),
                      PopupMenuItem(
                        textStyle: MyTextStyle.gilroyMedium(),
                        child: Text(controller.chatUserRoom?.iBlocked ?? false ? LKeys.unBlock.tr : LKeys.block.tr),
                        onTap: () {
                          if (controller.chatUserRoom?.iBlocked ?? false) {
                            controller.unblockUser(controller.user, () {
                              controller.chatUserRoom?.iBlocked = false;
                            });
                          } else {
                            controller.blockUser(controller.user, () {
                              controller.chatUserRoom?.iBlocked = true;
                            });
                          }
                          controller.update();
                        },
                      ),
                    ],
                    color: cPrimary,
                  )
          ],
        ),
      ),
    );
  }

  void _openSendCoinsDirectSheet(BuildContext context, ChattingController chatController) {
    final walletController = Get.put(WalletController());
    walletController.fetchWalletDetails(); // Ensure we have the latest balance

    double amount = 0.0;
    int currentStep = 1;

    final TextEditingController amountController = TextEditingController();
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    final recipientUser = chatController.user;
    final recipientUsername = recipientUser?.username ?? "User";
    final recipientProfile = recipientUser?.profile ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 25,
              bottom: MediaQuery.of(context).viewInsets.bottom + 25,
            ),
            child: Obx(() {
              if (walletController.isLoading.value) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF87)),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Text(
                    currentStep == 1
                        ? "Send Coins"
                        : currentStep == 2
                            ? "Confirm Transfer"
                            : walletController.hasPin.value
                                ? "Enter PIN"
                                : "Setup PIN",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Gilroy-Bold',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // STEP 1: Balance Card & Amount Input
                  if (currentStep == 1) ...[
                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Available Balance",
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${walletController.balance.value.toStringAsFixed(2)} Lc",
                            style: const TextStyle(
                              color: Color(0xFF00FF87),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Amount to send to @$recipientUsername",
                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
                        suffixText: "Lc",
                        suffixStyle: const TextStyle(color: Color(0xFF00FF87), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF87),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          amount = double.tryParse(amountController.text) ?? 0.0;
                          if (amount <= 0) {
                            Get.snackbar("Invalid Amount", "Please enter a valid amount.", backgroundColor: Colors.orange);
                            return;
                          }
                          if (amount > walletController.balance.value) {
                            Get.snackbar("Insufficient Balance", "You do not have enough coins.", backgroundColor: Colors.red, colorText: Colors.white);
                            return;
                          }
                          setModalState(() {
                            currentStep = 2;
                          });
                        },
                        child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],

                  // STEP 2: Confirmation
                  if (currentStep == 2) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "you are sending ${amount.toStringAsFixed(2)} Lc",
                            style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "New balance: ${(walletController.balance.value - amount).toStringAsFixed(2)} Lc",
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "to @$recipientUsername",
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: recipientProfile.isNotEmpty
                                    ? Image.network(recipientProfile, width: 30, height: 30, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const CircleAvatar(radius: 15, child: Icon(Icons.person)))
                                    : const CircleAvatar(radius: 15, child: Icon(Icons.person)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF87),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          // Biometric Auth
                          if (walletController.useBiometrics.value) {
                            final LocalAuthentication localAuth = LocalAuthentication();
                            bool canAuth = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
                            if (canAuth) {
                              bool authenticated = await localAuth.authenticate(
                                localizedReason: 'Authorize transfer of $amount Lc to @$recipientUsername',
                                options: const AuthenticationOptions(
                                  biometricOnly: true,
                                  stickyAuth: true,
                                ),
                              );
                              if (authenticated) {
                                _executeDirectTransfer(recipientUsername, amount, walletController);
                                return;
                              }
                            }
                          }
                          // PIN Validation Flow (Fallback)
                          setModalState(() {
                            currentStep = 3;
                          });
                        },
                        child: const Text("Complete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],

                  // STEP 3: Setup or Enter PIN
                  if (currentStep == 3) ...[
                    if (walletController.hasPin.value) ...[
                      const Text(
                        "Please enter your 4-digit Transaction PIN to authorize this transfer.",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 10),
                        decoration: const InputDecoration(
                          labelText: "Transaction PIN",
                          labelStyle: TextStyle(color: Colors.white54, letterSpacing: 0),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF87),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            String pin = pinController.text.trim();
                            if (pin.length != 4) {
                              Get.snackbar("Invalid PIN", "Please enter a valid 4-digit PIN.", backgroundColor: Colors.orange);
                              return;
                            }

                            Get.dialog(
                              const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)))),
                              barrierDismissible: false,
                            );

                            bool verified = await walletController.verifyTransactionPin(pin);
                            Get.back(); // close loader

                            if (verified) {
                              _executeDirectTransfer(recipientUsername, amount, walletController);
                            } else {
                              Get.snackbar("Authentication Failed", "Incorrect Transaction PIN.", backgroundColor: Colors.red, colorText: Colors.white);
                            }
                          },
                          child: const Text("Confirm & Authorize", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "Setup a 4-digit Transaction PIN to keep your transfers secure.",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 8),
                        decoration: const InputDecoration(
                          labelText: "Enter 4-digit PIN",
                          labelStyle: TextStyle(color: Colors.white54, letterSpacing: 0),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmPinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 8),
                        decoration: const InputDecoration(
                          labelText: "Confirm 4-digit PIN",
                          labelStyle: TextStyle(color: Colors.white54, letterSpacing: 0),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF87),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            String pin = pinController.text.trim();
                            String confirm = confirmPinController.text.trim();

                            if (pin.length != 4 || confirm.length != 4) {
                              Get.snackbar("Invalid PIN", "PIN must be exactly 4 digits.", backgroundColor: Colors.orange);
                              return;
                            }
                            if (pin != confirm) {
                              Get.snackbar("PIN Mismatch", "The PINs you entered do not match.", backgroundColor: Colors.orange);
                              return;
                            }

                            Get.dialog(
                              const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)))),
                              barrierDismissible: false,
                            );

                            bool success = await walletController.setTransactionPin(pin);
                            Get.back(); // close loader

                            if (success) {
                              _executeDirectTransfer(recipientUsername, amount, walletController);
                            }
                          },
                          child: const Text("Set PIN & Transfer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ],
                ],
              );
            }),
          );
        });
      },
    );
  }

  void _executeDirectTransfer(String recipient, double amount, WalletController walletController) {
    Get.dialog(
      const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)))),
      barrierDismissible: false,
    );

    walletController.sendCoins(recipientIdentity: recipient, amount: amount).then((success) {
      Get.back(); // close loading dialog
      if (success) {
        Get.back(); // close send modal sheet
        Get.snackbar(
          "Transfer Successful",
          "You have sent $amount Lc to @$recipient successfully.",
          backgroundColor: const Color(0xFF00FF87),
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    });
  }
}
