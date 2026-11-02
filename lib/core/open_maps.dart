import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Opens Google Maps with a search for the given place.
Future<void> openInMaps(BuildContext context, String place) async {
  final url = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}',
  );

  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Maps')),
    );
  }
}