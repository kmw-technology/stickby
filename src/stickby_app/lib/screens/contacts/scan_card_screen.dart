import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/p2p_provider.dart';
import '../../services/ml_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';

/// Screen for scanning business cards and extracting contacts.
class ScanCardScreen extends StatefulWidget {
  const ScanCardScreen({super.key});

  @override
  State<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends State<ScanCardScreen> {
  final MLService _mlService = MLService();
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();

  File? _imageFile;
  List<ContactCandidate>? _candidates;
  Set<int> _selectedIndices = {};
  bool _isProcessing = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Business Card'),
        actions: [
          if (_candidates != null && _candidates!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingState();
    }

    if (_candidates != null) {
      return _buildResultsState();
    }

    return _buildCaptureState();
  }

  Widget _buildCaptureState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.credit_card,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Scan a Business Card',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or select an image of a business card to automatically extract contact information.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Capture buttons
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Take Photo',
                  icon: Icons.camera_alt,
                  onPressed: () => _captureImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedGradientButton(
                  label: 'Gallery',
                  icon: Icons.photo_library,
                  onPressed: () => _captureImage(ImageSource.gallery),
                ),
              ),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_imageFile != null)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_imageFile!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Analyzing business card...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Extracting contact information',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }

  Widget _buildResultsState() {
    final candidates = _candidates!;

    if (candidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t extract any contact information from this image. Try a clearer photo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Try Again',
              icon: Icons.refresh,
              onPressed: _reset,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Image preview
        if (_imageFile != null)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(_imageFile!),
                fit: BoxFit.cover,
              ),
            ),
          ),

        // Results header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Found ${candidates.length} contacts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: _selectedIndices.length == candidates.length
                    ? () => setState(() => _selectedIndices.clear())
                    : () => setState(() => _selectedIndices = Set.from(
                        List.generate(candidates.length, (i) => i))),
                child: Text(
                  _selectedIndices.length == candidates.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
              ),
            ],
          ),
        ),

        // Contact list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              final isSelected = _selectedIndices.contains(index);

              return _buildCandidateCard(candidate, index, isSelected);
            },
          ),
        ),

        // Save button
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            label: _isSaving
                ? 'Saving...'
                : 'Save ${_selectedIndices.length} Contacts',
            icon: Icons.save,
            onPressed: _selectedIndices.isEmpty || _isSaving
                ? null
                : _saveSelectedContacts,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateCard(
    ContactCandidate candidate,
    int index,
    bool isSelected,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggleSelection(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(index),
                activeColor: AppColors.primary,
              ),

              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForType(candidate.type),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          candidate.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 8),
                        _buildConfidenceBadge(candidate.confidence),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editCandidate(index),
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final Color color;
    final String label;

    if (confidence >= 0.9) {
      color = AppColors.success;
      label = 'High';
    } else if (confidence >= 0.7) {
      color = AppColors.warning;
      label = 'Medium';
    } else {
      color = AppColors.danger;
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getIconForType(ContactType type) {
    switch (type) {
      case ContactType.email:
      case ContactType.businessEmail:
        return Icons.email_outlined;
      case ContactType.phone:
      case ContactType.businessPhone:
      case ContactType.mobile:
        return Icons.phone_outlined;
      case ContactType.website:
        return Icons.language_outlined;
      case ContactType.company:
        return Icons.business_outlined;
      case ContactType.position:
        return Icons.work_outlined;
      case ContactType.address:
        return Icons.location_on_outlined;
      case ContactType.linkedin:
        return Icons.link;
      case ContactType.twitter:
      case ContactType.instagram:
      case ContactType.facebook:
      case ContactType.social:
        return Icons.public_outlined;
      case ContactType.github:
        return Icons.code_outlined;
      default:
        return Icons.info_outlined;
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _isProcessing = true;
        _errorMessage = null;
      });

      // Process the image
      await _processImage();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    try {
      final recognizedText = await _mlService.recognizeText(_imageFile!);
      final candidates = _mlService.parseBusinessCard(recognizedText);

      setState(() {
        _candidates = candidates;
        _selectedIndices = Set.from(
          List.generate(candidates.length, (i) => i)
              .where((i) => candidates[i].confidence >= 0.7),
        );
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process image: $e';
        _isProcessing = false;
        _candidates = null;
      });
    }
  }

  Future<void> _editCandidate(int index) async {
    final candidate = _candidates![index];
    final labelController = TextEditingController(text: candidate.label);
    final valueController = TextEditingController(text: candidate.value);

    final result = await showDialog<ContactCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(ContactCandidate(
                type: candidate.type,
                label: labelController.text,
                value: valueController.text,
                confidence: candidate.confidence,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _candidates![index] = result;
      });
    }
  }

  Future<void> _saveSelectedContacts() async {
    if (_selectedIndices.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final isP2P = await _storageService.isPrivacyModeEnabled();
      final selectedCandidates = _selectedIndices
          .map((i) => _candidates![i])
          .toList();

      int savedCount = 0;

      if (isP2P) {
        // Save to P2P local database
        final p2pProvider = context.read<P2PProvider>();
        for (final candidate in selectedCandidates) {
          await p2pProvider.addLocalContact(
            type: candidate.type,
            label: candidate.label,
            value: candidate.value,
            releaseGroups: ReleaseGroup.all, // Default to all groups
          );
          savedCount++;
        }
      } else {
        // Save to cloud via API
        final contactsProvider = context.read<ContactsProvider>();
        for (final candidate in selectedCandidates) {
          await contactsProvider.createContact(
            type: candidate.type,
            label: candidate.label,
            value: candidate.value,
            releaseGroups: ReleaseGroup.all,
          );
          savedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved $savedCount contacts successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save contacts: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _candidates = null;
      _selectedIndices = {};
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }
}
