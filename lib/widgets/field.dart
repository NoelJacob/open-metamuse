import 'package:material_ui/material_ui.dart';

enum MuseFieldVariant { filled, bare }

class MuseField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final EdgeInsetsGeometry? contentPadding;
  final ValueChanged<String>? onChanged;
  final MuseFieldVariant variant;
  const MuseField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.keyboardType,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.contentPadding,
    this.onChanged,
    this.variant = MuseFieldVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: style,
      textAlign: textAlign,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        filled: variant == MuseFieldVariant.filled,
        fillColor: cs.surfaceContainerHigh,
        contentPadding:
            contentPadding ?? const EdgeInsets.symmetric(horizontal: 20),
        border: variant == MuseFieldVariant.filled
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              )
            : InputBorder.none,
        focusedBorder: variant == MuseFieldVariant.filled
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              )
            : InputBorder.none,
      ),
    );
  }
}
