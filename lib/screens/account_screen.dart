import 'package:eco_circuit/screens/auth_screen/login_screen.dart';
import 'package:eco_circuit/screens/market/seller_notification_screen.dart';
import 'package:eco_circuit/theme/pallete.dart';
import 'package:eco_circuit/widgets/Account_screen_widgets/build_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? user;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? scanStats;
  bool _isEditing = false;
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _logout() async {
    bool confirmSignOut =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Sign Out"),
                content: const Text("Are you sure you want to sign out?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      "Sign Out",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmSignOut) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        ); // Adjust the route as needed
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    user = _auth.currentUser;
    if (user != null) {
      // Load user profile data
      var userDoc = await _firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          _nameController.text = userData?['name'] ?? '';
          _phoneController.text = userData?['phone'] ?? '';
        });
      }

      // Load scan statistics
      var scans =
          await _firestore
              .collection('users')
              .doc(user!.uid)
              .collection('scans')
              .get();

      // Load purchase requests count
      var purchases =
          await _firestore
              .collection('purchases')
              .where('sellerId', isEqualTo: user!.uid)
              .get();

      setState(() {
        scanStats = {
          'totalScans': scans.docs.length,
          'badges': scans.docs.length ~/ 5,
          'purchaseRequests': purchases.docs.length, // Add purchase count
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user!.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null || user == null) return;

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/${user!.uid}.jpg',
      );
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      // Update Firestore
      await _firestore.collection('users').doc(user!.uid).update({
        'profileImage': url,
      });

      setState(() {
        userData?['profileImage'] = url;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Pallete.appBarColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Picture Section
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              userData?['profileImage'] != null
                                  ? NetworkImage(userData!['profileImage'])
                                  : null,
                          child:
                              userData?['profileImage'] == null
                                  ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[600],
                                  )
                                  : null,
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 196, 188, 188),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 20,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: _uploadProfileImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // User Info Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.person,
                                color: Colors.teal[700],
                              ),
                              title:
                                  _isEditing
                                      ? TextField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          labelText: 'Full Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      )
                                      : Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              userData?['name'] ??
                                                  'No name provided',
                                              style: const TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              color: Pallete.iconColor,
                                              Icons.edit,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(
                                Icons.email,
                                color: Colors.teal[700],
                              ),
                              title: Text(user?.email ?? 'No email'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(
                                Icons.phone,
                                color: Colors.teal[700],
                              ),
                              title:
                                  _isEditing
                                      ? TextField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.phone,
                                      )
                                      : Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              userData?['phone'] ??
                                                  'No phone number',
                                              style: const TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              color: Pallete.iconColor,
                                              Icons.edit,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildStatCard(
                            icon: Icons.devices,
                            value: scanStats?['totalScans']?.toString() ?? '0',
                            label: 'Devices Scanned',
                            color: Pallete.iconColor,
                          ),
                          buildStatCard(
                            icon: Icons.eco,
                            value: scanStats?['carbonSaved']?.toString() ?? '0',
                            label: 'Carbon Saved (kg)',
                            color: Colors.green,
                          ),
                          buildStatCard(
                            icon: Icons.star,
                            value: (scanStats?['badges'] ?? 0).toString(),
                            label: 'Badges \n Earned',
                            color: Colors.amber[600]!,
                          ),
                        ],
                      ),
                    ),
                    // const SizedBox(height: 10),

                    // Save/Cancel Buttons (only shown when editing)
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Pallete.buttonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _nameController.text =
                                        userData?['name'] ?? '';
                                    _phoneController.text =
                                        userData?['phone'] ?? '';
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.teal[700],
                                  side: BorderSide(color: Colors.teal[700]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const SellerNotificationsScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'View Purchase Requests',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent[700],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Logout",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
