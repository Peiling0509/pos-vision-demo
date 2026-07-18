<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

use Symfony\Component\HttpFoundation\StreamedResponse;

class ChatController extends Controller
{
    // Python AI Server API URL
    private $chatAPI = 'http://host.docker.internal:8000/api/chat';

    public function askAssistant(Request $request)
    {
        $request->validate([
            'question'   => 'required|string',
            'session_id' => 'nullable|string',
            'image'      => 'nullable|image|mimes:jpeg,png,jpg|max:5120', // max 5MB
        ]);

        try {
            // 2. initialize the HTTP client with a timeout of 30 seconds
            $http = Http::timeout(30);

            // 3. if an image is provided, attach it to the request
            if ($request->hasFile('image')) {
                // if has image，attach as multipart/form-data
                $file = $request->file('image');
                $http = $http->attach(
                    'image', 
                    file_get_contents($file->getRealPath()), 
                    $file->getClientOriginalName()
                );
            } else {
                // if no image, force using form format (application/x-www-form-urlencoded), prevent Laravel from sending JSON by default
                $http = $http->asForm();
            }

            // 4. send data to the Python microservice
            $response = $http->post($this->chatAPI, [
                'question'   => $request->question,
                // if the frontend doesn't provide a session_id, give a default one to prevent errors
                'session_id' => $request->session_id ?? 'laravel_fallback_session' 
            ]);

            // 5. process the Python microservice's response
            if ($response->successful()) {
                return response()->json([
                    'status' => 'success',
                    'answer' => $response->json('answer'),
                    'steps'  => $response->json('steps') // keep the step-by-step reasoning for debugging or logging purposes
                ]);
            }
            
            Log::error('Python AI Error: ' . $response->body());
            
            return response()->json([
                'status'  => 'error',
                'message' => 'AI Engine returned an error'
            ], 502);

        } catch (\Exception $e) {
            Log::error('Laravel Chat API Exception: ' . $e->getMessage());
            return response()->json([
                'status'  => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function askAssistantStream(Request $request)
    {
        $request->validate([
            'question'   => 'required|string',
            'session_id' => 'nullable|string',
            'image'      => 'nullable|image|mimes:jpeg,png,jpg|max:5120',
        ]);

        return new StreamedResponse(function () use ($request) {
            // close any existing output buffers to prevent buffering issues
            while (ob_get_level() > 0) {
                ob_end_clean();
            }

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $this->chatAPI . '/stream');
            curl_setopt($ch, CURLOPT_POST, true);

            $postData = [
                'question' => $request->question,
                'session_id' => $request->session_id ?? 'laravel_fallback_session'
            ];

            if ($request->hasFile('image')) {
                $file = $request->file('image');
                $postData['image'] = new \CURLFile(
                    $file->getRealPath(), 
                    $file->getMimeType(), 
                    $file->getClientOriginalName()
                );
            }

            curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, false);

            // prevent cURL from buffering the output, so we can stream it directly to the client
            curl_setopt($ch, CURLOPT_WRITEFUNCTION, function($curl, $data) {
                echo $data;
                flush();
                return strlen($data);
            });
            curl_exec($ch);

            if(curl_errno($ch)){
                Log::error('cURL Stream Error: ' . curl_error($ch));
                echo "data: {\"type\": \"error\", \"message\": \"Gateway error\"}\n\n";
                flush();
            }
            curl_close($ch);
            
        }, 200, [
            'Cache-Control'     => 'no-cache',
            'Content-Type'      => 'text/event-stream',
            'X-Accel-Buffering' => 'no',
        ]);
    }
}