import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:local_auth/local_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/models/registration.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/screens/wallet_screen/wallet_controller.dart';
import 'package:lumosocial/screens/wallet_screen/scanner_screen.dart';
import 'package:lumosocial/common/extensions/image_extension.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController controller = Get.put(WalletController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      appBar: AppBar(
        backgroundColor: cBlack,
        elevation: 0,
        title: const Text(
          "Lumo Wallet",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Gilroy-Bold',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00FF87)),
            onPressed: _scanQrCode,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: cPrimary));
        }

        final exchangeRatesText = "1 Lc = 1 RWF\n"
            "≈ \$${(controller.balance.value * controller.usdRate.value).toStringAsFixed(4)} USD\n"
            "≈ ₦${(controller.balance.value * controller.ngnRate.value).toStringAsFixed(2)} NGN";

        final displayValueText = "≈ ₦${(controller.balance.value * controller.ngnRate.value).toStringAsFixed(2)} NGN";

        return RefreshIndicator(
          color: const Color(0xFF00FF87),
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: () async {
            controller.fetchWalletDetails();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Apple Pay/Paypal Premium Wallet Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF00FF87).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF87).withValues(alpha: 0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Lumo Coin Balance",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontFamily: 'Gilroy-Medium',
                              ),
                            ),
                            Image.asset(
                              MyImages.walletIcon,
                              width: 32,
                              height: 32,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${controller.balance.value.toStringAsFixed(2)} Lc",
                          style: const TextStyle(
                            color: Color(0xFF00FF87),
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Gilroy-Bold',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              displayValueText,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontFamily: 'Gilroy-Regular',
                              ),
                            ),
                            Text(
                              "1 Lc = 1 RWF",
                              style: TextStyle(
                                color: const Color(0xFF00FF87).withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Gilroy-Bold',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Exchange Rates Details Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF00FF87), size: 24),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          exchangeRatesText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                            fontFamily: 'Gilroy-Medium',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Send / Receive Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF87),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () => _openSendCoinsModal(context),
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: const Text(
                          "Send",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Gilroy-Bold',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00FF87),
                          side: const BorderSide(color: Color(0xFF00FF87), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openReceiveCoinsModal(context),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                        label: const Text(
                          "Receive",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Gilroy-Bold',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Biometrics Settings Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fingerprint_rounded, color: Color(0xFF00FF87), size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Biometric Authorization",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Use Face ID / Fingerprint for transfers",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: controller.useBiometrics.value,
                        activeColor: const Color(0xFF00FF87),
                        activeTrackColor: const Color(0xFF00FF87).withValues(alpha: 0.2),
                        onChanged: (value) async {
                          if (value) {
                            final LocalAuthentication localAuth = LocalAuthentication();
                            bool canAuth = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
                            if (canAuth) {
                              bool authenticated = await localAuth.authenticate(
                                localizedReason: 'Authenticate to enable biometric transfers',
                                options: const AuthenticationOptions(
                                  biometricOnly: true,
                                  stickyAuth: true,
                                ),
                              );
                              if (authenticated) {
                                controller.toggleBiometrics(true);
                              }
                            } else {
                              Get.snackbar(
                                "Not Supported",
                                "Biometric authentication is not supported on this device.",
                                backgroundColor: Colors.orange,
                                colorText: Colors.black,
                              );
                            }
                          } else {
                            controller.toggleBiometrics(false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // Transactions Header
                const Text(
                  "Transactions History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy-Bold',
                  ),
                ),
                const SizedBox(height: 15),

                // Transactions list
                controller.transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40.0),
                          child: Column(
                            children: [
                              Icon(
                                  Icons.receipt_long_rounded,
                                  size: 50,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                "No transaction history yet",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 14,
                                  fontFamily: 'Gilroy-Regular',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.transactions.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final tx = controller.transactions[index];
                          final isReward = tx['type'] == 'reward';
                          final sender = tx['sender'];
                          final recipient = tx['recipient'];
                          final myId = SessionManager.shared.getUserID();
                          
                          final isIncoming = isReward || (recipient != null && recipient['id'] == myId);
                          final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
                          
                          String title = "Transfer";
                          String subtitle = tx['description'] ?? '';
                          String avatarUrl = "";
                          
                          if (isReward) {
                            title = "System Reward";
                          } else if (isIncoming && sender != null) {
                            title = "From ${sender['username'] ?? 'User'}";
                            avatarUrl = sender['profile'] ?? '';
                          } else if (recipient != null) {
                            title = "To ${recipient['username'] ?? 'User'}";
                            avatarUrl = recipient['profile'] ?? '';
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                                  child: avatarUrl.isEmpty
                                      ? Icon(
                                          isReward ? Icons.redeem_rounded : Icons.person_rounded,
                                          color: isReward ? const Color(0xFF00FF87) : Colors.white54,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  isIncoming ? "+${amount.toStringAsFixed(2)} Lc" : "-${amount.toStringAsFixed(2)} Lc",
                                  style: TextStyle(
                                    color: isIncoming ? const Color(0xFF00FF87) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    shadows: isIncoming
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00FF87).withValues(alpha: 0.2),
                                              blurRadius: 5,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Action methods
  Future<void> _scanQrCode() async {
    final result = await Get.to(() => const ScannerScreen());
    if (result is String && result.isNotEmpty) {
      _openSendCoinsModal(context, prefilledRecipient: result);
    }
  }

  void _openReceiveCoinsModal(BuildContext context) {
    final username = SessionManager.shared.getUser()?.username ?? "unknown";
    final avatar = SessionManager.shared.getUser()?.profile ?? "";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "My QR Code",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Gilroy-Bold',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1E1E1E),
                    backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                    child: avatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "@$username",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: username,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Scan this QR code with another device to receive Lumo Coins instantly",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontFamily: 'Gilroy-Regular',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _openSendCoinsModal(BuildContext context, {String? prefilledRecipient}) {
    double amount = 0.0;
    String recipient = prefilledRecipient ?? "";
    User? selectedUser;
    
    // Page controllers/states
    int currentStep = 1;
    final TextEditingController amountController = TextEditingController();
    final TextEditingController recipientController = TextEditingController(text: prefilledRecipient);
    
    // PIN controllers
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    if (prefilledRecipient != null) {
      currentStep = 2; // Jump to amount setting if scanned
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          void onSearchTextChanged(String text) {
            controller.searchUsers(text);
            setModalState(() {});
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 25,
              bottom: MediaQuery.of(context).viewInsets.bottom + 25,
            ),
            child: Column(
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

                // Title based on steps
                Text(
                  currentStep == 1
                      ? "Search Recipient"
                      : currentStep == 2
                          ? "Enter Amount"
                          : currentStep == 3
                              ? "Confirm Transfer"
                              : controller.hasPin.value
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

                // STEP 1: Search Recipient
                if (currentStep == 1) ...[
                  TextField(
                    controller: recipientController,
                    onChanged: onSearchTextChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Enter username or email",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Suggested users list
                  if (controller.isSearching.value)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Color(0xFF00FF87)),
                    ))
                  else if (controller.suggestedUsers.isNotEmpty)
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        itemCount: controller.suggestedUsers.length,
                        itemBuilder: (context, index) {
                          final user = controller.suggestedUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profile != null ? CachedNetworkImageProvider(user.profile!) : null,
                              child: user.profile == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(user.fullName ?? '', style: const TextStyle(color: Colors.white)),
                            subtitle: Text("@${user.username ?? ''}", style: const TextStyle(color: Colors.white54)),
                            onTap: () {
                              selectedUser = user;
                              recipient = user.username ?? "";
                              setModalState(() {
                                currentStep = 2;
                              });
                            },
                          );
                        },
                      ),
                    )
                  else if (recipientController.text.length >= 3)
                    const Center(child: Text("No users found", style: TextStyle(color: Colors.white30))),
                ],

                // STEP 2: Enter Amount
                if (currentStep == 2) ...[
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Amount (Lc)",
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
                      suffixText: "Lc",
                      suffixStyle: const TextStyle(color: Color(0xFF00FF87), fontSize: 18, fontWeight: FontWeight.bold),
                      helperText: "Available: ${controller.balance.value.toStringAsFixed(2)} Lc",
                      helperStyle: const TextStyle(color: Colors.white38),
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
                          Get.snackbar("Invalid Amount", "Please enter a valid transfer amount.", backgroundColor: Colors.orange);
                          return;
                        }
                        if (amount > controller.balance.value) {
                          Get.snackbar("Insufficient Balance", "You do not have enough coins.", backgroundColor: Colors.red, colorText: Colors.white);
                          return;
                        }
                        
                        // Validate username
                        if (recipient.isEmpty) {
                          recipient = recipientController.text.trim();
                        }
                        if (recipient.toLowerCase() == (SessionManager.shared.getUser()?.username ?? '').toLowerCase()) {
                          Get.snackbar("Transfer Error", "You cannot send coins to yourself.", backgroundColor: Colors.red, colorText: Colors.white);
                          return;
                        }

                        setModalState(() {
                          currentStep = 3;
                        });
                      },
                      child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],

                // STEP 3: Confirm Transfer Details
                if (currentStep == 3) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "${amount.toStringAsFixed(2)} Lc",
                          style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, fontSize: 32),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "to @$recipient",
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Amount to Send", style: TextStyle(color: Colors.white54, fontSize: 14)),
                      Text("${amount.toStringAsFixed(2)} Lc", style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Remaining Balance", style: TextStyle(color: Colors.white54, fontSize: 14)),
                      Text("${(controller.balance.value - amount).toStringAsFixed(2)} Lc", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
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
                        // Optional Biometric Auth Check
                        if (controller.useBiometrics.value) {
                          final LocalAuthentication localAuth = LocalAuthentication();
                          bool canAuth = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
                          if (canAuth) {
                            bool authenticated = await localAuth.authenticate(
                              localizedReason: 'Authorize transfer of $amount Lc to @$recipient',
                              options: const AuthenticationOptions(
                                biometricOnly: true,
                                stickyAuth: true,
                              ),
                            );
                            if (authenticated) {
                              _executeTransfer(recipient, amount);
                              return;
                            }
                          }
                        }

                        // PIN Validation Flow (Fallback)
                        setModalState(() {
                          currentStep = 4;
                        });
                      },
                      child: const Text("Send Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],

                // STEP 4: Setup or Enter PIN
                if (currentStep == 4) ...[
                  if (controller.hasPin.value) ...[
                    // Enter PIN Flow
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

                          bool verified = await controller.verifyTransactionPin(pin);
                          Get.back(); // close loader

                          if (verified) {
                            _executeTransfer(recipient, amount);
                          } else {
                            Get.snackbar("Authentication Failed", "Incorrect Transaction PIN.", backgroundColor: Colors.red, colorText: Colors.white);
                          }
                        },
                        child: const Text("Confirm & Authorize", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    // Setup PIN Flow
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

                          bool success = await controller.setTransactionPin(pin);
                          Get.back(); // close loader

                          if (success) {
                            _executeTransfer(recipient, amount);
                          }
                        },
                        child: const Text("Set PIN & Transfer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        });
      },
    );
  }

  void _executeTransfer(String recipient, double amount) {
    Get.dialog(
      const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)))),
      barrierDismissible: false,
    );

    controller.sendCoins(recipientIdentity: recipient, amount: amount).then((success) {
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
