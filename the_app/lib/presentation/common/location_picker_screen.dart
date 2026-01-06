import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/algeria_wilayas_baladiat.dart';

class LocationResult {
  final LatLng coordinates;
  final String address;

  LocationResult({required this.coordinates, required this.address});
}

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  bool _showManualInput = true; // Show manual input by default
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  // Default to Algiers
  static const LatLng _defaultLocation = LatLng(36.7538, 3.0588);

  // For wilaya/baladiya dropdowns
  String? _selectedWilaya;
  String? _selectedBaladiya;

  List<String> get _wilayaList => algeriaWilayasBaladiat.keys.toList();
  List<String> get _baladiyaList => _selectedWilaya != null
      ? algeriaWilayasBaladiat[_selectedWilaya!] ?? []
      : [];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _defaultLocation;
    _selectedAddress = widget.initialAddress ?? '';

    // Initialize controllers with existing data
    _addressController.text = _selectedAddress;
    if (_selectedLocation != null) {
      _latController.text = _selectedLocation!.latitude.toString();
      _lngController.text = _selectedLocation!.longitude.toString();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    if (_showManualInput) {
      // Get location from manual input
      final address = (_selectedWilaya ?? '') +
          (_selectedBaladiya != null ? ', $_selectedBaladiya' : '');
      double? lat, lng;

      try {
        lat = double.parse(_latController.text.trim());
        lng = double.parse(_lngController.text.trim());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid coordinates')),
        );
        return;
      }

      if (_selectedWilaya == null || _selectedBaladiya == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select wilaya and baladiya')),
        );
        return;
      }

      Navigator.pop(
        context,
        LocationResult(
          coordinates: LatLng(lat, lng),
          address: address,
        ),
      );
    } else if (_selectedLocation != null) {
      Navigator.pop(
        context,
        LocationResult(
          coordinates: _selectedLocation!,
          address:
              _selectedAddress.isEmpty ? 'Selected location' : _selectedAddress,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Location',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.primaryBlue),
            onPressed: () {
              setState(() => _showManualInput = true);
              _getCurrentLocationManual();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode toggle
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showManualInput = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showManualInput
                          ? AppColors.primaryBlue
                          : Colors.grey[200],
                      foregroundColor:
                          _showManualInput ? Colors.white : Colors.grey[600],
                      elevation: 0,
                    ),
                    child: const Text('Manual Input'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showManualInput = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showManualInput
                          ? AppColors.primaryBlue
                          : Colors.grey[200],
                      foregroundColor:
                          !_showManualInput ? Colors.white : Colors.grey[600],
                      elevation: 0,
                    ),
                    child: const Text('Map View'),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _showManualInput ? _buildManualInput() : _buildMapView(),
          ),

          // Confirm button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Location',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Location Details',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Wilaya dropdown
          Text('Wilaya',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedWilaya,
            items: _wilayaList.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedWilaya = val;
                _selectedBaladiya = null;
                _addressController.text = '';
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Select wilaya',
            ),
          ),
          const SizedBox(height: 16),

          // Baladiya dropdown
          Text('Baladiya',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBaladiya,
            items: _baladiyaList
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedBaladiya = val;
                _addressController.text = val ?? '';
              });
            },
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              hintText: 'Select baladiya',
            ),
          ),
          const SizedBox(height: 16),

          // Coordinates section
          Text(
            'Coordinates (Optional)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Latitude field
          TextFormField(
            controller: _latController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Latitude',
              hintText: '36.7538',
              prefixIcon: const Icon(Icons.explore),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Longitude field
          TextFormField(
            controller: _lngController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Longitude',
              hintText: '3.0588',
              prefixIcon: const Icon(Icons.explore_off),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current location button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _getCurrentLocationManual,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                  _isLoading ? 'Getting Location...' : 'Use Current Location'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border(
                  bottom: BorderSide(color: Colors.orange[200]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Map requires Google Maps API key. Use Manual Input instead.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Map View Unavailable',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please use Manual Input',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocationManual() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Try to get address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String address = [
            place.street,
            place.locality,
            place.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');

          _addressController.text = address;
        }
      } catch (e) {
        print('Reverse geocoding error: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
