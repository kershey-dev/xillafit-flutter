class AppLinks {
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

  static const authRedirectScheme = String.fromEnvironment(
    'XILLAFIT_AUTH_SCHEME',
    defaultValue: 'xillafit',
  );

  static const authRedirectHost = String.fromEnvironment(
    'XILLAFIT_AUTH_HOST',
    defaultValue: 'login-callback',
  );

  static const googleAuthRedirectUrl =
      '$authRedirectScheme://$authRedirectHost';

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
      scheme: authRedirectScheme,
      host: authRedirectHost,
      path: '/payment',
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
      path: '/mobile-payment-callback',
      queryParameters: <String, String>{
        'success': success ? 'true' : 'false',
        if ((flow ?? '').trim().isNotEmpty) 'flow': flow!.trim(),
        if ((orderId ?? '').trim().isNotEmpty) 'orderId': orderId!.trim(),
        if ((referenceId ?? '').trim().isNotEmpty)
          'referenceId': referenceId!.trim(),
      },
    ).toString();
  }

  const AppLinks._();
}
