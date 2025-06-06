import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:delivery_delivery/features/auth/controllers/auth_controller.dart';
import 'package:delivery_delivery/helper/route_helper.dart';
import 'package:delivery_delivery/util/dimensions.dart';
import 'package:delivery_delivery/util/styles.dart';

class ConditionCheckBoxWidget extends StatelessWidget {
  final AuthController authController;
  final bool fromSignUp;
  const ConditionCheckBoxWidget({super.key, required this.authController, this.fromSignUp = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: fromSignUp ? MainAxisAlignment.start : MainAxisAlignment.center, children: [

      fromSignUp ? Checkbox(
        activeColor: Theme.of(context).primaryColor,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        value: authController.acceptTerms,
        onChanged: (bool? isChecked) => authController.toggleTerms(),
      ) : const SizedBox(),

      fromSignUp ? const SizedBox() : const Text( '*', style: robotoRegular),
      Text('by_login_i_agree_with_all_the'.tr, style: robotoRegular.copyWith(color: fromSignUp ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).hintColor)),

      Flexible(
        child: InkWell(
          onTap: () => Get.toNamed(RouteHelper.getTermsRoute()),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Text('terms_conditions'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
          ),
        ),
      ),
    ]);
  }
}
