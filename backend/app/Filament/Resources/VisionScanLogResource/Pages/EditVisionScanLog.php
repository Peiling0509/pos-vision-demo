<?php

namespace App\Filament\Resources\VisionScanLogResource\Pages;

use App\Filament\Resources\VisionScanLogResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditVisionScanLog extends EditRecord
{
    protected static string $resource = VisionScanLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
