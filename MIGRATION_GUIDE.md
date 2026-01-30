# Design System Migration Quick Reference Guide

This guide provides quick patterns for migrating screens from the old blue/Cairo design to the new purple/Plus Jakarta Sans design system.

---

## 🎯 Quick Migration Checklist (Per Screen)

1. ✅ Update imports
2. ✅ Replace colors
3. ✅ Replace decorations
4. ✅ Replace text styles
5. ✅ Replace spacing
6. ✅ Update components
7. ✅ Test functionality

---

## 📦 Import Updates

### Add These Imports
```dart
// Theme
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_decorations.dart';

// Components
import '../../core/components/network_image_with_loader.dart';
import '../../core/components/skeleton_loader.dart';
import '../../core/components/dot_indicators.dart';
import '../../core/components/custom_modal_bottom_sheet.dart';
import '../../core/components/blur_container.dart';
import '../../core/components/check_mark.dart';
import '../../core/components/product/primary_product_card.dart';
import '../../core/components/product/secondary_product_card.dart';
```

---

## 🎨 Color Replacements

### Find and Replace (Global in File)
```dart
// Primary color
AppColors.primaryBlue        → AppColors.primaryColor
AppColors.primaryBlueDark    → AppColors.primaryDark
AppColors.primaryBlueLight   → AppColors.primaryLightShade

// Gradients
AppColors.blueGradient       → AppColors.purpleGradient
AppColors.goldGradient       → AppColors.purpleGradient

// Shadows
AppColors.goldShadow         → AppColors.purpleShadow

// Borders
AppColors.borderGold         → AppColors.borderPurple

// Notifications
AppColors.notificationBlue   → AppColors.notificationPurple
```

### Direct Color Values to Replace
```dart
Color(0xFF3B82F6)  → AppColors.primaryColor  // or Color(0xFF7B61FF)
Color(0xFF1D4ED8)  → AppColors.primaryDark   // or Color(0xFF6C56DD)
Color(0xFFDBEAFE)  → AppColors.primaryLightShade  // or Color(0xFFEFECFF)
```

---

## 📦 BoxDecoration Replacements

### Cards
```dart
// BEFORE
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [BoxShadow(...)],
)

// AFTER
AppDecorations.card()
// Or with custom color
AppDecorations.card(color: AppColors.surfacePrimary)
```

### Product Cards
```dart
// BEFORE
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Colors.grey),
)

// AFTER
AppDecorations.productCard()
```

### Search Bars
```dart
// BEFORE
BoxDecoration(
  color: Colors.grey[100],
  borderRadius: BorderRadius.circular(12),
)

// AFTER
AppDecorations.searchBar()
```

### Badges
```dart
// BEFORE (Discount badge)
BoxDecoration(
  color: Colors.red,
  borderRadius: BorderRadius.circular(8),
)

// AFTER
AppDecorations.discountBadge()

// BEFORE (Success badge)
BoxDecoration(
  color: Colors.green,
  borderRadius: BorderRadius.circular(8),
)

// AFTER
AppDecorations.successBadge()
```

### Gradients
```dart
// BEFORE
BoxDecoration(
  gradient: LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  ),
  borderRadius: BorderRadius.circular(16),
)

// AFTER
AppDecorations.primaryGradient()
```

### Filter Chips
```dart
// BEFORE
BoxDecoration(
  color: isActive ? Colors.blue : Colors.transparent,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: isActive ? Colors.blue : Colors.grey),
)

// AFTER
AppDecorations.filterChip(isActive: isActive)
```

### Circles (Avatars, Icons)
```dart
// BEFORE
BoxDecoration(
  color: Colors.white,
  shape: BoxShape.circle,
  border: Border.all(color: Colors.grey),
)

// AFTER
AppDecorations.circleBordered()
```

### Bottom Sheets
```dart
// BEFORE
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  ),
)

// AFTER
AppDecorations.bottomSheet()
```

---

## ✍️ Text Style Replacements

