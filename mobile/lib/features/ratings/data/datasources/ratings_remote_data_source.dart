import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/rating.dart';

class RatingsRemoteDataSource {
  final Dio dio;
  RatingsRemoteDataSource(this.dio);

  Future<Rating> submit({
    required int taskId,
    required String ratedUserId,
    required int score,
    String? comment,
  }) async {
    final r = await dio.post(
      ApiConstants.ratings,
      data: {
        'task_id': taskId,
        'rated_user_id': ratedUserId,
        'score': score,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
    return Rating.fromJson(Map<String, dynamic>.from(r.data['data'] as Map));
  }

  Future<RatingSummary> getForUser(String uid) async {
    final r = await dio.get(ApiConstants.userRatings(uid));
    final data = Map<String, dynamic>.from(r.data['data'] as Map);
    final raw = data['ratings'];
    return RatingSummary(
      ratings: raw is List
          ? raw.whereType<Map>().map((x) => Rating.fromJson(Map<String, dynamic>.from(x))).toList()
          : const [],
      average: (data['average_score'] as num?)?.toDouble(),
      total: (data['total_ratings'] as num?)?.toInt() ?? 0,
      publishedTasksCount: (data['published_tasks_count'] as num?)?.toInt() ?? 0,
      helpedTasksCount: (data['helped_tasks_count'] as num?)?.toInt() ?? 0,
    );
  }
}
