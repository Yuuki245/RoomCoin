import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state.dart';
import '../controllers/expense_controller.dart';
import '../models/tag.dart';
import '../widgets/expense_state_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ExpenseController controller = Get.find();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  Worker? _tagsWorker;
  Worker? _membersWorker;

  DateTime _selectedDate = DateTime.now();
  Tag? _selectedTag;
  List<String> _splitBetweenUids = [];
  String? _paidByUid;

  @override
  void initState() {
    super.initState();
    _paidByUid = controller.currentUid;
    _syncMemberDefaults();
    _syncTagDefaults();

    _tagsWorker = ever(controller.tags, (_) {
      if (mounted) {
        setState(_syncTagDefaults);
      }
    });
    _membersWorker = ever(controller.members, (_) {
      if (mounted) {
        setState(_syncMemberDefaults);
      }
    });
  }

  void _syncTagDefaults() {
    if (controller.tags.isEmpty) {
      _selectedTag = null;
      return;
    }

    final selectedId = _selectedTag?.id;
    _selectedTag =
        controller.tags.firstWhereOrNull((tag) => tag.id == selectedId) ??
        controller.tags.first;
  }

  void _syncMemberDefaults() {
    final memberUids = controller.members.map((m) => m.uid).toList();
    if (memberUids.isEmpty) {
      _splitBetweenUids = [];
      _paidByUid = controller.currentUid;
      return;
    }

    if (_splitBetweenUids.isEmpty) {
      _splitBetweenUids = List<String>.from(memberUids);
    } else {
      _splitBetweenUids = _splitBetweenUids.where(memberUids.contains).toList();
      if (_splitBetweenUids.isEmpty) {
        _splitBetweenUids = List<String>.from(memberUids);
      }
    }

    if (_paidByUid == null || !memberUids.contains(_paidByUid)) {
      _paidByUid = memberUids.contains(controller.currentUid)
          ? controller.currentUid
          : memberUids.first;
    }
  }

  @override
  void dispose() {
    _tagsWorker?.dispose();
    _membersWorker?.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (controller.isSaving.value) {
      return;
    }

    if (_amountController.text.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập số tiền',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedTag == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn danh mục',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_splitBetweenUids.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Phải có ít nhất 1 người chia tiền',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) {
      Get.snackbar(
        'Lỗi',
        'Số tiền không hợp lệ',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final paidByUid = _paidByUid;
    if (paidByUid == null || paidByUid.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn người trả',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    try {
      await controller.addExpense(
        amount: amount,
        paidByUid: paidByUid,
        splitBetweenUids: _splitBetweenUids,
        tagId: _selectedTag!.id,
        date: _selectedDate,
        note: note,
      );
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
    } catch (_) {}
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
      body: SingleChildScrollView(child: Obx(() => _buildBody(context))),
      bottomNavigationBar: SafeArea(
        child: Obx(() => _buildBottomAction(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isLoadingSetup =
        controller.isLoadingTags.value || controller.isLoadingMembers.value;
    final errorMessage = controller.primaryLoadError;

    if (isLoadingSetup &&
        controller.tags.isEmpty &&
        controller.members.isEmpty) {
      return _buildLoadingBody(context);
    }

    if (errorMessage != null &&
        controller.tags.isEmpty &&
        controller.members.isEmpty) {
      return ExpenseErrorState(
        title: 'Không thể tải dữ liệu biểu mẫu',
        subtitle: errorMessage,
        onRetry: controller.retryLoad,
      );
    }

    if (!controller.isLoadingTags.value && controller.tags.isEmpty) {
      return const EmptyState(
        icon: Icons.sell_outlined,
        title: 'Chưa có danh mục',
        subtitle: 'Danh mục chi tiêu của phòng chưa sẵn sàng.',
      );
    }

    if (!controller.isLoadingMembers.value && controller.members.isEmpty) {
      return const EmptyState(
        icon: Icons.group_outlined,
        title: 'Chưa có thành viên',
        subtitle: 'Phòng hiện chưa có thành viên để chia tiền.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Danh mục',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSplitChecklist(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Danh mục',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ExpenseTagGridShimmer(),
        ),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Chia tiền cho',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ExpenseChipWrapShimmer(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final isSaving = controller.isSaving.value;
    final canSubmit =
        controller.tags.isNotEmpty &&
        controller.members.isNotEmpty &&
        controller.primaryLoadError == null;

    if (!canSubmit && !isSaving) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: const StadiumBorder(),
          elevation: 4,
        ),
        child: Text(
          isSaving ? 'Đang lưu khoản chi...' : 'Nhập khoản Tiền chi',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(
                    () => _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    ),
                  );
                  HapticFeedback.selectionClick();
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    try {
                      final firstDate = DateTime(2020);
                      final lastDate = DateTime(2030);
                      final initialDate = _selectedDate.isBefore(firstDate)
                          ? firstDate
                          : (_selectedDate.isAfter(lastDate)
                                ? lastDate
                                : _selectedDate);

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        locale: const Locale('vi', 'VN'),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    } catch (_) {
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
                        Flexible(
                          child: Text(
                            DateFormat(
                              'dd/MM/yyyy (EEEE)',
                              'vi_VN',
                            ).format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_month,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(
                    () => _selectedDate = _selectedDate.add(
                      const Duration(days: 1),
                    ),
                  );
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Thêm ghi chú...',
              labelText: 'Ghi chú',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.members.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_paidByUid),
                  initialValue: _paidByUid,
                  decoration: const InputDecoration(
                    labelText: 'Người trả',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.members
                      .map(
                        (member) => DropdownMenuItem<String>(
                          value: member.uid,
                          child: Text(
                            member.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _paidByUid = value),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
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
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
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
        return const ExpenseTagGridShimmer();
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
          final baseColor = Color(
            int.parse(tag.colorHex.replaceFirst('#', '0xff')),
          );

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedTag = tag);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? baseColor
                        : baseColor.withValues(alpha: 0.15),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            width: 2,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: baseColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    IconData(tag.iconCode, fontFamily: 'MaterialIcons'),
                    size: 24,
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
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
        Get.snackbar(
          'Tính năng',
          'Sẽ ra mắt trong phiên bản sau',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Thêm mới', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSplitChecklist() {
    return Obx(() {
      if (controller.isLoadingMembers.value) {
        return const ExpenseChipWrapShimmer();
      }

      final members = controller.members;
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: members.map((member) {
          final isChecked = _splitBetweenUids.contains(member.uid);
          return FilterChip(
            label: Text(member.displayName, overflow: TextOverflow.ellipsis),
            selected: isChecked,
            onSelected: (value) {
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
