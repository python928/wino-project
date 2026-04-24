// ViewTracker is no longer needed.
// Product views are tracked server-side in ProductViewSet.retrieve().
// This file is kept as a stub so old imports don't break.

import 'package:flutter/material.dart';

@Deprecated('Views are tracked server-side. Remove ViewTracker wrapping.')
class ViewTracker extends StatelessWidget {
  final int productId;
  final Widget child;
  const ViewTracker({super.key, required this.productId, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
