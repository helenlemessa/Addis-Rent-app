import 'package:flutter/material.dart';
import 'dart:async';
import 'package:addis_rent/core/utils/helpers.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final void Function(int)? onPageChanged;
  final double? height;
  final bool autoPlay;

  const ImageCarousel({
    super.key,
    required this.images,
    this.onPageChanged,
    this.height = 300,
    this.autoPlay = true,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;
  late final PageController _pageController;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.images.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        final next = (_currentIndex + 1) % widget.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Check images in carousel
    print('🎠 ImageCarousel: ${widget.images.length} images');

    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(
            Icons.photo,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // PageView-based carousel
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final imagePath = widget.images[index];
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Helpers.buildPropertyImage(
                  imagePath,
                  height: widget.height,
                ),
              );
            },
          ),
        ),
        // Image Count Indicator
        if (widget.images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        // Dots Indicator
        if (widget.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}