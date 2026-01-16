import 'package:flutter/material.dart';
import 'package:addis_rent/core/utils/helpers.dart';

class AmenitiesChip extends StatelessWidget {
  final String amenity;

  const AmenitiesChip({
    super.key,
    required this.amenity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Helpers.getAmenityIcon(amenity),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            amenity,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}