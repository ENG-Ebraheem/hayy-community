import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../ratings/data/datasources/ratings_remote_data_source.dart';
import '../../../ratings/data/repositories/ratings_repository_impl.dart';
import '../../../ratings/presentation/screens/rating_screen.dart';
import '../../../tasks_home/domain/entities/task.dart';
import '../cubits/task_details_cubit.dart';

class TaskDetailsScreen extends StatelessWidget {
  final TaskDetailsCubit cubit;
  final AppUser user;
  const TaskDetailsScreen({super.key, required this.cubit, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'تفاصيل المهمة',
            style: TextStyle(
              color: Color(0xFF004D40),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2B)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocConsumer<TaskDetailsCubit, TaskDetailsState>(
          listener: (context, state) {
            if (state is TaskDetailsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            } else if (state is TaskDetailsLoaded &&
                state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: const Color(0xFF00695C),
                ),
              );
            }
          },
          builder: (context, state) {
            final task = state.task;
            if (task == null) {
              if (state is TaskDetailsLoading || state is TaskDetailsInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00695C)),
                );
              }
              if (state is TaskDetailsError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox();
            }

            final owner = task.ownerId == user.uid;
            final hasApplied = task.applications.any(
              (app) => app.volunteerId == user.uid,
            );
            final isLoading = state is TaskDetailsLoading;

            return RefreshIndicator(
              onRefresh: () => cubit.load(task.id),
              color: const Color(0xFF00695C),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (isLoading)
                    const LinearProgressIndicator(color: Color(0xFF00695C)),
                  if (isLoading) const SizedBox(height: 10),

                  // Task Details Container Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryIcon(task.category),
                                    size: 16,
                                    color: const Color(0xFF004D40),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    task.category,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF004D40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusBg(task.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(task.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusTextFg(task.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description
                        Text(
                          task.description,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF555555),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 12),

                        // Location & Date Info
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: Color(0xFF888888),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.event_outlined,
                              size: 18,
                              color: Color(0xFF888888),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.dueDate == null
                                  ? 'بدون موعد'
                                  : 'حتى ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions & Applications List
                  if (owner &&
                      task.applications.isNotEmpty &&
                      (task.isOpen || task.isInProgress))
                    _Applications(
                      task: task,
                      cubit: cubit,
                      isLoading: isLoading,
                    ),

                  if (!owner &&
                      task.isOpen &&
                      !hasApplied &&
                      task.assignedVolunteerId == null)
                    _VolunteerButton(
                      cubit: cubit,
                      isLoading: isLoading,
                      user: user,
                    ),

                  if (!owner && task.isOpen && hasApplied)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.access_time, color: Color(0xFFF57F17)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'تم إرسال طلب التطوع - بانتظار موافقة صاحب المهمة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFF57F17),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!owner &&
                      task.isInProgress &&
                      task.assignedVolunteerId == user.uid)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Color(0xFF00695C)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'أنت المتطوع المقبول في هذه المهمة!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF00695C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (owner && (task.isInProgress || task.isOpen))
                    _OwnerActions(
                      task: task,
                      cubit: cubit,
                      isLoading: isLoading,
                    ),

                  // RATING BUTTON WITH LOCK RULE (DISABLED IF ALREADY RATED)
                  if (owner &&
                      task.isCompleted &&
                      task.assignedVolunteerId != null)
                    _RateButton(task: task),

                  if (task.isCancelled)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.cancel_outlined, color: Color(0xFFC62828)),
                          SizedBox(width: 12),
                          Text(
                            'تم إلغاء المهمة',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
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

  Color _getStatusBg(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFFE0F2F1);
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

  Color _getStatusTextFg(String status) {
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
      default:
        return Icons.grid_view_outlined;
    }
  }
}

class _Applications extends StatefulWidget {
  final Task task;
  final TaskDetailsCubit cubit;
  final bool isLoading;

  const _Applications({
    required this.task,
    required this.cubit,
    this.isLoading = false,
  });

  @override
  State<_Applications> createState() => _ApplicationsState();
}

class _ApplicationsState extends State<_Applications> {
  final ProfileRemoteDataSource _profileDS = ProfileRemoteDataSource();
  final Map<String, String> _resolvedNames = {};

  @override
  void initState() {
    super.initState();
    _loadVolunteerNames();
  }

  @override
  void didUpdateWidget(covariant _Applications oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.applications != widget.task.applications) {
      _loadVolunteerNames();
    }
  }

