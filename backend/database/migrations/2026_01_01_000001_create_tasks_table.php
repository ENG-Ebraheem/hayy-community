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
        Schema::create('tasks', function (Blueprint $table) {
            $table->id();
            $table->string('owner_id', 128)->index();
            $table->string('assigned_volunteer_id', 128)->nullable()->index();
            $table->string('title', 255);
            $table->text('description');
            $table->string('category', 50)->index();
            $table->string('location', 255);
            $table->enum('status', ['OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'])->default('OPEN')->index();
            $table->dateTime('due_date')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
};
