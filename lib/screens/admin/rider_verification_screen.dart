import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'widgets/info_card.dart';
import 'widgets/image_tile.dart';

class RiderVerificationScreen extends StatefulWidget {
  final String riderUid;
  final Map<String, dynamic> riderData;

  const RiderVerificationScreen({
    super.key,
    required this.riderUid,
    required this.riderData,
  });

  @override
  State<RiderVerificationScreen> createState() => _RiderVerificationScreenState();
}

class _RiderVerificationScreenState extends State<RiderVerificationScreen> {
  late String _currentStatus;
  late bool _isBlocked;

  static const _primaryColor = Color(0xFFFC153B);

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.riderData['status'] ?? 'pending';
    _isBlocked = widget.riderData['isBlocked'] == true;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'blocked':
        return Colors.deepPurple;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'blocked':
        return 'Blocked';
      default:
        return 'Pending';
    }
  }

  Future<void> _toggleBlock(bool currentlyBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(currentlyBlocked ? 'Unblock Rider' : 'Block Rider'),
        content: Text(
          currentlyBlocked
              ? 'This rider will regain access to the app. Continue?'
              : 'This rider will be blocked and cannot use the app. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyBlocked ? Colors.green : Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(currentlyBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('Passengers')
          .doc(widget.riderUid)
          .update({
        'isBlocked': !currentlyBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyBlocked ? 'Rider unblocked successfully.' : 'Rider blocked successfully.',
            ),
            backgroundColor: currentlyBlocked ? Colors.green : Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete this account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await DatabaseService.deleteUserDoc(
      uid: widget.riderUid,
      collection: 'Passengers',
    );
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account deleted successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _updateStatus(String status) async {
    final label = status == 'approved' ? 'Approve' : 'Reject';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$label Rider'),
        content: Text('Are you sure you want to $label this rider?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await DatabaseService.updateUserStatus(
      uid: widget.riderUid,
      collection: 'Passengers',
      status: status,
    );
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rider ${status == 'approved' ? 'approved' : 'rejected'} successfully.'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rider Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: DatabaseService.getUserDocStream(widget.riderUid, 'Passengers'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? widget.riderData;
          _currentStatus = data['status'] ?? 'pending';
          _isBlocked = data['isBlocked'] == true;
          final displayStatus = _isBlocked ? 'blocked' : _currentStatus;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: AuthService.getImageProvider(
                                      data['image_selfie'] ??
                                          data['profileImageUrl'] ??
                                          '',
                                    ),
                                    onBackgroundImageError: (_, __) {},
                                    child: (data['image_selfie'] == null &&
                                            data['profileImageUrl'] == null)
                                        ? const Icon(Icons.person,
                                            size: 40, color: Colors.grey)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(displayStatus)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _getStatusText(displayStatus)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _getStatusColor(
                                                  displayStatus),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _iconRow(
                                            Icons.phone,
                                            data['phone'] ??
                                                data['phoneNo'] ??
                                                'No phone'),
                                        if (data['createdAt'] != null) ...[
                                          const SizedBox(height: 4),
                                          _iconRow(
                                            Icons.calendar_today,
                                            'Registered: ${DateFormat('MMM dd, yyyy').format((data['createdAt'] as Timestamp).toDate())}',
                                            size: 13,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _iconRow(Icons.email, data['email'] ?? 'No email'),
                              const SizedBox(height: 6),
                              _iconRow(
                                Icons.location_on,
                                data['city'] ?? data['address'] ?? 'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CNIC Verification
                      InfoCard(
                        title: 'CNIC Verification',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CNIC No.: ${data['Cnic_Number'] ?? data['cnicNumber'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Front',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                      const SizedBox(height: 4),
                                      ImageTile(
                                        imagePath: data['image_cnic_front'] ??
                                            data['cnicFrontUrl'] ??
                                            '',
                                        height: 110,
                                        isNetwork: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Back',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                      const SizedBox(height: 4),
                                      ImageTile(
                                        imagePath: data['image_cnic_back'] ??
                                            data['cnicBackUrl'] ??
                                            '',
                                        height: 110,
                                        isNetwork: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Selfie
                      InfoCard(
                        title: 'Selfie Verification',
                        child: Center(
                          child: ImageTile(
                            imagePath: data['image_selfie'] ??
                                data['facePhotoUrl'] ??
                                '',
                            height: 200,
                            isNetwork: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Emergency Contact
                      InfoCard(
                        title: 'Emergency Contact',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.contact_phone_rounded,
                                  size: 28, color: _primaryColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['emergency_relation'] ??
                                        data['emergencyContactRelation'] ??
                                        'N/A',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  _iconRow(
                                    Icons.phone,
                                    data['emergency_contact'] ??
                                        data['emergencyContactPhone'] ??
                                        'N/A',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ride history
                      _rideHistoryCard(data),
                      const SizedBox(height: 20),

                      // Action Buttons
                      if (!_isBlocked) ...[
                        if (_currentStatus != 'approved' || _currentStatus == 'rejected')
                          Row(
                            children: [
                              if (_currentStatus != 'approved')
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus('approved'),
                                    icon: const Icon(Icons.check_circle_outline, size: 18),
                                    label: const Text('Approve',
                                        style: TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              if (_currentStatus != 'approved' && _currentStatus != 'rejected')
                                const SizedBox(width: 10),
                              if (_currentStatus != 'rejected')
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _updateStatus('rejected'),
                                    icon: const Icon(Icons.cancel_outlined, size: 18),
                                    label: const Text('Reject',
                                        style: TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red, width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 10),
                      ],

                      // Block / Unblock
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleBlock(_isBlocked),
                          icon: Icon(
                            _isBlocked
                                ? Icons.lock_open_rounded
                                : Icons.block_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isBlocked ? 'Unblock Rider' : 'Block Rider',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isBlocked ? Colors.green : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      
                      // Delete Account (only if rejected or blocked)
                      if (_currentStatus == 'rejected' || _isBlocked) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _deleteAccount,
                            icon: const Icon(Icons.delete_forever, size: 18),
                            label: const Text(
                              'Delete Account',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rideHistoryCard(Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Rides')
          .where('passengerId', isEqualTo: widget.riderUid)
          .snapshots(),
      builder: (context, snapshot) {
        final rides = snapshot.data?.docs ?? [];
        final total = rides.length;
        final completed = rides
            .where((r) =>
                (r.data() as Map<String, dynamic>)['status'] == 'completed')
            .length;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ride Statistics',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Total Rides', total.toString(), Colors.blue),
                    _statItem('Completed', completed.toString(), Colors.green),
                    _statItem(
                      'Rating',
                      '${(data['rating'] ?? 0.0).toStringAsFixed(1)}★',
                      Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _iconRow(IconData icon, String text, {double size = 14}) {
    return Row(
      children: [
        Icon(icon, size: size, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: size, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
