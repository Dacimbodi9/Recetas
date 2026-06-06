import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:recetas/l10n.dart';
import 'package:recetas/models/models.dart';
import 'package:recetas/services/recipe_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';



class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.selectedIngredients});

  final List<String> selectedIngredients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle, size: 42)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: -4,
                end: 4,
                duration: 2500.ms,
                curve: Curves.easeInOut,
              ),
          SizedBox(height: 12),
          Text(
            'No existen recetas'.tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Se intentÃ³ con: ${selectedIngredients.join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class NutritionFactCard extends StatelessWidget {
  const NutritionFactCard({super.key, required this.fact});

  final NutritionFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fact.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '${fact.formattedAmount} ${fact.unit}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SlidingSegmentedControl extends StatelessWidget {
  const SlidingSegmentedControl({super.key, 
    required this.controller,
    required this.selectedIndex,
    required this.onTap,
    required this.tabs,
  });

  final PageController controller;
  final int selectedIndex;
  final Function(int) onTap;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              // Animated Background Indicator
              AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  // If controller not attached yet (initially), use selectedIndex
                  final double page = controller.hasClients
                      ? (controller.page ?? selectedIndex.toDouble())
                      : selectedIndex.toDouble();
                  final double left = page * tabWidth;

                  return Positioned(
                    left: left,
                    top: 4,
                    bottom: 4,
                    width: tabWidth,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Text Labels
              Row(
                children: List.generate(tabs.length, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior
                          .translucent, // Ensure tap targets whole area
                      child: Center(
                        child: AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            final double page = controller.hasClients
                                ? (controller.page ?? selectedIndex.toDouble())
                                : selectedIndex.toDouble();
                            // Calculate opacity/color based on distance from current page
                            final double distance = (page - index).abs();
                            final bool isSelected = distance < 0.5;

                            return Text(
                              tabs[index],
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LikeButton extends StatefulWidget {
  const LikeButton({super.key, required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  State<LikeButton> createState() => LikeButtonState();
}

class LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite && !oldWidget.isFavorite) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          widget.isFavorite
              ? CupertinoIcons.bookmark_fill
              : CupertinoIcons.bookmark,
          color: widget.isFavorite ? Colors.amber : null,
        ),
        onPressed: () {
          // Trigger animation if turning ON, or just toggle
          // The parent handles the state change, so we rely on didUpdateWidget for the 'filling' animation.
          // But we can also animate on tap for immediate feedback.
          // If we want a "pop" effect on both check/uncheck, we can run it.
          // Usually hearts pop when filled.
          if (!widget.isFavorite) {
            HapticFeedback.mediumImpact();
            _controller.forward(from: 0.0);
          }
          widget.onTap();
        },
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsSection({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
            child: Text(
              title!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? theme.cardColor
                : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: theme.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool lastItem;

  const SettingsTile({super.key, 
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.textColor,
    this.trailing,
    this.onTap,
    this.isSwitch = false,
    this.switchValue = false,
    this.onSwitchChanged,
    this.lastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    if (isSwitch) {
      return Column(
        children: [
          SwitchListTile(
            title: Text(
              title,
              style: TextStyle(
                color: textColor ?? theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  )
                : null,
            value: switchValue,
            onChanged: onSwitchChanged,
            secondary: icon != null
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 18),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            activeThumbColor: theme.colorScheme.primary,
          ),
          if (!lastItem)
            Divider(
              height: 1,
              indent: 56,
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
        ],
      );
    } else {
      return Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: TextStyle(
                color: textColor ?? theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  )
                : null,
            leading: icon != null
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 18),
                  )
                : null,
            trailing: trailing,
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
          ),
          if (!lastItem)
            Divider(
              height: 1,
              indent: 56,
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
        ],
      );
    }
  }
}

class PartialStar extends StatelessWidget {
  const PartialStar({super.key, required this.filledPercentage, required this.size});

  final double filledPercentage;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(
          Icons.star_rounded,
          color: Colors.grey.withValues(alpha: 0.3),
          size: size,
        ),
        if (filledPercentage > 0)
          ClipRect(
            clipper: StarClipper(filledPercentage),
            child: Icon(Icons.star_rounded, color: Colors.amber, size: size),
          ),
      ],
    );
  }
}

class StarClipper extends CustomClipper<Rect> {
  final double percentage;

  StarClipper(this.percentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * percentage, size.height);
  }

  @override
  bool shouldReclip(covariant StarClipper oldClipper) {
    return oldClipper.percentage != percentage;
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key, 
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child:
          Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 48,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .moveY(
                          begin: -4,
                          end: 4,
                          duration: 2500.ms,
                          curve: Curves.easeInOut,
                        ),
                    SizedBox(height: 24),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (action != null) ...[
                      SizedBox(height: 24),
                      action!,
                    ],
                  ],
                ),
              )
              .animate()
              .fade(duration: 500.ms)
              .scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
    );
  }
}

class LegalContent extends StatelessWidget {
  const LegalContent({super.key, required this.isPrivacy});

  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    final text = isPrivacy ? 'legal_privacy'.tr : 'legal_tos'.tr;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

// ---------------------------------------------------------------------------
// RATING WIDGETS
// ---------------------------------------------------------------------------

class InteractiveStarRating extends StatelessWidget {
  final double rating;
  final double starSize;
  final ValueChanged<double> onRatingChanged;

  const InteractiveStarRating({super.key, 
    required this.rating,
    required this.starSize,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapUp: (details) {
            final width = starSize;
            final dx = details.localPosition.dx;
            double newRating = index + (dx < width / 2 ? 0.5 : 1.0);
            if (newRating != rating) HapticFeedback.selectionClick();
            onRatingChanged(newRating);
          },
          child: Icon(_getIcon(index), size: starSize, color: Colors.amber),
        );
      }),
    );
  }

  IconData _getIcon(int index) {
    if (rating >= index + 1) return Icons.star_rounded;
    if (rating >= index + 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }
}

class PremiumRatingButton extends StatelessWidget {
  final Recipe recipe;

  const PremiumRatingButton({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = recipe.rating ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu valoraciÃ³n'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                rating > 0 ? rating.toStringAsFixed(1) : 'Sin valorar'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Center(
            child: InteractiveStarRating(
              rating: rating,
              starSize: 42,
              onRatingChanged: (val) {
                if (val == rating) {
                  RecipeManager.rateRecipe(recipe, 0.0);
                } else {
                  RecipeManager.rateRecipe(recipe, val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Onboarding Flow ---



class SkeletonRecipeCard extends StatelessWidget {
  const SkeletonRecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white12 : Colors.grey[300]!,
      highlightColor: isDark ? Colors.white24 : Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white12 : Colors.grey[300]!,
      highlightColor: isDark ? Colors.white24 : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
