class CreateTaskInput {
  final String title, description, category, location;
  final String? ownerName;
  final DateTime? dueDate;

  const CreateTaskInput({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.ownerName,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        if (ownerName != null && ownerName!.trim().isNotEmpty) 'owner_name': ownerName!.trim(),
        if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      };
}
