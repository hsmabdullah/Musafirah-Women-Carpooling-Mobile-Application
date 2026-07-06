class DriverData {
  static int carCapacity = 3; // Current available
  static int totalCapacity = 3; // Max capacity

  // New Fields for syncing data
  static String name = "Sana Ali"; // Default/Mock
  static String phone = "+923001234567";
  static String vehicleModel = "Honda City";
  static String vehicleColor = "White";
  static String vehiclePlate = "ABC-123";

  // Active Rides
  static List<AcceptedRide> acceptedRides = [];
}

class AcceptedRide {
  final String rideId;
  final String passengerId;
  final String passengerImageUrl;
  final String passengerName;
  final String pickupName;
  final String dropoffName;
  final dynamic pickup; // LatLng
  final dynamic dropoff; // LatLng
  final int price;
  final DateTime acceptedAt;
  final String paymentMethod; // 'Cash' or 'Online'

  AcceptedRide({
    this.rideId = '',
    this.passengerId = '',
    this.passengerImageUrl = '',
    required this.passengerName,
    required this.pickupName,
    required this.dropoffName,
    required this.pickup,
    required this.dropoff,
    required this.price,
    required this.acceptedAt,
    this.paymentMethod = 'Cash',
  });
}