  void _loadVolunteerNames() {
    final pending = widget.task.applications.where(
      (a) => a.status == 'PENDING',
    );
    for (final app in pending) {
      if (app.volunteerName != null &&
          app.volunteerName!.trim().isNotEmpty &&
          !_isRawUid(app.volunteerName!)) {
        if (_resolvedNames[app.volunteerId] != app.volunteerName!.trim()) {
          setState(() {
            _resolvedNames[app.volunteerId] = app.volunteerName!.trim();
          });
        }
      } else {
        _profileDS
            .getProfile(uid: app.volunteerId)
            .then((profile) {
              if (mounted && profile.name.trim().isNotEmpty) {
                setState(() {
                  _resolvedNames[app.volunteerId] = profile.name.trim();
                });
              }
            })
            .catchError((_) {});
      }
    }
  }

  bool _isRawUid(String val) {
    return val.length > 20 && !val.contains(' ');
  }

  String _getDisplayName(TaskApplication app) {
    if (_resolvedNames.containsKey(app.volunteerId)) {
      return _resolvedNames[app.volunteerId]!;
    }
    if (app.volunteerName != null &&
        app.volunteerName!.trim().isNotEmpty &&
        !_isRawUid(app.volunteerName!)) {
      return app.volunteerName!.trim();
    }
    return 'متطوع';
  }

  String _getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'م';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.task.applications
        .where((a) => a.status == 'PENDING')
        .toList();
    if (pending.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'طلبات التطوع المتاحة (${pending.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 12),
        ...pending.map((app) {
          final name = _getDisplayName(app);
          final initial = _getInitial(name);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF00695C),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.message?.isNotEmpty == true
                            ? app.message!
                            : 'أرغب في المساعدة',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.cubit.accept(app.volunteerId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'قبول',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _VolunteerButton extends StatelessWidget {
  final TaskDetailsCubit cubit;
  final bool isLoading;
  final AppUser? user;

  const _VolunteerButton({
    required this.cubit,
    this.isLoading = false,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  final message = await showDialog<String>(
                    context: context,
                    useRootNavigator: true,
                    builder: (dialogContext) => const _VolunteerDialog(),
                  );
                  if (message != null &&
                      message.trim().isNotEmpty &&
                      context.mounted) {
                    String? volunteerName = user?.displayName;
                    if (volunteerName == null || volunteerName.trim().isEmpty) {
                      final authUser = FirebaseAuth.instance.currentUser;
                      volunteerName = authUser?.displayName;
                    }
                    if ((volunteerName == null ||
                            volunteerName.trim().isEmpty) &&
                        user != null) {
                      try {
                        final p = await ProfileRemoteDataSource().getProfile(
                          uid: user!.uid,
                          email: user!.email,
                        );
                        if (p.name.trim().isNotEmpty) {
                          volunteerName = p.name.trim();
                        }
                      } catch (_) {}
                    }
                    cubit.volunteer(
                      message.trim(),
                      volunteerName: volunteerName,
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.volunteer_activism, color: Colors.white),
          label: const Text(
            'التطوع لهذه المهمة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _VolunteerDialog extends StatefulWidget {
  const _VolunteerDialog();

  @override
  State<_VolunteerDialog> createState() => _VolunteerDialogState();
}

class _VolunteerDialogState extends State<_VolunteerDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'رسالة التطوع',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
      ),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'اكتب رسالة بسيطة لصاحب المهمة...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'إلغاء',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('إرسال', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _OwnerActions extends StatelessWidget {
  final Task task;
  final TaskDetailsCubit cubit;
  final bool isLoading;

  const _OwnerActions({
    required this.task,
    required this.cubit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasVolunteer =
        task.assignedVolunteerId != null || task.isInProgress;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        if (!hasVolunteer) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'لا يمكن إتمام المهمة لأنه لم يتطوع لها أي مستخدم إلى الآن',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        } else {
                          cubit.updateStatus('COMPLETED');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasVolunteer
                      ? const Color(0xFF00695C)
                      : const Color(0xFFB0BEC5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'إتمام المهمة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => cubit.updateStatus('CANCELLED'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.close, color: Color(0xFFC62828)),
                label: const Text(
                  'إلغاء المهمة',
                  style: TextStyle(fontSize: 15, color: Color(0xFFC62828)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final Task task;
  const _RateButton({required this.task});

  @override
  Widget build(BuildContext context) {
    // LOCK RULE: If task is already rated, disable tap and display "تم التقييم ⭐"
    if (task.isRated) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00695C)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF00695C)),
              SizedBox(width: 8),
              Text(
                'تم تقييم المتطوع ⭐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            final dio = DioClient();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RatingScreen(
                  taskId: task.id,
                  volunteerId: task.assignedVolunteerId!,
                  repository: RatingsRepositoryImpl(
                    RatingsRemoteDataSource(dio.dio),
                  ),
                ),
              ),
            ).then((_) {
              // Reload task details to update isRated state
              if (context.mounted) {
                context.read<TaskDetailsCubit>().load(task.id);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00695C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.star, color: Colors.white),
          label: const Text(
            'تقييم المتطوع الآن',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
