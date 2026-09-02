import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../services/complaint_service.dart';
import 'pick_location_screen.dart';

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  PickedLocation? _pickedLocation;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(builder: (context) => const PickLocationScreen()),
    );

    if (result != null) {
      setState(() {
        _pickedLocation = result;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() {
        _errorMessage = 'Please select a category.';
      });
      return;
    }
    if (_pickedLocation == null) {
      setState(() {
        _errorMessage = 'Please select the problem\'s location on the map.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ComplaintService.createComplaint(
        municipality: _pickedLocation!.municipality,
        categoryId: _selectedCategoryId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _pickedLocation!.point.latitude,
        longitude: _pickedLocation!.point.longitude,
        address: _pickedLocation!.address,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not submit complaint. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCategories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    return ChoiceChip(
                      label: Text(cat.name),
                      avatar: Icon(cat.icon, size: 18),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Large pothole near school gate',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the problem in detail',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe the problem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickLocation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map, color: _pickedLocation == null ? Colors.grey : Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _pickedLocation == null
                              ? const Text('Tap to select location on map', style: TextStyle(color: Colors.grey))
                              : Text(
                            _pickedLocation!.address ?? _pickedLocation!.municipality,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Photo upload will be added in a later phase. Your ward will be confirmed by the ward administrator during review.',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Complaint', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}