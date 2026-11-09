<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AcceptVolunteerRequest;
use App\Http\Requests\UpdateTaskStatusRequest;
use App\Http\Requests\VolunteerRequest;
use App\Models\Task;
use App\Models\TaskApplication;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class VolunteerController extends Controller
{
    /**
     * POST /api/v1/tasks/{id}/volunteer
     * Volunteer / Apply for a task.
     */
    public function volunteer(VolunteerRequest $request, int $id): JsonResponse
    {
        $task = Task::find($id);

        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found.',
            ], 404);
        }

        $authUid = $request->attributes->get('firebase_uid');

        // RULE 1: Task owner cannot volunteer for their own task
        if ($task->owner_id === $authUid) {
            return response()->json([
                'success' => false,
                'message' => 'Task owner cannot volunteer for their own task.',
            ], 403);
        }

        // Only OPEN tasks can accept volunteers
        if ($task->status !== 'OPEN') {
            return response()->json([
                'success' => false,
                'message' => 'Volunteering is only allowed for open tasks.',
            ], 422);
        }

        // RULE 2: A volunteer cannot apply for the same task multiple times
        $existing = TaskApplication::where('task_id', $id)
            ->where('volunteer_id', $authUid)
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'You have already volunteered for this task.',
            ], 409);
        }

        $application = TaskApplication::create([
            'task_id' => $id,
            'volunteer_id' => $authUid,
            'volunteer_name' => $request->input('volunteer_name'),
            'status' => 'PENDING',
            'message' => $request->input('message'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Volunteered successfully.',
            'data' => $application,
        ], 201);
    }

    /**
     * POST /api/v1/tasks/{id}/accept-volunteer
     * Task owner accepts a volunteer.
     */
    public function acceptVolunteer(AcceptVolunteerRequest $request, int $id): JsonResponse
    {
        $task = Task::find($id);

        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found.',
            ], 404);
        }

        $authUid = $request->attributes->get('firebase_uid');

        // RULE 3: Only the task owner can accept a volunteer
        if ($task->owner_id !== $authUid) {
            return response()->json([
                'success' => false,
                'message' => 'Only the task owner can accept a volunteer.',
            ], 403);
        }

        if ($task->status !== 'OPEN') {
            return response()->json([
                'success' => false,
                'message' => 'Only open tasks can accept a volunteer.',
            ], 422);
        }

        $volunteerId = $request->input('volunteer_id');

        $application = TaskApplication::where('task_id', $id)
            ->where('volunteer_id', $volunteerId)
            ->first();

        if (!$application) {
            return response()->json([
                'success' => false,
                'message' => 'Volunteer application not found for this task.',
            ], 404);
        }

        if ($application->status !== 'PENDING') {
            return response()->json([
                'success' => false,
                'message' => 'This volunteer application is no longer pending.',
            ], 422);
        }

        // RULE 4: Update task status to IN_PROGRESS, assign volunteer, accept target app, reject others
        DB::transaction(function () use ($task, $application, $volunteerId) {
            $task->update([
                'assigned_volunteer_id' => $volunteerId,
                'status' => 'IN_PROGRESS',
            ]);

            $application->update([
                'status' => 'ACCEPTED',
            ]);

            TaskApplication::where('task_id', $task->id)
                ->where('id', '!=', $application->id)
                ->where('status', 'PENDING')
                ->update(['status' => 'REJECTED']);
        });

        return response()->json([
            'success' => true,
            'message' => 'Volunteer accepted successfully.',
            'data' => $task->fresh(['applications']),
        ], 200);
    }

    /**
     * PATCH /api/v1/tasks/{id}/status
     * Task owner updates task status (COMPLETED or CANCELLED).
     */
    public function updateStatus(UpdateTaskStatusRequest $request, int $id): JsonResponse
    {
        $task = Task::find($id);

        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found.',
            ], 404);
        }

        $authUid = $request->attributes->get('firebase_uid');

        // RULE 5: Only the task owner can update task status
        if ($task->owner_id !== $authUid) {
            return response()->json([
                'success' => false,
                'message' => 'Only the task owner can update task status.',
            ], 403);
        }

        $newStatus = $request->input('status');

        if (in_array($task->status, ['COMPLETED', 'CANCELLED'])) {
            return response()->json([
                'success' => false,
                'message' => 'Task status cannot be modified after completion or cancellation.',
            ], 422);
        }

        if ($newStatus === 'COMPLETED' && $task->status !== 'IN_PROGRESS') {
            return response()->json([
                'success' => false,
                'message' => 'Only an in-progress task can be completed.',
            ], 422);
        }

        $task->update(['status' => $newStatus]);

        return response()->json([
            'success' => true,
            'message' => "Task status updated to {$newStatus}.",
            'data' => $task,
        ], 200);
    }
}
