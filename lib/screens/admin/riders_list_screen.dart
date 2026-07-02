import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'rider_verification_screen.dart';
import 'widgets/bottom_nav.dart';
import 'package:musafirah_app/services/auth_service.dart';

class RidersListScreen extends StatefulWidget {
  const RidersListScreen({super.key});

  @override
  State<RidersListScreen> createState() => _RidersListScreenState();
}

class _RidersListScreenState extends State<RidersListScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 2;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  static const _primaryColor = Color(0xFFFC153B);
  static const _filters = ['All', 'Pending', 'Approved', 'Rejected', 'Blocked'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
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
        return Colors.grey;
    }
  }

  void _handleNavigation(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    if (index == 0) Navigator.pushReplacementNamed(context, '/dashboard');
    if (index == 1) Navigator.pushReplacementNamed(context, '/drivers');
    if (index == 3) Navigator.pushReplacementNamed(context, '/rides');
    if (index == 4) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  List<QueryDocumentSnapshot> _filterDocs(
    List<QueryDocumentSnapshot> docs,
    String filter,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      if (!name.contains(_searchQuery)) return false;
      if (filter == 'All') return true;
      if (filter == 'Blocked') return data['isBlocked'] == true;
      return (data['status'] ?? '').toString().toLowerCase() ==
          filter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _primaryColor,
        elevation: 0,
        title: Text(
          'Passenger Verification',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _filters.map((f) => Tab(text: f)).toList(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(),
                      decoration: InputDecoration(
                        hintText: 'Search by passenger name...',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: _primaryColor.withValues(alpha: 0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _filters.map((filter) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Passengers')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error loading data', style: GoogleFonts.outfit()));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: _primaryColor));
                          }

                          final docs = _filterDocs(snapshot.data!.docs, filter);

                          if (docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade200),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No passengers found',
                                    style: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final rider = doc.data() as Map<String, dynamic>;
                              final status = rider['status'] ?? 'pending';
                              final isBlocked = rider['isBlocked'] == true;
                              final displayStatus = isBlocked ? 'blocked' : status;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0.5,
                                color: Colors.white,
                                shadowColor: Colors.black.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RiderVerificationScreen(
                                        riderUid: doc.id,
                                        riderData: rider,
                                      ),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Leading Profile
                                        Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                                              ),
                                              child: CircleAvatar(
                                                radius: 28,
                                                backgroundColor: Colors.grey.shade50,
                                                backgroundImage: AuthService.getImageProvider(
                                                  rider['profileImageUrl'] ??
                                                      rider['image_selfie'] ??
                                                      '',
                                                ),
                                                onBackgroundImageError: (_, __) {},
                                                child: (rider['profileImageUrl'] == null && rider['image_selfie'] == null)
                                                    ? const Icon(Icons.person, color: Colors.grey)
                                                    : null,
                                              ),
                                            ),
                                            if (isBlocked)
                                              Positioned(
                                                right: -2,
                                                bottom: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.deepPurple,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.block, size: 10, color: Colors.white),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Title & Subtitle
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                rider['name'] ?? 'Musafirah Member',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(displayStatus).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      displayStatus.toUpperCase(),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: _getStatusColor(displayStatus),
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(Icons.phone_iphone_rounded, size: 12, color: Colors.grey.shade400),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          rider['phone'] ?? rider['phoneNo'] ?? 'No phone',
                                                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (rider['statusUpdatedAt'] != null && (displayStatus == 'rejected' || displayStatus == 'blocked' || displayStatus == 'approved'))
                                                          Text(
                                                            '${displayStatus == 'approved' ? 'Approved on:' : 'Since:'} ${DateFormat('MMM d, yyyy h:mm a').format((rider['statusUpdatedAt'] as Timestamp).toDate())}',
                                                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500),
                                                            maxLines: 1,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Trailing
                                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
