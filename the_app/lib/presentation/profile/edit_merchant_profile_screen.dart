import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/helpers.dart';
import '../common/location_picker_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// dart:html is web-only, imported conditionally
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class EditMerchantProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String? initialImage;
  final String? initialCoverImage;
  final String? initialStoreDescription;
  final String? initialAddress;
  final String? initialFacebook;
  final String? initialInstagram;
  final String? initialWhatsapp;
  final String? initialTiktok;
  final String? initialYoutube;
  final double? initialLatitude;
  final double? initialLongitude;

  const EditMerchantProfileScreen({
    super.key,
    required this.initialName,
    required this.initialPhone,
    this.initialImage,
    this.initialCoverImage,
    this.initialStoreDescription,
    this.initialAddress,
    this.initialFacebook,
    this.initialInstagram,
    this.initialWhatsapp,
    this.initialTiktok,
    this.initialYoutube,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<EditMerchantProfileScreen> createState() =>
      _EditMerchantProfileScreenState();
}

class _EditMerchantProfileScreenState extends State<EditMerchantProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

// ... existing imports

  // Social Controllers
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _whatsappController;
  late TextEditingController _tiktokController;
  late TextEditingController _youtubeController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isUploadingCover = false;
  bool _isGettingLocation = false; // New state
  String? _avatarUrl;
  String? _coverUrl;
  int? _storeId;
  String? _selectedWilaya;
  String? _selectedBaladiya;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _descriptionController =
        TextEditingController(text: widget.initialStoreDescription ?? '');

    _facebookController = TextEditingController(text: widget.initialFacebook ?? '');
    _instagramController = TextEditingController(text: widget.initialInstagram ?? '');
    _whatsappController = TextEditingController(text: widget.initialWhatsapp ?? '');
    _tiktokController = TextEditingController(text: widget.initialTiktok ?? '');
    _youtubeController = TextEditingController(text: widget.initialYoutube ?? '');

    _avatarUrl = widget.initialImage;
    _coverUrl = widget.initialCoverImage;
    
    // Initialize Lat/Lng
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    
    // Fallback to storage if not passed in props but we have address
    if (_latitude == null) {
         final userData = StorageService.getUserData();
         if (userData != null && userData['latitude'] != null) {
             _latitude = double.tryParse(userData['latitude'].toString());
             _longitude = double.tryParse(userData['longitude'].toString());
         }
    }

    _loadAddress();
    _loadStoreId();
  }

  Future<void> _getCurrentLocation() async {
    // 60-day coordinate lock check
    final userData = StorageService.getUserData();
    final locUpdatedStr = userData?['location_updated_at']?.toString();
    if (locUpdatedStr != null && locUpdatedStr.isNotEmpty) {
      final locUpdated = DateTime.tryParse(locUpdatedStr);
      if (locUpdated != null) {
        final daysSince = DateTime.now().difference(locUpdated).inDays;
        if (daysSince < 60) {
          final remaining = 60 - daysSince;
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Coordinates Locked'),
                content: Text(
                  'You can only change your GPS coordinates once every 60 days.\n\n'
                  '$remaining day(s) remaining before you can update.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
    }

    if (!kIsWeb) {
      if (mounted) Helpers.showSnackBar(context, 'GPS only works on the mobile app.');
      return;
    }

    setState(() => _isGettingLocation = true);
    try {
      final geolocation = html.window.navigator.geolocation;

      final completer = Completer<html.Geoposition>();
      geolocation.getCurrentPosition(
        enableHighAccuracy: true,
        timeout: const Duration(seconds: 15),
      ).then(completer.complete).catchError(completer.completeError);

      final position = await completer.future;

      setState(() {
        _latitude = position.coords!.latitude!.toDouble();
        _longitude = position.coords!.longitude!.toDouble();
      });

      if (mounted) Helpers.showSnackBar(context, 'Location updated successfully ✅');

    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Could not get location: $e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _whatsappController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  void _loadAddress() {
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _parseAddressToWilayaBaladiya(widget.initialAddress!);
    } else {
      final userData = StorageService.getUserData();
      if (userData != null) {
        final address = userData['location'] ?? userData['address'] ?? '';
        _parseAddressToWilayaBaladiya(address);
      }
    }
  }

  void _parseAddressToWilayaBaladiya(String address) {
    if (address.contains(',')) {
      final parts = address.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        _selectedBaladiya = parts[0];
        _selectedWilaya = parts[1];
      }
    }
  }

  Future<void> _loadStoreId() async {
    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) return;

      final response =
          await ApiService.get('${ApiConfig.stores}?owner=$userId');
      final storesList = response is Map && response.containsKey('results')
          ? response['results'] as List
          : (response is List ? response : []);

      if (storesList.isNotEmpty) {
        setState(() {
          _storeId = storesList.first['id'];
        });
      }
    } catch (e) {
      debugPrint('Error loading store ID: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      if (mounted) Helpers.showSnackBar(context, 'No image selected');
      return;
    }

    {
      setState(() => _isUploadingImage = true);

      try {
        final userData = StorageService.getUserData();
        final userId = userData?['id'];
        if (userId == null) throw Exception('Cannot identify user ID');

        await ApiService.updateMultipart(
            '${ApiConfig.users}$userId/', {}, pickedFile, 'profile_image',
            method: 'PATCH');

        final response = await ApiService.get('${ApiConfig.users}$userId/');
        await StorageService.saveUserData(response);

        setState(() {
          _avatarUrl = response['profile_image'] ?? response['avatar'];
        });

        if (mounted)
          Helpers.showSnackBar(context, 'Profile picture updated successfully');
      } catch (e) {
        if (mounted)
          Helpers.showSnackBar(context, 'Failed to update image: $e');
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _pickCoverImage() async {
    if (_storeId == null) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      if (mounted) Helpers.showSnackBar(context, 'No image selected');
      return;
    }

    setState(() => _isUploadingCover = true);
    try {
      await ApiService.updateMultipart(
        ApiConfig.storeDetail(_storeId!),
        {},
        pickedFile,
        'cover_image',
        method: 'PATCH',
      );

      final store = await ApiService.get(ApiConfig.storeDetail(_storeId!));
      setState(() {
        _coverUrl = store is Map ? store['cover_image']?.toString() : _coverUrl;
      });

      if (mounted) {
        Helpers.showSnackBar(context, 'Cover image updated successfully');
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Failed to update cover: $e');
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Please enter your name');
      return;
    }

    setState(() => _isLoading = true);
    String? errorMessage;

    try {
      final userData = StorageService.getUserData();
      final userId = userData?['id'];
      if (userId == null) throw Exception('Cannot identify user ID');

      // Build address
      final address = (_selectedWilaya != null && _selectedBaladiya != null)
          ? '$_selectedBaladiya, $_selectedWilaya'
          : (userData?['address'] ?? '');

      // Single PATCH — store == user in this backend
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'store_description': _descriptionController.text.trim(),
        'address': address,
        'facebook': _facebookController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'youtube': _youtubeController.text.trim(),
      };

      // Only add coordinates if they have been set (round to 6dp to fit DecimalField(max_digits=9, decimal_places=6))
      if (_latitude != null) payload['latitude'] = _latitude!.toStringAsFixed(6);
      if (_longitude != null) payload['longitude'] = _longitude!.toStringAsFixed(6);

      debugPrint('💾 Saving profile payload: $payload');

      final updated = await ApiService.patch(ApiConfig.userDetail(userId), payload);
      debugPrint('✅ Save response: $updated');

      // Sync local storage with fresh server values
      if (updated is Map<String, dynamic>) {
        final merged = <String, dynamic>{...(userData ?? {}), ...updated};
        // Address keys in sync
        merged['location'] = merged['address'] ?? address;
        await StorageService.saveUserData(merged);
        debugPrint('✅ Local storage updated');
      } else {
        // Fallback: update locally
        if (userData != null) {
          userData['name'] = _nameController.text.trim();
          userData['phone'] = _phoneController.text.trim();
          userData['store_description'] = _descriptionController.text.trim();
          userData['address'] = address;
          userData['location'] = address;
          userData['facebook'] = _facebookController.text.trim();
          userData['instagram'] = _instagramController.text.trim();
          userData['whatsapp'] = _whatsappController.text.trim();
          userData['tiktok'] = _tiktokController.text.trim();
          userData['youtube'] = _youtubeController.text.trim();
          if (_latitude != null) userData['latitude'] = _latitude.toString();
          if (_longitude != null) userData['longitude'] = _longitude.toString();
          await StorageService.saveUserData(userData);
        }
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (errorMessage != null) {
      // Show error as a dialog so it cannot be missed
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Failed'),
          content: Text(errorMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      Helpers.showSnackBar(context, '✅ Profile saved successfully');
      Navigator.pop(context, true);
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialWilaya: _selectedWilaya,
          initialBaladiya: _selectedBaladiya,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedWilaya = result.wilaya;
        _selectedBaladiya = result.baladiya;
      });
    }
  }

  Future<void> _becomeCustomer() async {
    // Intentionally removed from this screen per requested scope.
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.textPrimary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Edit Profile',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Fields
                  AppTextField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Enter your name',
                    icon: Icons.person_rounded,
                    style: AppTextFieldStyle.profile,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe your store...',
                    icon: Icons.description_rounded,
                    maxLines: 3,
                    style: AppTextFieldStyle.profile,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+213 XXX XXX XXX',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    style: AppTextFieldStyle.profile,
                  ),

                  const SizedBox(height: 8),
                  _buildLocationSection(),
                  const SizedBox(height: 28),

                  // Social Accounts Section
                  Text('Social Accounts',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _facebookController,
                    label: 'Facebook',
                    hint: 'https://facebook.com/...',
                    icon: Icons.facebook,
                    style: AppTextFieldStyle.profile,
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    controller: _instagramController,
                    label: 'Instagram',
                    hint: 'https://instagram.com/...',
                    icon: Icons.camera_alt_outlined, // Fallback as we don't have font_awesome here yet
                    style: AppTextFieldStyle.profile,
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    controller: _whatsappController,
                    label: 'WhatsApp',
                    hint: 'Number (e.g. 213555...)',
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    style: AppTextFieldStyle.profile,
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    controller: _tiktokController,
                    label: 'TikTok',
                    hint: 'https://tiktok.com/@...',
                    icon: Icons.music_note,
                    style: AppTextFieldStyle.profile,
                  ),
                   const SizedBox(height: 12),

                  AppTextField(
                    controller: _youtubeController,
                    label: 'YouTube',
                    hint: 'https://youtube.com/@...',
                    icon: Icons.video_library,
                    style: AppTextFieldStyle.profile,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 224,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryDeep.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: (_coverUrl != null && _coverUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Image.network(
                      _coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryDeep.withValues(alpha: 0.08),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.primaryDeep.withValues(alpha: 0.08),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 190,
            child: Center(
              child: GestureDetector(
                onTap: _isUploadingCover ? null : _pickCoverImage,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isUploadingCover
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined,
                          size: 24, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.grey.shade100,
                      child: _isUploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? ClipOval(
                                  child: Image.network(
                                    _avatarUrl!,
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.store,
                                        size: 30,
                                        color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.store,
                                  size: 30, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(Icons.camera_alt,
                          size: 14, color: AppColors.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _selectedWilaya != null && _selectedBaladiya != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Store Location',
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: hasLocation
                  ? Border.all(
                      color: AppColors.successGreen.withValues(alpha: 0.5),
                      width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasLocation
                        ? Icons.location_on
                        : Icons.add_location_alt_outlined,
                    color: hasLocation
                        ? AppColors.successGreen
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: hasLocation
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedBaladiya!,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedWilaya!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Text(
                          'Tap to select location',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                        ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: hasLocation
                      ? AppColors.successGreen
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // GPS Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            icon: _isGettingLocation 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, size: 18),
            label: Text(_latitude != null 
                ? 'Update Grid Coordinates (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})' 
                : 'Get Current GPS Location'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
              foregroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
