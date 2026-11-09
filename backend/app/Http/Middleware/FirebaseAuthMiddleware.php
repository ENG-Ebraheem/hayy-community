<?php

namespace App\Http\Middleware;

use Closure;
use Exception;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

class FirebaseAuthMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $authHeader = $request->header('Authorization');

        if (!$authHeader || !str_starts_with($authHeader, 'Bearer ')) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated. Authorization Bearer token is missing.',
            ], 401);
        }

        $idToken = trim(substr($authHeader, 7));

        if (empty($idToken)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated. Authorization token cannot be empty.',
            ], 401);
        }

        // Isolated test authentication driver for automated test suites
        if ($this->shouldUseTestDriver($idToken)) {
            $uid = $this->extractTestUid($idToken);
            if ($uid) {
                $request->attributes->set('firebase_uid', $uid);
                return $next($request);
            }
        }

        // Cryptographic Firebase JWT Token Verification
        try {
            $projectId = config('services.firebase.project_id') ?? env('FIREBASE_PROJECT_ID');
            $decoded = $this->verifyFirebaseIdToken($idToken, $projectId);

            if (!$decoded || empty($decoded->sub)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated. Invalid Firebase user identity claim.',
                ], 401);
            }

            $request->attributes->set('firebase_uid', $decoded->sub);
            return $next($request);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated. Invalid or expired Firebase ID token.',
            ], 401);
        }
    }

    /**
     * Cryptographically verify the Firebase ID Token using Google Public Certificates.
     */
    protected function verifyFirebaseIdToken(string $token, ?string $projectId)
    {
        $publicKeys = $this->getGooglePublicCertificates();

        $keys = [];
        foreach ($publicKeys as $keyId => $cert) {
            $keys[$keyId] = new Key($cert, 'RS256');
        }

        // Decode JWT using Google public keys
        $decoded = JWT::decode($token, $keys);

        // Verify Claims
        if ($projectId) {
            $expectedIssuer = "https://securetoken.google.com/{$projectId}";
            if (($decoded->iss ?? null) !== $expectedIssuer) {
                throw new Exception("Invalid token issuer.");
            }
            if (($decoded->aud ?? null) !== $projectId) {
                throw new Exception("Invalid token audience.");
            }
        }

        return $decoded;
    }

    /**
     * Cache and fetch Google Public Certificates for Firebase ID Tokens.
     */
    protected function getGooglePublicCertificates(): array
    {
        return Cache::remember('google_firebase_public_certs', 3600, function () {
            $response = Http::get('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');
            if ($response->successful()) {
                return $response->json();
            }
            return [];
        });
    }

    /**
     * Check if test token driver applies.
     */
    protected function shouldUseTestDriver(string $token): bool
    {
        if (str_starts_with($token, 'test-token-')) {
            return app()->environment('testing');
        }

        if (str_starts_with($token, 'dev-token-')) {
            return app()->environment(['local', 'testing']);
        }

        return false;
    }

    /**
     * Extract test UID from test token.
     */
    protected function extractTestUid(string $token): ?string
    {
        if (str_starts_with($token, 'test-token-')) {
            return substr($token, 11);
        }
        if (str_starts_with($token, 'dev-token-')) {
            return substr($token, 10);
        }
        return null;
    }
}
