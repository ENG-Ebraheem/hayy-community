import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../data/datasources/tasks_remote_data_source.dart';
import '../../data/repositories/tasks_repository_impl.dart';
import '../../domain/entities/task.dart';

class MyTasksScreen extends StatefulWidget {
  final AppUser user;
  final DioClient dioClient;
  final Function(Task) onOpenTask;

  const MyTasksScreen({
    super.key,
    required this.user,
    required this.dioClient,
    required this.onOpenTask,
  });

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  int _activeTab = 0; // 0: طلباتي المنشورة, 1: تطوّعاتي
  late final TasksRepositoryImpl _repository;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = TasksRepositoryImpl(
      TasksRemoteDataSource(widget.dioClient.dio),
    );
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = _activeTab == 0
          ? await _repository.getTasks(ownerId: widget.user.uid)
          : await _repository.getTasks(volunteerId: widget.user.uid);

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تحميل المهام';
          _loading = false;
        });
      }
    }
  }

  void _onTabChanged(int index) {
    if (_activeTab == index) return;
    setState(() => _activeTab = index);
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Screen Large Title in Unified Teal Brand Color
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'مهامي',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004D40),
            ),
          ),
        ),

        // Segmented Control Tabs Switcher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                // Tab 1: طلباتي المنشورة
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabChanged(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 0
                            ? const Color(0xFF00695C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'طلباتي المنشورة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _activeTab == 0
                              ? Colors.white
                              : const Color(0xFF757575),
                        ),
                      ),
                    ),
                  ),
                ),
                // Tab 2: تطوّعاتي
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabChanged(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 1
                            ? const Color(0xFF00695C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'تطوّعاتي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _activeTab == 1
                              ? Colors.white
                              : const Color(0xFF757575),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Content Area
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchTasks,
            color: const Color(0xFF00695C),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00695C)),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchTasks,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _tasks.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Icon(
                        _activeTab == 0
                            ? Icons.post_add_outlined
                            : Icons.volunteer_activism_outlined,
                        size: 64,
                        color: const Color(0xFFB0BEC5),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _activeTab == 0
                              ? 'لم تقم بنشر أي طلب مساعدة بعد'
                              : 'لم تتطوع في أي مهمة بعد',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return _MyTaskCard(
                        task: task,
                        user: widget.user,
                        onTap: () => widget.onOpenTask(task),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _MyTaskCard extends StatelessWidget {
  final Task task;
  final AppUser user;
  final VoidCallback onTap;

  const _MyTaskCard({
    required this.task,
    required this.user,
    required this.onTap,
  });

  String _getStatusText(String status) {
    switch (status) {
      case 'OPEN':
        return 'بحاجة لمتطوع';
      case 'IN_PROGRESS':
        return 'قيد التنفيذ';
      case 'COMPLETED':
        return 'منتهية';
      case 'CANCELLED':
        return 'ملغاة';
      default:
        return status;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFFE7F4ED);
      case 'IN_PROGRESS':
        return const Color(0xFFFFF8E1);
      case 'COMPLETED':
        return const Color(0xFFF5F5F5);
      case 'CANCELLED':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFF00695C);
      case 'IN_PROGRESS':
        return const Color(0xFFF57F17);
      case 'COMPLETED':
        return const Color(0xFF616161);
      case 'CANCELLED':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF424242);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'توصيل':
        return Icons.local_shipping_outlined;
      case 'نقل أغراض':
        return Icons.inventory_2_outlined;
      case 'دراسة':
        return Icons.school_outlined;
      case 'تسوق':
        return Icons.shopping_bag_outlined;
      case 'صيانة بسيطة':
        return Icons.handyman_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }

  String _resolveOwnerName(Task task, AppUser user) {
    if (task.ownerName != null &&
        task.ownerName!.trim().isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9]{5,30}$').hasMatch(task.ownerName!.trim()) &&
        !task.ownerName!.startsWith('حساب')) {
      return task.ownerName!.trim();
    }

    if (task.ownerId == user.uid) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        return user.displayName!.trim();
      }
      if (user.email != null && user.email!.contains('@')) {
        final prefix = user.email!.split('@').first.trim();
        if (prefix.isNotEmpty) return prefix;
      }
      return 'أنا';
    }

    if (task.ownerId.contains('@')) {
      final namePart = task.ownerId.split('@').first;
      final parts = namePart.split(RegExp(r'[._-]'));
      final formatted = parts
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
      if (formatted.isNotEmpty) return formatted;
    }

    if (task.ownerId.startsWith('demo-')) {
      final sub = task.ownerId.substring(5).replaceAll(RegExp(r'-\d+$'), '');
      final parts = sub.split('-').where((p) => p.isNotEmpty);
      if (parts.isNotEmpty) {
        return parts
            .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
            .join(' ');
      }
    }

    return 'عضو الحي';
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusText(task.status);
    final statusBg = _getStatusBgColor(task.status);
    final statusFg = _getStatusTextColor(task.status);
    final ownerDisplayName = _resolveOwnerName(task, user);
    final initial = ownerDisplayName.isNotEmpty
        ? ownerDisplayName[0].toUpperCase()
        : 'ع';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category tag on right, Status badge on left
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(task.category),
                      size: 16,
                      color: const Color(0xFF00695C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2B2B),
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
              ),
            ],
            const SizedBox(height: 12),

            const Divider(color: Color(0xFFEEEEEE), height: 1),
            const SizedBox(height: 12),

            // Bottom Row: Owner name + initial avatar & relative time
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF00695C),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ownerDisplayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF444444),
                  ),
                ),
                const Spacer(),
                const Text(
                  'منذ قليل',
                  style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
