/// A simple, fixed list of departments complaints can be assigned to.
/// Kept as a Dart constant rather than a Firestore collection for now,
/// matching the same reasoning as categories.dart - departments rarely
/// change, so this avoids an extra collection + admin CRUD screen just
/// for a short static list.
const List<String> kDepartments = [
  'Roads Department',
  'Water Supply Department',
  'Sanitation Department',
  'Electricity Department',
  'Public Works Department',
  'Health & Environment Department',
  'General Administration',
];