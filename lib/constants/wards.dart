/// Bhaktapur District's real municipality and ward structure,
/// based on Nepal's 2022 local election data.
const Map<String, int> kMunicipalityWardCounts = {
  'Bhaktapur Municipality': 10,
  'Madhyapur Thimi Municipality': 9,
  'Suryabinayak Municipality': 10,
  'Changunarayan Municipality': 9,
};

List<String> get kMunicipalityList => kMunicipalityWardCounts.keys.toList();

/// Returns ward labels like 'Ward 1', 'Ward 2', ... for a given municipality.
List<String> wardsForMunicipality(String municipality) {
  final count = kMunicipalityWardCounts[municipality] ?? 0;
  return List.generate(count, (i) => 'Ward ${i + 1}');
}