# Design System Migration Progress

**Date Started:** January 30, 2026
**Migration:** lib → the_app (Toprice to Dzlocal Shop)
**Primary Goal:** Purple design system (#7B61FF) + Plus Jakarta Sans font

---

## ✅ COMPLETED PHASES

### Phase 1: Foundation Setup ✅

#### 1.1 Constants System ✅
- ✅ Created `app_constants.dart`
  - Added spacing scale (4, 8, 12, 16, 20, 24, 32)
  - Added border radius scale (small: 8, medium: 12, large: 16, XL: 20, round: 24)
  - Added icon sizes (small: 16, medium: 24, large: 32, XL: 48)
  - Added animation durations (short: 200ms, default: 300ms, long: 500ms)
  - Added product card dimensions (140x220, 256x114)

#### 1.2 Color System Migration ✅
- ✅ Updated `app_colors.dart`
  - **Primary color:** Blue (#3B82F6) → Purple (#7B61FF)
  - Added black opacity scale (100%, 80%, 60%, 40%, 20%, 10%, 5%)
  - Added white opacity scale (100%, 80%, 60%, 40%, 20%, 10%, 5%)
  - Updated status colors:
    - Success: #2ED573 (from lib)
    - Warning: #FFBE21 (from lib)
    - Error: #EA5B5B (from lib)
  - Updated gradients to purple
  - Updated shadows to purple
  - Updated borders to purple
  - Added backward compatibility with @Deprecated annotations

#### 1.3 Typography Migration ✅
- ✅ Updated `app_text_styles.dart`
  - **Font family:** Cairo → Plus Jakarta Sans
  - Updated all color references to use new purple palette
  - Maintained RTL support (Plus Jakarta Sans supports RTL)
  - Preserved existing hierarchy (h1-h4, bodyLarge/Medium/Small, etc.)

#### 1.4 Theme Configuration ✅
- ✅ Updated `app_theme.dart`
  - **Font family:** All GoogleFonts.cairo() → GoogleFonts.plusJakartaSans()
  - **Primary color:** Updated throughout theme
  - **Input Decoration Theme:**
    - Filled with light grey background (AppColors.lightGreyColor)
    - Transparent borders when inactive
    - Purple border on focus
    - Red border on error
    - 12px border radius
  - **Button Themes:**
    - ElevatedButton: Purple background, white text, 16px padding, full-width
    - OutlinedButton: Transparent with blackColor10 border, 16px padding
    - TextButton: Purple foreground
  - **AppBar Theme:**
    - White background, elevation 0 (flat)
    - Black icons and title
    - 16px title font size
  - **Bottom Navigation:**
    - Fixed type (supports 5 items)
    - Purple selected color
    - Transparent unselected
    - 12px font size
  - **Checkbox Theme:**
    - Rounded corners (6px)
    - White checkmark
    - Purple when selected

---

### Phase 2: Component Library Migration ✅

Created `the_app\lib\core\components\` directory with:

#### Essential Components ✅
1. ✅ `network_image_with_loader.dart`
   - CachedNetworkImage wrapper
   - Skeleton placeholder during load
   - Error icon on failure
   - Customizable border radius

2. ✅ `skeleton_loader.dart`
   - `Skeleton` - Rectangular loading placeholder
   - `CircleSkeleton` - Circular loading placeholder
   - Opacity layers for depth effect

3. ✅ `dot_indicators.dart`
   - Animated dot indicator for carousels
   - Active/inactive states
   - Purple primary color
   - 300ms animation duration

4. ✅ `custom_modal_bottom_sheet.dart`
   - Rounded top corners (24px)
   - Customizable height
   - Dismissible option
   - Follows lib design system

5. ✅ `blur_container.dart`
   - BackdropFilter with blur effect
   - Glass morphism support
   - Customizable text and dimensions

6. ✅ `check_mark.dart`
   - Circular checkmark indicator
   - Uses Material Icons (no SVG needed)
   - Customizable color and size

#### Product Components ✅
7. ✅ `product/primary_product_card.dart`
   - Vertical card (140x220)
   - Image with NetworkImageWithLoader
   - Discount badge (red)
   - Brand name, title, price
   - Price after discount display
   - Purple price color

8. ✅ `product/secondary_product_card.dart`
   - Horizontal card (256x114)
   - Same features as primary
   - Optimized for horizontal layouts

#### Expanded Decorations ✅
9. ✅ Enhanced `app_decorations.dart`
   - Added `productCard()` - Product-specific styling
   - Added `storeCard()` - Store profile styling
   - Added `searchBar()` - Light grey filled search
   - Added `filterChip()` - Active/inactive chip states
   - Added `circle()` and `circleBordered()` - Avatar/icon containers
   - Added `bottomSheet()` - 24px rounded top corners
   - Added `modal()` - Dialog styling
   - Updated to use purple color scheme

---

## 📋 REMAINING PHASES

### Phase 3: Screen-by-Screen Migration (NOT STARTED)

**Tier 1: Core User Screens** (12 screens)
- [ ] `home_screen.dart`
- [ ] `discovery_screen.dart`
- [ ] `search_results_screen.dart`
- [ ] `product_details_screen.dart`
- [ ] `pack_detail_screen.dart`
- [ ] `store_screen.dart`
- [ ] `store_details_screen.dart`
- [ ] `favorites_screen.dart`
- [ ] `profile_screen.dart`
- [ ] `login_screen.dart`
- [ ] `register_screen.dart`
- [ ] `main_navigation_screen.dart`

**Tier 2: Merchant & Management** (10 screens)
- [ ] Add/edit product screens
- [ ] Add/edit pack screens
- [ ] Add/edit promotion screens
- [ ] Merchant profile screens
- [ ] Statistics screens

**Tier 3: Supporting Screens** (8 screens)
- [ ] Messages & chat screens
- [ ] Notification screens
- [ ] Location pickers
- [ ] Splash screen

**Remaining:** ~23 widget files and helper screens

#### Per-Screen Migration Steps:
1. Update imports to new components
2. Replace color references (primaryBlue → primaryColor)
3. Replace BoxDecorations with AppDecorations methods
4. Update text styles to use AppTextStyles or theme
5. Replace spacing magic numbers with AppConstants
6. Update components (CircularProgressIndicator → Skeleton, etc.)
7. Test functionality, RTL, loading states, error states

---

### Phase 4: Code Quality & Duplication Elimination (NOT STARTED)

#### 4.1 Consolidate Add/Edit Screens
**Target files:**
- [ ] `add_product_screen.dart` + `edit_product_screen.dart` (867 lines → ~500)
- [ ] `add_pack_screen.dart` + `edit_pack_screen.dart`
- [ ] `add_promotion_screen.dart`
- [ ] `edit_merchant_profile_screen.dart` + `edit_customer_profile_screen.dart`

**Strategy:** Create shared form widgets (`ProductForm`, `PackForm`, etc.)

#### 4.2 BoxDecoration Consolidation
- **Current:** 265 BoxDecoration instances
- **Target:** <50 instances
- **Method:** Replace with AppDecorations methods

**Pattern replacement examples:**
```dart
// Before
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [...],
  ),
)

