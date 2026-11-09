import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
sealed class ProfileState {}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState { final Profile profile; ProfileLoaded(this.profile); }
class ProfileError extends ProfileState { final String message; ProfileError(this.message); }
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;
  ProfileCubit(this.repository): super(ProfileInitial());
  Future<void> load(String uid, {String? email}) async { emit(ProfileLoading()); try { emit(ProfileLoaded(await repository.getProfile(uid, email: email))); } catch(e) { final f=e is Failure?e:mapDioFailure(e); emit(ProfileError(f.message)); } }
  Future<void> save(Profile profile) async { emit(ProfileLoading()); try { emit(ProfileLoaded(await repository.saveProfile(profile))); } catch(e) { final f=e is Failure?e:mapDioFailure(e); emit(ProfileError(f.message)); } }
}
