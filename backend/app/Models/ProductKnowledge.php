<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductKnowledge extends Model
{
    protected $table = 'product_knowledges';

    protected $fillable = [
        'item_code',
        'item_name',
        'knowledge_content',
        'pinecone_vector_id',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

}