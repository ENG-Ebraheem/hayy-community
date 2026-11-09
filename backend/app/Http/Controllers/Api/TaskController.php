<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateTaskRequest;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    /**
     * GET /api/v1/tasks
     * Browse available tasks with optional filters (status, category, search, owner_id, volunteer_id).
     */
    public function index(Request $request): JsonResponse
    {
        $query = Task::with(['applications']);

        if ($request->has('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->has('category') && $request->query('category') !== 'الكل') {
            $query->where('category', $request->query('category'));
        }

        if ($request->has('owner_id')) {
            $query->where('owner_id', $request->query('owner_id'));
        }

        if ($request->has('volunteer_id')) {
            $volId = $request->query('volunteer_id');
            $query->where(function ($q) use ($volId) {
                $q->where('assigned_volunteer_id', $volId)
                  ->orWhereHas('applications', function ($appQ) use ($volId) {
                      $appQ->where('volunteer_id', $volId);
                  });
            });
        }

        if ($request->has('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('location', 'like', "%{$search}%");
            });
        }

        $tasks = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $tasks,
        ], 200);
    }

    /**
     * POST /api/v1/tasks
     * Create a new task.
     */
    public function store(CreateTaskRequest $request): JsonResponse
    {
        $authUid = $request->attributes->get('firebase_uid');

        $validated = $request->validated();
        $validated['owner_id'] = $authUid;
        if (!empty($validated['owner_name'])) {
            $validated['owner_name'] = trim($validated['owner_name']);
        }
        $validated['status'] = 'OPEN';

        $task = Task::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Task created successfully.',
            'data' => $task,
        ], 201);
    }

    /**
     * GET /api/v1/tasks/{id}
     * Get detailed task information including applications.
     */
    public function show(int $id): JsonResponse
    {
        $task = Task::with('applications')->find($id);

        if (!$task) {
            return response()->json([
                'success' => false,
                'message' => 'Task not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $task,
        ], 200);
    }
}
