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
  ),
];
