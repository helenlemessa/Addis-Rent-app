import 'package:flutter/material.dart';
import 'package:addis_rent/core/utils/helpers.dart';

class ContactButtons extends StatelessWidget {
  final String phone;
  final String email;
  final bool vertical;

  const ContactButtons({
    super.key,
    required this.phone,
    required this.email,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        children: [
          _buildCallButton(context),
          const SizedBox(height: 8),
          _buildEmailButton(context),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildCallButton(context)),
        const SizedBox(width: 12),
        Expanded(child: _buildEmailButton(context)),
      ],
    );
  }

  Widget _buildCallButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Helpers.launchPhone(phone),
      icon: const Icon(Icons.call, size: 20),
      label: const Text('Call'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildEmailButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Helpers.launchEmail(email),
      icon: const Icon(Icons.email, size: 20),
      label: const Text('Email'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}