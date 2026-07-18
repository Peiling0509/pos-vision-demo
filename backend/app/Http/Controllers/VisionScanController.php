<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\VisionScanLog;
use Illuminate\Support\Facades\Http;

class VisionScanController extends Controller
{
    private $scanAPI = 'http://host.docker.internal:8000/api/scan';

    public function syncData(Request $request)
    {
        // 1. Flutter only needs to upload the image now; it no longer needs to send ai_raw_data by itself
        $request->validate([
            'image'     => 'required|image|max:10240', // Maximum file size limit: 10MB
            'device_id' => 'nullable|string',
        ]);

        // 2. Receive and store the image uploaded from Flutter
        $imagePath = $request->file('image')->store('vision_scans', 'public');
        
        // Get the absolute physical path of the image, preparing it to be sent to Python
        $absoluteImagePath = storage_path('app/public/' . $imagePath);

        // 3. Laravel acts as a gateway, forwarding the image to the internal Python AI service for inference
        try {
            // Use host.docker.internal to solve the Docker-to-host-machine Python connection issue
            $response = Http::timeout(30)
                ->attach(
                    'image',
                    file_get_contents($absoluteImagePath),
                    'upload.jpg'
                )
                ->post($this->scanAPI); 

            // Check whether Python AI server returned an error
            if (!$response->successful()) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'AI Server Error: ' . $response->body()
                ], 502);
            }

            // Parse the JSON data returned from Python
            $aiData = $response->json();
            $aiRawData = $aiData['data'] ?? $aiData; 
            $totalItems = count($aiRawData);

        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Failed to connect to AI server: ' . $e->getMessage()
            ], 500);
        }

        // 4. Store the AI detection results into the database
        // $log = VisionScanLog::create([
        //     'device_id'   => $request->input('device_id', 'Flutter_Client_01'),
        //     'image_path'  => $imagePath,
        //     'total_items' => $totalItems,
        //     'ai_raw_data' => $aiRawData, 
        // ]);

        // 5. Return the complete detection results to Flutter for direct UI rendering
        return response()->json([
            'status'      => 'success',
            'message'     => 'Vision scan processed and synchronized successfully.',
            //'log_id'      => $log->id,
            'total_items' => $totalItems,
            'ai_raw_data' => $aiRawData
        ], 200);
    }
}