import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../create_task/data/datasources/create_task_remote_data_source.dart';
import '../../../create_task/data/repositories/create_task_repository_impl.dart';
import '../../../create_task/presentation/cubits/create_task_cubit.dart';
import '../../../create_task/presentation/screens/create_task_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../task_details/data/datasources/task_details_remote_data_source.dart';
import '../../../task_details/data/repositories/task_details_repository_impl.dart';
import '../../../task_details/presentation/cubits/task_details_cubit.dart';
import '../../../task_details/presentation/screens/task_details_screen.dart';
import '../../data/datasources/tasks_remote_data_source.dart';
import '../../data/repositories/tasks_repository_impl.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/task.dart';
import '../cubits/tasks_home_cubit.dart';
import 'my_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;
  final DioClient dioClient;
  final AuthCubit authCubit;
  final LocalStorage? localStorage;

  const HomeScreen({
    super.key,
    required this.user,
    required this.dioClient,
    required this.authCubit,
    this.localStorage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0; // 0: الرئيسية, 1: إنشاء مهمة, 2: مهامي, 3: حسابي
  late final TasksHomeCubit _tasksCubit;
  late final ProfileCubit _profileCubit;
  late final ProfileRemoteDataSource _profileRemoteDataSource;

  // Cache for Firestore user profile names mapped by UID
  final Map<String, String> _ownerNamesCache = {};

  final List<String> _categories = [
    'الكل',
    'توصيل',
    'نقل أغراض',
    'دراسة',
    'تسوق',
    'صيانة بسيطة',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _profileRemoteDataSource = ProfileRemoteDataSource();

    _tasksCubit = TasksHomeCubit(
      TasksRepositoryImpl(TasksRemoteDataSource(widget.dioClient.dio)),
      localStorage: widget.localStorage,
    )..load();

    _profileCubit = ProfileCubit(
      ProfileRepositoryImpl(_profileRemoteDataSource),
    )..load(widget.user.uid, email: widget.user.email);
  }

  @override
  void dispose() {
    _tasksCubit.close();
    _profileCubit.close();
    super.dispose();
  }

  void _openCreateTask() {
    final cubit = CreateTaskCubit(
      CreateTaskRepositoryImpl(
        CreateTaskRemoteDataSource(widget.dioClient.dio),
      ),
    );

    String name = '';
    if (_profileCubit.state is ProfileLoaded) {
      name = (_profileCubit.state as ProfileLoaded).profile.name.trim();
    }
    if (name.isEmpty && widget.user.displayName != null) {
      name = widget.user.displayName!.trim();
    }
    if (name.isEmpty &&
        widget.user.email != null &&
        widget.user.email!.contains('@')) {
      name = widget.user.email!.split('@').first.trim();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(cubit: cubit, userDisplayName: name),
      ),
    ).then((created) {
      cubit.close();
      if (created == true && mounted) {
        _tasksCubit.refresh();
      }
    });
  }

  void _openTaskDetails(Task task) {
    final cubit = TaskDetailsCubit(
      TaskDetailsRepositoryImpl(
        TaskDetailsRemoteDataSource(widget.dioClient.dio),
      ),
    )..load(task.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(cubit: cubit, user: widget.user),
      ),
    ).then((_) {
      cubit.close();
      if (mounted) _tasksCubit.refresh();
    });
  }

  void _onNavigationSelected(int index) {
    if (index == 1) {
      _openCreateTask();
      return;
    }
    setState(() => _currentTab = index);
  }

  String _getDynamicUserName() {
    final profileState = _profileCubit.state;
    if (profileState is ProfileLoaded &&
        profileState.profile.name.trim().isNotEmpty) {
      return profileState.profile.name.trim();
    }
    if (widget.user.displayName != null &&
        widget.user.displayName!.trim().isNotEmpty) {
      return widget.user.displayName!.trim();
    }
    if (widget.user.email != null && widget.user.email!.contains('@')) {
      final namePart = widget.user.email!.split('@').first;
      final parts = namePart.split(RegExp(r'[._-]'));
      return parts
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
    }
    return 'صاحب الحساب';
  }

  // Fetch Firestore profile for task owner if not cached
  void _preloadOwnerProfile(String ownerId) {
    if (ownerId.isEmpty ||
        ownerId == widget.user.uid ||
        _ownerNamesCache.containsKey(ownerId)) {
      return;
    }

    _ownerNamesCache[ownerId] = ''; // Mark in progress
    _profileRemoteDataSource
        .getProfile(uid: ownerId)
        .then((profile) {
          if (profile.name.trim().isNotEmpty && mounted) {
            setState(() {
              _ownerNamesCache[ownerId] = profile.name.trim();
            });
          }
        })
        .catchError((_) {});
  }

  bool _isRawUid(String? name, String ownerId) {
    if (name == null || name.trim().isEmpty) return true;
    final clean = name.trim();
    if (clean == ownerId) return true;
    if (ownerId.length >= 6 && clean == ownerId.substring(0, 6)) return true;
    if (RegExp(r'^[a-zA-Z0-9]{5,30}$').hasMatch(clean)) return true;
    return false;
  }

  String _resolveTaskOwnerName(Task task, String currentUserName) {
    // 1. If this task belongs to the currently logged-in user
    if (task.ownerId == widget.user.uid) {
      final name = currentUserName.trim();
      return name.isNotEmpty ? name : 'أنا';
    }

    // Preload Firestore name asynchronously
    _preloadOwnerProfile(task.ownerId);

    // 2. Check if cached from Firestore
    if (_ownerNamesCache.containsKey(task.ownerId) &&
        _ownerNamesCache[task.ownerId]!.isNotEmpty) {
      return _ownerNamesCache[task.ownerId]!;
    }

    // 3. If ownerName parsed from backend API is valid AND not a raw UID hash
    if (task.ownerName != null &&
        task.ownerName!.trim().isNotEmpty &&
        !task.ownerName!.startsWith('حساب') &&
        !_isRawUid(task.ownerName, task.ownerId)) {
      return task.ownerName!.trim();
    }

    // 4. Fallback if ownerId is an email address
    if (task.ownerId.contains('@')) {
      final namePart = task.ownerId.split('@').first;
      final parts = namePart.split(RegExp(r'[._-]'));
      final formatted = parts
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
      if (formatted.isNotEmpty) return formatted;
    }

    // 5. Fallback if ownerId starts with demo-
    if (task.ownerId.startsWith('demo-')) {
      final parts = task.ownerId.substring(5).split('-');
      final nameParts = parts.where((p) => !RegExp(r'^\d+$').hasMatch(p));
      final formatted = nameParts
          .map(
            (p) => p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : '',
          )
          .join(' ')
          .trim();
      if (formatted.isNotEmpty) return formatted;
    }

    // 6. Friendly member name fallback
    return 'عضو الحي';
  }

  Color _resolveOwnerAvatarColor(String ownerId) {
    if (ownerId == widget.user.uid) {
      return const Color(0xFF00695C); // Teal for current user
    }

    final palette = const [
      Color(0xFF1976D2), // Blue
      Color(0xFF388E3C), // Green
      Color(0xFF7B1FA2), // Purple
      Color(0xFFD32F2F), // Red
      Color(0xFFE65100), // Orange
      Color(0xFF00796B), // Dark Teal
      Color(0xFF512DA8), // Deep Purple
      Color(0xFFC2185B), // Pink
    ];

    final index = ownerId.hashCode.abs() % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      bloc: _profileCubit,
      builder: (context, profileState) {
        final currentUserName = _getDynamicUserName();

        return Scaffold(
          backgroundColor: const Color(0xFFFAF6F0),
          body: SafeArea(
            child: IndexedStack(
              index: _currentTab,
              children: [
                // Tab 0: الرئيسية
                _buildHomeTab(currentUserName),
                // Tab 1: Placeholder for Create Task
                const SizedBox(),
                // Tab 2: مهامي
                MyTasksScreen(
                  user: widget.user,
                  dioClient: widget.dioClient,
                  onOpenTask: _openTaskDetails,
                ),
                // Tab 3: حسابي
                ProfileScreen(
                  user: widget.user,
                  cubit: _profileCubit,
                  dioClient: widget.dioClient,
                  authCubit: widget.authCubit,
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: _onNavigationSelected,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFE0F2F1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Color(0xFF00695C)),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle, color: Color(0xFF00695C)),
                label: 'إنشاء مهمة',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_outlined),
                selectedIcon: Icon(Icons.task, color: Color(0xFF00695C)),
                label: 'مهامي',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: Color(0xFF00695C)),
                label: 'حسابي',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(String currentUserName) {
    return BlocBuilder<TasksHomeCubit, TasksHomeState>(
      bloc: _tasksCubit,
      builder: (context, state) {
        final loaded = state is TasksHomeLoaded ? state : null;
        final selectedCat = loaded?.category ?? 'الكل';
        final items = loaded?.tasks ?? const <Task>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar: Brand Logo & Dynamic Greeting
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: Color(0xFF00695C),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'حيّ',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Dynamic Greeting with Currently Logged-in User Name
                      Text(
                        '👋 أهلاً $currentUserName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search & Sort Row (فهرسة وترتيب المهام)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                      ),
                      child: TextField(
                        onSubmitted: _tasksCubit.setSearch,
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن مهمة...',
                          hintStyle: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF00695C),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () =>
                        _showSortModal(context, loaded?.sortBy ?? 'newest'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00695C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Horizontal Category Chips List
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == selectedCat;
                  final displayLabel = _getCategoryLabel(cat);

                  return GestureDetector(
                    onTap: () => _tasksCubit.setCategory(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00695C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00695C)
                              : const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat != 'الكل') ...[
                            Icon(
                              _getCategoryIcon(cat),
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF00695C),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            displayLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Task Items List Feed
            Expanded(
              child: RefreshIndicator(
                onRefresh: _tasksCubit.refresh,
                color: const Color(0xFF00695C),
                child: state is TasksHomeLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00695C),
                        ),
                      )
                    : state is TasksHomeError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.message),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _tasksCubit.load,
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
                    : items.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final task = items[index];
                          return _buildHomeTaskCard(task, currentUserName);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryLabel(String cat) {
    return cat;
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
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
      case 'أخرى':
        return Icons.grid_view_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism,
              size: 44,
              color: Color(0xFF00695C),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'ما فيه طلبات مساعدة حالياً',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2B2B),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'كن أول من ينشر طلباً في حيك',
            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTaskCard(Task task, String currentUserName) {
    final catLabel = _getCategoryLabel(task.category);

    // Dynamic resolution of task owner name and unique avatar color/initial
    final ownerDisplayName = _resolveTaskOwnerName(task, currentUserName);
    final avatarColor = _resolveOwnerAvatarColor(task.ownerId);

    // Initial character from the clean account name
    final initial = ownerDisplayName.trim().isNotEmpty
        ? ownerDisplayName.trim()[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () => _openTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
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
            // Category Tag & Dynamic Status Badge
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
                      catLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
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
                    color: _getStatusBgColor(task.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(task.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(task.status),
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
            const SizedBox(height: 4),
            Text(
              task.dueDate != null
                  ? 'حتى ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                  : 'اليوم',
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 12),

            const Divider(color: Color(0xFFEEEEEE), height: 1),
            const SizedBox(height: 12),

            // Bottom Row: Dynamic Task Owner Unique Avatar Color & Name
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: avatarColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 11,
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

  void _showSortModal(BuildContext context, String currentSortBy) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, color: Color(0xFF004D40)),
                  const SizedBox(width: 8),
                  const Text(
                    'ترتيب وفهرسة الطلبات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSortOption(
                context,
                title: 'الأحدث أولاً (التاريخ التنازلي)',
                icon: Icons.access_time_rounded,
                value: 'newest',
                currentValue: currentSortBy,
              ),
              _buildSortOption(
                context,
                title: 'الأقدم أولاً (التاريخ التصاعدي)',
                icon: Icons.history_rounded,
                value: 'oldest',
                currentValue: currentSortBy,
              ),
              _buildSortOption(
                context,
                title: 'أقرب موعد إنجاز',
                icon: Icons.event_available_rounded,
                value: 'due_date',
                currentValue: currentSortBy,
              ),
              _buildSortOption(
                context,
                title: 'الطلبات المتاحة أولاً (بحاجة لمتطوع)',
                icon: Icons.check_circle_outline_rounded,
                value: 'open_first',
                currentValue: currentSortBy,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String value,
    required String currentValue,
  }) {
    final isSelected = value == currentValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE0F2F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF00695C) : const Color(0xFF757575),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF00695C)
                : const Color(0xFF333333),
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF00695C))
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          _tasksCubit.setSortBy(value);
          Navigator.pop(context);
        },
      ),
    );
  }
}
