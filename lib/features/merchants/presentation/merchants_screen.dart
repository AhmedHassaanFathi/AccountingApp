import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/merchant_repository.dart';

final merchantsProvider = StreamProvider((ref) {
  return ref.watch(merchantRepositoryProvider).getMerchants();
});

class MerchantsScreen extends ConsumerWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(merchantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('merchants')),
      ),
      body: merchantsAsync.when(
        data: (merchants) {
          if (merchants.isEmpty) {
            return Center(child: Text(context.loc('noDelegates'))); // Reusing, or can add 'noMerchants'
          }
          final dateFormat = DateFormat.yMMMEd();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: merchants.length,
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(merchant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(dateFormat.format(merchant.createdAt)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.go('/merchants/${merchant.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMerchantDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.loc('addMerchant')),
      ),
    );
  }

  void _showAddMerchantDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.loc('addMerchant')),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: context.loc('name')),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.loc('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(merchantRepositoryProvider).addMerchant(name);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(context.loc('save')),
            ),
          ],
        );
      },
    );
  }
}
