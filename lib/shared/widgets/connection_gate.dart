import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/connection_status_provider.dart';
import 'no_connection_page.dart';

/// `MaterialApp.builder` ichida ishlatiladigan "gate" widget.
///
/// Ilovaning istalgan joyida (splash, login, courses, va h.k.) internet
/// yo'qligi yoki serverga ulanib bo'lmasligi aniqlansa, shu widget asosiy
/// ekranni [NoConnectionPage] bilan almashtiradi — foydalanuvchi qaysi
/// sahifada turgan bo'lsa, ortidan o'sha sahifa saqlanib qoladi (Navigator
/// stack o'zgarmaydi), shunchaki ustiga to'liq ekranli xatolik chiqadi.
///
/// Muammo hal bo'lgan zahoti (`issue == ConnectionIssue.none`) bu widget
/// avtomatik ravishda asosiy ilovani qaytarib ko'rsatadi va foydalanuvchi
/// xuddi to'xtagan joyidan davom etadi.
class ConnectionGate extends StatelessWidget {
  const ConnectionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<ConnectionStatusProvider>();

    return Stack(
      children: [
        child,
        if (status.hasIssue)
          const Positioned.fill(
            child: Material(
              child: NoConnectionPage(),
            ),
          ),
      ],
    );
  }
}
