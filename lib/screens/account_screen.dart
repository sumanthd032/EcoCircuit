import 'package:eco_circuit/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
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

  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

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
                title: Text("Sign Out"),
                content: Text("Are you sure you want to sign out?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
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
          MaterialPageRoute(builder: (context) => LoginScreen()),
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
      setState(() {
        scanStats = {
          'totalScans': scans.docs.length,
          'badges': scans.docs.length ~/ 5, // 1 badge per 5 scans
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
        SnackBar(
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
        title: Text('My Profile'),
        backgroundColor: Colors.teal[700],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
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
                            color: Colors.teal[700],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 20,
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _uploadProfileImage,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // User Info Section
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
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
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                            ),
                            Divider(),
                            ListTile(
                              leading: Icon(
                                Icons.email,
                                color: Colors.teal[700],
                              ),
                              title: Text(user?.email ?? 'No email'),
                            ),
                            Divider(),
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
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit, size: 20),
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
                    SizedBox(height: 20),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.devices,
                            value: scanStats?['totalScans']?.toString() ?? '0',
                            label: 'Devices Scanned',
                            color: Colors.teal[700]!,
                          ),
                          _buildStatCard(
                            icon: Icons.eco,
                            value: scanStats?['carbonSaved']?.toString() ?? '0',
                            label: 'Carbon Saved (kg)',
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            icon: Icons.star,
                            value: (scanStats?['badges'] ?? 0).toString(),
                            label: 'Badges Earned',
                            color: Colors.amber[600]!,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),

                    // Save/Cancel Buttons (only shown when editing)
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              child: Text('Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
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
                              child: Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        child: Text(
                          "Logout",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 120,
      margin: EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 30, color: color),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
