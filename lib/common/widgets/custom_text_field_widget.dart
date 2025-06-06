import 'package:country_code_picker/country_code_picker.dart';
import 'package:delivery_delivery/util/dimensions.dart';
import 'package:delivery_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_delivery/common/widgets/code_picker_widget.dart';

class CustomTextFieldWidget extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final bool isPassword;
  final Function? onChanged;
  final Function? onSubmit;
  final bool isEnabled;
  final int maxLines;
  final TextCapitalization capitalization;
  final IconData? prefixIcon;
  final bool divider;
  final bool showTitle;
  final String? prefixImage;
  final double prefixSize;
  final double iconSize;
  final bool isPhone;
  final String? countryDialCode;
  final Function(CountryCode countryCode)? onCountryChanged;
  final bool border;

  const CustomTextFieldWidget({
    super.key,
    this.hintText = 'Write something...',
    this.controller,
    this.focusNode,
    this.nextFocus,
    this.isEnabled = true,
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.maxLines = 1,
    this.onSubmit,
    this.onChanged,
    this.prefixIcon,
    this.capitalization = TextCapitalization.none,
    this.isPassword = false,
    this.divider = false,
    this.showTitle = false,
    this.prefixImage,
    this.prefixSize = Dimensions.paddingSizeSmall,
    this.iconSize = 18,
    this.isPhone = false,
    this.countryDialCode,
    this.onCountryChanged,
    this.border = true,
  });

  @override
  CustomTextFieldWidgetState createState() => CustomTextFieldWidgetState();
}

class CustomTextFieldWidgetState extends State<CustomTextFieldWidget> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      widget.showTitle ? Text(widget.hintText, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)) : const SizedBox(),
      SizedBox(height: widget.showTitle ? Dimensions.paddingSizeExtraSmall : 0),

      TextField(
        maxLines: widget.maxLines,
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
        textInputAction: widget.inputAction,
        keyboardType: widget.inputType,
        cursorColor: Theme.of(context).primaryColor,
        textCapitalization: widget.capitalization,
        enabled: widget.isEnabled,
        autofocus: false,
        obscureText: widget.isPassword ? _obscureText : false,
        inputFormatters: widget.inputType == TextInputType.phone ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[0-9+]'))] : null,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide(style: widget.border ? BorderStyle.solid : BorderStyle.none, width: 0.3, color: Theme.of(context).primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide(style: widget.border ? BorderStyle.solid : BorderStyle.none, width: 0.3, color: Theme.of(context).primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide(style: widget.border ? BorderStyle.solid : BorderStyle.none, width: 1, color: Theme.of(context).primaryColor),
          ),
          isDense: true,
          hintText: widget.hintText,
          fillColor: Theme.of(context).cardColor,
          hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).hintColor),
          filled: true,
          prefixIcon: widget.isPhone ? SizedBox(width: 95, child: Row(children: [
            Container(
              width: 85, height: 50,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusSmall),
                  bottomLeft: Radius.circular(Dimensions.radiusSmall),
                ),
              ),
              margin: const EdgeInsets.only(right: 0),
              padding: const EdgeInsets.only(left: 5),
              child: Center(
                child: CodePickerWidget(
                  backgroundColor: Theme.of(context).cardColor,
                  dialogBackgroundColor: Theme.of(context).cardColor,
                  flagWidth: 25,
                  padding: EdgeInsets.zero,
                  onChanged: widget.onCountryChanged,
                  initialSelection: widget.countryDialCode,
                  favorite: [widget.countryDialCode!],
                  enabled: false,
                  textStyle: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ),
            ),

            Container(
              height: 20, width: 2,
              color: Theme.of(context).disabledColor,
            )
          ])) : widget.prefixImage != null && widget.prefixIcon == null ? Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.prefixSize),
            child: Image.asset(widget.prefixImage!, height: 20, width: 20),
          ) : widget.prefixImage == null && widget.prefixIcon != null ? Icon(widget.prefixIcon, size: widget.iconSize) : null,
          suffixIcon: widget.isPassword ? IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).hintColor.withOpacity(0.3)),
            onPressed: _toggle,
          ) : null,
        ),
        onSubmitted: (text) => widget.nextFocus != null ? FocusScope.of(context).requestFocus(widget.nextFocus) : widget.onSubmit != null ? widget.onSubmit!(text) : null,
        onChanged: widget.onChanged as void Function(String)?,
      ),

      widget.divider ? const Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge), child: Divider()) : const SizedBox(),

    ]);
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
