
import 'package:flutter/material.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController =
      TextEditingController();

  // Temporary event data. Firebase will be connected later.
  final List<Map<String, dynamic>> _events = [
    {
      'title': 'AI and Technology Seminar',
      'date': '5 November 2026',
      'location': 'APU Campus, Auditorium',
      'description':
          'Learn about artificial intelligence and the latest technology trends.',
      'capacity': 100,
      'registered': 65,
      'icon': Icons.computer,
    },
    {
      'title': 'Campus Photography Workshop',
      'date': '8 November 2026',
      'location': 'APU Campus, Room 3.1',
      'description':
          'Learn basic photography skills and practise taking creative photos.',
      'capacity': 40,
      'registered': 28,
      'icon': Icons.camera_alt,
    },
    {
      'title': 'University Sports Day',
      'date': '12 November 2026',
      'location': 'APU Sports Ground',
      'description':
          'Join your friends for a fun day of sports and campus activities.',
      'capacity': 150,
      'registered': 90,
      'icon': Icons.sports_basketball,
    },
  ];

  List<Map<String, dynamic>> get _filteredEvents {
    final keyword = _searchController.text.toLowerCase().trim();

    if (keyword.isEmpty) {
      return _events;
    }

    return _events.where((event) {
      return event['title']
          .toString()
          .toLowerCase()
          .contains(keyword);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event['title']),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${event['date']}'),
                const SizedBox(height: 8),
                Text('Location: ${event['location']}'),
                const SizedBox(height: 8),
                Text(
                  'Available places: '
                  '${event['capacity'] - event['registered']}',
                ),
                const SizedBox(height: 16),
                Text(event['description']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search events by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? const Center(
                        child: Text('No events found.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 20,
                        ),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final available =
                              event['capacity'] - event['registered'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _showEventDetails(event),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        event['icon'] as IconData,
                                        size: 42,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text('Date: ${event['date']}'),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Location: ${event['location']}',
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            available > 0
                                                ? '$available places available'
                                                : 'Fully booked',
                                            style: TextStyle(
                                              color: available > 0
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
