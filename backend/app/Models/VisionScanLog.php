<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VisionScanLog extends Model
{
    use HasFactory;

    // 1. Disable mass assignment protection so we can use ::create()
    protected $guarded = [];

    // 2. Tell Laravel to automatically cast the JSON to an array
    protected $casts = [
        'ai_raw_data' => 'array',
    ];
}