### Using AppTextStyles
```dart
// Headings
Text('Heading 1', style: AppTextStyles.h1)
Text('Heading 2', style: AppTextStyles.h2)
Text('Heading 3', style: AppTextStyles.h3)
Text('Heading 4', style: AppTextStyles.h4)

// Body
Text('Body text', style: AppTextStyles.bodyLarge)
Text('Body text', style: AppTextStyles.bodyMedium)
Text('Body text', style: AppTextStyles.bodySmall)

// Special
Text('Button', style: AppTextStyles.buttonText)
Text('$99.99', style: AppTextStyles.priceText)
Text('$149.99', style: AppTextStyles.oldPriceText)
Text('Link', style: AppTextStyles.linkText)
```

### Using Theme Text Styles
```dart
// Theme-based (automatically uses Plus Jakarta Sans)
Text('Title', style: Theme.of(context).textTheme.titleLarge)
Text('Body', style: Theme.of(context).textTheme.bodyMedium)
```

### Google Fonts Direct Replacement
```dart
// BEFORE
GoogleFonts.cairo(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
)

// AFTER
GoogleFonts.plusJakartaSans(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
)
```

---

## 📏 Spacing Replacements

### Padding
```dart
// BEFORE
Padding(padding: EdgeInsets.all(16))
Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8))

// AFTER
Padding(padding: EdgeInsets.all(AppConstants.defaultPadding))
Padding(padding: EdgeInsets.symmetric(
  horizontal: AppConstants.spacing16,
  vertical: AppConstants.spacing8,
))
```

### SizedBox
```dart
// BEFORE
SizedBox(height: 16)
SizedBox(width: 8)

// AFTER
SizedBox(height: AppConstants.spacing16)
SizedBox(width: AppConstants.spacing8)
```

### Border Radius
```dart
// BEFORE
BorderRadius.circular(12)
BorderRadius.circular(16)
BorderRadius.circular(20)

// AFTER
BorderRadius.circular(AppConstants.defaultBorderRadius)  // 12
BorderRadius.circular(AppConstants.radiusLarge)          // 16
BorderRadius.circular(AppConstants.radiusXL)             // 20
```

---

## 🔄 Component Replacements

### Loading Indicators
```dart
// BEFORE
CircularProgressIndicator()

// AFTER
Skeleton(height: 200, width: double.infinity)
// Or for circular
CircleSkeleton(size: 48)
```

### Network Images
```dart
// BEFORE
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
  loadingBuilder: (context, child, loadingProgress) =>
    loadingProgress == null ? child : CircularProgressIndicator(),
)

// AFTER
NetworkImageWithLoader(
  imageUrl,
  fit: BoxFit.cover,
  radius: AppConstants.defaultBorderRadius,
)
```

### Bottom Sheets
```dart
// BEFORE
showModalBottomSheet(
  context: context,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => Container(child: content),
)

// AFTER
customModalBottomSheet(
  context,
  child: content,
  height: 400,  // Optional
  isDismissible: true,  // Optional
)
```

### Product Cards
```dart
// BEFORE
Container(
  width: 140,
  height: 220,
  decoration: BoxDecoration(...),
  child: Column(
    children: [
      Image.network(product.image),
      Text(product.title),
      Text('\$${product.price}'),
    ],
  ),
)

// AFTER
PrimaryProductCard(
  image: product.imageUrl,
  brandName: product.storeName,
  title: product.title,
  price: product.price,
  priceAfterDiscount: product.oldPrice,
  discountPercent: product.discountPercent,
  press: () => Navigator.pushNamed(
    context,
    Routes.productDetails,
    arguments: product.id,
  ),
)
```

### Dot Indicators (Carousels)
```dart
// BEFORE
Container(
  width: isActive ? 12 : 4,
  height: 4,
  decoration: BoxDecoration(
    color: isActive ? Colors.blue : Colors.grey,
    borderRadius: BorderRadius.circular(12),
  ),
)

// AFTER
DotIndicator(
  isActive: currentIndex == index,
  activeColor: AppColors.primaryColor,
)
```

### Checkmarks
```dart
// BEFORE
Container(
  width: 24,
  height: 24,
  decoration: BoxDecoration(
    color: Colors.green,
    shape: BoxShape.circle,
  ),
  child: Icon(Icons.check, color: Colors.white, size: 16),
)

// AFTER
CheckMark(
  activeColor: AppColors.successGreen,
  size: 24,
)
```

