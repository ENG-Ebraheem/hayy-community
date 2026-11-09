import '../../../../core/errors/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/ratings_repository.dart';
import '../datasources/ratings_remote_data_source.dart';
class RatingsRepositoryImpl implements RatingsRepository { final RatingsRemoteDataSource remote; RatingsRepositoryImpl(this.remote); @override Future<Rating> submit({required int taskId,required String ratedUserId,required int score,String? comment}) async {try{return await remote.submit(taskId:taskId,ratedUserId:ratedUserId,score:score,comment:comment);}catch(e){throw mapDioFailure(e);}} @override Future<RatingSummary> getForUser(String uid) async {try{return await remote.getForUser(uid);}catch(e){throw mapDioFailure(e);}} }
