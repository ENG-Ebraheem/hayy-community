<?php

use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\TaskController;
use App\Http\Controllers\Api\VolunteerController;
use App\Http\Middleware\FirebaseAuthMiddleware;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - Hayy Platform v1
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // Public Endpoints
    Route::get('/tasks', [TaskController::class, 'index']);
    Route::get('/tasks/{id}', [TaskController::class, 'show']);
    Route::get('/users/{uid}/ratings', [RatingController::class, 'userRatings']);

    // Protected Endpoints (Requires Verified Firebase Authentication)
    Route::middleware([FirebaseAuthMiddleware::class])->group(function () {
        Route::post('/tasks', [TaskController::class, 'store']);
        Route::post('/tasks/{id}/volunteer', [VolunteerController::class, 'volunteer']);
        Route::post('/tasks/{id}/accept-volunteer', [VolunteerController::class, 'acceptVolunteer']);
        Route::patch('/tasks/{id}/status', [VolunteerController::class, 'updateStatus']);
        Route::post('/ratings', [RatingController::class, 'store']);
    });
});
