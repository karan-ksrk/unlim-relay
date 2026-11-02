import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Rounded gradient badge used as the in-app brand mark.
class LumaMark extends StatelessWidget {
  const LumaMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LumaColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.sync_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}
