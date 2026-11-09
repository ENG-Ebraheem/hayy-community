import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ratings_repository.dart';
import '../cubits/rating_cubit.dart';

class RatingScreen extends StatefulWidget {
  final int taskId;
  final String volunteerId;
  final RatingsRepository repository;
  const RatingScreen({super.key, required this.taskId, required this.volunteerId, required this.repository});
  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int score = 5;
  final comment = TextEditingController();
  @override
  void dispose() { comment.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RatingCubit(widget.repository),
      child: Scaffold(
        appBar: AppBar(title: const Text('تقييم المتطوع')),
        body: BlocConsumer<RatingCubit, RatingState>(
          listener: (context, state) {
            if (state is RatingSubmitted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لتقييمك')));
              Navigator.pop(context, true);
            }
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('كيف كانت تجربة المساعدة؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(onPressed: () => setState(() => score = index + 1), icon: Icon(index < score ? Icons.star : Icons.star_border, color: Colors.amber, size: 42)))),
                Center(child: Text('$score من 5')),
                const SizedBox(height: 20),
                TextField(controller: comment, maxLines: 4, decoration: const InputDecoration(labelText: 'تعليق اختياري', alignLabelWithHint: true, border: OutlineInputBorder())),
                if (state is RatingError) Padding(padding: const EdgeInsets.only(top: 12), child: Text(state.message, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: state is RatingLoading ? null : () => context.read<RatingCubit>().submit(taskId: widget.taskId, ratedUserId: widget.volunteerId, score: score, comment: comment.text), icon: state is RatingLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send), label: const Text('إرسال التقييم')),
              ],
            );
          },
        ),
      ),
    );
  }
}
