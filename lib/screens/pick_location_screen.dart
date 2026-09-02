import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../constants/municipality_centers.dart';
import '../services/location_service.dart';

class PickedLocation {
  final LatLng point;
  final String municipality;
  final String? address;

  PickedLocation({
    required this.point,
    required this.municipality,
    this.address,
  });
}

class PickLocationScreen extends StatefulWidget {
  /// Optional starting point/address, used when editing an existing
  /// complaint's location instead of picking a brand-new one.
  final LatLng? initialPoint;
  final String? initialAddress;

  const PickLocationScreen({super.key, this.initialPoint, this.initialAddress});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final _mapController = MapController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  LatLng? _selectedPoint;
  String? _detectedMunicipality;
  bool _isOutsideDistrict = false;
  bool _isLocating = false;
  bool _isSearching = false;
  bool _isLookingUpAddress = false;
  List<AddressSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPoint != null) {
      _selectedPoint = widget.initialPoint;
      _detectedMunicipality = LocationService.detectNearestMunicipality(widget.initialPoint!);
      _isOutsideDistrict = !LocationService.isWithinBhaktapurDistrict(widget.initialPoint!);
      _addressController.text = widget.initialAddress ?? '';
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyPoint(LatLng point) async {
    final withinDistrict = LocationService.isWithinBhaktapurDistrict(point);

    setState(() {
      _selectedPoint = point;
      _isOutsideDistrict = !withinDistrict;
      _searchResults = [];
      _detectedMunicipality = withinDistrict ? LocationService.detectNearestMunicipality(point) : null;
      _addressController.text = '';
    });

    if (!withinDistrict) return;

    setState(() {
      _isLookingUpAddress = true;
    });

    final address = await LocationService.reverseGeocode(point);

    if (!mounted) return;
    setState(() {
      _isLookingUpAddress = false;
      if (address != null) {
        _addressController.text = address;
      }
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _applyPoint(point);
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _isLocating = true;
    });

    final position = await LocationService.getCurrentLocation();

    if (!mounted) return;
    setState(() {
      _isLocating = false;
    });

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location. Please check permissions and try tapping the map instead.')),
      );
      return;
    }

    await _applyPoint(position);
    _mapController.move(position, 16);
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    final results = await LocationService.searchAddress(query);

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchResults = results;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching locations found in Bhaktapur District.')),
      );
    }
  }

  Future<void> _selectSearchResult(AddressSearchResult result) async {
    setState(() {
      _searchResults = [];
      _searchController.text = result.displayName;
    });
    _mapController.move(result.point, 16);
    await _applyPoint(result.point);
    FocusScope.of(context).unfocus();
  }

  void _confirmSelection() {
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map.')),
      );
      return;
    }
    if (_isOutsideDistrict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This app only supports locations within Bhaktapur District.')),
      );
      return;
    }

    Navigator.pop(
      context,
      PickedLocation(
        point: _selectedPoint!,
        municipality: _detectedMunicipality!,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.initialPoint ?? kBhaktapurDistrictCenter,
                    initialZoom: widget.initialPoint != null ? 16 : 13,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.ward_complaint_app',
                    ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_pin,
                              color: _isOutsideDistrict ? Colors.grey : Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for an address in Bhaktapur District',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: _searchAddress,
                        ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_outlined, size: 18),
                                title: Text(
                                  result.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                onTap: () => _selectSearchResult(result),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'locateMe',
                    backgroundColor: Colors.white,
                    onPressed: _isLocating ? null : _useMyLocation,
                    icon: _isLocating
                        ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.my_location, color: Colors.blue),
                    label: const Text('Use My Location', style: TextStyle(color: Colors.blue)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isOutsideDistrict) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This location is outside Bhaktapur District. This app currently only supports locations within the district.',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_detectedMunicipality != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_city, size: 18, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_detectedMunicipality!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      helperText: 'Auto-filled from map location - edit if needed',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _isLookingUpAddress
                          ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _selectedPoint == null || _isOutsideDistrict ? null : _confirmSelection,
                    child: const Text('Confirm Location'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}