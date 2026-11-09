class Rating {
  final int? id;
  final int taskId;
  final String raterId;
  final String ratedUserId;
  final int score;
  final String? comment;
  final String? createdAt;

  const Rating({
    this.id,
    required this.taskId,
    required this.raterId,
    required this.ratedUserId,
    required this.score,
    this.comment,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> j) => Rating(
        id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}'),
        taskId: j['task_id'] is int ? j['task_id'] : int.tryParse('${j['task_id']}') ?? 0,
        raterId: '${j['rater_id'] ?? ''}',
        ratedUserId: '${j['rated_user_id'] ?? ''}',
        score: j['score'] is int ? j['score'] : int.tryParse('${j['score']}') ?? 0,
        comment: j['comment']?.toString(),
        createdAt: j['created_at']?.toString(),
      );
}

class RatingSummary {
  final List<Rating> ratings;
  final double? average;
  final int total;
  final int publishedTasksCount;
  final int helpedTasksCount;

  const RatingSummary({
    required this.ratings,
    this.average,
    required this.total,
    this.publishedTasksCount = 0,
    this.helpedTasksCount = 0,
  });
}
