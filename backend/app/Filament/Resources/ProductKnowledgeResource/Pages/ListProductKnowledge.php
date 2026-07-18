<?php

namespace App\Filament\Resources\ProductKnowledgeResource\Pages;

use App\Filament\Resources\ProductKnowledgeResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListProductKnowledge extends ListRecords
{
    protected static string $resource = ProductKnowledgeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
