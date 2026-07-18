<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\VisionScanController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\InventoryController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::post('/vision-scan/sync', [VisionScanController::class, 'syncData']);

Route::post('/chat', [ChatController::class, 'askAssistant']);
Route::post('/chat/stream', [ChatController::class, 'askAssistantStream']);

Route::post('/inventory/add', [InventoryController::class, 'addStock']);
Route::post('/inventory/check-sku', [InventoryController::class, 'checkSku']);