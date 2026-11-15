import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StaffCheckInPage extends StatefulWidget {
  final String eventId;
  final bool isScanMode;

  const StaffCheckInPage({
    super.key,
    required this.eventId,
    required this.isScanMode,
  });

  @override
  State<StaffCheckInPage> createState() => _StaffCheckInPageState();
}

class _StaffCheckInPageState extends State<StaffCheckInPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // Core Logic: Process Check-in by ticketId inside the subcollection
  Future<void> _processCheckIn(String scannedValue) async {
    setState(() => _isProcessing = true);
    String message = '';
    Color color = Colors.green;

    try {
      // Query inside the subcollection: events -> [eventId] -> registrations
      final querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId) 
          .collection('registrations')
          .where('ticketId', isEqualTo: scannedValue)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Invalid Ticket: Record not found.';
      }

      final targetDoc = querySnapshot.docs.first;
      final data = targetDoc.data();
      
      // Check status and duplicate
      if (data['checkInStatus'] == true) {
        throw 'Participant is already checked in.';
      }
      if (data['status'] == 'cancelled') {
        throw 'This registration has been cancelled.';
      }

      // Update database
      await targetDoc.reference.update({
        'checkInStatus': true,
        'checkInTime': FieldValue.serverTimestamp(),
      });

      message = 'Check-in successful!';
    } catch (e) {
      message = e.toString().replaceAll('Exception: ', '');
      color = Colors.red;
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isScanMode ? _buildScanUI() : _buildSearchUI();
  }

  // Scanner UI
  Widget _buildScanUI() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (_isProcessing) return;
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              _processCheckIn(barcodes.first.rawValue!);
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  // Search / List UI
  Widget _buildSearchUI() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search by Ticket ID / Participant ID',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Listen to the subcollection
            stream: FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventId) 
                .collection('registrations')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ticketId = (data['ticketId'] ?? '').toString().toLowerCase();
                final participantId = (data['participantId'] ?? '').toString().toLowerCase();
                final docId = doc.id.toLowerCase();

                return ticketId.contains(_searchQuery) || 
                       participantId.contains(_searchQuery) || 
                       docId.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(child: Text('No registration records found.'));
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                  bool isPresent = data['checkInStatus'] == true;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPresent ? Colors.green : Colors.grey,
                        child: Icon(isPresent ? Icons.check : Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        data['ticketId'] ?? 'No Ticket ID',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('P-ID: ${data['participantId'] ?? "Unknown"} | ${isPresent ? "Checked-in" : "Not Checked-in"}'),
                      trailing: isPresent
                          ? null
                          : ElevatedButton(
                              onPressed: () => _processCheckIn(data['ticketId'] ?? filteredDocs[index].id),
                              child: const Text('Manual Check-in'),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}