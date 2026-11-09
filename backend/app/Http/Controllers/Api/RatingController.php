<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\SubmitRatingRequest;
use App\Models\Rating;
use App\Models\Task;
use Illuminate\Http\JsonResponse;

class RatingController extends Controller
{
    /**
     * POST /api/v1/ratings
     * Submit a rating for a completed task volunteer.
     */
    public function store(SubmitRatingRequest $request): JsonResponse
    {
        $taskId = $request->input('task_id');
        $ratedUserId = $request->input('rated_user_id');
        $score = $request->input('score');
        $comment = $request->input('comment');

        $task = Task::find($taskId);

        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found.',
            ], 404);
        }

        $authUid = $request->attributes->get('firebase_uid');

        // RULE 7: Only the task owner can rate the volunteer
        if ($task->owner_id !== $authUid) {
            return response()->json([
                'success' => false,
                'message' => 'Only the task owner can rate the volunteer.',
            ], 403);
        }

        // RULE 6: Rating can only be submitted for a COMPLETED task
        if ($task->status !== 'COMPLETED') {
            return response()->json([
                'success' => false,
                'message' => 'Ratings can only be submitted for completed tasks.',
            ], 422);
        }

        // Rated user must be the assigned volunteer
        if ($task->assigned_volunteer_id !== $ratedUserId) {
            return response()->json([
                'success' => false,
                'message' => 'The rated user must be the assigned volunteer for this task.',
            ], 422);
        }

        // RULE 8: Task cannot be rated multiple times by the owner
        $existing = Rating::where('task_id', $taskId)
            ->where('rater_id', $authUid)
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'This task has already been rated.',
            ], 409);
        }

        $rating = Rating::create([
            'task_id' => $taskId,
            'rater_id' => $authUid,
            'rated_user_id' => $ratedUserId,
            'score' => $score,
            'comment' => $comment,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Rating submitted successfully.',
            'data' => $rating,
        ], 201);
    }

    /**
     * GET /api/v1/users/{uid}/ratings
     * Get ratings received by a specific user + user cumulative statistics.
     */
    public function userRatings(string $uid): JsonResponse
    {
        $ratings = Rating::where('rated_user_id', $uid)
            ->orderBy('created_at', 'desc')
            ->get();

        $totalRatings = $ratings->count();
        $averageScore = $totalRatings > 0 ? round($ratings->avg('score'), 1) : null;

        $publishedTasksCount = Task::where('owner_id', $uid)->count();
        $helpedTasksCount = Task::where('assigned_volunteer_id', $uid)
            ->where('status', 'COMPLETED')
            ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'ratings' => $ratings,
                'average_score' => $averageScore,
                'total_ratings' => $totalRatings,
                'published_tasks_count' => $publishedTasksCount,
                'helped_tasks_count' => $helpedTasksCount,
            ],
        ], 200);
    }
}
