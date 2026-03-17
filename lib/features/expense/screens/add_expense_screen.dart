import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/expense_controller.dart';
import '../models/tag.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ExpenseController controller = Get.find();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Tag? _selectedTag;
  List<String> _splitBetweenUids = [];
  String? _paidByUid;

  @override
  void initState() {
    super.initState();
    final currentUid = controller.currentUid;
    _paidByUid = currentUid;
    _splitBetweenUids = controller.members.map((m) => m.uid).toList();
    if (controller.tags.isNotEmpty) _selectedTag = controller.tags.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_amountController.text.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập số tiền', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    if (_selectedTag == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn danh mục', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (_splitBetweenUids.isEmpty) {
      Get.snackbar('Lỗi', 'Phải có ít nhất 1 người chia tiền', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountStr) ?? 0;

    if (amount <= 0) {
      Get.snackbar('Lỗi', 'Số tiền không hợp lệ', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final paidByUid = _paidByUid;
    if (paidByUid == null || paidByUid.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn người trả', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    controller
        .addExpense(
          amount: amount,
          paidByUid: paidByUid,
          splitBetweenUids: _splitBetweenUids,
          tagId: _selectedTag!.id,
          date: _selectedDate,
          note: note,
        )
        .then((_) {
          HapticFeedback.lightImpact();
          Get.back();
          Get.snackbar(
            'Thành công',
            'Đã thêm khoản chi!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
            margin: const EdgeInsets.all(16),
          );
        })
        .catchError((e) {
          Get.snackbar('Lỗi', e.toString(), snackPosition: SnackPosition.BOTTOM);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm khoản chi'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Danh mục',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTagGridView(),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Chia tiền cho',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSplitChecklist(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: ElevatedButton(
            onPressed: _saveExpense,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: const StadiumBorder(),
              elevation: 4,
            ),
            child: const Text('Nhập khoản Tiền chi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Date Selector with Left/Right arrows
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  HapticFeedback.selectionClick();
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    debugPrint('[AddExpense] Mở bộ chọn ngày. initialDate=$_selectedDate');
                    try {
                      final firstDate = DateTime(2020);
                      final lastDate = DateTime(2030);
                      final initialDate = _selectedDate.isBefore(firstDate)
                          ? firstDate
                          : (_selectedDate.isAfter(lastDate) ? lastDate : _selectedDate);

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        locale: const Locale('vi', 'VN'),
                      );
                      debugPrint('[AddExpense] Đóng bộ chọn ngày. picked=$picked');
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    } catch (e) {
                      debugPrint('[AddExpense] Lỗi bộ chọn ngày: $e');
                      Get.snackbar(
                        'Lỗi',
                        'Không thể mở bộ chọn ngày. Vui lòng thử lại.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy (EEEE)', 'vi_VN').format(_selectedDate),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_month, size: 20, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2. Note Input (Ghi chú)
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Thêm ghi chú...',
              labelText: 'Ghi chú', // Label
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          // Người trả
          if (controller.members.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _paidByUid ?? controller.currentUid,
              decoration: const InputDecoration(
                labelText: 'Người trả',
                border: OutlineInputBorder(),
              ),
              items: controller.members
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.uid,
                      child: Text(m.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _paidByUid = v),
            ),
            const SizedBox(height: 12),
          ],
          // 3. Amount Input (Tiền chi)
          Row(
            children: [
              const Text(
                'Tiền chi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true, // Autofocus keyboard
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'đ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagGridView() {
    return Obx(() {
      if (controller.isLoadingTags.value) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              highlightColor: Theme.of(context).colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 44, color: Colors.white),
                ],
              ),
            );
          },
        );
      }

      final tags = controller.tags;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        itemCount: tags.length + 1,
        itemBuilder: (context, index) {
          if (index == tags.length) {
            return _buildAddTagButton();
          }
          final tag = tags[index];
          final isSelected = _selectedTag?.id == tag.id;
          final baseColor = Color(int.parse(tag.colorHex.replaceFirst('#', '0xff')));
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedTag = tag);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48, // Giảm từ 56
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? baseColor : baseColor.withValues(alpha: 0.15),
                    border: isSelected 
                        ? Border.all(color: Theme.of(context).colorScheme.secondaryContainer, width: 2)
                        : null,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ] : null,
                  ),
                  child: Icon(
                    IconData(tag.iconCode, fontFamily: 'MaterialIcons'),
                    size: 24, // Giảm từ 28
                    color: isSelected ? Colors.white : baseColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tag.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10, // Giảm từ 12
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildAddTagButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Mở popup tạo Tag mới
        Get.snackbar('Tính năng', 'Sẽ ra mắt trong phiên bản sau', snackPosition: SnackPosition.BOTTOM);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          const Text('Thêm mới', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Note input is now inline in _buildHeader

  Widget _buildSplitChecklist() {
    return Obx(() {
      final members = controller.members;
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: members.map((member) {
          final isChecked = _splitBetweenUids.contains(member.uid);
          return FilterChip(
            label: Text(member.displayName),
            selected: isChecked,
            onSelected: (bool value) {
              setState(() {
                if (value) {
                  _splitBetweenUids.add(member.uid);
                } else {
                  _splitBetweenUids.remove(member.uid);
                }
              });
            },
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            checkmarkColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: isChecked 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      );
    });
  }
}
