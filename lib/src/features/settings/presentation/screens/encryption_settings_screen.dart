import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';

/// Screen for managing encryption keys and settings
class EncryptionSettingsScreen extends ConsumerStatefulWidget {
  const EncryptionSettingsScreen({super.key});

  @override
  ConsumerState<EncryptionSettingsScreen> createState() =>
      _EncryptionSettingsScreenState();
}

class _EncryptionSettingsScreenState
    extends ConsumerState<EncryptionSettingsScreen> {
  bool _isLoading = false;
  String? _exportedKey;

  @override
  Widget build(BuildContext context) {
    final encryptionService = ref.watch(encryptionServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Encryption Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Encryption Key Management',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your encryption keys for secure data storage.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Key Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.green[700],
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Master Key Status',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<bool>(
                                future: encryptionService.hasMasterKey(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Text('Checking...');
                                  }
                                  return Text(
                                    snapshot.data!
                                        ? 'Active and ready'
                                        : 'Not configured',
                                    style: TextStyle(
                                      color: snapshot.data!
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.info_outline,
                      'Your master key encrypts all sensitive data including chat messages and task descriptions.',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.warning_amber_outlined,
                      'Losing your key means permanent data loss. Always keep a backup!',
                      isWarning: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Backup Section
            Text(
              'Backup & Recovery',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Export Key Button
            FutureBuilder<bool>(
              future: encryptionService.hasMasterKey(),
              builder: (context, snapshot) {
                final hasKey = snapshot.data ?? false;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.download,
                      color: hasKey ? Colors.blue : Colors.grey,
                    ),
                    title: const Text('Export Master Key'),
                    subtitle: const Text(
                      'Save your encryption key to a secure location',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: hasKey && !_isLoading,
                    onTap: hasKey ? _exportKey : null,
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Import Key Button
            Card(
              child: ListTile(
                leading: const Icon(Icons.upload, color: Colors.blue),
                title: const Text('Import Master Key'),
                subtitle: const Text('Restore your encryption key from backup'),
                trailing: const Icon(Icons.chevron_right),
                enabled: !_isLoading,
                onTap: _importKey,
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            Text(
              'Danger Zone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.red[50],
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Master Key'),
                subtitle: const Text(
                  'Permanently delete key and lose access to encrypted data',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: !_isLoading,
                onTap: _deleteKey,
              ),
            ),

            // Exported Key Display (if shown)
            if (_exportedKey != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Exported Key',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: SelectableText(
                          _exportedKey!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _exportedKey!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Key copied to clipboard'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy to Clipboard'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _exportedKey = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Hide key',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Store this key in a secure location. Anyone with this key can decrypt your data.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isWarning = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isWarning ? Colors.orange[700] : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isWarning ? Colors.orange[900] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportKey() async {
    // Show warning dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Export Encryption Key'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Warning:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '• This key can decrypt ALL your encrypted data\n'
              '• Store it in a secure password manager\n'
              '• Never share it with anyone\n'
              '• Keep it safe - losing it means data loss',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I Understand, Export'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      final key = await encryptionService.exportMasterKey();

      if (!mounted) return;

      setState(() {
        _exportedKey = key;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting key: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importKey() async {
    final controller = TextEditingController();

    final key = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Master Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your exported master key below:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Paste key here',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This will replace your current encryption key if one exists.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (key == null || key.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      await encryptionService.importMasterKey(key);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master key imported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing key: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Master Key'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DANGER:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• All encrypted data will become permanently inaccessible\n'
              '• Encrypted chat messages will be lost\n'
              '• Encrypted task descriptions will be lost\n'
              '• This action CANNOT be undone',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Are you absolutely sure?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      await encryptionService.deleteMasterKey();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _exportedKey = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master key deleted'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting key: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