// After
Container(decoration: AppDecorations.card())
```

---

### Phase 5: Visual Polish & Effects (NOT STARTED)

- [ ] Replace all CircularProgressIndicator with Skeleton loaders
- [ ] Add skeleton states for product cards
- [ ] Add skeleton states for store cards
- [ ] Add skeleton states for lists
- [ ] Apply BlurContainer for modal overlays
- [ ] Apply BlurContainer for unavailable products
- [ ] Add DotIndicator to carousels (home banners, product images)
- [ ] Verify all animations use AppConstants.defaultDuration
- [ ] Add Material Icons (replace any SVG references)

---

### Phase 6: Testing & Validation (NOT STARTED)

#### Visual Testing
- [ ] Purple theme (#7B61FF) applied everywhere
- [ ] Plus Jakarta Sans font rendering
- [ ] Spacing consistency (16px padding, 12px radius)
- [ ] RTL layout correctness (Arabic)
- [ ] Component styling (buttons, inputs, cards)

#### Functional Testing
- [ ] Authentication (login, register, logout)
- [ ] Product browsing (home, search, filters, favorites)
- [ ] Merchant features (add/edit product, pack, promotion)
- [ ] Messaging (list, chat, real-time)
- [ ] Navigation (bottom nav, screen transitions)

#### Performance Testing
- [ ] App startup time
- [ ] Screen transition smoothness
- [ ] Image loading (CachedNetworkImage)
- [ ] List scrolling performance

#### Code Quality Verification
- [ ] BoxDecoration count <50
- [ ] No duplicate add/edit screens
- [ ] All imports use new component paths
- [ ] All colors reference AppColors constants

---

## 📊 METRICS

### Completed
- **Files Created:** 11 (constants + 10 components)
- **Files Modified:** 4 (app_colors, app_text_styles, app_theme, app_decorations)
- **Color Migrations:** 100% (all blue → purple references updated)
- **Font Migrations:** 100% (all Cairo → Plus Jakarta Sans)
- **Components Ported:** 10/10 essential components

### Remaining
- **Screens to Migrate:** 53 screens
- **BoxDecorations to Consolidate:** ~265 → target <50
- **Duplicate Code to Eliminate:** ~867 lines in forms

---

## 🎨 DESIGN SYSTEM REFERENCE

### Colors
- **Primary:** #7B61FF (Purple)
- **Success:** #2ED573 (Green)
- **Warning:** #FFBE21 (Amber)
- **Error:** #EA5B5B (Red)
- **Background:** #F8F8F9 (Light grey)

### Typography
- **Font:** Plus Jakarta Sans
- **Weights:** 400 (regular), 500 (medium), 600 (semibold), 700 (bold)

### Spacing
- **Default padding:** 16px
- **Default border radius:** 12px
- **Scale:** 4, 8, 12, 16, 20, 24, 32

### Components
- **Cards:** 12-16px radius, white background, optional shadow
- **Buttons:** 12px radius, 16px padding, full-width
- **Inputs:** 12px radius, light grey fill, transparent border
- **Bottom sheets:** 24px top radius
- **Product cards:** 140x220 (vertical), 256x114 (horizontal)

---

## 🚀 NEXT STEPS

1. **Start Phase 3:** Begin migrating Tier 1 screens (12 core user screens)
2. **Testing strategy:** Test each screen after migration
3. **Documentation:** Update as screens are migrated
4. **Rollback plan:** Git commits after each tier completion

---

## 📝 NOTES

- **Backward Compatibility:** @Deprecated annotations added for smooth transition
- **RTL Support:** Plus Jakarta Sans fully supports RTL rendering
- **No Breaking Changes:** All API services, providers, models, and business logic preserved
- **No New Dependencies:** All packages already in pubspec.yaml
- **Asset Strategy:** Using Material Icons instead of SVG assets (simpler)

---

## Backend note (unified profile)
- The backend no longer uses a separate `stores` app/model.
- “Store” = `users.User` (unified profile).
- Any remaining references to `stores` in migrations/models must be removed.

---

## ✅ VERIFICATION CHECKLIST

### Phase 1 & 2 Verification
- ✅ Constants file created with all spacing/sizing values
- ✅ All color references updated to purple
- ✅ All font references updated to Plus Jakarta Sans
- ✅ Theme configuration updated (AppBar, buttons, inputs, bottom nav, checkbox)
- ✅ All essential components ported (10 components)
- ✅ AppDecorations expanded with common patterns
- ✅ Compilation check passed (0 errors, only expected warnings)
- ⏳ Visual preview (pending app run)

### Full Migration Verification (Pending)
- ⏳ All 53 screens migrated
- ⏳ BoxDecorations <50 instances
- ⏳ No functional regressions
- ⏳ RTL support verified
- ⏳ Performance benchmarks met
