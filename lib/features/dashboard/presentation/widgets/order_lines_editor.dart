import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/products_mock_data.dart';

class OrderLineDraft {
  OrderLineDraft({this.productId, this.quantity = 1, this.unitValue});
  String? productId;
  int quantity;
  double? unitValue;
}

/// Repeating "product + quantity (+ unit cost/price)" row editor shared
/// by the Purchase Order, Transfer and Sale dialogs — the three flows
/// that all need "pick some products and quantities" but differ in
/// whether there's a per-line money value and what it means.
class OrderLinesEditor extends StatefulWidget {
  const OrderLinesEditor({
    super.key,
    required this.products,
    this.showUnitValue = false,
    this.unitValueLabel = 'Valor unitario',
    this.defaultUnitValue,
    this.onChanged,
  });

  final List<ProductRow> products;
  final bool showUnitValue;
  final String unitValueLabel;

  /// Prefills the unit value field when a product is picked (e.g. the
  /// product's current price, for a sale).
  final double? Function(String productId)? defaultUnitValue;

  final ValueChanged<List<OrderLineDraft>>? onChanged;

  @override
  State<OrderLinesEditor> createState() => OrderLinesEditorState();
}

class OrderLinesEditorState extends State<OrderLinesEditor> {
  final List<OrderLineDraft> _lines = [OrderLineDraft()];

  /// Only lines with a product selected and a positive quantity count.
  List<OrderLineDraft> get validLines => _lines.where((l) => l.productId != null && l.quantity > 0).toList();

  void _notify() => widget.onChanged?.call(validLines);

  void _addLine() => setState(() => _lines.add(OrderLineDraft()));

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _lines.length; i++) _LineRow(
              key: ValueKey(_lines[i]),
              draft: _lines[i],
              products: widget.products,
              showUnitValue: widget.showUnitValue,
              unitValueLabel: widget.unitValueLabel,
              defaultUnitValue: widget.defaultUnitValue,
              onChanged: () {
                setState(() {});
                _notify();
              },
              onRemove: _lines.length > 1 ? () => _removeLine(i) : null,
            ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: _addLine,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Agregar línea'),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.draft,
    required this.products,
    required this.showUnitValue,
    required this.unitValueLabel,
    required this.defaultUnitValue,
    required this.onChanged,
    required this.onRemove,
  });

  final OrderLineDraft draft;
  final List<ProductRow> products;
  final bool showUnitValue;
  final String unitValueLabel;
  final double? Function(String productId)? defaultUnitValue;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: draft.productId,
              isExpanded: true,
              decoration: const InputDecoration(hintText: 'Producto', isDense: true),
              items: [
                for (final p in products) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) {
                draft.productId = value;
                if (value != null && showUnitValue && draft.unitValue == null) {
                  draft.unitValue = defaultUnitValue?.call(value);
                }
                onChanged();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: draft.quantity.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cant.', isDense: true),
              onChanged: (v) {
                draft.quantity = int.tryParse(v) ?? 0;
                onChanged();
              },
            ),
          ),
          if (showUnitValue) ...[
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 110,
              child: TextFormField(
                initialValue: draft.unitValue?.toStringAsFixed(2) ?? '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: unitValueLabel, isDense: true),
                onChanged: (v) {
                  draft.unitValue = double.tryParse(v);
                  onChanged();
                },
              ),
            ),
          ],
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: onRemove == null ? AppColors.border : AppColors.textMuted),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
