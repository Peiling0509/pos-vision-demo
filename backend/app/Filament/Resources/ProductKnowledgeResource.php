<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductKnowledgeResource\Pages;
use App\Models\ProductKnowledge;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ProductKnowledgeResource extends Resource
{
    protected static ?string $model = ProductKnowledge::class;

    protected static ?string $navigationIcon = 'heroicon-o-book-open';

    protected static ?string $navigationLabel = 'Product Knowledge';

    protected static ?string $modelLabel = 'Product Knowledge';


    /*
    |--------------------------------------------------------------------------
    | CREATE / UPDATE FORM
    |--------------------------------------------------------------------------
    */

    public static function form(Form $form): Form
    {
        return $form
            ->schema([

                Forms\Components\TextInput::make('item_code')
                    ->label('YOLO Item Code')
                    ->placeholder('e.g. dutch_lady_low_fat')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),


                Forms\Components\TextInput::make('item_name')
                    ->label('Product Name')
                    ->required()
                    ->maxLength(255),


                Forms\Components\Textarea::make('knowledge_content')
                    ->label('AI Knowledge Content')
                    ->placeholder(
                        'Product information, ingredients, usage, storage, return policy...'
                    )
                    ->required()
                    ->rows(10)
                    ->columnSpanFull(),


                Forms\Components\TextInput::make('pinecone_vector_id')
                    ->label('Pinecone Vector ID')
                    ->disabled()
                    ->placeholder('Generated after vector embedding'),


                Forms\Components\Toggle::make('is_active')
                    ->label('Active')
                    ->default(true),

            ])
            ->columns(2);
    }



    /*
    |--------------------------------------------------------------------------
    | TABLE LIST
    |--------------------------------------------------------------------------
    */

    public static function table(Table $table): Table
    {
        return $table
            ->columns([


                Tables\Columns\TextColumn::make('id')
                    ->sortable(),


                Tables\Columns\TextColumn::make('item_code')
                    ->label('YOLO Label')
                    ->searchable()
                    ->sortable()
                    ->copyable(),


                Tables\Columns\TextColumn::make('item_name')
                    ->label('Product')
                    ->searchable()
                    ->sortable(),


                Tables\Columns\TextColumn::make('knowledge_content')
                    ->label('AI Knowledge')
                    ->limit(50)
                    ->wrap(),


                Tables\Columns\TextColumn::make('pinecone_vector_id')
                    ->label('Vector ID')
                    ->placeholder('Not generated'),


                Tables\Columns\IconColumn::make('is_active')
                    ->label('Status')
                    ->boolean(),


                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),

            ])

            ->filters([


                Tables\Filters\TernaryFilter::make('is_active')
                    ->label('Active Status'),


            ])

            ->actions([


                Tables\Actions\EditAction::make(),


                Tables\Actions\DeleteAction::make(),


            ])


            ->bulkActions([

                Tables\Actions\BulkActionGroup::make([

                    Tables\Actions\DeleteBulkAction::make(),

                ]),

            ]);
    }



    /*
    |--------------------------------------------------------------------------
    | RELATIONS
    |--------------------------------------------------------------------------
    */

    public static function getRelations(): array
    {
        return [];
    }



    /*
    |--------------------------------------------------------------------------
    | PAGES
    |--------------------------------------------------------------------------
    */

    public static function getPages(): array
    {
        return [

            'index' => Pages\ListProductKnowledge::route('/'),

            'create' => Pages\CreateProductKnowledge::route('/create'),

            'edit' => Pages\EditProductKnowledge::route('/{record}/edit'),

        ];
    }
}