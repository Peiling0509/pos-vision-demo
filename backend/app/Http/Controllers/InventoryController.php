<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Product;

class InventoryController extends Controller
{
    public function addStock(Request $request)
    {
        // 1. Validate incoming data:
        // SKU becomes the primary identifier, while item_name and quantity are still required
        $request->validate([
            'sku' => 'required|string|max:255', // Allow empty for pure AI vision inventory input
            'item_name' => 'required|string|max:255',
            'quantity' => 'required|integer|min:1',
        ]);

        $sku = $request->input('sku');
        $itemName = $request->input('item_name');
        $quantity = $request->input('quantity');

        $product = null;

        // 2. Core matching logic:
        // If SKU is provided, always prioritize searching by SKU
        if (!empty($sku)) {
            $product = Product::where('sku', $sku)->first();
        }
        // 3. Fallback matching logic:
        // If SKU is unavailable (e.g., inventory added through pure AI vision),
        // search by product name instead
        else {
            $product = Product::where('name', 'LIKE', $itemName)->first();
        }

        // 4. Update existing inventory or create a new product record
        if ($product) {
            // Scenario A: Existing product, directly increase stock quantity
            $product->stock_quantity += $quantity;
            $product->save();

            return response()->json([
                'status' => 'success',
                'message' => "Successfully added {$quantity} to '{$product->name}' (SKU: {$product->sku}).",
                'data' => $product
            ], 200);

        } else {

            // Scenario B: Product does not exist in database, automatically create a new record
            $product = Product::create([
                'item_code' => $sku ?? 'PRD-' . time(),
                'sku' => $sku,
                'name' => $itemName,
                'stock_quantity' => $quantity,
                'price' => 0.00,
                'category' => 'Uncategorized',
                'is_active' => true,
            ]);

            return response()->json([
                'status' => 'success',
                'message' => "New product registered and added {$quantity} stock.",
                'data' => $product
            ], 201);
        }
    }


    //Dedicated API endpoint for checking SKU after barcode scanning
    public function checkSku(Request $request)
    {
        $request->validate([
            'sku' => 'required|string|max:255',
        ]);

        $product = Product::where('sku', $request->sku)->first();

        if ($product) {

            return response()->json([
                'status' => 'success',
                'exists' => true,
                'data' => $product
            ], 200);

        } else {

            return response()->json([
                'status' => 'success',
                'exists' => false,
                'message' => 'Product not found. Will be created upon adding inventory.'
            ], 200);

        }
    }
}