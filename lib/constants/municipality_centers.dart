import 'package:latlong2/latlong.dart';

/// Approximate administrative center of each Bhaktapur District
/// municipality. Used only to detect the NEAREST municipality to a
/// tapped map point - not precise ward boundaries (see Phase 10 notes).
const Map<String, LatLng> kMunicipalityCenters = {
  'Bhaktapur Municipality': LatLng(27.6710, 85.4298),
  'Madhyapur Thimi Municipality': LatLng(27.6806, 85.3875),
  'Suryabinayak Municipality': LatLng(27.6650, 85.4200),
  'Changunarayan Municipality': LatLng(27.6891, 85.4496),
};

/// Rough center of the whole district - used to center the map on open.
const LatLng kBhaktapurDistrictCenter = LatLng(27.6720, 85.4280);