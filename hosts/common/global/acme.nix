{ lib, ... }: {
  # Enable acme for usage with nginx vhosts
  security.acme = {
    defaults.email = "gabe@sent.at";
    acceptTerms = true;
  };
}
