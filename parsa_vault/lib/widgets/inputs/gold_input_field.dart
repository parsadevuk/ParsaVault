import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class GoldInputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final String? suffixText;
  final Widget? suffixIcon;
  final bool optional;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;

  const GoldInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.prefixText,
    this.suffixText,
    this.suffixIcon,
    this.optional = false,
    this.focusNode,
    this.onEditingComplete,
    this.onChanged,
  });

  @override
  State<GoldInputField> createState() => _GoldInputFieldState();
}

class _GoldInputFieldState extends State<GoldInputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: AppTextStyles.label),
            if (widget.optional) ...[
              const SizedBox(width: 6),
              Text('(optional)',
                  style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: isPassword ? _obscure : false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          onEditingComplete: widget.onEditingComplete,
          onChanged: widget.onChanged,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.inputPlaceholder,
            prefixText: widget.prefixText,
            prefixStyle: AppTextStyles.label
                .copyWith(color: AppColors.mediumGrey),
            suffixText: widget.suffixText,
            suffixStyle: AppTextStyles.caption,
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: _obscure
                          ? AppColors.mediumGrey
                          : AppColors.gold,
                      size: 20,
                    ),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}
