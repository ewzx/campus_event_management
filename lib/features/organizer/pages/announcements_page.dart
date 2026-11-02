import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
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

  final _messageController = TextEditingController();
  final AnnouncementService _service = AnnouncementService();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a message first')),
      );
      return;
    }

    await _service.addAnnouncement(
      Announcement(
        announcementId: '',
        eventId: widget.event.eventId,
        createdBy: widget.event.organizerId,
        message: text,
        createdAt: DateTime.now(),
      ),
    );
    _messageController.clear();
  }

  Future<void> _delete(Announcement a) {
    return _service.deleteAnnouncement(a.eventId, a.announcementId);
  }

  @override
  Widget build(BuildContext context) {
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

                StreamBuilder<List<Announcement>>(
                  stream: _service.getAnnouncements(widget.event.eventId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final announcements = snapshot.data!;
                    if (announcements.isEmpty) {
                      return const Text('No announcements yet.');
                    }
                    return Column(
                      children: [
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}