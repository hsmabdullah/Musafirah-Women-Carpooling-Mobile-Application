class WalletRepository {
  WalletRepository._();

  // Seed balance chosen so that initial entries display Rs. 2,500 after debits/credits.
  static const double _initialBalance = 2770.0;

  static final List<WalletEntry> _entries = [
    WalletEntry(
      id: 'txn_001',
      title: 'Ride Payment (Clifton to DHA)',
      subtitle: '2023-10-26 14:30',
      amount: -350,
      timestamp: DateTime(2023, 10, 26, 14, 30),
      type: WalletEntryType.ridePayment,
    ),
    WalletEntry(
      id: 'txn_002',
      title: 'Wallet Top-up',
      subtitle: '2023-10-25 09:00',
      amount: 1000,
      timestamp: DateTime(2023, 10, 25, 9, 0),
      type: WalletEntryType.topUp,
    ),
    WalletEntry(
      id: 'txn_003',
      title: 'Ride Payment (Gulshan to Tariq Road)',
      subtitle: '2023-10-24 18:15',
      amount: -420,
      timestamp: DateTime(2023, 10, 24, 18, 15),
      type: WalletEntryType.ridePayment,
    ),
    WalletEntry(
      id: 'txn_004',
      title: 'Referral Bonus',
      subtitle: '2023-10-23 11:00',
      amount: 200,
      timestamp: DateTime(2023, 10, 23, 11, 0),
      type: WalletEntryType.bonus,
    ),
    WalletEntry(
      id: 'txn_005',
      title: 'Ride Payment (Airport to Saddar)',
      subtitle: '2023-10-22 21:00',
      amount: -700,
      timestamp: DateTime(2023, 10, 22, 21, 0),
      type: WalletEntryType.ridePayment,
    ),
  ];

  static final List<RideHistoryEntry> _rideHistory = [
    RideHistoryEntry(
      rideId: 'ride_20231026_01',
      pickup: 'Clifton, Karachi',
      dropoff: 'DHA Phase V, Karachi',
      fare: 350,
      timestamp: DateTime(2023, 10, 26, 14, 30),
      status: 'Completed',
    ),
    RideHistoryEntry(
      rideId: 'ride_20231024_02',
      pickup: 'Gulshan-e-Iqbal',
      dropoff: 'Tariq Road',
      fare: 420,
      timestamp: DateTime(2023, 10, 24, 18, 15),
      status: 'Completed',
    ),
    RideHistoryEntry(
      rideId: 'ride_20231022_03',
      pickup: 'Karachi Airport',
      dropoff: 'Saddar',
      fare: 700,
      timestamp: DateTime(2023, 10, 22, 21, 0),
      status: 'Completed',
    ),
  ];

  static double get balance =>
      _initialBalance +
      _entries.fold<double>(0, (sum, entry) => sum + entry.amount);

  static List<WalletEntry> getTransactions() {
    final entries = [..._entries];
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  static List<RideHistoryEntry> getRideHistory() {
    final rides = [..._rideHistory];
    rides.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return rides;
  }

  static void addFunds({
    required double amount,
    String source = 'Manual Top-up',
  }) {
    _entries.insert(
      0,
      WalletEntry(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        title: source,
        subtitle: _formatDate(DateTime.now()),
        amount: amount,
        timestamp: DateTime.now(),
        type: WalletEntryType.topUp,
      ),
    );
  }

  static void recordRideCompletion({
    required String rideId,
    required String pickup,
    required String dropoff,
    required double fare,
    required DateTime timestamp,
    int rating = 0,
    String? comment,
  }) {
    _entries.insert(
      0,
      WalletEntry(
        id: 'txn_${timestamp.millisecondsSinceEpoch}',
        title: 'Ride Payment ($pickup to $dropoff)',
        subtitle: _formatDate(timestamp),
        amount: -fare,
        timestamp: timestamp,
        type: WalletEntryType.ridePayment,
        metadata: {
          'rideId': rideId,
          'rating': rating,
          'comment': comment ?? '',
        },
      ),
    );

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
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatTimestamp(DateTime dateTime) => _formatDate(dateTime);
}

enum WalletEntryType { ridePayment, topUp, bonus }

class WalletEntry {
  WalletEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.timestamp,
    required this.type,
    this.metadata,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime timestamp;
  final WalletEntryType type;
  final Map<String, dynamic>? metadata;

  bool get isCredit => amount >= 0;
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
  });

  final String rideId;
  final String pickup;
  final String dropoff;
  final double fare;
  final DateTime timestamp;
  final String status;
  final int? rating;
  final String? comment;
}
