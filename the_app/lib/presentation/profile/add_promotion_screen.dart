import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/pack_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/wallet_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_compact_action_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_toggle_button.dart';
import '../../core/widgets/date_time_picker_field.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/post_model.dart';
import '../common/location_filter_picker.dart';
import '../common/radius_picker_sheet.dart';
import '../shared_widgets/app_switch_tile.dart';
import '../shared_widgets/wino_coin_badge.dart';
import '../subscription/subscription_gate.dart';
import '../wallet/coin_store_screen.dart';
import 'widgets/pack_picker_sheet.dart';
import 'widgets/product_picker_sheet.dart';

class AddPromotionScreen extends StatefulWidget {
  final Offer? offer;
  final String initialKind;
  final Post? initialProduct;
  final int? initialPackId;
  final String? initialPackName;

  const AddPromotionScreen({
    super.key,
    this.offer,
    this.initialKind = 'promotion',
    this.initialProduct,
    this.initialPackId,
    this.initialPackName,
  });

  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  static final List<int> _allHours = List<int>.generate(24, (hour) => hour);
  static final List<int> _businessHours =
      List<int>.generate(12, (index) => index + 8);

  static const List<ToggleOption> _kindOptions = [
    ToggleOption(label: 'Discount', value: 'promotion'),
    ToggleOption(label: 'Sponsored Ad', value: 'advertising'),
  ];
  static const List<ToggleOption> _audienceOptions = [
    ToggleOption(label: 'All', value: 'all'),
    ToggleOption(label: 'Followers', value: 'followers'),
    ToggleOption(label: 'Nearby', value: 'nearby'),
    ToggleOption(label: 'Wilaya', value: 'wilaya'),
  ];

  static const List<ToggleOption> _geoOptions = [
    ToggleOption(label: 'All Algeria', value: 'all'),
    ToggleOption(label: 'Wilayas', value: 'wilaya'),
    ToggleOption(label: 'Radius (km)', value: 'radius'),
  ];

  Post? _selectedProduct;
  int? _selectedPackId;
  String? _selectedPackName;
  String _adTargetType = 'product';
  Offer? _existingOffer;
  final _formKey = GlobalKey<FormState>();
  final _newPriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _maxImpressionsController = TextEditingController();
  final _ageFromController = TextEditingController();
  final _ageToController = TextEditingController();
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isAvailable = true;
  String _kind = 'promotion';
  List<int> _displayHours = List<int>.from(_allHours);
  String _audienceMode = 'all';
  String _geoMode = 'all';
  List<String> _selectedTargetWilayas = const [];
  double? _targetRadiusKm;
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic> _adInventory = const {};
  Map<String, dynamic> _planFeatures = const {};

  bool get _isAdMode => _kind == 'advertising';
  bool get _allowKindSwitch => false;

  String get _screenTitle {
    if (_isEditMode && _isAdMode) return 'Edit Sponsored Ad';
    if (_isEditMode) return 'Edit Discount';
    return _isAdMode ? 'Create Sponsored Ad' : 'Add Discount';
  }

  bool get _isPackTarget => _isAdMode && _adTargetType == 'pack';
  bool get _isDiscountTarget => _isAdMode && _adTargetType == 'discount';

  bool get _hasSelectedTarget =>
      _selectedProduct != null || (_selectedPackId != null && _isAdMode);

  String get _targetSelectionTitle {
    if (!_isAdMode) return 'Select Product';
    if (_isPackTarget) return 'Select Pack to Sponsor';
    if (_isDiscountTarget) return 'Select Discount to Sponsor';
    return 'Select Product to Sponsor';
  }

  String get _targetSelectionHint {
    if (!_isAdMode) return 'Tap to select product...';
    if (_isPackTarget) return 'Tap to select pack to sponsor...';
    if (_isDiscountTarget) {
      return 'Tap to select a product with active discount...';
    }
    return 'Tap to select product to sponsor...';
  }

  String get _availabilityTitle => _isAdMode ? 'Ad Active' : 'Available';

  String get _availabilitySubtitle => _isAdMode
      ? 'Show this sponsored ad to customers'
      : 'Show this discount to customers';

  String get _submitButtonText {
    if (_isLoading) return 'Saving...';
    if (_isEditMode) return 'Save Changes';
    return _isAdMode ? 'Launch Sponsored Ad' : 'Apply Discount';
  }

  String get _deleteTitle =>
      _isAdMode ? 'Delete Sponsored Ad?' : 'Delete Discount?';

  String get _deleteDescription => _isAdMode
      ? 'This will remove the sponsored ad from this product.'
      : 'This will remove the discount from this product.';

