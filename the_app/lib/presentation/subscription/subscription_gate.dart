import 'package:flutter/material.dart';

import '../wallet/coin_store_screen.dart';

Future<void> openCoinStore(
  BuildContext context, {
  int? required,
  int? balance,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CoinStoreScreen(
        requiredCoins: required,
        currentBalance: balance,
      ),
    ),
  );
}
