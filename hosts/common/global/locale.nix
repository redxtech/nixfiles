{ lib, ... }: {
  i18n = {
    defaultLocale = lib.mkDefault "en_CA.UTF-8";
    supportedLocales =
      lib.mkDefault [ "en_CA.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };
  time.timeZone = lib.mkDefault "America/Vancouver";
}
