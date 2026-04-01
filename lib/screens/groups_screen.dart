import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../models/group.dart';
import '../services/firestore_service.dart';
import 'group_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/toast_helper.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _createGroupController = TextEditingController();
  final _joinCodeController    = TextEditingController();
  final _nameController        = TextEditingController();
  bool _nameSet = false;

  @override
  void initState() {
    super.initState();
    _checkDisplayName();
  }

  // Ask user for display name if not set
 void _checkDisplayName() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  final data = doc.data();
  final displayName = data?['displayName'] as String?;

  // Show dialog if no display name set yet
  if (displayName == null || displayName.trim().isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSetNameDialog();
    });
  } else {
    setState(() => _nameSet = true);
  }
}

 void _showSetNameDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Your name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Enter your name so group members can identify you.'),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g. Maharshi',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            // Save to Firestore
            final uid = FirebaseAuth.instance.currentUser!.uid;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .set(
              {
                'displayName': name,
                'uid': uid,
                'email':
                    FirebaseAuth.instance.currentUser?.email ?? '',
              },
              SetOptions(merge: true),
            );

            setState(() => _nameSet = true);
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 24, 16,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Group',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Create a group for your trip or event.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _createGroupController,
              decoration: const InputDecoration(
                labelText: 'Group name (e.g. Goa Trip 2026)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_createGroupController.text.trim().isEmpty)
                    return;
                  final group = await FirestoreService.instance
                      .createGroup(
                          _createGroupController.text.trim());
                          ToastHelper.success('Group "${group.name}" created!'); 
                  _createGroupController.clear();
                  Navigator.pop(ctx);
                  // Navigate to group detail
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupDetailScreen(group: group),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Group',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 24, 16,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join Group',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Enter the 6-character invite code.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _joinCodeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Invite code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final code = _joinCodeController.text.trim();
                  if (code.length != 6) return;
                  final group = await FirestoreService.instance
                      .joinGroupByCode(code);
                  _joinCodeController.clear();
                  Navigator.pop(ctx);
                  if (group != null) {
                    ToastHelper.success('Joined "${group.name}" successfully!');  
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupDetailScreen(group: group),
                      ),
                    );
                  } else {
                    ToastHelper.error('Invalid invite code. Try again!'); 
                    ScaffoldMessenger.of(context).showSnackBar(

                      SnackBar(
                        content:
                            const Text('Invalid invite code!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Join Group',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _createGroupController.dispose();
    _joinCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        title: const Text('Groups',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<List<Group>>(
        stream: FirestoreService.instance.getGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group,
                      size: 64,
                      color: scheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Text('No groups yet',
                      style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.4),
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Create or join a group',
                      style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.3),
                          fontSize: 13)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showCreateGroupSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _showJoinGroupSheet,
                        icon: const Icon(Icons.vpn_key),
                        label: const Text('Join'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (ctx, index) {
              final group = groups[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupDetailScreen(group: group),
                    ),
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF6C63FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.group,
                        color: Color(0xFF6C63FF), size: 24),
                  ),
                  title: Text(group.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  subtitle: Text(
                      '${group.members.length} members · Code: ${group.inviteCode}',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.5))),
                  trailing: IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () {
                      Share.share(
                        'Join my expense group "${group.name}" on Expense Tracker!\nInvite code: ${group.inviteCode}',
                        subject: 'Join ${group.name}',
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: _showJoinGroupSheet,
            child: const Icon(Icons.vpn_key),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: _showCreateGroupSheet,
            icon: const Icon(Icons.add),
            label: const Text('Create Group'),
          ),
        ],
      ),
    );
  }
}