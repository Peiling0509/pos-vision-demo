<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'sku',
        'item_code',
        'name',
        'category',
        'price',
        'stock_quantity',
        'is_active',
    ];

    // Optional: Cast attributes to specific data types
    protected $casts = [
        'price' => 'decimal:2',
        'is_active' => 'boolean',
    ];
}