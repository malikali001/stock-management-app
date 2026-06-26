import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/computed_stock.dart';
import '../models/portfolio_stock.dart';
import '../providers/portfolio_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/sector_data.dart';

class StockFormSheet extends ConsumerStatefulWidget {
  final ComputedStock? editStock;

  const StockFormSheet({super.key, this.editStock});

  @override
  ConsumerState<StockFormSheet> createState() => _StockFormSheetState();
}

class _StockFormSheetState extends ConsumerState<StockFormSheet> {
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _qtyController = TextEditingController();
  final _symbolFocus = FocusNode();
  String _selectedSector = 'other';
  List<String> _filteredSymbols = [];
  bool _showSuggestions = false;

  bool get _isEditing => widget.editStock != null;

  @override
  void initState() {
    super.initState();
    _symbolFocus.addListener(() {
      if (!_symbolFocus.hasFocus && _showSuggestions) {
        setState(() => _showSuggestions = false);
      }
    });
    if (_isEditing) {
      final s = widget.editStock!;
      _symbolController.text = s.symbol;
      _nameController.text = s.name;
      _costController.text = s.avgCost.toString();
      _qtyController.text = s.qty.toString();
      _selectedSector = s.sector;
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _costController.dispose();
    _qtyController.dispose();
    _symbolFocus.dispose();
    super.dispose();
  }

  void _onSymbolChanged(String value) {
    final allSymbols = ref.read(portfolioProvider).allSymbols;
    if (value.isEmpty) {
      setState(() {
        _filteredSymbols = [];
        _showSuggestions = false;
      });
      return;
    }

    final upper = value.toUpperCase();
    final matches =
        allSymbols.where((s) => s.toUpperCase().contains(upper)).take(8).toList();
    setState(() {
      _filteredSymbols = matches;
      _showSuggestions = matches.isNotEmpty;
    });
  }

  void _selectSymbol(String symbol) {
    _symbolController.text = symbol;
    _nameController.text = symbol; // Will be overwritten if user knows the name
    setState(() {
      _showSuggestions = false;
    });
  }

  double get _investmentPreview {
    final cost = double.tryParse(_costController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    return cost * qty;
  }

  void _submit() {
    final symbol = _symbolController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final cost = double.tryParse(_costController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 0;

    if (symbol.isEmpty || cost <= 0 || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields.',
              style: AppTheme.bodyMedium),
          backgroundColor: AppColors.surface1,
        ),
      );
      return;
    }

    if (_isEditing) {
      final updated = PortfolioStock(
        id: widget.editStock!.id,
        symbol: symbol,
        name: name.isEmpty ? symbol : name,
        sector: _selectedSector,
        avgCost: cost,
        qty: qty,
      );
      ref.read(portfolioProvider.notifier).updateStock(updated);
    } else {
      final newStock = PortfolioStock(
        id: StorageService.generateId(),
        symbol: symbol,
        name: name.isEmpty ? symbol : name,
        sector: _selectedSector,
        avgCost: cost,
        qty: qty,
      );
      ref.read(portfolioProvider.notifier).addStock(newStock);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEditing ? 'Edit Stock' : 'Add Stock',
                  style: AppTheme.displayMedium,
                ),
                const SizedBox(height: 20),

                // Symbol input with autocomplete
                Text('PSX Symbol', style: AppTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _symbolController,
                  focusNode: _symbolFocus,
                  style: AppTheme.bodyLarge,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. HBL, MCB, OGDC',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textMuted, size: 20),
                    suffixIcon: _symbolController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _symbolController.clear();
                              _onSymbolChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSymbolChanged,
                ),
                // Suggestions dropdown
                if (_showSuggestions)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surface2),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredSymbols.length,
                      itemBuilder: (context, index) {
                        final sym = _filteredSymbols[index];
                        return ListTile(
                          dense: true,
                          title: Text(sym, style: AppTheme.bodyLarge),
                          onTap: () => _selectSymbol(sym),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // Company Name
                Text('Company Name', style: AppTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: AppTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Habib Bank Ltd',
                  ),
                ),
                const SizedBox(height: 16),

                // Sector picker
                Text('Sector', style: AppTheme.labelMedium),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSector,
                      isExpanded: true,
                      dropdownColor: AppColors.surface1,
                      style: AppTheme.bodyLarge,
                      items: SectorData.all
                          .map((s) => DropdownMenuItem(
                                value: s.key,
                                child: Text('${s.icon} ${s.name}'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedSector = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Avg buy price
                Text('Average Buy Price', style: AppTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _costController,
                  style: AppTheme.monoSmall,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixText: '\u20A8 ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Quantity
                Text('Quantity (Shares)', style: AppTheme.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _qtyController,
                  style: AppTheme.monoSmall,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Investment preview
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Investment',
                          style: AppTheme.labelMedium
                              .copyWith(color: AppColors.accent)),
                      Text(
                        Formatters.currency(_investmentPreview),
                        style: AppTheme.monoMedium
                            .copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(
                      _isEditing
                          ? '\u2713 Update'
                          : '\uFF0B Add to Portfolio',
                      style: AppTheme.titleMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
