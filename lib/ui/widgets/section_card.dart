import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 360
              ? AppSpacing.md
              : AppSpacing.lg;
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final header = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs / 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    );
                    if (action == null) return header;
                    if (constraints.maxWidth < 420) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: AppSpacing.xs),
                          action!,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: header),
                        const SizedBox(width: AppSpacing.sm),
                        action!,
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                child,
              ],
            ),
          );
        },
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.tone,
  });
  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Semantics(
          container: true,
          label: caption == null
              ? '$label: $value'
              : '$label: $value. $caption',
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 300
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.icon,
                              ),
                            ),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        _MetricText(
                          label: label,
                          value: value,
                          caption: caption,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (icon != null)
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.icon,
                              ),
                            ),
                            child: Icon(icon, color: color),
                          ),
                        if (icon != null) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MetricText(
                            label: label,
                            value: value,
                            caption: caption,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value, this.caption});
  final String label, value;
  final String? caption;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: AppSpacing.xs / 2),
      ReadableValueText(
        value: value,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      if (caption != null)
        Text(
          caption!,
          softWrap: true,
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ],
  );
}

/// Keeps the fractional cents and each thousands group together when money
/// needs more than one line at large text sizes.
class ReadableValueText extends StatelessWidget {
  const ReadableValueText({super.key, required this.value, this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final groups = value.split('.');
    if (!RegExp(r'^-?R\$ \d{1,3}(?:\.\d{3})+,\d{2}$').hasMatch(value)) {
      return Text(value, style: style);
    }
    return Semantics(
      label: value,
      child: ExcludeSemantics(
        child: Wrap(
          children: [
            for (var i = 0; i < groups.length; i++)
              Text(
                i < groups.length - 1 ? '${groups[i]}.' : groups[i],
                style: style,
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
