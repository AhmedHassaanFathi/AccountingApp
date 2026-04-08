import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../delegates/data/delegate_repository.dart';
import '../../delegates/domain/models/delegate_model.dart';
import '../domain/models/merchant_collection_model.dart';
import '../data/merchant_collection_repository.dart';

class AddCollectionScreen extends ConsumerStatefulWidget {
  final String merchantId;

  const AddCollectionScreen({super.key, required this.merchantId});

  @override
  ConsumerState<AddCollectionScreen> createState() => _AddCollectionScreenState();
}

class _AddCollectionScreenState extends ConsumerState<AddCollectionScreen> {
  DelegateModel? _selectedDelegate;
  final List<_OrderEntry> _orders = [_OrderEntry()];
  final _paidController = TextEditingController();
  final _noteController = TextEditingController();

  double get _totalAmount {
    return _orders.fold(0.0, (sum, order) {
      if (order.status == 'returned') return sum;
      return sum + (double.tryParse(order.priceController.text) ?? 0);
    });
  }

  double get _paidAmount => double.tryParse(_paidController.text) ?? 0;
  double get _remainingAmount => _totalAmount - _paidAmount;

  @override
  void dispose() {
    _paidController.dispose();
    _noteController.dispose();
    for (var o in _orders) {
      o.dispose();
    }
    super.dispose();
  }

  void _addOrder() {
    setState(() {
      _orders.add(_OrderEntry());
    });
  }

  void _removeOrder(int index) {
    setState(() {
      _orders[index].dispose();
      _orders.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_selectedDelegate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المندوب')));
      return;
    }

    final validOrders = _orders.where((o) => o.addressController.text.isNotEmpty && o.priceController.text.isNotEmpty).toList();
    if (validOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إضافة أوردر واحد على الأقل')));
      return;
    }

    final collection = MerchantCollectionModel(
      id: '',
      merchantId: widget.merchantId,
      delegateId: _selectedDelegate!.id,
      delegateName: _selectedDelegate!.name,
      date: DateTime.now(),
      orders: validOrders.map((o) => OrderItem(
        address: o.addressController.text,
        price: o.status == 'returned' ? 0 : (double.tryParse(o.priceController.text) ?? 0),
        status: o.status,
      )).toList(),
      totalAmount: _totalAmount,
      paidAmount: _paidAmount,
      remainingAmount: _remainingAmount,
      note: _noteController.text,
    );

    await ref.read(merchantCollectionRepositoryProvider).addCollection(collection);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final delegatesAsync = ref.watch(delegatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحصيل جديد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: delegatesAsync.when(
        data: (delegates) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<DelegateModel>(
                  decoration: const InputDecoration(labelText: 'اختر المندوب', border: OutlineInputBorder()),
                  value: _selectedDelegate,
                  items: delegates.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDelegate = val),
                ),
                const SizedBox(height: 24),
                const Text('الأوردرات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._orders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final order = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: order.addressController,
                              decoration: const InputDecoration(labelText: 'العنوان'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: order.priceController,
                              decoration: const InputDecoration(labelText: 'السعر'),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: order.status,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'delivered', child: Text('ناجح', style: TextStyle(color: Colors.green, fontSize: 13))),
                                  DropdownMenuItem(value: 'returned', child: Text('مرتجع', style: TextStyle(color: Colors.red, fontSize: 13))),
                                  DropdownMenuItem(value: 'postponed', child: Text('مؤجل', style: TextStyle(color: Colors.orange, fontSize: 13))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => order.status = val);
                                },
                              ),
                            ),
                          ),
                          if (_orders.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeOrder(index),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addOrder,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة أوردر جديد'),
                ),
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('إجمالي الأوردرات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${_totalAmount.toStringAsFixed(0)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _paidController,
                  decoration: const InputDecoration(labelText: 'استلمت منه كام؟ (المُحصّل)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _remainingAmount > 0 ? Colors.red.shade50 : Colors.green.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المتبقي على المندوب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${_remainingAmount.toStringAsFixed(0)} EGP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _remainingAmount > 0 ? Colors.red : Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (مثال: فودافون كاش على التليفون)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('حفظ التحصيل', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OrderEntry {
  final addressController = TextEditingController();
  final priceController = TextEditingController();
  String status = 'delivered';

  void dispose() {
    addressController.dispose();
    priceController.dispose();
  }
}

final delegatesProvider = StreamProvider((ref) {
  return ref.watch(delegateRepositoryProvider).getDelegates();
});