  String get _deleteSuccessMessage => _isAdMode
      ? 'Sponsored ad deleted successfully'
      : 'Discount deleted successfully';

  String get _deleteFailurePrefix =>
      _isAdMode ? 'Failed to delete sponsored ad' : 'Failed to delete discount';

  String get _saveSuccessMessage => _isAdMode
      ? 'Sponsored ad updated successfully'
      : 'Discount edited successfully';

  String get _createSuccessMessage => _isAdMode
      ? 'Sponsored ad created successfully'
      : 'Discount added successfully';

  @override
  void initState() {
    super.initState();

    final offer = widget.offer;
    if (offer != null) {
      _existingOffer = offer;
      _isEditMode = true;
      _isAvailable = offer.isAvailable;
      _discountPercentageController.text = offer.discountPercentage.toString();
      _newPriceController.text = offer.newPrice.toStringAsFixed(2);
      _kind = offer.kind;
      _displayHours = _resolveInitialDisplayHours(offer);
      _audienceMode = offer.audienceMode;
      _geoMode = offer.geoMode;
      _maxImpressionsController.text = offer.maxImpressions?.toString() ?? '';
      _selectedTargetWilayas = List<String>.from(offer.targetWilayas);
      _targetRadiusKm = offer.targetRadiusKm?.toDouble();
      _ageFromController.text = offer.ageFrom?.toString() ?? '';
      _ageToController.text = offer.ageTo?.toString() ?? '';
      _startDate = offer.startDate?.toLocal();
      _endDate = offer.endDate?.toLocal();
      if (offer.kind == 'advertising' && offer.targetType == 'pack') {
        _adTargetType = 'pack';
        _selectedPackId = offer.targetPackId;
        _selectedPackName = offer.targetPackName;
      } else {
        _adTargetType = 'product';
        _selectedProduct = offer.product;
      }
    } else {
      _kind = widget.initialKind;
      _selectedProduct = widget.initialProduct;
      _selectedPackId = widget.initialPackId;
      _selectedPackName = widget.initialPackName;
      if (_kind == 'advertising') {
        _displayHours = List<int>.from(_allHours);
      }
      if (_kind == 'advertising' && _selectedPackId != null) {
        _adTargetType = 'pack';
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure posts are loaded
      final provider = Provider.of<PostProvider>(context, listen: false);
      if (provider.myPosts.isEmpty) {
        // Assuming user ID is available in AuthProvider or similar,
        // but for now we rely on ProfileScreen having loaded them.
        // If empty, we might need to fetch.
      }
    });

    _loadPlanData();
    _loadAccessStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WalletProvider>().fetchWallet(notifyStart: false);
      }
    });
  }

  Future<void> _loadAccessStatus() async {
    try {
      final status = await SubscriptionService.fetchAccessStatus();
      if (!mounted) return;
      final features =
          (status['plan_features'] as Map?)?.cast<String, dynamic>();
      if (features == null) return;
      setState(() {
        _planFeatures = features;
      });
    } catch (_) {
      // Best effort only.
    }
  }

  int? _planMaxDurationDaysForCurrentKind() {
    final key =
        _isAdMode ? 'ad_max_duration_days' : 'promotion_max_duration_days';
    final raw = _planFeatures[key];
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  int _computeDurationDaysLikeBackend(DateTime startUtc, DateTime endUtc) {
    final durationSeconds = endUtc.difference(startUtc).inSeconds;
    final days = (durationSeconds ~/ 86400) + 1;
    return days < 1 ? 1 : days;
  }

  Future<void> _loadPlanData() async {
    try {
      final data = await WalletService.fetchWallet();
      if (!mounted) return;
      final costs =
          (data['costs'] as Map?)?.cast<String, dynamic>() ?? const {};
      final adViewCost = costs['ad_view'];
      setState(() {
        _adInventory = {
          'ad_view_coins_balance': data['ad_view_coins_balance'] ?? 0,
          'ad_view_coin_cost': adViewCost ?? 1,
        };
        if (_kind == 'advertising' &&
            _maxImpressionsController.text.trim().isEmpty) {
          final affordable = _maxAffordableImpressions;
          final fallback = affordable > 0 ? affordable.clamp(1, 100) : 100;
          _maxImpressionsController.text = '$fallback';
        }
      });
    } catch (_) {
      // Best effort only.
    }
  }

  int get _adViewCoinsBalance =>
      int.tryParse((_adInventory['ad_view_coins_balance'] ?? 0).toString()) ??
      0;

  int get _adViewCoinCost =>
      int.tryParse((_adInventory['ad_view_coin_cost'] ?? 1).toString()) ?? 1;

  int get _maxAffordableImpressions {
    final cost = _adViewCoinCost <= 0 ? 1 : _adViewCoinCost;
    return _adViewCoinsBalance ~/ cost;
  }

  @override
  void dispose() {
    _newPriceController.dispose();
    _discountPercentageController.dispose();
    _maxImpressionsController.dispose();
    _ageFromController.dispose();
    _ageToController.dispose();
    super.dispose();
  }

  Future<void> _openTargetPicker() async {
    if (_isEditMode) return;

    if (_isPackTarget) {
      final packProvider = context.read<PackProvider>();
      final picked = await showPackPickerBottomSheet(
        context,
        packs: packProvider.myPacks,
        title: context.tr(_targetSelectionTitle),
      );
      if (picked != null) {
        setState(() {
          _selectedPackId = picked.id;
          _selectedPackName = picked.name;
          _selectedProduct = null;
          _existingOffer = context
              .read<PostProvider>()
              .myOffers
              .where(
                  (o) => o.kind == 'advertising' && o.targetPackId == picked.id)
              .firstOrNull;
          _isEditMode = _existingOffer != null;
        });
      }
      return;
    }

    final provider = context.read<PostProvider>();
    var products = provider.myPosts;
    if (_isDiscountTarget) {
      final discountedProductIds = provider.myOffers
          .where((offer) => offer.kind == 'promotion' && offer.isAvailable)
          .map((offer) => offer.product.id)
          .toSet();
      products = products
          .where((product) => discountedProductIds.contains(product.id))
          .toList();
      if (products.isEmpty) {
        Helpers.showSnackBar(
          context,
          context.tr('No active discounts found. Create a discount first.'),
        );
        return;
      }
    }

    final picked = await showProductPickerBottomSheet(
      context,
      products: products,
      title: context.tr(_targetSelectionTitle),
    );
    if (picked != null) _onProductSelected(picked);
  }

  void _clearSelectedTarget() {
    setState(() {
      _selectedProduct = null;
      _selectedPackId = null;
      _selectedPackName = null;
      _existingOffer = null;
      _isEditMode = false;
      _isAvailable = true;
      _newPriceController.clear();
      _discountPercentageController.clear();
    });
  }

  void _onProductSelected(Post post) {
    final provider = Provider.of<PostProvider>(context, listen: false);

    // Check if product already has an offer of the selected kind.
    final existingOffer = provider.myOffers
        .where((o) => o.product.id == post.id && o.kind == _kind)
        .firstOrNull;

    if (existingOffer != null) {
      _showExistingPromotionDialog(post, existingOffer);
    } else {
      setState(() {
        _selectedProduct = post;
        _existingOffer = null;
        _isEditMode = false;
        if (!_isAdMode) {
          _newPriceController.clear();
          _discountPercentageController.clear();
        }
      });
    }
  }

  Offer? _promotionForSelectedProduct(PostProvider provider) {
    final productId = _selectedProduct?.id;
    if (productId == null) return null;
    return provider.myOffers
        .where((offer) =>
            offer.product.id == productId && offer.kind == 'promotion')
        .firstOrNull;
  }

  String _selectedTargetLabel() {
    if (_isPackTarget) {
      return _selectedPackName ??
          '${context.tr('Pack')} #${_selectedPackId ?? 0}';
    }
    return _selectedProduct?.title ?? _targetSelectionHint;
  }

  int _resolvePercentage(Offer? selectedPromotion) {
    if (_isAdMode) {
      return selectedPromotion?.discountPercentage ??
          int.tryParse(_discountPercentageController.text) ??
          0;
    }
    return int.parse(_discountPercentageController.text);
  }

  String? _validateAdImpressionLimit(
      BuildContext context, int? maxImpressions) {
    if (!_isAdMode) {
      return null;
    }
    if ((maxImpressions ?? 0) <= 0) {
      return context.tr('Please enter the number of ad impressions');
    }

    final requested = maxImpressions!;
    final alreadyReserved = int.tryParse(
          (_existingOffer?.maxImpressions ?? 0).toString(),
        ) ??
        0;
    final extraNeeded =
        requested > alreadyReserved ? requested - alreadyReserved : 0;
    final affordable = _maxAffordableImpressions;

    if (extraNeeded > affordable) {
      return context.tr(
          'Insufficient Ad View Coins. Need $extraNeeded more impressions budget, available $affordable.');
    }
    return null;
  }

  int _selectedOptionIndex(List<ToggleOption> options, String value) {
    final index = options.indexWhere((option) => option.value == value);
    return index >= 0 ? index : 0;
  }

  List<int> _resolveInitialDisplayHours(Offer offer) {
    final hours = List<int>.from(offer.displayHours)..sort();
    if (hours.isNotEmpty) {
      return hours;
    }
    if (offer.displayHour != null) {
      return <int>[offer.displayHour!];
    }
    return List<int>.from(_allHours);
  }

  String _formatHourLabel(BuildContext context, int hour) {
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final suffix = hour < 12 ? context.tr('am') : context.tr('pm');
    return '$h12$suffix';
  }

  String _selectedHoursSummary(BuildContext context) {
    if (_displayHours.isEmpty) return context.tr('No hour selected');
    final sorted = List<int>.from(_displayHours)..sort();
    if (sorted.length == 24) return context.tr('All day (24h)');
    if (_isBusinessHoursOnly(sorted)) {
      return context.tr('Business hours (8AM-7PM)');
    }
    return '${sorted.length}/24';
  }

  Widget _buildSelectedHoursPreview(BuildContext context) {
    if (_displayHours.isEmpty) return const SizedBox.shrink();
    final sorted = List<int>.from(_displayHours)..sort();
    final visible = sorted.take(8).toList(growable: false);
    final remaining = sorted.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map(
          (hour) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatHourLabel(context, hour),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
      ],
    );
  }

  bool _isBusinessHoursOnly(List<int> hours) {
    if (hours.length != _businessHours.length) return false;
    for (final hour in _businessHours) {
      if (!hours.contains(hour)) return false;
    }
    return true;
  }

  Future<void> _pickDisplayHours() async {
    final initial = Set<int>.from(_displayHours);
    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (context) {
        final temp = Set<int>.from(initial);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(context.tr('Show At Hour')),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('Selected hours')}: ${temp.length}/24',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppCompactActionButton(
                            label: context.tr('All day'),
                            onTap: () {
                              setModalState(() {
                                temp
                                  ..clear()
                                  ..addAll(_allHours);
                              });
                            },
                          ),
                          AppCompactActionButton(
                            label: context.tr('Business hours'),
                            onTap: () {
                              setModalState(() {
                                temp
                                  ..clear()
                                  ..addAll(_businessHours);
                              });
                            },
                          ),
                          AppCompactActionButton(
                            label: context.tr('Clear'),
                            onTap: () {
                              setModalState(() {
                                temp.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.generate(24, (hour) {
                          final selectedHour = temp.contains(hour);
                          return FilterChip(
                            selected: selectedHour,
                            label: Text(_formatHourLabel(context, hour)),
                            onSelected: (checked) {
                              setModalState(() {
                                if (checked) {
                                  temp.add(hour);
                                } else {
                                  temp.remove(hour);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                AppTextButton(
                  onPressed: () => Navigator.pop(context),
                  text: context.tr('Cancel'),
                ),
                AppPrimaryButton(
                  onPressed: () => Navigator.pop(context, temp),
                  text: context.tr('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null) return;
    if (selected.isEmpty) {
      Helpers.showSnackBar(context, context.tr('Select at least one hour'));
      return;
    }

    setState(() {
      _displayHours = selected.toList()..sort();
    });
  }

  Widget _buildToggleSection({
    required String title,
    required List<ToggleOption> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final localizedOptions = options
        .map(
          (option) => ToggleOption(
            label: this.context.tr(option.label),
            value: option.value,
            icon: option.icon,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AppToggleButtonGroup(
          options: localizedOptions,
          selectedIndex: _selectedOptionIndex(localizedOptions, selectedValue),
          onChanged: (index) => onChanged(localizedOptions[index].value),
          scrollable: true,
          compact: true,
        ),
      ],
    );
  }

  void _showExistingPromotionDialog(Post post, Offer offer) {
    final isAdvertising = offer.kind == 'advertising';
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAdvertising
                      ? context.tr('Existing Sponsored Ad')
                      : context.tr('Existing Discount'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: post.image != null && post.image!.isNotEmpty
                            ? Image.network(post.image!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey[300],
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${offer.discountPercentage}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Helpers.formatPrice(offer.newPrice),
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAdvertising
                    ? context.tr(
                        'This product already has an ad campaign. Do you want to edit it?')
                    : context.tr(
                        'This product already has a discount. Do you want to edit it?'),
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            AppTextButton(
              onPressed: () => Navigator.pop(context),
              text: context.tr('Cancel'),
            ),
            AppPrimaryButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedProduct = post;
                  _existingOffer = offer;
                  _isEditMode = true;
                  _isAvailable = offer.isAvailable;
                  _kind = offer.kind;
                  _displayHours = _resolveInitialDisplayHours(offer);
                  _audienceMode = offer.audienceMode;
                  _geoMode = offer.geoMode;
                  _discountPercentageController.text =
                      offer.discountPercentage.toString();
                  _newPriceController.text = offer.newPrice.toStringAsFixed(2);
                  _maxImpressionsController.text =
                      offer.maxImpressions?.toString() ?? '';
                  _selectedTargetWilayas =
                      List<String>.from(offer.targetWilayas);
                  _targetRadiusKm = offer.targetRadiusKm?.toDouble();
                  _ageFromController.text = offer.ageFrom?.toString() ?? '';
                  _ageToController.text = offer.ageTo?.toString() ?? '';
                  _startDate = offer.startDate?.toLocal();
                  _endDate = offer.endDate?.toLocal();
                });
              },
              text: isAdvertising
                  ? context.tr('Edit Sponsored Ad')
                  : context.tr('Edit Discount'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOffer() async {
    final offer = _existingOffer;
    if (!_isEditMode || offer == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          title: Text(context.tr(_deleteTitle)),
          content: Text(context.tr(_deleteDescription)),
          actions: [
            AppTextButton(
              onPressed: () => Navigator.pop(context, false),
              text: context.tr('Cancel'),
            ),
            AppPrimaryButton(
              onPressed: () => Navigator.pop(context, true),
              text: context.tr('Delete'),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true) return;

    try {
      setState(() => _isLoading = true);
      await context.read<PostProvider>().deleteOffer(offer.id);
      if (mounted) {
        Helpers.showSnackBar(context, context.tr(_deleteSuccessMessage));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
            context, '${context.tr(_deleteFailurePrefix)}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNewPriceChanged(String value) {
    if (_selectedProduct == null || value.isEmpty) return;

    final newPrice = double.tryParse(value);
    if (newPrice != null) {
      final originalPrice = _selectedProduct!.price;
      if (originalPrice > 0) {
        final discount = ((originalPrice - newPrice) / originalPrice) * 100;
        _discountPercentageController.text = discount.toStringAsFixed(0);
        setState(() {});
      }
    }
  }

  Future<void> _pickTargetWilayas() async {
    final result = await showModalBottomSheet<LocationFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationFilterPicker(
        initialFilter: LocationFilterResult(
          selectedWilayas: _selectedTargetWilayas,
          selectedBaladiyat: const {},
          allAlgeria: _geoMode == 'all',
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.allAlgeria) {
        _geoMode = 'all';
        _selectedTargetWilayas = const [];
      } else {
        _geoMode = 'wilaya';
        _selectedTargetWilayas = result.selectedWilayas;
      }
    });
  }

  void _pickRadius() {
    showRadiusPickerSheet(
      context,
      initialRadius: _targetRadiusKm ?? 25,
      onRadiusChanged: (value) {
        setState(() {
          if (value <= 0) {
            _targetRadiusKm = null;
          } else {
            _geoMode = 'radius';
            _targetRadiusKm = value;
          }
        });
      },
    );
  }

  Widget _buildScheduleSection() {
    return DateRangePickerField(
      title: context.tr('Schedule'),
      startLabel: context.tr('Start Date & Time'),
      endLabel: context.tr('End Date & Time'),
      startIcon: Icons.schedule,
      endIcon: Icons.timer_off_outlined,
      startValue: _startDate,
      endValue: _endDate,
      onStartChanged: (dt) => setState(() {
        _startDate = dt;
        // Reset end date if it's before the new start date
        if (_endDate != null && _endDate!.isBefore(dt)) {
          _endDate = null;
        }
      }),
      onEndChanged: (dt) => setState(() => _endDate = dt),
      onStartCleared: () => setState(() => _startDate = null),
      onEndCleared: () => setState(() => _endDate = null),
      showTime: true,
    );
  }

  Widget _buildAvailabilitySection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isAvailable
            ? AppColors.primaryColor.withOpacity(0.08)
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAvailable
              ? AppColors.primaryColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: AppSwitchTile(
          title: context.tr(_availabilityTitle),
          subtitle: context.tr(_availabilitySubtitle),
          value: _isAvailable,
          onChanged:
              _isLoading ? null : (v) => setState(() => _isAvailable = v),
          showContainer: false,
          padding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _isAvailable
                  ? AppColors.primaryColor.withOpacity(0.12)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.toggle_on_outlined,
              size: 18,
              color:
                  _isAvailable ? AppColors.primaryColor : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  void _onPercentageChanged(String value) {
    if (_selectedProduct == null || value.isEmpty) return;

    final percentage = double.tryParse(value);
    if (percentage != null) {
      final originalPrice = _selectedProduct!.price;
      final newPrice = originalPrice * (1 - (percentage / 100));
      _newPriceController.text = newPrice.toStringAsFixed(2);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final hasTarget = _isAdMode
        ? (_selectedProduct != null || _selectedPackId != null)
        : _selectedProduct != null;
    if (!_formKey.currentState!.validate() || !hasTarget) {
      Helpers.showSnackBar(
        context,
        _isPackTarget
            ? context.tr('Please select a pack')
            : context.tr('Please select a product'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<PostProvider>(context, listen: false);
      final selectedPromotion = _promotionForSelectedProduct(provider);
      final percentage = _resolvePercentage(selectedPromotion);
      final maxImpressions =
          int.tryParse(_maxImpressionsController.text.trim());
      final ageFrom = int.tryParse(_ageFromController.text.trim());
      final ageTo = int.tryParse(_ageToController.text.trim());
      final impressionValidationError =
          _validateAdImpressionLimit(context, maxImpressions);
      if (impressionValidationError != null) {
        Helpers.showSnackBar(context, impressionValidationError);
        return;
      }

      if (_isAdMode && ageFrom != null && ageTo != null && ageFrom > ageTo) {
        Helpers.showSnackBar(context, context.tr('Age range is invalid'));
        return;
      }

      if (_isAdMode && _displayHours.isEmpty) {
        Helpers.showSnackBar(
            context, context.tr('Select at least one hour to show your ad'));
        return;
      }

      if (_isDiscountTarget && selectedPromotion == null) {
        Helpers.showSnackBar(
          context,
          context
              .tr('Discount target requires a product with active discount.'),
        );
        return;
      }

      if (_isAdMode && _geoMode == 'wilaya' && _selectedTargetWilayas.isEmpty) {
        Helpers.showSnackBar(
            context, context.tr('Select at least one target wilaya'));
        return;
      }

      if (_isAdMode &&
          _geoMode == 'radius' &&
          (_targetRadiusKm == null || _targetRadiusKm! <= 0)) {
        Helpers.showSnackBar(context, context.tr('Choose target radius in km'));
        return;
      }

      if (!_isAdMode &&
          _startDate != null &&
          _endDate != null &&
          !_endDate!.isAfter(_startDate!)) {
        Helpers.showSnackBar(
            context, context.tr('End time must be after start time'));
        return;
      }

      // Match backend duration constraint (subscriptions/services.py).
      if (!_isAdMode && _startDate != null && _endDate != null) {
        if (_planFeatures.isEmpty) {
          await _loadAccessStatus();
        }
        final maxDays = _planMaxDurationDaysForCurrentKind();
        if (maxDays != null && maxDays > 0) {
          final startUtc = _startDate!.toUtc();
          final endUtc = _endDate!.toUtc();
          final durationDays =
              _computeDurationDaysLikeBackend(startUtc, endUtc);
          final maxAllowedWithBuffer = maxDays + 1;
          if (durationDays > maxAllowedWithBuffer) {
            Helpers.showSnackBar(
              context,
              context.tr('Duration exceeds the current limit ($maxDays days).'),
            );
            return;
          }
        }
      }

      if (_isEditMode && _existingOffer != null) {
        // Update existing offer
        await provider.updateOffer(
          offerId: _existingOffer!.id,
          productId: _isPackTarget ? null : _selectedProduct?.id,
          packId: _isPackTarget ? _selectedPackId : null,
          discountPercentage: percentage,
          isAvailable: _isAvailable,
          kind: _kind,
          audienceMode: _audienceMode,
          targetWilayas: _selectedTargetWilayas,
          maxImpressions: maxImpressions,
          ageFrom: ageFrom,
          ageTo: ageTo,
          geoMode: _geoMode,
          targetRadiusKm: _targetRadiusKm?.round(),
          displayHour: _isAdMode && _displayHours.isNotEmpty
              ? _displayHours.first
              : null,
          displayHours: _isAdMode ? _displayHours : null,
          startDate: _isAdMode ? null : _startDate,
          endDate: _isAdMode ? null : _endDate,
        );

        if (mounted) {
          await context.read<WalletProvider>().fetchWallet();
          Helpers.showSnackBar(context, context.tr(_saveSuccessMessage));
          Navigator.pop(context, true);
        }
      } else {
        // Create new offer
        await provider.createOffer(
          productId: _isPackTarget ? null : _selectedProduct?.id,
          packId: _isPackTarget ? _selectedPackId : null,
          discountPercentage: percentage,
          isAvailable: _isAvailable,
          kind: _kind,
          audienceMode: _audienceMode,
          targetWilayas: _selectedTargetWilayas,
          maxImpressions: maxImpressions,
          ageFrom: ageFrom,
          ageTo: ageTo,
          geoMode: _geoMode,
          targetRadiusKm: _targetRadiusKm?.round(),
          displayHour: _isAdMode && _displayHours.isNotEmpty
              ? _displayHours.first
              : null,
          displayHours: _isAdMode ? _displayHours : null,
          startDate: _isAdMode ? null : _startDate,
          endDate: _isAdMode ? null : _endDate,
        );

        if (mounted) {
          await context.read<WalletProvider>().fetchWallet();
          Helpers.showSnackBar(context, context.tr(_createSuccessMessage));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        final coinInfo = SubscriptionService.parseCoinBalanceError(e);
        if (coinInfo != null) {
          await openCoinStore(
            context,
            required: coinInfo['required'] as int?,
            balance: coinInfo['balance'] as int?,
          );
          return;
        }
        Helpers.showSnackBar(
          context,
          '${context.tr('Failed to')} ${context.tr(_isEditMode ? 'save' : 'create')} ${context.tr(_isAdMode ? 'sponsored ad' : 'discount')}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxAffordableImpressions = _maxAffordableImpressions;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(_screenTitle)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isAdMode)
              Consumer<WalletProvider>(
                builder: (context, wallet, _) => WinoCoinBadge(
                  coins: wallet.coinsBalance,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CoinStoreScreen(),
                      ),
                    );
                  },
                ),
              ),
            if (_isEditMode && _existingOffer != null)
              IconButton(
                onPressed: _isLoading ? null : _confirmDeleteOffer,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status message if discount is out of time
                if (_existingOffer != null) ...[
                  Builder(
                    builder: (ctx) {
                      final statusMsg = _existingOffer!.getStatusMessage();
                      if (statusMsg != null) {
                        final isUnavailable =
                            statusMsg.toLowerCase().contains('not available');
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isUnavailable
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFFFF3E0),
                            border: Border.all(
                              color: isUnavailable
                                  ? const Color(0xFFFFCDD2)
                                  : const Color(0xFFFFE0B2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isUnavailable
                                    ? Icons.error_outline
                                    : Icons.schedule,
                                color: isUnavailable
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFF8A4B08),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isUnavailable
                                      ? context
                                          .tr('This discount is not available')
                                      : statusMsg,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isUnavailable
                                        ? const Color(0xFFC62828)
                                        : const Color(0xFF8A4B08),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
                if (_isAdMode) ...[
                  _buildToggleSection(
                    title: context.tr('Ad Target'),
                    options: const [
                      ToggleOption(label: 'Product', value: 'product'),
                      ToggleOption(label: 'Discounts', value: 'discount'),
                      ToggleOption(label: 'Pack', value: 'pack'),
                    ],
                    selectedValue: _adTargetType,
                    onChanged: _isEditMode
                        ? (_) {}
                        : (value) {
                            setState(() {
                              _adTargetType = value;
                              _selectedProduct = null;
                              _selectedPackId = null;
                              _selectedPackName = null;
                              _existingOffer = null;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  context.tr(_targetSelectionTitle),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _isEditMode ? null : _openTargetPicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (_selectedProduct != null)
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (_selectedProduct!.image == null ||
                                      _selectedProduct!.image!.isEmpty)
                                  ? Container(
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image,
                                          size: 20, color: Colors.grey),
                                    )
                                  : Image.network(
                                      _selectedProduct!.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.broken_image,
                                              size: 20, color: Colors.grey),
                                        );
                                      },
                                    ),
                            ),
                          )
                        else if (_isPackTarget && _selectedPackId != null)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Colors.grey),
                          ),
                        if (_hasSelectedTarget) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _hasSelectedTarget
                                ? _selectedTargetLabel()
                                : context.tr(_selectedTargetLabel()),
                            style: TextStyle(
                              color: _hasSelectedTarget
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        if (_hasSelectedTarget && !_isEditMode)
                          IconButton(
                            onPressed: _clearSelectedTarget,
                            icon: const Icon(Icons.close),
                            splashRadius: 18,
                          )
                        else if (!_hasSelectedTarget && !_isEditMode)
                          const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                if (_hasSelectedTarget) ...[
                  const SizedBox(height: 24),

                  if (_allowKindSwitch) ...[
                    _buildToggleSection(
                      title: context.tr('Campaign Type'),
                      options: _kindOptions,
                      selectedValue: _kind,
                      onChanged: _isEditMode
                          ? (_) {}
                          : (value) {
                              setState(() {
                                _kind = value;
                                _existingOffer = (_selectedProduct == null)
                                    ? null
                                    : context
                                        .read<PostProvider>()
                                        .myOffers
                                        .where((offer) =>
                                            offer.product.id ==
                                                _selectedProduct!.id &&
                                            offer.kind == _kind)
                                        .firstOrNull;
                                if (_isAdMode &&
                                    _maxImpressionsController.text
                                        .trim()
                                        .isEmpty &&
                                    maxAffordableImpressions > 0) {
                                  _maxImpressionsController.text =
                                      '$maxAffordableImpressions';
                                }
                                if (!_isAdMode) {
                                  _adTargetType = 'product';
                                  _selectedPackId = null;
                                  _selectedPackName = null;
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 24),
                  ],

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAdMode
                              ? (_isPackTarget
                                  ? context.tr('Sponsored Pack Summary')
                                  : (_isDiscountTarget
                                      ? context.tr('Sponsored Discount Summary')
                                      : context
                                          .tr('Sponsored Product Summary')))
                              : context.tr('Current Price'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (_isAdMode) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr('Original Price:')),
                              Text(
                                Helpers.formatPrice(_selectedProduct!.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!_isPackTarget) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr('New Price:')),
                              Text(
                                _newPriceController.text.isEmpty
                                    ? Helpers.formatPrice(
                                        _selectedProduct!.price)
                                    : '${_newPriceController.text} ${context.tr('DZD')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (!_isAdMode) ...[
                    AppTextField(
                      controller: _discountPercentageController,
                      label: context.tr('Discount Percentage (%)'),
                      hint: '0',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                      suffixText: '%',
                      onChanged: _onPercentageChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('Required');
                        }
                        final n = double.tryParse(value);
                        if (n == null || n <= 0 || n >= 100) {
                          return context.tr('Invalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _newPriceController,
                      label: context.tr('New Price'),
                      hint: '0',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      suffixText: context.tr('DZD'),
                      onChanged: _onNewPriceChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('Required');
                        }
                        final n = double.tryParse(value);
                        final original = _selectedProduct!.price;
                        if (n == null || n <= 0 || n >= original) {
                          return context.tr('Invalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_isAdMode) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC7DAFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.tr('Ad View Coins balance:')} $_adViewCoinsBalance',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${context.tr('Cost per impression:')} $_adViewCoinCost ${context.tr('coin')}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${context.tr('Current max impressions you can activate:')} $maxAffordableImpressions',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Show At Hour'),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickDisplayHours,
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              '${context.tr('Select Hours')} (${_displayHours.length}/24)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${context.tr('Selected hours')}: ${_selectedHoursSummary(context)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        _buildSelectedHoursPreview(context),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildToggleSection(
                      title: context.tr('Audience'),
                      options: _audienceOptions,
                      selectedValue: _audienceMode,
                      onChanged: (value) {
                        setState(() => _audienceMode = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _maxImpressionsController,
                      label: context.tr('Ad Impressions'),
                      hint: maxAffordableImpressions > 0
                          ? '${context.tr('Up to')} $maxAffordableImpressions'
                          : context.tr('e.g. 5000'),
                      icon: Icons.visibility_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${context.tr('Current ad impressions to activate:')} ${_maxImpressionsController.text.trim().isEmpty ? '-' : _maxImpressionsController.text.trim()}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _ageFromController,
                            label: context.tr('Age From'),
                            hint: '18',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _ageToController,
                            label: context.tr('Age To'),
                            hint: '45',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildToggleSection(
                      title: context.tr('Geo Target'),
                      options: _geoOptions,
                      selectedValue: _geoMode,
                      onChanged: (value) {
                        setState(() => _geoMode = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_geoMode == 'wilaya') ...[
                      AppCompactActionButton(
                        label: _selectedTargetWilayas.isEmpty
                            ? context.tr('Select Target Wilayas')
                            : '${_selectedTargetWilayas.length} ${context.tr('wilayas selected')}',
                        icon: Icons.map_outlined,
                        onTap: _pickTargetWilayas,
                      ),
                    ] else if (_geoMode == 'radius') ...[
                      AppCompactActionButton(
                        label: _targetRadiusKm == null
                            ? context.tr('Choose Radius (km)')
                            : '${_targetRadiusKm!.round()} ${context.tr('km radius')}',
                        icon: Icons.radar,
                        onTap: _pickRadius,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                          'Sponsored ad will stay active until impressions are exhausted.'),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],

                  const SizedBox(height: 24),
                  if (!_isAdMode) ...[
                    _buildScheduleSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildAvailabilitySection(),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      text: context.tr(_submitButtonText),
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
