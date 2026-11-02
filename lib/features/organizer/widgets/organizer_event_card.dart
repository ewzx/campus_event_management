import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/formatters.dart';
import '../../../models/event.dart';

class OrganizerEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const OrganizerEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:               ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: event.imageUrl.isEmpty
                      ? Container(
                    width: 72,
                    height: 72,
                    color: scheme.primaryContainer,
                    child: Icon(
                      Icons.event,
                      size: 36,
                      color: scheme.primary,
                    ),
                  )
                      : Image.memory(
                    base64Decode(event.imageUrl),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatDate(event.dateTime)}, '
                          '${formatTime(event.dateTime)}',
                    ),
                    const SizedBox(height: 2),
                    Text(event.venue),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${event.registeredCount} / ${event.capacity} '
                              'registered',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                          label: Text(
                            event.registrationOpen ? 'Open' : 'Closed',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
