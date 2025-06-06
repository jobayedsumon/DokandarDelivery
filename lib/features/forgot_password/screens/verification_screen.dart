import 'dart:async';
import 'package:delivery_delivery/features/splash/controllers/splash_controller.dart';
import 'package:delivery_delivery/features/forgot_password/controllers/forgot_password_controller.dart';
import 'package:delivery_delivery/helper/route_helper.dart';
import 'package:delivery_delivery/util/dimensions.dart';
import 'package:delivery_delivery/util/styles.dart';
import 'package:delivery_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:delivery_delivery/common/widgets/custom_button_widget.dart';
import 'package:delivery_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerificationScreen extends StatefulWidget {
  final String? number;
  const VerificationScreen({super.key, required this.number});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  String? _number;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();

    _number = widget.number!.startsWith('+') ? widget.number : '+${widget.number!.substring(1, widget.number!.length)}';
    _startTimer();
  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds - 1;
      if(_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CustomAppBarWidget(title: 'otp_verification'.tr),

      body: SafeArea(child: Center(child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Center(child: SizedBox(width: 1170, child: GetBuilder<ForgotPasswordController>(builder: (forgotPasswordController) {
          return Column(children: [

            Get.find<SplashController>().configModel!.demo! ? Text(
              'for_demo_purpose'.tr, style: robotoRegular,
            ) : RichText(text: TextSpan(children: [
              TextSpan(text: 'enter_the_verification_sent_to'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
              TextSpan(text: ' $_number', style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
            ])),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 39, vertical: 35),
              child: PinCodeTextField(
                length: 4,
                appContext: context,
                keyboardType: TextInputType.number,
                animationType: AnimationType.slide,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  fieldHeight: 60,
                  fieldWidth: 60,
                  borderWidth: 1,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Theme.of(context).disabledColor.withOpacity(0.2),
                  inactiveColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  activeColor: Theme.of(context).primaryColor.withOpacity(0.4),
                  activeFillColor: Theme.of(context).disabledColor.withOpacity(0.2),
                ),
                animationDuration: const Duration(milliseconds: 300),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,
                onChanged: forgotPasswordController.updateVerificationCode,
                beforeTextPaste: (text) => true,
              ),
            ),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [

              Text(
                'did_not_receive_the_code'.tr,
                style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
              ),

              TextButton(
                onPressed: _seconds < 1 ? () {
                  forgotPasswordController.forgetPassword(widget.number).then((value) {
                    if (value.isSuccess) {
                      showCustomSnackBar('resend_code_successful'.tr, isError: false);
                    } else {
                      showCustomSnackBar(value.message);
                    }
                  });
                } : null,
                child: Text('${'resend'.tr}${_seconds > 0 ? ' ($_seconds)' : ''}'),
              ),

            ]),

            forgotPasswordController.verificationCode.length == 4 ? !forgotPasswordController.isLoading ? CustomButtonWidget(
              buttonText: 'verify'.tr,
              onPressed: () {
                forgotPasswordController.verifyToken(_number).then((value) {
                  if(value.isSuccess) {
                    Get.toNamed(RouteHelper.getResetPasswordRoute(_number, forgotPasswordController.verificationCode, 'reset-password'));
                  }else {
                    showCustomSnackBar(value.message);
                  }
                });
              },
            ) : const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),

          ]);
        }))),
      ))),
    );
  }
}
