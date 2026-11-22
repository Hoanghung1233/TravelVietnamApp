import 'package:flutter/material.dart';

import '../widgets/bottom_navbar.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DestinationMapPage extends StatelessWidget {
  const DestinationMapPage({
    super.key,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);
    return Scaffold(
      bottomNavigationBar: const BottomNavbar(),
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: position, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'vn.travelvietnam.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 44,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.https('www.openstreetmap.org', '/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: ListTile(
              title: Text(name),
              subtitle: Text(
                '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
              ),
              trailing: IconButton(
                tooltip: 'Mở Google Maps',
                icon: const Icon(Icons.directions),
                onPressed: () async {
                  final uri = Uri.https('www.google.com', '/maps/dir/', {
                    'api': '1',
                    'destination': '$latitude,$longitude',
                  });
                  if (!await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      ) &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không mở được Google Maps'),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
