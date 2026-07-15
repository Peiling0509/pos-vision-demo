<?php

namespace App\Filament\Resources\ProductKnowledgeResource\Pages;

use App\Filament\Resources\ProductKnowledgeResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditProductKnowledge extends EditRecord
{
    protected static string $resource = ProductKnowledgeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
