import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/announcement.dart';
import '../../../models/event.dart';

class AnnouncementsPage extends StatefulWidget {
  final Event event;

  const AnnouncementsPage({super.key, required this.event});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  // Temporary list for all events while the app is running.
  // Firebase will replace this later.
  static final List<Announcement> _allAnnouncements = [];

  final _messageController = TextEditingController();

  // only announcements from this event.
  List<Announcement> get _eventAnnouncements {
    return _allAnnouncements
        .where((a) => a.eventId == widget.event.eventId)
        .toList();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a message first')),
      );
      return;
    }

    setState(() {
      _allAnnouncements.insert(
        0,
        Announcement(
          announcementId: 'local_${DateTime.now().millisecondsSinceEpoch}',
          eventId: widget.event.eventId,
          createdBy: widget.event.organizerId,
          message: text,
          createdAt: DateTime.now(),
        ),
      );
      _messageController.clear();
    });
  }

  void _delete(Announcement announcement) {
    setState(() => _allAnnouncements.remove(announcement));
  }

  @override
  Widget build(BuildContext context) {
    final announcements = _eventAnnouncements;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Write an update for participants',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _send,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Send announcement'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sent announcements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (announcements.isEmpty)
                  const Text('No announcements yet.'),
                for (final a in announcements)
                  Card(
                    child: ListTile(
                      title: Text(a.message),
                      subtitle: Text(
                        '${formatDate(a.createdAt)}, ${formatTime(a.createdAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(a),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}