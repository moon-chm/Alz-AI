import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/family_service.dart';
import '../../models/family_member.dart';
import 'package:mobile/core/widgets/family_grid.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  // FamilyService now provided via provider
  List<FamilyMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    final identifier = ref.read(authProvider).identifier;
    if (identifier == null) return;
    
    // Use identifier for family fetch
    final members = await ref.read(familyServiceProvider).getFamilyMembers(identifier);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Family', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Face recognition button
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton.icon(
                  onPressed: () => context.push(faceRecognitionRoute),
                  icon: const Icon(Icons.document_scanner, size: 28),
                  label: const Text('Who is this?', style: TextStyle(fontSize: 24)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                  ),
                ),
              ),
              
              const Text('Family Members', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              FamilyGrid(
                members: _members,
                onMemberTap: (member) {
                  context.push(photoCollectionRoute, extra: {'name': member.name});
                },
              ),
            ],
          ),
    );
  }
}
