import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final bool isPropertyCard;

  const LoadingShimmer({
    super.key,
    this.isPropertyCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: isPropertyCard ? _buildPropertyCard() : _buildListTile(),
    );
  }

  Widget _buildPropertyCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 200,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 150,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 16,
                      width: 80,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile() {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        color: Colors.white,
      ),
      title: Container(
        height: 20,
        width: 150,
        color: Colors.white,
      ),
      subtitle: Container(
        height: 16,
        width: 100,
        color: Colors.white,
      ),
    );
  }
}