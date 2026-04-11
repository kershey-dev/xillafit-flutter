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

  const AppLinks._();
}
