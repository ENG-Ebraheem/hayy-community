<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained('tasks')->onDelete('cascade');
            $table->string('rater_id', 128)->index();
            $table->string('rated_user_id', 128)->index();
            $table->tinyInteger('score')->unsigned();
            $table->text('comment')->nullable();
            $table->timestamps();

            $table->unique(['task_id', 'rater_id'], 'unique_task_rater');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ratings');
    }
};
