import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 14,
    this.label,
  });
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppTheme.surface,
      alignment: Alignment.center,
      child: const Icon(Icons.live_tv_rounded, color: AppTheme.muted, size: 34),
    );
    return Semantics(
      label: label,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: url == null || url!.isEmpty
              ? placeholder
              : Image.network(
                  url!,
                  fit: fit,
                  errorBuilder: (_, error, stack) => placeholder,
                  frameBuilder: (_, child, frame, loadedSynchronously) =>
                      loadedSynchronously || frame != null
                      ? child
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            placeholder,
                            const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
        ),
      ),
    );
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.action,
    this.actionLabel = 'Try again',
    this.illustration,
  });
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? action;
  final String actionLabel;
  final Widget? illustration;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration ??
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 50, color: AppTheme.purple),
              ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, height: 1.6),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: action, child: Text(actionLabel)),
          ],
        ],
      ),
    ),
  );
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});
  final double? rating;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star_rounded, color: Color(0xFFFFD16B), size: 16),
      const SizedBox(width: 4),
      Text(
        rating?.toStringAsFixed(1) ?? 'NR',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ],
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 24),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1050),
      child: child,
    ),
  );
}
