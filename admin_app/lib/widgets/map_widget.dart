import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final List<LatLng> driverLocations;

  const MapWidget({super.key, this.driverLocations = const []});

  @override
  Widget build(BuildContext context) {
    // Default to Karachi coordinates
    final karachiCenter = LatLng(24.8607, 67.0011);

    // Sample driver locations if none provided
    final locations = driverLocations.isEmpty
        ? [
            LatLng(24.8610, 67.0015),
            LatLng(24.8600, 67.0005),
            LatLng(24.8615, 67.0020),
            LatLng(24.8595, 67.0000),
            LatLng(24.8620, 67.0010),
          ]
        : driverLocations;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    center: karachiCenter,
                    zoom: 13.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.musafirah.admin',
                    ),
                    MarkerLayer(
                      markers: locations.map((location) {
                        return Marker(
                          point: location,
                          width: 30,
                          height: 30,
                          builder: (context) => const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF1744),
                            size: 30,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Drivers in Karachi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${locations.length} drivers currently online',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
