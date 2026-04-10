import 'package:latlong2/latlong.dart';

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.seats,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.avatarAsset,
    required this.initialEta,
    required this.initialPosition,
    this.currentTrip,
  });

  final String id;
  final String name;
  final String phone;
  final String rating;
  final String seats;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String avatarAsset;
  final String initialEta;
  final LatLng initialPosition;
  final Map<String, dynamic>? currentTrip;

  factory DriverProfile.fromFirestore(Map<String, dynamic> data, String id) {
    final trip = data['currentTrip'] as Map<String, dynamic>?;
    final pos = trip != null 
        ? LatLng(trip['pickupLat'] ?? 0.0, trip['pickupLng'] ?? 0.0)
        : const LatLng(0, 0);

    return DriverProfile(
      id: id,
      name: data['name'] ?? 'Driver',
      phone: data['phone'] ?? '',
      rating: (data['rating'] ?? 0.0).toString(),
      seats: '3/4 seats', // Default for now
      vehicleModel: data['vehicleModel'] ?? 'Toyota',
      vehicleColor: data['vehicleColor'] ?? 'White',
      vehiclePlate: data['vehicleRegistration'] ?? 'ABC-123',
      avatarAsset: data['profileImageUrl'] ?? 'Assets/icons/women1.jpeg',
      initialEta: 'Calculating...', 
      initialPosition: pos,
      currentTrip: trip,
    );
  }
}

final List<DriverProfile> mockDriverProfiles = [
  DriverProfile(
    id: 'driver_sana_ali',
    name: 'Sana Ali',
    phone: '+923001112233',
    rating: '4.9',
    seats: '2/3 seats',
    vehicleModel: 'Toyota Corolla',
    vehicleColor: 'White',
    vehiclePlate: 'LEB-4521',
    avatarAsset: 'Assets/icons/women1.jpeg',
    initialEta: '6 min',
    initialPosition: const LatLng(24.8740, 67.0320),
    currentTrip: null,
  ),
  DriverProfile(
    id: 'driver_hina_khan',
    name: 'Hina Khan',
    phone: '+923008889900',
    rating: '5.0',
    seats: '1/3 seats',
    vehicleModel: 'Honda City',
    vehicleColor: 'Silver',
    vehiclePlate: 'KHI-6234',
    avatarAsset: 'Assets/icons/pakistani.jpg',
    initialEta: '5 min',
    initialPosition: const LatLng(24.8705, 67.0450),
    currentTrip: null,
  ),
  DriverProfile(
    id: 'driver_maira_ahmed',
    name: 'Maira Ahmed',
    phone: '+923021234567',
    rating: '4.8',
    seats: '3/3 seats',
    vehicleModel: 'Suzuki Swift',
    vehicleColor: 'Red',
    vehiclePlate: 'AJK-9087',
    avatarAsset: 'Assets/icons/woman_2.jpg',
    initialEta: '7 min',
    initialPosition: const LatLng(24.8785, 67.0210),
    currentTrip: null,
  ),
  DriverProfile(
    id: 'driver_nimra_yousuf',
    name: 'Nimra Yousuf',
    phone: '+923335551234',
    rating: '4.7',
    seats: '2/3 seats',
    vehicleModel: 'Toyota Vitz',
    vehicleColor: 'Blue',
    vehiclePlate: 'BWP-3210',
    avatarAsset: 'Assets/icons/women1.jpeg',
    initialEta: '8 min',
    initialPosition: const LatLng(24.8665, 67.0550),
    currentTrip: null,
  ),
];
