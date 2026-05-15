
class WalletRepository {
  WalletRepository._();

  static final List<RideHistoryEntry> _rideHistory = [
    RideHistoryEntry(
      rideId: 'MUS-J92A-K182',
      pickup: 'Clifton, Karachi',
      dropoff: 'DHA Phase V, Karachi',
      fare: 350,
      timestamp: DateTime(2023, 11, 19, 14, 30),
      status: 'Completed',
    ),
    RideHistoryEntry(
      rideId: 'MUS-L08B-W221',
      pickup: 'Gulshan-e-Iqbal',
      dropoff: 'Tariq Road',
      fare: 420,
      timestamp: DateTime(2023, 11, 17, 18, 15),
      status: 'Completed',
    ),
    RideHistoryEntry(
      rideId: 'MUS-R55G-Z001',
      pickup: 'Karachi Airport',
      dropoff: 'Saddar',
      fare: 700,
      timestamp: DateTime(2023, 11, 15, 21, 0),
      status: 'Completed',
    ),
  ];

  static List<RideHistoryEntry> getRideHistory() {
    final rides = [..._rideHistory];
    rides.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return rides;
  }

  static void recordRideCompletion({
    required String rideId,
    required String pickup,
    required String dropoff,
    required double fare,
    required DateTime timestamp,
    int rating = 0,
    String? comment,
    String? screenshotUrl,
  }) {
    _rideHistory.insert(
      0,
      RideHistoryEntry(
        rideId: rideId,
        pickup: pickup,
        dropoff: dropoff,
        fare: fare,
        timestamp: timestamp,
        status: 'Completed',
        rating: rating,
        comment: comment,
        screenshotUrl: screenshotUrl,
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatTimestamp(DateTime dateTime) => _formatDate(dateTime);
}

class RideHistoryEntry {
  RideHistoryEntry({
    required this.rideId,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.timestamp,
    required this.status,
    this.rating,
    this.comment,
    this.screenshotUrl,
  });

  final String rideId;
  final String pickup;
  final String dropoff;
  final double fare;
  final DateTime timestamp;
  final String status;
  final int? rating;
  final String? comment;
  final String? screenshotUrl;
}
