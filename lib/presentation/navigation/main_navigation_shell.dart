import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const destinations = [
      (label: 'Backlog', icon: Icons.sports_esports_outlined),
      (label: 'Explorar', icon: Icons.explore_outlined),
      (label: 'Configuración', icon: Icons.settings_outlined),
    ];
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0D0C14)
            : Colors.grey.shade100,
        body: navigationShell,
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF171622) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C293C)
                          : const Color(0xFFE4DFEF),
                    ),
                  ),
                  child: Row(
                    children: List.generate(destinations.length, (index) {
                      final destination = destinations[index];
                      final selected = navigationShell.currentIndex == index;
                      final color = selected
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFAAA4BA)
                                : const Color(0xFF655E76));
                      return Expanded(
                        child: Semantics(
                          selected: selected,
                          button: true,
                          child: Material(
                            color: selected
                                ? const Color(0xFF6949DB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(27),
                            child: InkWell(
                              key: ValueKey('nav-$index'),
                              borderRadius: BorderRadius.circular(27),
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                navigationShell.goBranch(index);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      destination.icon,
                                      color: color,
                                      size: 26,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      destination.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
      ),
    );
  }
}