---

## 🎭 Animation Duration

```dart
// BEFORE
Duration(milliseconds: 300)
Duration(milliseconds: 200)
Duration(milliseconds: 500)

// AFTER
AppConstants.defaultDuration  // 300ms
AppConstants.shortDuration    // 200ms
AppConstants.longDuration     // 500ms
```

---

## 🧪 Testing Checklist (Per Screen)

After migrating each screen, verify:

- [ ] **Visual:** Colors match purple theme (#7B61FF)
- [ ] **Typography:** Plus Jakarta Sans font renders correctly
- [ ] **Spacing:** Consistent padding (16px) and radius (12px)
- [ ] **RTL:** Layout works correctly in Arabic (if applicable)
- [ ] **Functionality:** All buttons, navigation, forms work
- [ ] **Loading:** Skeleton loaders appear during data fetch
- [ ] **Error:** Error states display correctly
- [ ] **Navigation:** Screen transitions work smoothly
- [ ] **State:** Provider state management still functions

---

## 🚨 Common Pitfalls

1. **Don't forget @Deprecated imports:** Old code may still use deprecated colors
2. **Test RTL:** Always test in Arabic to ensure layout doesn't break
3. **Watch for hardcoded colors:** Search for `Color(0x` to find hardcoded values
4. **Preserve functionality:** Migration should only change visuals, not behavior
5. **Use const constructors:** For decorations that don't change
6. **Check null safety:** Ensure all nullable values are handled

---

## 📝 Example: Full Screen Migration

### BEFORE
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details',
          style: GoogleFonts.cairo(fontSize: 18)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                )],
              ),
              child: Image.network('url'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
              ),
              child: Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### AFTER
```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/components/network_image_with_loader.dart';

class ProductDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),  // Theme handles font
      ),
      body: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Container(
              decoration: AppDecorations.card(),
              child: NetworkImageWithLoader('url'),
            ),
            SizedBox(height: AppConstants.spacing16),
            ElevatedButton(
              onPressed: () {},
              child: Text('Add to Cart'),  // Theme handles style
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 Quick Win Patterns

These patterns give the biggest visual impact with minimal code changes:

1. **Replace all `Color(0xFF3B82F6)` with `AppColors.primaryColor`**
2. **Replace all `BorderRadius.circular(12)` with `AppConstants.defaultBorderRadius`**
3. **Replace all `EdgeInsets.all(16)` with `AppConstants.defaultPadding`**
4. **Replace all card BoxDecorations with `AppDecorations.card()`**
5. **Replace all CircularProgressIndicator with `Skeleton()`**

---

## 📚 Reference Files

- **Colors:** `the_app/lib/core/theme/app_colors.dart`
- **Constants:** `the_app/lib/core/theme/app_constants.dart`
- **Text Styles:** `the_app/lib/core/theme/app_text_styles.dart`
- **Decorations:** `the_app/lib/core/theme/app_decorations.dart`
- **Theme:** `the_app/lib/core/theme/app_theme.dart`
- **Components:** `the_app/lib/core/components/`

---

## ✅ Migration Workflow

For each screen:

1. **Create a backup** (Git commit before changes)
2. **Update imports** (add theme and component imports)
3. **Find & replace colors** (use patterns above)
4. **Replace decorations** (BoxDecoration → AppDecorations)
5. **Update spacing** (magic numbers → AppConstants)
6. **Test functionality** (run app, verify screen works)
7. **Test RTL** (if applicable)
8. **Commit changes** (Git commit after verification)

---

## 🔍 Search Patterns

Use these regex/search patterns to find code that needs updating:

- `Color\(0xFF3B82F6\)` - Find blue color references
- `GoogleFonts\.cairo` - Find Cairo font usage
- `BorderRadius\.circular\(\d+\)` - Find border radius values
- `EdgeInsets\.all\(\d+\)` - Find padding values
- `BoxDecoration\(` - Find decoration instances
- `CircularProgressIndicator` - Find loading indicators

---

Good luck with the migration! 🚀
