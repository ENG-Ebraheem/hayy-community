import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/ratings_repository.dart';
sealed class RatingState {}
class RatingInitial extends RatingState {}
class RatingLoading extends RatingState {}
class RatingSubmitted extends RatingState { final Rating rating; RatingSubmitted(this.rating); }
class RatingSummaryLoaded extends RatingState { final RatingSummary summary; RatingSummaryLoaded(this.summary); }
class RatingError extends RatingState { final String message; RatingError(this.message); }
class RatingCubit extends Cubit<RatingState> { final RatingsRepository repo; RatingCubit(this.repo):super(RatingInitial()); Future<void> submit({required int taskId,required String ratedUserId,required int score,String? comment}) async {emit(RatingLoading());try{emit(RatingSubmitted(await repo.submit(taskId:taskId,ratedUserId:ratedUserId,score:score,comment:comment)));}catch(e){final f=e is Failure?e:mapDioFailure(e);emit(RatingError(f.message));}} Future<void> loadSummary(String uid) async {emit(RatingLoading());try{emit(RatingSummaryLoaded(await repo.getForUser(uid)));}catch(e){final f=e is Failure?e:mapDioFailure(e);emit(RatingError(f.message));}} }
