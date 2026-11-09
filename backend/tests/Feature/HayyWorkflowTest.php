<?php

namespace Tests\Feature;

use App\Models\Rating;
use App\Models\Task;
use App\Models\TaskApplication;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HayyWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_complete_owner_and_volunteer_journey(): void
    {
        $owner = 'workflow-owner-001';
        $volunteer = 'workflow-volunteer-002';

        $create = $this->withHeaders($this->auth($owner))->postJson('/api/v1/tasks', [
            'title' => 'إيصال كتاب إلى المكتبة',
            'description' => 'أحتاج مساعدة في إيصال كتاب إلى مكتبة الجامعة.',
            'category' => 'تعليم',
            'location' => 'مبنى العلوم',
            'due_date' => '2026-09-01 15:00:00',
        ]);
        $create->assertCreated()->assertJsonPath('data.status', 'OPEN');
        $taskId = (int) $create->json('data.id');
        $this->assertDatabaseHas('tasks', ['id' => $taskId, 'owner_id' => $owner, 'status' => 'OPEN']);

        $this->getJson('/api/v1/tasks')->assertOk()->assertJsonPath('data.0.id', $taskId);
        $this->getJson("/api/v1/tasks/{$taskId}")->assertOk()->assertJsonPath('data.applications', []);

        $apply = $this->withHeaders($this->auth($volunteer))->postJson("/api/v1/tasks/{$taskId}/volunteer", [
            'message' => 'سأكون في المكتبة بعد المحاضرة ويمكنني إيصال الكتاب.',
        ]);
        $apply->assertCreated()->assertJsonPath('data.status', 'PENDING');
        $this->assertDatabaseHas('task_applications', ['task_id' => $taskId, 'volunteer_id' => $volunteer, 'status' => 'PENDING']);

        $this->withHeaders($this->auth($owner))->getJson("/api/v1/tasks/{$taskId}")
            ->assertOk()->assertJsonPath('data.applications.0.volunteer_id', $volunteer);

        $accept = $this->withHeaders($this->auth($owner))->postJson("/api/v1/tasks/{$taskId}/accept-volunteer", [
            'volunteer_id' => $volunteer,
        ]);
        $accept->assertOk()->assertJsonPath('data.status', 'IN_PROGRESS');
        $this->assertDatabaseHas('tasks', ['id' => $taskId, 'assigned_volunteer_id' => $volunteer, 'status' => 'IN_PROGRESS']);
        $this->assertDatabaseHas('task_applications', ['task_id' => $taskId, 'volunteer_id' => $volunteer, 'status' => 'ACCEPTED']);

        $complete = $this->withHeaders($this->auth($owner))->patchJson("/api/v1/tasks/{$taskId}/status", ['status' => 'COMPLETED']);
        $complete->assertOk()->assertJsonPath('data.status', 'COMPLETED');
        $this->assertDatabaseHas('tasks', ['id' => $taskId, 'status' => 'COMPLETED']);

        $rating = $this->withHeaders($this->auth($owner))->postJson('/api/v1/ratings', [
            'task_id' => $taskId,
            'rated_user_id' => $volunteer,
            'score' => 5,
            'comment' => 'مساعدة ممتازة وفي الموعد.',
        ]);
        $rating->assertCreated()->assertJsonPath('data.score', 5);
        $this->assertDatabaseHas('ratings', ['task_id' => $taskId, 'rater_id' => $owner, 'rated_user_id' => $volunteer, 'score' => 5]);

        $this->getJson("/api/v1/users/{$volunteer}/ratings")
            ->assertOk()->assertJsonPath('data.total_ratings', 1)->assertJsonPath('data.average_score', 5);
        $this->assertSame(1, Rating::where('task_id', $taskId)->count());
        $this->assertSame(1, TaskApplication::where('task_id', $taskId)->where('status', 'ACCEPTED')->count());
        $this->assertSame('COMPLETED', Task::findOrFail($taskId)->status);
    }

    private function auth(string $uid): array
    {
        return ['Authorization' => "Bearer test-token-{$uid}"];
    }
}
