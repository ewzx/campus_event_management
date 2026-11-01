import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/event.dart';

class CreateEventPage extends StatefulWidget {
  final Event? eventToEdit; // null = creating, not null = editing

  const CreateEventPage({super.key, this.eventToEdit});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _capacityController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  bool _registrationOpen = true;
  bool _showDateTimeError = false;

  @override
  void initState() {
    super.initState();
    final e = widget.eventToEdit;
    if (e != null) {
      _titleController.text = e.title;
      _descriptionController.text = e.description;
      _venueController.text = e.venue;
      _capacityController.text = e.capacity.toString();
      _date = e.dateTime;
      _time = TimeOfDay.fromDateTime(e.dateTime);
      _registrationOpen = e.registrationOpen;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _submit() {
    final formValid = _formKey.currentState!.validate();
    final dateTimeChosen = _date != null && _time != null;

    setState(() => _showDateTimeError = !dateTimeChosen);

    if (!formValid || !dateTimeChosen) return;

    final dateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    final old = widget.eventToEdit;

    final event = Event(
      // Keep the old values when editing. Firebase will make real IDs later.
      eventId: old?.eventId ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      venue: _venueController.text.trim(),
      dateTime: dateTime,
      imageUrl: old?.imageUrl ?? '',
      capacity: int.parse(_capacityController.text.trim()),
      registeredCount: old?.registeredCount ?? 0,
      registrationOpen: _registrationOpen,
      // placeholder id change after firebase
      organizerId: old?.organizerId ?? 'organizer_1',
      staffIds: old?.staffIds ?? [],
    );

    Navigator.pop(context, event);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventToEdit == null ? 'Create Event' : 'Edit Event',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster placeholder. Real upload will use image_picker
                  // and Firebase Storage, and save the URL in imageUrl.
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 8),
                        const Text('Event poster (upload coming soon)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a description'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _venueController,
                    decoration: const InputDecoration(
                      labelText: 'Venue',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a venue'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _date == null ? 'Pick date' : formatDate(_date!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _time == null
                                ? 'Pick time'
                                : _time!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showDateTimeError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        'Please choose both a date and a time',
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Capacity (number of seats)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final number = int.tryParse((value ?? '').trim());
                      if (number == null || number <= 0) {
                        return 'Enter a whole number greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Registration open'),
                    subtitle: const Text(
                      'Participants can register while this is on',
                    ),
                    value: _registrationOpen,
                    onChanged: (value) =>
                        setState(() => _registrationOpen = value),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(widget.eventToEdit == null ? 'Create Event' : 'Save Changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}