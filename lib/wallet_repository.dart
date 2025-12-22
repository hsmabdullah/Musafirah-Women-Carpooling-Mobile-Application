import 'package:musafirah_app/utils/id_utils.dart';

class WalletRepository {
  WalletRepository._();

  // Seed balance chosen so that initial entries display Rs. 2,500 after debits/credits.
  static const double _initialBalance = 2770.0;

  static final List<WalletEntry> _entries = [
    WalletEntry(
      id: 'TXN-K89J2-1029',
      title: 'Ride Payment (Clifton to DHA)',
      subtitle: '2023-11-19 14:30',
      amount: -350,
      timestamp: DateTime(2023, 11, 19, 14, 30),
      type: WalletEntryType.ridePayment,
    ),
    WalletEntry(
      id: 'TXN-M72G1-5582',
      title: 'Wallet Top-up',
      subtitle: '2023-11-18 09:00',
      amount: 1000,
      timestamp: DateTime(2023, 11, 18, 9, 0),
      type: WalletEntryType.topUp,
    ),
    WalletEntry(
      id: 'TXN-P11A0-9931',
      title: 'Ride Payment (Gulshan to Tariq Road)',
      subtitle: '2023-11-17 18:15',
      amount: -420,
      timestamp: DateTime(2023, 11, 17, 18, 15),
      type: WalletEntryType.ridePayment,
    ),
    WalletEntry(
      id: 'TXN-B22Q9-4402',
      title: 'Referral Bonus',
      subtitle: '2023-11-16 11:00',
      amount: 200,
      timestamp: DateTime(2023, 11, 16, 11, 0),
      type: WalletEntryType.bonus,
    ),
    WalletEntry(
      id: 'TXN-X44W5-7761',
      title: 'Ride Payment (Airport to Saddar)',
      subtitle: '2023-11-15 21:00',
      amount: -700,
      timestamp: DateTime(2023, 11, 15, 21, 0),
      type: WalletEntryType.ridePayment,
    ),
  ];

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
        id: IdUtils.generateTransactionId(),
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
    bool isWalletPayment = false,
    int rating = 0,
    String? comment,
  }) {
    if (isWalletPayment) {
      _entries.insert(
        0,
        WalletEntry(
          id: IdUtils.generateTransactionId(),
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
    }

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
