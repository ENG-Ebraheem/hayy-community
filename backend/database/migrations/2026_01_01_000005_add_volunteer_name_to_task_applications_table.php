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
        Schema::table('task_applications', function (Blueprint $table) {
            $table->string('volunteer_name', 255)->nullable()->after('volunteer_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('task_applications', function (Blueprint $table) {
            $table->dropColumn('volunteer_name');
        });
    }
};
