import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/delegate_repository.dart';
import '../domain/models/delegate_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';

final delegatesStreamProvider = StreamProvider<List<DelegateModel>>((ref) {
  return ref.watch(delegateRepositoryProvider).getDelegates();
});

class DelegatesScreen extends ConsumerWidget {
  const DelegatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegatesAsync = ref.watch(delegatesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('delegates')),
      ),
      body: delegatesAsync.when(
        data: (delegates) {
          if (delegates.isEmpty) {
            return Center(child: Text(context.loc('noDelegates')));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: delegates.length,
            itemBuilder: (context, index) {
              final delegate = delegates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(delegate.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${context.loc('type')}: ${delegate.type == AppConstants.delegateTypePercentage ? context.loc('percentageBased') : context.loc('halfBased')} (${delegate.percentage}%)',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to delegate details
                    context.push('/delegates/${delegate.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditDelegateDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDelegateDialog(BuildContext context, WidgetRef ref, [DelegateModel? delegate]) {
    final nameController = TextEditingController(text: delegate?.name);
    final percentageController = TextEditingController(text: delegate?.percentage.toString());
    String selectedType = delegate?.type ?? AppConstants.delegateTypePercentage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(delegate == null ? context.loc('addDelegate') : context.loc('editDelegate')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: context.loc('name')),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(labelText: context.loc('type')),
                      items: [
                        DropdownMenuItem(
                          value: AppConstants.delegateTypePercentage,
                          child: Text(context.loc('percentageBased')),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.delegateTypeHalf,
                          child: Text(context.loc('halfBased')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: percentageController,
                      decoration: InputDecoration(
                        labelText: selectedType == AppConstants.delegateTypePercentage 
                            ? context.loc('officePercentage') 
                            : context.loc('delegatePercentage'),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('%'),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.loc('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || percentageController.text.isEmpty) return;

                    final newDelegate = DelegateModel(
                      id: delegate?.id ?? '',
                      name: nameController.text.trim(),
                      type: selectedType,
                      percentage: double.tryParse(percentageController.text) ?? 0,
                    );

                    final repo = ref.read(delegateRepositoryProvider);
                    if (delegate == null) {
                      await repo.addDelegate(newDelegate);
                    } else {
                      await repo.updateDelegate(newDelegate);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(context.loc('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
