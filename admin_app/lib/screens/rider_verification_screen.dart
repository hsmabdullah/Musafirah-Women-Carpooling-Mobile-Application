import 'package:flutter/material.dart';
import '../widgets/info_card.dart';
import '../widgets/image_tile.dart';

class RiderVerificationScreen extends StatefulWidget {
  final String? riderName;
  final String initialStatus;

  const RiderVerificationScreen({
    super.key,
    this.riderName,
    this.initialStatus = 'Pending',
  });

  @override
  State<RiderVerificationScreen> createState() =>
      _RiderVerificationScreenState();
}

class _RiderVerificationScreenState extends State<RiderVerificationScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return const Color.fromARGB(255, 255, 152, 0);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF1744),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rider Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rider Information
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: const AssetImage(
                                    'assets/images/d1.png',
                                  ),
                                  onBackgroundImageError: (_, __) {},
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              widget.riderName ?? 'Aisha Khan',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                _currentStatus,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _getStatusText(_currentStatus),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(
                                                  _currentStatus,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+92 300 1234567',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'aisha.khan@example.com',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Guidance: +92 300 7654321',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CNIC Verification
                    InfoCard(
                      title: 'CNIC Verification',
                      status: 'Pending',
                      statusColor: const Color(0xFFFF1744),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CNIC Number: 42101-1234567-8',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ImageTile(
                                  imagePath: 'assets/images/cnic_front.png',
                                  height: 120,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ImageTile(
                                  imagePath: 'assets/images/cnic_back.png',
                                  height: 120,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Uploaded Photos
                    InfoCard(
                      title: 'Uploaded Photos',
                      child: Row(
                        children: [
                          Expanded(
                            child: ImageTile(
                              imagePath: 'assets/images/d1.png',
                              height: 150,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ImageTile(
                              imagePath: 'assets/images/d1.png',
                              height: 150,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Emergency Contact
                    InfoCard(
                      title: 'Emergency Contact',
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: const AssetImage(
                              'assets/images/emergency_contact.png',
                            ),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ali Khan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Brother',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+92 321 9876543',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentStatus = 'Verified';
                              });
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Rider Approved'),
                                    content: const Text(
                                      'Rider has been approved successfully.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop('Verified');
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF1744),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Approve Rider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentStatus = 'Rejected';
                              });
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Rider Rejected'),
                                    content: const Text(
                                      'Rider has been rejected.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop('Rejected');
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF1744),
                              side: const BorderSide(
                                color: Color(0xFFFF1744),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Reject Rider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
