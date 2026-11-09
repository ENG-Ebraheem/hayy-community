<?php

namespace Tests\Feature;

use App\Models\Rating;
use App\Models\Task;
use App\Models\TaskApplication;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HayyApiTest extends TestCase
{
    use RefreshDatabase;

    private string $ownerUid = 'firebase_user_owner_123';
    private string $volunteerUid = 'firebase_user_volunteer_456';
    private string $otherUserUid = 'firebase_user_other_789';

    /** Helper for authenticated Bearer headers */
    private function authHeader(string $uid): array
    {
        return ['Authorization' => "Bearer test-token-{$uid}"];
    }

    /** 1. GET tasks */
    public function test_can_list_tasks(): void
    {
        Task::create([
            'owner_id' => $this->ownerUid,
            'title' => 'Gardening Help',
            'description' => 'Need help planting flowers',
            'category' => 'Home',
            'location' => 'Building 4',
            'status' => 'OPEN',
        ]);

        $response = $this->getJson('/api/v1/tasks');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonCount(1, 'data');
    }

    /** 2. POST task */
    public function test_can_create_task(): void
    {
        $payload = [
            'title' => 'Move furniture',
            'description' => 'Need 2 people to move a desk',
            'category' => 'Moving',
            'location' => 'Block C, Room 202',
        ];

        $response = $this->withHeaders($this->authHeader($this->ownerUid))
            ->postJson('/api/v1/tasks', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Task created successfully.',
                'data' => [
                    'title' => 'Move furniture',
                    'owner_id' => $this->ownerUid,
                    'status' => 'OPEN',
                ],
            ]);

        $this->assertDatabaseHas('tasks', [
            'title' => 'Move furniture',
            'owner_id' => $this->ownerUid,
        ]);
    }

    /** 3. GET task details */
    public function test_can_get_task_details(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'title' => 'Car Clean',
            'description' => 'Washing car exterior',
            'category' => 'Auto',
            'location' => 'Parking lot',
            'status' => 'OPEN',
        ]);

        $response = $this->getJson("/api/v1/tasks/{$task->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $task->id,
                    'title' => 'Car Clean',
                ],
            ]);
    }

    /** 4. POST volunteer */
    public function test_volunteer_can_apply_for_task(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'title' => 'Study partner',
            'description' => 'Math exam prep',
            'category' => 'Education',
            'location' => 'Library',
            'status' => 'OPEN',
        ]);

        $response = $this->withHeaders($this->authHeader($this->volunteerUid))
            ->postJson("/api/v1/tasks/{$task->id}/volunteer", [
                'message' => 'I can help with Math!',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Volunteered successfully.',
            ]);

        $this->assertDatabaseHas('task_applications', [
            'task_id' => $task->id,
            'volunteer_id' => $this->volunteerUid,
            'status' => 'PENDING',
        ]);
    }

    /** 5. Duplicate volunteer attempt */
    public function test_cannot_volunteer_for_same_task_twice(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'title' => 'Study partner',
            'description' => 'Math exam prep',
            'category' => 'Education',
            'location' => 'Library',
            'status' => 'OPEN',
        ]);

        TaskApplication::create([
            'task_id' => $task->id,
            'volunteer_id' => $this->volunteerUid,
            'status' => 'PENDING',
        ]);

        $response = $this->withHeaders($this->authHeader($this->volunteerUid))
            ->postJson("/api/v1/tasks/{$task->id}/volunteer");

        $response->assertStatus(409)
            ->assertJson([
                'success' => false,
                'message' => 'You have already volunteered for this task.',
            ]);
    }

    /** 6. Owner volunteering for own task */
    public function test_owner_cannot_volunteer_for_own_task(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'title' => 'Own Task',
            'description' => 'Self task',
            'category' => 'General',
            'location' => 'Home',
            'status' => 'OPEN',
        ]);

        $response = $this->withHeaders($this->authHeader($this->ownerUid))
            ->postJson("/api/v1/tasks/{$task->id}/volunteer");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Task owner cannot volunteer for their own task.',
            ]);
    }

    /** 7. Accept volunteer */
    public function test_owner_can_accept_volunteer(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'title' => 'Painting Fence',
            'description' => 'Need fence painted',
            'category' => 'Home',
            'location' => 'Garden',
            'status' => 'OPEN',
        ]);

        $app1 = TaskApplication::create([
            'task_id' => $task->id,
            'volunteer_id' => $this->volunteerUid,
            'status' => 'PENDING',
        ]);

        $app2 = TaskApplication::create([
            'task_id' => $task->id,
            'volunteer_id' => $this->otherUserUid,
            'status' => 'PENDING',
        ]);

        $response = $this->withHeaders($this->authHeader($this->ownerUid))
            ->postJson("/api/v1/tasks/{$task->id}/accept-volunteer", [
                'volunteer_id' => $this->volunteerUid,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Volunteer accepted successfully.',
            ]);

        $this->assertDatabaseHas('tasks', [
            'id' => $task->id,
            'assigned_volunteer_id' => $this->volunteerUid,
            'status' => 'IN_PROGRESS',
        ]);

        $this->assertDatabaseHas('task_applications', [
            'id' => $app1->id,
            'status' => 'ACCEPTED',
        ]);

        $this->assertDatabaseHas('task_applications', [
            'id' => $app2->id,
            'status' => 'REJECTED',
        ]);
    }

    /** 8. Complete task */
    public function test_owner_can_complete_task(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'assigned_volunteer_id' => $this->volunteerUid,
            'title' => 'Painting Fence',
            'description' => 'Need fence painted',
            'category' => 'Home',
            'location' => 'Garden',
            'status' => 'IN_PROGRESS',
        ]);

        $response = $this->withHeaders($this->authHeader($this->ownerUid))
            ->patchJson("/api/v1/tasks/{$task->id}/status", [
                'status' => 'COMPLETED',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'status' => 'COMPLETED',
                ],
            ]);
    }

    /** 9. Invalid rating */
    public function test_cannot_submit_invalid_rating(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'assigned_volunteer_id' => $this->volunteerUid,
            'title' => 'Painting Fence',
            'description' => 'Need fence painted',
            'category' => 'Home',
            'location' => 'Garden',
            'status' => 'COMPLETED',
        ]);

        $response = $this->withHeaders($this->authHeader($this->ownerUid))
            ->postJson('/api/v1/ratings', [
                'task_id' => $task->id,
                'rated_user_id' => $this->volunteerUid,
                'score' => 6,
            ]);

        $response->assertStatus(422);
    }

    /** 10. Valid rating */
    public function test_owner_can_submit_valid_rating(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'assigned_volunteer_id' => $this->volunteerUid,
            'title' => 'Painting Fence',
            'description' => 'Need fence painted',
            'category' => 'Home',
            'location' => 'Garden',
            'status' => 'COMPLETED',
        ]);

        $response = $this->withHeaders($this->authHeader($this->ownerUid))
            ->postJson('/api/v1/ratings', [
                'task_id' => $task->id,
                'rated_user_id' => $this->volunteerUid,
                'score' => 5,
                'comment' => 'Great work!',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'score' => 5,
                    'comment' => 'Great work!',
                ],
            ]);

        $this->assertDatabaseHas('ratings', [
            'task_id' => $task->id,
            'rater_id' => $this->ownerUid,
            'rated_user_id' => $this->volunteerUid,
            'score' => 5,
        ]);
    }

    /** 11. Unauthorized owner-only operations */
    public function test_non_owner_cannot_accept_volunteer_or_change_status(): void
    {
        $task = Task::create([
            'owner_id' => $this->ownerUid,
            'title' => 'Painting Fence',
            'description' => 'Need fence painted',
            'category' => 'Home',
            'location' => 'Garden',
            'status' => 'OPEN',
        ]);

        $response1 = $this->withHeaders($this->authHeader($this->otherUserUid))
            ->postJson("/api/v1/tasks/{$task->id}/accept-volunteer", [
                'volunteer_id' => $this->volunteerUid,
            ]);

        $response1->assertStatus(403);

        $response2 = $this->withHeaders($this->authHeader($this->otherUserUid))
            ->patchJson("/api/v1/tasks/{$task->id}/status", [
                'status' => 'COMPLETED',
            ]);

        $response2->assertStatus(403);
    }

    /* =========================================================================
     * TASK 5 AUTHENTICATION TESTS (Missing header, invalid token, verified token)
     * ========================================================================= */

    public function test_protected_endpoint_without_authorization_header_returns_401(): void
    {
        $response = $this->postJson('/api/v1/tasks', [
            'title' => 'Test Task',
            'description' => 'Test Desc',
            'category' => 'Test',
            'location' => 'Test Loc',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthenticated. Authorization Bearer token is missing.',
            ]);
    }

    public function test_protected_endpoint_with_empty_bearer_token_returns_401(): void
    {
        $response = $this->withHeaders(['Authorization' => 'Bearer '])
            ->postJson('/api/v1/tasks', [
                'title' => 'Test Task',
                'description' => 'Test Desc',
                'category' => 'Test',
                'location' => 'Test Loc',
            ]);

        $response->assertStatus(401);
    }

    public function test_protected_endpoint_with_invalid_jwt_returns_401(): void
    {
        // When not in testing driver mode, invalid JWT format throws exception -> 401
        config(['services.firebase.project_id' => 'fake-project']);

        $response = $this->withHeaders(['Authorization' => 'Bearer invalid.jwt.token'])
            ->postJson('/api/v1/tasks', [
                'title' => 'Test Task',
                'description' => 'Test Desc',
                'category' => 'Test',
                'location' => 'Test Loc',
            ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthenticated. Invalid or expired Firebase ID token.',
            ]);
    }

    public function test_protected_endpoint_with_valid_bearer_token_extracts_firebase_uid(): void
    {
        $response = $this->withHeaders($this->authHeader('user_abc_999'))
            ->postJson('/api/v1/tasks', [
                'title' => 'Valid Auth Task',
                'description' => 'Authenticated task',
                'category' => 'General',
                'location' => 'Building 1',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'owner_id' => 'user_abc_999',
                ],
            ]);
    }
}
