import 'package:flutter/material.dart';

import '../../data/models/offer_model.dart';
import '../../data/models/post_model.dart';
import '../profile/add_promotion_screen.dart';

class AddAdScreen extends StatelessWidget {
  final Offer? offer;
  final Post? initialProduct;
  final int? initialPackId;
  final String? initialPackName;

  const AddAdScreen({
    super.key,
    this.offer,
    this.initialProduct,
    this.initialPackId,
    this.initialPackName,
  });

  @override
  Widget build(BuildContext context) {
    return AddPromotionScreen(
      offer: offer,
      initialKind: 'advertising',
      initialProduct: initialProduct,
      initialPackId: initialPackId,
      initialPackName: initialPackName,
    );
  }
}
