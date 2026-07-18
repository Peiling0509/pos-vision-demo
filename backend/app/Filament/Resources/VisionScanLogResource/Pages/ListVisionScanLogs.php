<?php

namespace App\Filament\Resources\VisionScanLogResource\Pages;

use App\Filament\Resources\VisionScanLogResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListVisionScanLogs extends ListRecords
{
    protected static string $resource = VisionScanLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
