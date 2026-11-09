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
        Schema::create('task_applications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained('tasks')->onDelete('cascade');
            $table->string('volunteer_id', 128)->index();
            $table->enum('status', ['PENDING', 'ACCEPTED', 'REJECTED'])->default('PENDING')->index();
            $table->text('message')->nullable();
            $table->timestamps();

            $table->unique(['task_id', 'volunteer_id'], 'unique_task_volunteer');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('task_applications');
    }
};
