class TaskExport {
	final List<Map<String, dynamic>> tasks;
	final DateTime exportedAt;
	final String version;

	TaskExport({
		required this.tasks,
		DateTime? exportedAt,
		this.version = '1.0.0',
	}) : exportedAt = exportedAt ?? DateTime.now();

	Map<String, dynamic> toJson() {
		return {
			'version': version,
			'exportedAt': exportedAt.toIso8601String(),
			'tasks': tasks,
		};
	}

	factory TaskExport.fromJson(Map<String, dynamic> json) {
		return TaskExport(
			tasks: List<Map<String, dynamic>>.from(json['tasks'] as List),
			exportedAt: DateTime.parse(json['exportedAt'] as String),
			version: json['version'] as String? ?? '1.0.0',
		);
	}
}
