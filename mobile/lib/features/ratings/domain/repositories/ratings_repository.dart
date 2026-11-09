import '../entities/rating.dart';
abstract class RatingsRepository { Future<Rating> submit({required int taskId,required String ratedUserId,required int score,String? comment}); Future<RatingSummary> getForUser(String uid); }
