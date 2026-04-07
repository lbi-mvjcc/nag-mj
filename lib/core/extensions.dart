import 'package:flutter/material.dart';

extension DateTimeExtensions on DateTime {
	String formatTime(BuildContext context) {
		final hour = this.hour > 12 ? this.hour - 12 : (this.hour == 0 ? 12 : this.hour);
		final period = this.hour < 12 ? 'AM' : 'PM';
		return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
	}

	String formatDate(BuildContext context) {
		const months = [
			'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
			'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
		];
		return '${months[month - 1]} ${day.toString().padLeft(2, '0')}, $year';
	}

	String formatDateTime(BuildContext context) {
		return '${formatDate(context)} ${formatTime(context)}';
	}

	bool isSameDay(DateTime other) {
		return year == other.year && month == other.month && day == other.day;
	}

	DateTime copyWith({
		int? year,
		int? month,
		int? day,
		int? hour,
		int? minute,
		int? second,
		int? millisecond,
		int? microsecond,
	}) {
		return DateTime(
			year ?? this.year,
			month ?? this.month,
			day ?? this.day,
			hour ?? this.hour,
			minute ?? this.minute,
			second ?? this.second,
			millisecond ?? this.millisecond,
			microsecond ?? this.microsecond,
		);
	}
}

extension StringExtensions on String {
	String truncate(int maxLength) {
		if (length <= maxLength) return this;
		return '${substring(0, maxLength)}...';
	}
}
