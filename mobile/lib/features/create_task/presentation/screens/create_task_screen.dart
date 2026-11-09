import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/create_task_cubit.dart';
import '../../domain/entities/create_task_input.dart';

class CreateTaskScreen extends StatefulWidget {
  final CreateTaskCubit cubit;
  final String? userDisplayName;
  const CreateTaskScreen({
    super.key,
    required this.cubit,
    this.userDisplayName,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String _selectedCategory = 'توصيل';
  DateTime? _dueDate;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'توصيل', 'icon': Icons.local_shipping_outlined},
    {'name': 'نقل أغراض', 'icon': Icons.inventory_2_outlined},
    {'name': 'دراسة', 'icon': Icons.school_outlined},
    {'name': 'تسوق', 'icon': Icons.shopping_bag_outlined},
    {'name': 'صيانة بسيطة', 'icon': Icons.handyman_outlined},
    {'name': 'أخرى', 'icon': Icons.grid_view_outlined},
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2B)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocConsumer<CreateTaskCubit, CreateTaskState>(
          listener: (context, state) {
            if (state is CreateTaskSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نشر طلب المساعدة بنجاح')),
              );
              Navigator.pop(context, true);
            }
          },
          builder: (context, state) {
            final isBusy = state is CreateTaskLoading;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                children: [
                  // Title matching Auth Teal Theme
                  const Text(
                    'اطلب مساعدة',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'جيرانك حاضرين يساعدونك بأي شي بسيط',
                    style: TextStyle(fontSize: 14, color: Color(0xFF777777)),
                  ),
                  const SizedBox(height: 24),

                  // Input 1: عنوان الطلب
                  const Text(
                    'عنوان الطلب',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        hintText: 'مثال: أحتاج توصيل كتاب من المكتبة',
                        hintStyle: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'عنوان الطلب مطلوب'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input 2: التفاصيل
                  const Text(
                    'التفاصيل',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: TextFormField(
                      controller: _description,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'اشرح المطلوب بالضبط ومتى تحتاجه...',
                        hintStyle: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      validator: (v) => v == null || v.trim().length < 5
                          ? 'يرجى كتابة تفاصيل واضحة'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input 3: الفئة Section Header
                  const Text(
                    'الفئة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grid of Category Cards (3 columns x 2 rows)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat['name'] == _selectedCategory;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat['name']!),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00695C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00695C)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 28,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF00695C),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat['name'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  if (state is CreateTaskError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

                  // Action Button: نشر الطلب
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<CreateTaskCubit>().submit(
                                  CreateTaskInput(
                                    title: _title.text.trim(),
                                    description: _description.text.trim(),
                                    category: _selectedCategory,
                                    location: _location.text.trim().isEmpty
                                        ? 'الحي'
                                        : _location.text.trim(),
                                    ownerName: widget.userDisplayName,
                                    dueDate: _dueDate,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isBusy
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'نشر الطلب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.send_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
