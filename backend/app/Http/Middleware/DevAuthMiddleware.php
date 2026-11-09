<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class DevAuthMiddleware
{
    /**
     * Handle an incoming request.
     * Note: This middleware isolates authentication resolution during dev.
     * In production / Phase 3, this will be replaced/extended by Firebase JWT Token verification.
     */
    public function handle(Request $request, Closure $next)
    {
        $uid = $request->header('X-Firebase-UID');

        if (!$uid) {
            $authHeader = $request->header('Authorization');
            if ($authHeader && str_starts_with($authHeader, 'Bearer ')) {
                $token = substr($authHeader, 7);
                // Accepts dev-<uid> tokens for testing before full Firebase SDK verification
                if (str_starts_with($token, 'dev-')) {
                    $uid = substr($token, 4);
                } else {
                    $uid = $token;
                }
            }
        }

        if (!$uid) {
            $uid = $request->input('auth_uid');
        }

        if (!$uid) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated. Firebase UID authentication context is required.',
            ], 401);
        }

        // Attach resolved firebase_uid to request attributes
        $request->attributes->set('firebase_uid', $uid);

        return $next($request);
    }
}
