<?php
namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ChatController extends Controller
{
    // Python AI Server API URL
    private $chatAPI = 'http://host.docker.internal:8000/api/chat';

    public function askAssistant(Request $request)
    {
        // 1. Make item_code nullable (optional)
        $request->validate([
            'question'  => 'required|string',
            'item_code' => 'nullable|string',
        ]);

        $contextData = "";

        // 2. If the user is asking from the product scanning page,
        // proactively retrieve product information and send it to the AI
        if ($request->filled('item_code')) {
            $product = Product::where('item_code', $request->item_code)
                              ->where('is_active', true)
                              ->first();

            if ($product) {
                $contextData = "Product name: {$product->name}, Price: RM {$product->price}, Stock: {$product->stock_quantity}";
            }
        }

        try {
            // 3. Forward the request to Python AI service
            $response = Http::timeout(20)->post($this->chatAPI, [
                'question'     => $request->question,
                'context_data' => $contextData
            ]);

            if ($response->successful()) {
                return response()->json([
                    'status' => 'success',
                    'answer' => $response->json('answer')
                ]);
            }

            return response()->json([
                'status' => 'error',
                'message' => 'AI Error'
            ], 502);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}