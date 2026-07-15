<?php

namespace App\Filament\Resources;

use App\Filament\Resources\VisionScanLogResource\Pages;
use App\Filament\Resources\VisionScanLogResource\RelationManagers;
use App\Models\VisionScanLog;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class VisionScanLogResource extends Resource
{
    protected static ?string $model = VisionScanLog::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                // Left Column: Visual Evidence & AI Raw Data (Takes up 2/3 of the screen)
                Forms\Components\Group::make()->schema([

                    Forms\Components\Section::make('Scan Evidence')
                        ->description('The original image captured by the field operator.')
                        ->icon('heroicon-o-camera')
                        ->schema([
                            Forms\Components\FileUpload::make('image_path')
                                ->label('Captured Image')
                                ->image()
                                ->imageEditor() // Allows basic zooming/cropping in the backend
                                ->columnSpanFull()
                                // Usually, we don't want admins altering the original evidence
                                ->disabled(),
                        ]),

                    Forms\Components\Section::make('AI Detection Engine Data')
                        ->description('Detailed breakdown of objects identified by the YOLO model.')
                        ->icon('heroicon-o-cpu-chip')
                        ->schema([
                            // Use a Repeater to beautifully render the JSON array
                            Forms\Components\Repeater::make('ai_raw_data')
                                ->label('')
                                ->schema([
                                    Forms\Components\TextInput::make('item_name')
                                        ->label('Detected Object')
                                        ->required(),
                                        
                                    // Use the exact key from your Python code
                                    Forms\Components\TextInput::make('confidence') 
                                        ->label('AI Confidence Score')
                                        ->numeric()
                                        // Safely multiply by 100 to convert 0.85 to 85
                                        ->formatStateUsing(fn ($state) => is_numeric($state) ? ($state * 100) : $state)
                                        ->suffix('%'), // Add the % symbol neatly at the end of the input box
                                ])
                                ->columns(2)
                                ->columnSpanFull()
                                ->addable(false)
                                ->deletable(false)
                                ->reorderable(false)
                                ->disabled(),
                        ]),
                ])->columnSpan(['lg' => 2]),

                // Right Column: Meta Information & Auditing (Takes up 1/3 of the screen)
                Forms\Components\Group::make()->schema([

                    Forms\Components\Section::make('Audit Metrics')
                        ->schema([
                            // Admins can manually correct this number if the AI missed an item
                            Forms\Components\TextInput::make('total_items')
                                ->label('Total Items Detected')
                                ->numeric()
                                ->required()
                                ->hint('Can be manually adjusted if AI undercounted.'),

                            Forms\Components\TextInput::make('device_id')
                                ->label('Operation Device')
                                ->disabled(),

                            // A beautiful placeholder to show exactly when this happened
                            Forms\Components\Placeholder::make('created_at')
                                ->label('Scanned At')
                                ->content(fn($record) => $record?->created_at ? $record->created_at->diffForHumans() : '-'),
                        ]),
                ])->columnSpan(['lg' => 1]),
            ])
            ->columns(3); // Divide the screen into 3 grid columns
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                // 1. Display the captured image as a square thumbnail
                //    for a cleaner and more modern appearance.
                Tables\Columns\ImageColumn::make('image_path')
                    ->label('Captured Image')
                    ->square(),

                // 2. Display the total number of detected items
                //    with a color-coded badge.
                Tables\Columns\TextColumn::make('total_items')
                    ->label('Total Items')
                    ->sortable()
                    ->badge()
                    ->color(fn(string $state): string => match (true) {
                        $state == 0 => 'danger',
                        $state > 10 => 'success',
                        default => 'warning',
                    }),

                // 3. Display the device ID that performed the detection.
                Tables\Columns\TextColumn::make('device_id')
                    ->label('Device ID')
                    ->searchable(),

                // 4. Display the inventory scan timestamp.
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Scan Time')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])

            // Sort records by the latest scan time in descending order
            // so that the newest records appear first.
            ->defaultSort('created_at', 'desc')

            ->filters([
                //
            ])

            ->actions([
                Tables\Actions\EditAction::make(),
            ])

            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }
    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListVisionScanLogs::route('/'),
            'create' => Pages\CreateVisionScanLog::route('/create'),
            'edit' => Pages\EditVisionScanLog::route('/{record}/edit'),
        ];
    }
}
