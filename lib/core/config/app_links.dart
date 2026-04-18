class AppLinks {
  static const mobileScheme = 'xillafit';

  static const backendApiUrl = String.fromEnvironment(
    'XILLAFIT_API_URL',
    defaultValue: 'https://server.xillafit.com/api/v1/',
  );

  static const customizeUrl = String.fromEnvironment(
    'XILLAFIT_CUSTOMIZE_URL',
    defaultValue: 'https://xillafit.com/customize',
  );

  static const siteUrl = String.fromEnvironment(
    'XILLAFIT_SITE_URL',
    defaultValue: 'https://xillafit.com',
  );

  static const legacyAuthRedirectHost = String.fromEnvironment(
    'XILLAFIT_AUTH_HOST',
    defaultValue: 'login-callback',
  );

  static const authHost = 'auth';
  static const paymentHost = 'payment';
  static const customizerHost = 'customizer';
  static const authCallbackPath = '/callback';
  static const paymentSuccessPath = '/success';
  static const paymentCancelPath = '/cancel';
  static const customizerCompletePath = '/complete';
  static const customizerCancelPath = '/cancel';
  static const paymentBridgePath = '/mobile-payment-callback';
  static const authBridgePath = '/mobile-auth-callback';

  static const googleAuthRedirectUrl =
      '$mobileScheme://$legacyAuthRedirectHost';

  static String authCallbackUrl({
    Map<String, String>? queryParameters,
  }) {
    return Uri(
      scheme: mobileScheme,
      host: authHost,
      path: authCallbackPath,
      queryParameters: queryParameters,
    ).toString();
  }

  static String paymentCallbackUrl({
    required bool success,
    String? flow,
    String? orderId,
    String? referenceId,
  }) {
    final query = <String, String>{
      'success': success ? 'true' : 'false',
      if ((flow ?? '').trim().isNotEmpty) 'flow': flow!.trim(),
      if ((orderId ?? '').trim().isNotEmpty) 'orderId': orderId!.trim(),
      if ((referenceId ?? '').trim().isNotEmpty)
        'referenceId': referenceId!.trim(),
    };

    return Uri(
      scheme: mobileScheme,
      host: paymentHost,
      path: success ? paymentSuccessPath : paymentCancelPath,
      queryParameters: query,
    ).toString();
  }

  static String paymentBridgeUrl({
    required bool success,
    String? flow,
    String? orderId,
    String? referenceId,
  }) {
    return Uri.parse(siteUrl).replace(
      path: paymentBridgePath,
      queryParameters: <String, String>{
        'success': success ? 'true' : 'false',
        if ((flow ?? '').trim().isNotEmpty) 'flow': flow!.trim(),
        if ((orderId ?? '').trim().isNotEmpty) 'orderId': orderId!.trim(),
        if ((referenceId ?? '').trim().isNotEmpty)
          'referenceId': referenceId!.trim(),
      },
    ).toString();
  }

  static String authBridgeUrl({Map<String, String>? queryParameters}) {
    return Uri.parse(siteUrl).replace(
      path: authBridgePath,
      queryParameters: queryParameters,
    ).toString();
  }

  static String customizerCallbackUrl({
    required bool saved,
    String? productId,
  }) {
    return Uri(
      scheme: mobileScheme,
      host: customizerHost,
      path: saved ? customizerCompletePath : customizerCancelPath,
      queryParameters: <String, String>{
        if ((productId ?? '').trim().isNotEmpty) 'productId': productId!.trim(),
      },
    ).toString();
  }

  const AppLinks._();
}
