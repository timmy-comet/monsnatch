import 'package:flutter/material.dart';

class MonButton extends StatelessWidget {
  final String   label;
  final Color    color;
  final VoidCallback? onPressed;
  final bool     isLoading;
  final double   width;
  final double   height;

  const MonButton({
    super.key,
    required this.label,
    required this.color,
    this.onPressed,
    this.isLoading = false,
    this.width   = 260,
    this.height  = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:    color,
          disabledBackgroundColor: color.withOpacity(0.6),
          foregroundColor:    Colors.white,
          elevation:          3,
          shadowColor:        color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}
