import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/utilities/const.dart';

class Menu {
  final List<MenuAction> children;

  Menu({required this.children});
}

class MenuAction {
  final String title;
  final VoidCallback callback;

  MenuAction({required this.title, required this.callback});
}

typedef MenuProvider = Menu? Function(BuildContext context);

class ContextMenuWidget extends StatelessWidget {
  final Widget child;
  final MenuProvider menuProvider;

  const ContextMenuWidget({
    super.key,
    required this.child,
    required this.menuProvider,
  });

  Future<void> _showMenu(BuildContext context, Offset globalPosition) async {
    final menu = menuProvider(context);
    if (menu == null || menu.children.isEmpty) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      elevation: 3,
      surfaceTintColor: Colors.white,
      shadowColor: cLightIcon.withValues(alpha: 0.3),
      // padding: const EdgeInsets.all(20),
      shape: const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
      items: menu.children
          .asMap()
          .entries
          .map(
            (entry) => PopupMenuItem<int>(
              value: entry.key,
              child: Text(
                entry.value.title,
                style: MyTextStyle.gilroyRegular(color: cDarkText),
              ),
            ),
          )
          .toList(),
    );

    if (selected != null) {
      menu.children[selected].callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        // Save the tap position for longPress
        final tapPosition = details.globalPosition;
        // Wait for longPress
        GestureDetector(
          onLongPress: () => _showMenu(context, tapPosition),
        );
      },
      onLongPressStart: (details) {
        _showMenu(context, details.globalPosition);
      },
      child: child,
    );
  }
}
