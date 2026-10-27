import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/pricing_settings.dart';
import '../../services/firestore_service.dart';

/// Admin → Payments → Price list. The things a payment can be for: name,
/// price and what the student gets. Invoices pick a row from here and the
/// server charges that price, so changing a row changes future invoices only.
class AdminPriceListScreen extends StatelessWidget {
  const AdminPriceListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return ShellNestedPage(
      embedded: embedded,
      title: 'Price list',
      child: StreamBuilder<PricingSettings>(
        stream: firestore.watchPricing(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _PriceListBody(pricing: snap.data!);
        },
      ),
    );
  }
}

class _PriceListBody extends StatefulWidget {
  const _PriceListBody({required this.pricing});

  final PricingSettings pricing;

  @override
  State<_PriceListBody> createState() => _PriceListBodyState();
}

class _PriceListBodyState extends State<_PriceListBody> {
  bool _busy = false;

  Future<void> _save(PricingSettings next) async {
    setState(() => _busy = true);
    try {
      await context.read<FirestoreService>().updatePricing(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price list saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([PriceItem? existing]) async {
    final result = await showDialog<PriceItem>(
      context: context,
      builder: (_) => _PriceItemDialog(
        existing: existing,
        takenIds: widget.pricing.items.map((i) => i.id).toSet(),
      ),
    );
    if (result == null) return;
    final items = [...widget.pricing.items];
    final index = items.indexWhere((i) => i.id == result.id);
    if (index >= 0) {
      items[index] = result;
    } else {
      items.add(result);
    }
    await _save(widget.pricing.copyWith(items: items));
  }

  Future<void> _remove(PriceItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove "${item.name}"?'),
        content: const Text(
          'Invoices already created keep their price. New invoices can no '
          'longer pick this item.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _save(
      widget.pricing.copyWith(
        items: widget.pricing.items.where((i) => i.id != item.id).toList(),
      ),
    );
  }

  Future<void> _editValidity() async {
    final controller =
        TextEditingController(text: '${widget.pricing.termValidDays}');
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Voucher validity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Days a paid voucher stays valid',
            helperText: 'Flyer: 2 months = 60 days',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (days == null || days <= 0) return;
    await _save(widget.pricing.copyWith(termValidDays: days));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pricing;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Everything a payment can be for. Create invoice picks a row from '
          'this list and the server charges exactly this price. Rows that give '
          'class sessions become vouchers when paid.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.navy,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add item'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final item in p.items) ...[
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    switch (item.kind) {
                      PriceKind.sessions => Icons.confirmation_number_outlined,
                      PriceKind.book => Icons.menu_book_outlined,
                      PriceKind.registration => Icons.how_to_reg_outlined,
                      PriceKind.other => Icons.sell_outlined,
                    },
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Gives ${item.givesLabel}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.navy,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: _busy ? null : () => _edit(item),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  onPressed: _busy ? null : () => _remove(item),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        AppCard(
          onTap: _busy ? null : _editValidity,
          child: Row(
            children: [
              const Icon(Icons.event_available_outlined,
                  color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voucher validity',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${p.termValidDays} days from payment '
                      '(${(p.termValidDays / 30).toStringAsFixed(p.termValidDays % 30 == 0 ? 0 : 1)} months)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        if (p.updatedAt != null) ...[
          const SizedBox(height: 12),
          Text(
            'Last saved ${p.updatedAt!.day}/${p.updatedAt!.month}/${p.updatedAt!.year}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceItemDialog extends StatefulWidget {
  const _PriceItemDialog({this.existing, required this.takenIds});

  final PriceItem? existing;
  final Set<String> takenIds;

  @override
  State<_PriceItemDialog> createState() => _PriceItemDialogState();
}

class _PriceItemDialogState extends State<_PriceItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(
    text: widget.existing == null ? '' : '${widget.existing!.price}',
  );
  late final _sessions = TextEditingController(
    text: widget.existing == null || widget.existing!.sessions == 0
        ? ''
        : '${widget.existing!.sessions}',
  );
  late PriceKind _kind = widget.existing?.kind ?? PriceKind.sessions;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _sessions.dispose();
    super.dispose();
  }

  String _newId() {
    final base = _name.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    var id = base.isEmpty ? 'item' : base;
    var n = 2;
    while (widget.takenIds.contains(id)) {
      id = '${base}_$n';
      n++;
    }
    return id;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      PriceItem(
        id: widget.existing?.id ?? _newId(),
        name: _name.text.trim(),
        price: int.parse(_price.text.trim()),
        kind: _kind,
        sessions: _kind == PriceKind.sessions
            ? int.parse(_sessions.text.trim())
            : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New item' : 'Edit item'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. 8 class sessions',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (Rp, whole number)',
                  hintText: '2450000',
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n == null || n <= 0 ? 'Enter a price above 0' : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PriceKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'What it gives'),
                items: [
                  for (final k in PriceKind.values)
                    DropdownMenuItem(value: k, child: Text(k.label)),
                ],
                onChanged: (k) => setState(() => _kind = k ?? _kind),
              ),
              if (_kind == PriceKind.sessions) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sessions,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of class sessions',
                    hintText: '8',
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n <= 0 ? 'Enter 1 or more' : null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
