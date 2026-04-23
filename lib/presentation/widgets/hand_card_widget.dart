import 'package:flutter/material.dart';
import '../../domain/entities/mon_card.dart';

class HandCardWidget extends StatelessWidget {
  final MonCard   card;
  final bool      isFocused;
  final bool      isSelected;
  final VoidCallback? onLensTap;
  final double    width, height;

  const HandCardWidget({
    super.key,
    required this.card,
    this.isFocused  = false,
    this.isSelected = false,
    this.onLensTap,
    this.width  = 68,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card image
        Container(
          width: width, height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: const Color(0xFFF5C842), width: 2.5)
                : Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow: isFocused
                ? [BoxShadow(
                    color: const Color(0xFFF5C842).withOpacity(0.4),
                    blurRadius: 16, spreadRadius: 2)]
                : [],
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(card.imageAsset, fit: BoxFit.cover),
        ),
        // Level badge — bottom-left circle
        Positioned(
          bottom: 4, left: 4,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF333333), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${card.level}',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        ),
        // Power badge — top-right
        Positioned(
          top: 4, right: 4,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${card.power}',
                style: const TextStyle(color: Color(0xFF333333), fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ),
        // Lens icon — only on focused card
        if (isFocused && onLensTap != null)
          Positioned(
            bottom: -10, right: 0,
            child: GestureDetector(
              onTap: onLensTap,
              child: Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.search_rounded, size: 14, color: Color(0xFF333333)),
              ),
            ),
          ),
      ],
    );
  }
}