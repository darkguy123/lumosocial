import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lumosocial/common/api_service/api_service.dart';
import 'package:lumosocial/common/managers/session_manager.dart';
import 'package:lumosocial/models/registration.dart';
import 'package:lumosocial/utilities/const.dart';
import 'package:lumosocial/utilities/web_service.dart';

class WalletController extends GetxController {
  final box = GetStorage();

  var isLoading = false.obs;
  var isSending = false.obs;

  var balance = 0.0.obs;
  var todayEarnings = 0.0.obs;
  var transactions = <dynamic>[].obs;
  var hasPin = false.obs;
  var useBiometrics = false.obs;
  
  // Exchange rates (Base: RWF, 1 Lc = 1 RWF)
  var usdRate = 0.00073.obs;
  var ngnRate = 1.15.obs;

  // Search Results
  var suggestedUsers = <User>[].obs;
  var isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    useBiometrics.value = box.read('use_biometrics') ?? false;
    fetchWalletDetails();
  }

  void toggleBiometrics(bool value) {
    useBiometrics.value = value;
    box.write('use_biometrics', value);
  }

  void fetchWalletDetails() {
    isLoading.value = true;
    final userId = SessionManager.shared.getUserID();
    
    ApiService.shared.call(
      url: WebService.walletDetails,
      param: {'user_id': userId},
      completion: (response) {
        isLoading.value = false;
        if (response['status'] == true) {
          final data = response['data'] ?? {};
          balance.value = double.tryParse(data['balance'].toString()) ?? 0.0;
          todayEarnings.value = double.tryParse(data['today_earnings'].toString()) ?? 0.0;
          hasPin.value = data['has_pin'] == true;
          transactions.value = data['transactions'] ?? [];
          
          final rates = data['rates'] ?? {};
          usdRate.value = double.tryParse(rates['USD'].toString()) ?? 0.00073;
          ngnRate.value = double.tryParse(rates['NGN'].toString()) ?? 1.15;
        }
      },
    );
  }

  void searchUsers(String query) {
    if (query.trim().length < 3) {
      suggestedUsers.clear();
      return;
    }
    
    isSearching.value = true;
    ApiService.shared.call(
      url: WebService.walletSearchUsers,
      param: {'query': query},
      completion: (response) {
        isSearching.value = false;
        if (response['status'] == true) {
          final list = response['data'] as List? ?? [];
          suggestedUsers.value = list.map((e) => User.fromJson(e)).toList();
        }
      },
    );
  }

  Future<bool> setTransactionPin(String pin) async {
    final userId = SessionManager.shared.getUserID();
    final completer = Completer<bool>();
    
    ApiService.shared.call(
      url: WebService.walletSetPin,
      param: {'user_id': userId, 'pin': pin},
      completion: (response) {
        if (response['status'] == true) {
          hasPin.value = true;
          completer.complete(true);
        } else {
          completer.complete(false);
          Get.snackbar(
            "Error",
            response['message'] ?? "Failed to set Transaction PIN.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
    return completer.future;
  }

  Future<bool> verifyTransactionPin(String pin) async {
    final userId = SessionManager.shared.getUserID();
    final completer = Completer<bool>();
    
    ApiService.shared.call(
      url: WebService.walletVerifyPin,
      param: {'user_id': userId, 'pin': pin},
      completion: (response) {
        if (response['status'] == true) {
          completer.complete(true);
        } else {
          completer.complete(false);
        }
      },
    );
    return completer.future;
  }

  Future<bool> sendCoins({
    required String recipientIdentity,
    required double amount,
  }) async {
    isSending.value = true;
    final senderId = SessionManager.shared.getUserID();

    final completer = Completer<bool>();

    ApiService.shared.call(
      url: WebService.walletSend,
      param: {
        'sender_id': senderId,
        'recipient_identity': recipientIdentity,
        'amount': amount,
      },
      completion: (response) {
        isSending.value = false;
        if (response['status'] == true) {
          fetchWalletDetails(); // Refresh wallet details
          completer.complete(true);
        } else {
          completer.complete(false);
          Get.snackbar(
            "Transfer Failed",
            response['message'] ?? "An error occurred during transfer.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );

    return completer.future;
  }
}
