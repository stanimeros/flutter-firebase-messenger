import 'app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
  }) : assert(title == null || titleWidget == null, 'Cannot provide both title and titleWidget');

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.darkBackground,
      foregroundColor: Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: const HeroIcon(
                    HeroIcons.arrowLeft,
                    style: HeroIconStyle.outline,
                    color: Colors.white,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : SizedBox.shrink()),
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null),
      centerTitle: false,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

