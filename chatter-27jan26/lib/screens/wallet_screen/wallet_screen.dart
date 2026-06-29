import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/screens/wallet_screen/wallet_controller.dart';
import 'package:lumosocial/screens/wallet_screen/scanner_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController controller = Get.put(WalletController());
  String _selectedCurrency = 'RWF'; // Default currency view conversion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBlack,
      appBar: AppBar(
        backgroundColor: cBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF00FF87),
              shadows: [
                BoxShadow(
                  color: Color(0xFF00FF87),
                  blurRadius: 15,
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Text(
              "Lumo Wallet",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gilroy-Bold',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => controller.fetchWalletDetails(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.balance.value == 0) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)),
            ),
          );
        }

        double balanceVal = controller.balance.value;
        String displayValueText = "";
        if (_selectedCurrency == 'RWF') {
          displayValueText = "${balanceVal.toStringAsFixed(2)} RWF";
        } else if (_selectedCurrency == 'USD') {
          double usdVal = balanceVal * controller.usdRate.value;
          displayValueText = "\$${usdVal.toStringAsFixed(2)} USD";
        } else if (_selectedCurrency == 'NGN') {
          double ngnVal = balanceVal * controller.ngnRate.value;
          displayValueText = "₦${ngnVal.toStringAsFixed(2)} NGN";
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Apple Pay Style Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF00FF87).withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          const Text(
                            "Lumo Coin Balance",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontFamily: 'Gilroy-Medium',
                            ),
                          ),
                          GestureDetector(
                            onTap: _scanQrCode,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xFF00FF87),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "${balanceVal.toStringAsFixed(2)} Lc",
                        style: const TextStyle(
                          color: Color(0xFF00FF87),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Gilroy-Bold',
                          shadows: [
                            BoxShadow(
                              color: Color(0xFF00FF87),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(
                            displayValueText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Gilroy-SemiBold',
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              dropdownColor: const Color(0xFF1E1E1E),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                              items: ['RWF', 'NGN', 'USD'].map((String currency) {
                                return DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(
                                    currency,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCurrency = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
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
              // User info card inside modal
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
              // QR Code container
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
    final TextEditingController passwordController = TextEditingController();

    if (prefilledRecipient != null) {
      currentStep = 2; // Jump to recipient verification if scanned
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
          // Suggestion list callback
          void onSearchTextChanged(String text) {
            controller.searchUsers(text);
            setModalState(() {});
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 30,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
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
                const SizedBox(height: 20),
                Text(
                  currentStep == 1
                      ? "Enter Amount"
                      : currentStep == 2
                          ? "Select Recipient"
                          : currentStep == 3
                              ? "Confirm Transfer"
                              : "Enter Password",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Gilroy-Bold',
                  ),
                ),
                const SizedBox(height: 20),

                // STEP 1: Enter Amount
                if (currentStep == 1) ...[
                  Text(
                    "Available Balance: ${controller.balance.value.toStringAsFixed(2)} Lc",
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixText: "Lc ",
                      prefixStyle: const TextStyle(color: Color(0xFF00FF87), fontSize: 24, fontWeight: FontWeight.bold),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFF00FF87).withValues(alpha: 0.3)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF87)),
                      ),
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
                        double enteredAmt = double.tryParse(amountController.text) ?? 0.0;
                        if (enteredAmt <= 0) {
                          Get.snackbar("Invalid Amount", "Please enter an amount greater than 0.", backgroundColor: Colors.orange);
                          return;
                        }
                        if (enteredAmt > controller.balance.value) {
                          Get.snackbar("Insufficient Funds", "You do not have enough coins.", backgroundColor: Colors.orange);
                          return;
                        }
                        amount = enteredAmt;
                        setModalState(() {
                          currentStep = 2;
                        });
                      },
                      child: const Text("Next", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],

                // STEP 2: Enter Recipient
                if (currentStep == 2) ...[
                  TextField(
                    controller: recipientController,
                    onChanged: onSearchTextChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Recipient Username or Email",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF87)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (controller.isSearching.value)
                    const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87))))
                  else if (controller.suggestedUsers.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.suggestedUsers.length,
                        itemBuilder: (context, index) {
                          final user = controller.suggestedUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profile != null && user.profile!.isNotEmpty
                                  ? CachedNetworkImageProvider(user.profile!)
                                  : null,
                              child: user.profile == null || user.profile!.isEmpty
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(user.username ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(user.fullName ?? '', style: const TextStyle(color: Colors.white54)),
                            onTap: () {
                              selectedUser = user;
                              recipient = user.username ?? '';
                              recipientController.text = recipient;
                              controller.suggestedUsers.clear();
                              setModalState(() {});
                            },
                          );
                        },
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
                        if (recipientController.text.trim().isEmpty) {
                          Get.snackbar("Error", "Please select or type a recipient.", backgroundColor: Colors.orange);
                          return;
                        }
                        recipient = recipientController.text.trim();
                        setModalState(() {
                          currentStep = 3;
                        });
                      },
                      child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],

                // STEP 3: Confirm Transfer
                if (currentStep == 3) ...[
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: const Color(0xFF1E1E1E),
                          backgroundImage: selectedUser != null && selectedUser!.profile != null && selectedUser!.profile!.isNotEmpty
                              ? CachedNetworkImageProvider(selectedUser!.profile!)
                              : null,
                          child: selectedUser == null || selectedUser!.profile == null || selectedUser!.profile!.isEmpty
                              ? const Icon(Icons.person, size: 35, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "@$recipient",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Amount details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      const Text("Amount to Send", style: TextStyle(color: Colors.white54, fontSize: 14)),
                      Text("${amount.toStringAsFixed(2)} Lc", style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      const Text("Remaining Balance", style: TextStyle(color: Colors.white54, fontSize: 14)),
                      Text("${(controller.balance.value - amount).toStringAsFixed(2)} Lc", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
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
                        // Check if email/password login user to ask for password verification
                        bool hasPassword = false;
                        final fbUser = fb.FirebaseAuth.instance.currentUser;
                        if (fbUser != null) {
                          for (final userInfo in fbUser.providerData) {
                            if (userInfo.providerId == 'password') {
                              hasPassword = true;
                            }
                          }
                        }
                        
                        if (hasPassword) {
                          setModalState(() {
                            currentStep = 4;
                          });
                        } else {
                          // Social logins bypass password auth
                          _executeTransfer(recipient, amount);
                        }
                      },
                      child: const Text("Send Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],

                // STEP 4: Password Verification
                if (currentStep == 4) ...[
                  const Text(
                    "Please authenticate this transaction with your profile password.",
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FF87)),
                      ),
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
                        String pass = passwordController.text.trim();
                        if (pass.isEmpty) {
                          Get.snackbar("Error", "Password is required.", backgroundColor: Colors.orange);
                          return;
                        }

                        // Authenticate Firebase Auth locally
                        Get.dialog(
                          const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)))),
                          barrierDismissible: false,
                        );

                        try {
                          final email = fb.FirebaseAuth.instance.currentUser?.email;
                          if (email != null) {
                            final credential = fb.EmailAuthProvider.credential(email: email, password: pass);
                            await fb.FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
                          }
                          Get.back(); // close loading dialog
                          
                          // Execute transfer
                          _executeTransfer(recipient, amount);
                        } catch (e) {
                          Get.back(); // close loading dialog
                          Get.snackbar(
                            "Authentication Failed",
                            "Incorrect profile password. Please try again.",
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                      child: const Text("Confirm & Authorize", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
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
