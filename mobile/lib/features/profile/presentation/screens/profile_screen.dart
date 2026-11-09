import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../ratings/data/datasources/ratings_remote_data_source.dart';
import '../../../ratings/domain/entities/rating.dart';
import '../cubits/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;
  final ProfileCubit cubit;
  final DioClient dioClient;
  final AuthCubit authCubit;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.cubit,
    required this.dioClient,
    required this.authCubit,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final RatingsRemoteDataSource _ratingsDataSource;
  RatingSummary? _summary;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _ratingsDataSource = RatingsRemoteDataSource(widget.dioClient.dio);
    widget.cubit.load(widget.user.uid, email: widget.user.email);
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loadingStats = true);
    try {
      final summary = await _ratingsDataSource.getForUser(widget.user.uid);
      if (mounted) {
        setState(() {
          _summary = summary;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  String _getInitial(String name) {
    if (name.trim().isEmpty) return widget.user.email?.substring(0, 1).toUpperCase() ?? 'M';
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final profile = state is ProfileLoaded ? state.profile : null;
          final displayName = (profile != null && profile.name.trim().isNotEmpty)
              ? profile.name
              : (widget.user.displayName ?? 'عضو الحي');
          final email = widget.user.email ?? '';
          final initial = _getInitial(displayName);

          return RefreshIndicator(
            onRefresh: _fetchStats,
            color: const Color(0xFF00695C),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Top Profile Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Teal Circle Avatar matching Auth theme
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFF00695C),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Name
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Rating Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '(${_summary?.total ?? 0} تقييم)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('—', style: TextStyle(color: Color(0xFF757575))),
                          const SizedBox(width: 6),
                          Text(
                            _summary?.average != null
                                ? _summary!.average!.toStringAsFixed(1)
                                : '—',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Color(0xFFF57F17), size: 20),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Statistics Row (Side by Side)
                      Row(
                        children: [
                          // Card 1: طلبات نشرتها
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_summary?.publishedTasksCount ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF004D40),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'طلبات نشرتها',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF004D40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Card 2: مرات ساعدت
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_summary?.helpedTasksCount ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'مرات ساعدت',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Section Title: آخر التقييمات
                const Text(
                  'آخر التقييمات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 16),

                // Ratings List / Empty State
                if (_loadingStats)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Color(0xFF00695C)),
                    ),
                  )
                else if (_summary == null || _summary!.ratings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        'ما وصلتك تقييمات بعد',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  )
                else
                  ..._summary!.ratings.map((r) => _buildRatingCard(r)),

                const SizedBox(height: 32),

                // Logout Action Button
                Center(
                  child: TextButton.icon(
                    onPressed: () => widget.authCubit.logout(),
                    icon: const Icon(Icons.logout, color: Color(0xFF757575)),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating.score ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF57F17),
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              if (rating.createdAt != null)
                Text(
                  rating.createdAt!.length > 10
                      ? rating.createdAt!.substring(0, 10)
                      : rating.createdAt!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ],
        ],
      ),
    );
  }
}
