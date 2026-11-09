<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Task extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id',
        'owner_name',
        'assigned_volunteer_id',
        'title',
        'description',
        'category',
        'location',
        'status',
        'due_date',
    ];

    protected $casts = [
        'due_date' => 'datetime',
    ];

    protected $appends = ['is_rated', 'owner_name'];

    /**
     * Get applications submitted for this task.
     */
    public function applications(): HasMany
    {
        return $this->hasMany(TaskApplication::class, 'task_id');
    }

    /**
     * Get rating submitted for this task.
     */
    public function rating(): HasOne
    {
        return $this->hasOne(Rating::class, 'task_id');
    }

    /**
     * Get ratings associated with this task.
     */
    public function ratings(): HasMany
    {
        return $this->hasMany(Rating::class, 'task_id');
    }

    /**
     * Check if task has already been rated by owner.
     */
    public function getIsRatedAttribute(): bool
    {
        return $this->rating()->exists();
    }

    /**
     * Get dynamic owner display name for this task.
     */
    public function getOwnerNameAttribute(): string
    {
        if (!empty($this->attributes['owner_name'])) {
            return $this->attributes['owner_name'];
        }
        if (str_contains($this->owner_id, '@')) {
            $parts = explode('@', $this->owner_id)[0];
            $words = preg_split('/[._-]/', $parts);
            $capitalized = array_map(function ($w) {
                return $w ? ucfirst($w) : '';
            }, array_filter($words));
            $res = implode(' ', array_filter($capitalized));
            return $res ?: 'عضو الحي';
        }
        if (str_starts_with($this->owner_id, 'demo-')) {
            $sub = substr($this->owner_id, 5);
            $sub = preg_replace('/-\d+$/', '', $sub);
            $parts = explode('-', $sub);
            $capitalized = array_map('ucfirst', array_filter($parts));
            $res = implode(' ', $capitalized);
            return $res ?: 'عضو الحي';
        }
        return 'عضو الحي';
    }
}
