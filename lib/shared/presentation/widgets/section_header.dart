import 'package:flutter/material.dart';

/// Reusable gradient SliverAppBar used across feature screens.
/// No double-title: the collapsed state shows only the back button area,
/// the expanded state shows the icon + title + optional subtitle in the
/// FlexibleSpaceBar background. The FlexibleSpaceBar.title is intentionally
/// omitted to prevent the built-in title from overlapping the custom content.
class FeaturePageHeader extends StatelessWidget {
  const FeaturePageHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actions,
    this.bottom,
    this.contentTopOffset,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double? contentTopOffset;

  // Height of the collapsed toolbar (standard kToolbarHeight = 56)
  static const double _collapsedHeight = kToolbarHeight;

  double get _expandedHeight {
    double h = _collapsedHeight + 50; // Increased from 34 to 50
    if (subtitle != null) h += 18;
    if (bottom != null) h += bottom!.preferredSize.height + 6;
    return h;
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: _expandedHeight,
      collapsedHeight: _collapsedHeight,
      pinned: true,
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      // Show the title only in the collapsed (pinned) toolbar
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      // Hide the title when the bar is expanded so it doesn't overlap
      // the custom background content
      titleSpacing: 0,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        // No title here — avoids the double-title problem
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    bottom != null ? 4 : 8,
                  ),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (subtitle != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            subtitle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottom: bottom,
    );
  }
}

/// Simple status chip used in list cards.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
