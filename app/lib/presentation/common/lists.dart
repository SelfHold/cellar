import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';

/// Round avatar: initials (or an icon) in a tint of [color], with an
/// optional marker in the corner (the provider of a chat).
class HmAvatar extends StatelessWidget {
  const HmAvatar({super.key, required this.label, this.icon, this.color = HmColors.accent, this.size = 36, this.corner, this.image, this.online = false, this.showOffline = false});

  final String label;
  final IconData? icon;

  /// A photo over the initials, once it is loaded.
  final ImageProvider? image;
  final Color color;
  final double size;
  final Widget? corner;

  /// The person is online: a green dot at the top right.
  final bool online;

  /// When not [online], a grey dot instead of none.
  final bool showOffline;

  static String initials(String s) {
    final words = s.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words.first.characters.first;
    return (words.length > 1 ? first + words[1].characters.first : first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HmColors.tint(color, HmColors.badge),
        border: Border.all(color: HmColors.tint(color, HmColors.ring)),
      ),
      child: icon != null ? Icon(icon, size: size * 0.45, color: color) : Text(initials(label), style: HmText.jb(size * 0.36, weight: 700, color: color)),
    );
    final face = image == null
        ? circle
        : Stack(
            children: [
              circle,
              ClipOval(
                child: Image(
                  image: image!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          );
    final marked = online || showOffline;
    if (corner == null && !marked) return face;
    final dot = (size * 0.28).clamp(9.0, 14.0);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          face,
          if (corner != null) Positioned(right: -3, bottom: -3, child: corner!),
          if (marked)
            Positioned(
              right: -1,
              top: -1,
              child: Semantics(
                label: online ? tr('online', 'в сети') : tr('offline', 'не в сети'),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: online ? HmColors.ok : HmColors.paused,
                    border: Border.all(color: HmColors.surface, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small round marker for [HmAvatar.corner]: an icon on the surface.
class HmMarker extends StatelessWidget {
  const HmMarker({super.key, required this.icon, required this.color, this.tooltip});

  final IconData icon;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final m = Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: HmColors.surface,
        border: Border.all(color: HmColors.tint(color, HmColors.ring)),
      ),
      child: Icon(icon, size: 9, color: color),
    );
    return tooltip == null ? m : Tooltip(message: tooltip!, child: m);
  }
}

/// Unread counter. Muted chats get a grey one.
class HmCount extends StatelessWidget {
  const HmCount(this.count, {super.key, this.muted = false});

  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: muted ? HmColors.tint(HmColors.paused, 0.4) : HmColors.accent, borderRadius: BorderRadius.circular(10)),
      child: Text(count > 999 ? '999+' : '$count', style: HmText.badge.copyWith(color: muted ? HmColors.text : HmColors.onAccent)),
    );
  }
}

/// A row of a list (chats, accounts): hover and selection tints, a 2 px
/// accent bar on the selected one. [meta] sits right of the title,
/// [trailing] right of the subtitle.
class HmListItem extends StatefulWidget {
  const HmListItem({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.meta,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.dense = false,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? meta;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// One line (folders, calendars in a side panel): [trailing] sits right
  /// of the title; no subtitle or meta.
  final bool dense;

  @override
  State<HmListItem> createState() => _HmListItemState();
}

class _HmListItemState extends State<HmListItem> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final bg = widget.selected ? HmColors.tint(HmColors.accent, 0.08) : (_hot ? HmColors.tint(HmColors.text, HmColors.subtle) : Colors.transparent);
    return Semantics(
      button: widget.onTap != null,
      selected: widget.selected,
      child: MouseRegion(
        cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap == null
              ? null
              : () {
                  if (hm.mobile) HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(minHeight: widget.dense ? (hm.mobile ? 44 : 34) : (hm.mobile ? 64 : 56)),
            padding: EdgeInsets.symmetric(horizontal: hm.mobile ? 16 : 14, vertical: widget.dense ? 4 : 10),
            decoration: BoxDecoration(
              color: bg,
              border: Border(left: BorderSide(color: widget.selected ? HmColors.accent : Colors.transparent, width: 2)),
            ),
            child: Row(
              children: [
                if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 12)],
                if (widget.dense) ...[
                  Expanded(
                    child: DefaultTextStyle(style: HmText.body, maxLines: 1, overflow: TextOverflow.ellipsis, child: widget.title),
                  ),
                  if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
                ] else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DefaultTextStyle(style: HmText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis, child: widget.title),
                            ),
                            if (widget.meta != null) ...[const SizedBox(width: 8), DefaultTextStyle(style: HmText.footer, child: widget.meta!)],
                          ],
                        ),
                        if (widget.subtitle != null || widget.trailing != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: DefaultTextStyle(
                                  style: HmText.small,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: widget.subtitle ?? const SizedBox.shrink(),
                                ),
                              ),
                              if (widget.trailing != null) ...[const SizedBox(width: 8), widget.trailing!],
                            ],
                          ),
                        ],
                      ],
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

/// A filter chip (the account strip above the chat list on phones).
class HmChip extends StatelessWidget {
  const HmChip({super.key, required this.label, required this.active, required this.onTap, this.leading, this.count = 0});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget? leading;
  final int count;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return Semantics(
      button: true,
      selected: active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: hm.buttonSm,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active ? HmColors.tint(HmColors.accent, HmColors.resting) : Colors.transparent,
              borderRadius: BorderRadius.circular(hm.buttonSm / 2),
              border: Border.all(color: active ? HmColors.tint(HmColors.accent, HmColors.ring) : HmColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Text(label, style: HmText.button.copyWith(color: active ? HmColors.accent : HmColors.muted)),
                if (count > 0) ...[const SizedBox(width: 6), HmCount(count)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A heading between groups of a list (chat list sections).
class HmListHeader extends StatelessWidget {
  const HmListHeader(this.label, {super.key, this.count = 0, this.collapsed, this.onTap});

  final String label;
  final int count;

  /// Non-null: the group folds; an arrow shows its state.
  final bool? collapsed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(hm.mobile ? 16 : 14, 12, 12, 6),
          child: Row(
            children: [
              if (collapsed != null) ...[Icon(collapsed! ? Icons.chevron_right : Icons.expand_more, size: 14, color: HmColors.muted), const SizedBox(width: 4)],
              Expanded(child: Text(label.toUpperCase(), style: HmText.sectionTitle)),
              HmCount(count, muted: true),
            ],
          ),
        ),
      ),
    );
  }
}
