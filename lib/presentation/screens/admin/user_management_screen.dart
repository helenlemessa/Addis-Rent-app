import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:addis_rent/presentation/providers/user_provider.dart';
import 'package:addis_rent/core/utils/helpers.dart';
import 'package:addis_rent/data/models/user_model.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userProvider.users.length,
              itemBuilder: (context, index) {
                final user = userProvider.users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.fullName.substring(0, 1)),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text('${user.email} • ${user.role}'),
                  trailing: user.isSuspended
                      ? const Chip(
                          label: Text('Suspended'),
                          backgroundColor: Colors.red,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
