// import 'dart:ui';
// import 'package:flutter/material.dart';
// import '../../domain/entities/mon_card.dart';
// import '../../domain/entities/card_element.dart';
// import '../../game/logic/element_chart.dart';

// class LensOverlayWidget extends StatelessWidget {
//   final MonCard    card;
//   final VoidCallback onClose;

//   const LensOverlayWidget({super.key, required this.card, required this.onClose});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onClose,
//       child: Stack(
//         children: [
//           // Backdrop blur + darkening
//           Positioned.fill(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//               child: Container(color: Colors.black.withOpacity(0.55)),
//             ),
//           ),
//           // Content panel
//           Positioned(
//             bottom: 160, left: 20, right: 20,
//             child: GestureDetector(
//               onTap: () {}, // prevent close on panel tap
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Card preview
//                   Center(
//                     child: Container(
//                       width: 140, height: 200,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: [BoxShadow(
//                           color: const Color(0xFFF5C842).withOpacity(0.6),
//                           blurRadius: 28, spreadRadius: 4,
//                         )],
//                       ),
//                       clipBehavior: Clip.hardEdge,
//                       child: Image.asset(card.imageAsset, fit: BoxFit.cover),
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                   // Card name
//                   Center(child: Text(card.name,
//                       style: const TextStyle(
//                           color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
//                   const SizedBox(height: 16),
//                   // Stat rows
//                   _StatRow(
//                     color:  const Color(0xFF78909C),
//                     label:  ElementChart.advantageText(card.element),
//                     icon:   card.element.emoji,
//                   ),
//                   const SizedBox(height: 8),
//                   _StatRow(
//                     color:  const Color(0xFF42A5F5),
//                     label:  'High defense. Strong against ${_strongAgainst()}.',
//                     icon:   '🛡',
//                     value:  card.defense,
//                   ),
//                   const SizedBox(height: 8),
//                   _StatRow(
//                     color:  const Color(0xFF26A69A),
//                     label:  card.abilityText,
//                     icon:   '⚔',
//                     value:  card.attack,
//                   ),
//                   const SizedBox(height: 14),
//                   // Keywords
//                   if (card.keywords.isNotEmpty)
//                     Wrap(
//                       spacing: 8,
//                       children: card.keywords.map((k) => Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                         decoration: BoxDecoration(
//                           color:        const Color(0xFFF5C842),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(k.name.toUpperCase(),
//                             style: const TextStyle(
//                                 fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF333333))),
//                       )).toList(),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//           // Close hint
//           Positioned(
//             top: 50, right: 20,
//             child: GestureDetector(
//               onTap: onClose,
//               child: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _strongAgainst() {
//     const defensiveAdvantage = {
//       CardElement.fire:    'Wind',
//       CardElement.water:   'Earth',
//       CardElement.nature:  'Water',
//       CardElement.wind:    'Nature',
//       CardElement.earth:   'Fire',
//       CardElement.neutral: 'None',
//     };
//     return defensiveAdvantage[card.element] ?? 'None';
//   }
// }

// class _StatRow extends StatelessWidget {
//   final Color  color;
//   final String label, icon;
//   final int?   value;
//   const _StatRow({required this.color, required this.label, required this.icon, this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color:        Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(10),
//         border:       Border.all(color: Colors.white.withOpacity(0.15)),
//       ),
//       child: Row(children: [
//         Container(
//           width: 28, height: 28,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//           alignment: Alignment.center,
//           child: Text(icon, style: const TextStyle(fontSize: 14)),
//         ),
//         const SizedBox(width: 10),
//         Expanded(child: Text(label,
//             style: const TextStyle(color: Colors.white, fontSize: 12))),
//         if (value != null)
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.7),
//               borderRadius: BorderRadius.circular(8)),
//             child: Text('$value',
//                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
//           ),
//       ]),
//     );
//   }
// }
