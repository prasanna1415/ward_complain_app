import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/wards.dart';
import 'home_screen.dart';

class SelectWardScreen extends StatefulWidget {
  const SelectWardScreen({super.key});

  @override
  State<SelectWardScreen> createState() => _SelectWardScreenState();
}

class _SelectWardScreenState extends State<SelectWardScreen> {
  String? _selectedWard;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _saveWard() async {
    if (_selectedWard == null) {
      setState(() {
        _errorMessage = 'Please select your ward to continue.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'wardId': _selectedWard,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not save your ward. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Ward'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_city, size: 70, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Which ward do you live in?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This helps route your complaints to the right ward administrator.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedWard,
              decoration: const InputDecoration(
                labelText: 'Ward',
                border: OutlineInputBorder(),
              ),
              items: kWardList
                  .map((ward) => DropdownMenuItem(value: ward, child: Text(ward)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWard = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWard,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}