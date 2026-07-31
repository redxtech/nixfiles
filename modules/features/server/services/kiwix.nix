{ self, ... }:

{
  den.aspects.kiwix.nixos =
    { host, ... }:
    {
      virtualisation.oci-containers.containers.kiwix = {
        image = "ghcr.io/kiwix/kiwix-serve:latest";
        labels = self.lib.containers.labels.mkHomepage {
          name = "kiwix";
          group = "media";
          icon = "kiwix.svg";
          href = "http://quasar:9060";
          desc = "offline encyclopedia";
          weight = -20;
        };
        volumes = [ "${host.settings.server.downloadsRoot}/deluge/zim:/data" ];
        ports = [ (self.lib.containers.mkPort 9060 8080) ];
        cmd = [
          "archlinux_en_all_maxi_2022-04.zim"
          "beer.stackexchange.com_en_all_2022-05.zim"
          "cooking.stackexchange.com_en_all_2022-05.zim"
          "cs.stackexchange.com_en_all_2021-04.zim"
          "developer.mozilla.org_en_all_2022-05.zim"
          "engineering.stackexchange.com_en_all_2022-05.zim"
          "explainxkcd_en_all_maxi_2021-03.zim"
          "the_infosphere_en_all_maxi_2022-01.zim"
          "movies.stackexchange.com_en_all_2022-05.zim"
          "musicfans.stackexchange.com_en_all_2022-05.zim"
          "openstreetmap-wiki_en_all_maxi_2021-03.zim"
          "programmers.stackexchange.com_en_all_2017-10.zim"
          "rationalwiki_en_all_maxi_2021-03.zim"
          "stackoverflow.com_en_all_2022-05.zim"
          "superuser.com_en_all_2022-05.zim"
          "sustainability.stackexchange.com_en_all_2022-05.zim"
          "unix.stackexchange.com_en_all_2022-05.zim"
          "vi.stackexchange.com_en_all_2022-05.zim"
          "wikibooks_en_all_maxi_2021-03.zim"
          "wikihow_en_maxi_2022-01.zim"
          "wikileaks_en_afghanistan-war-diary_2012-01.zim/wikileaks_en_afghanistan-war-diary_2012-01.zim"
          "wikipedia_en_all_maxi_2024-01.zim"
          "wikiquote_en_all_maxi_2022-05.zim"
          "wikisource_en_all_nopic_2022-05.zim"
          "wikisummaries_en_all_maxi_2021-04.zim"
          "wikiversity_en_all_maxi_2021-03.zim"
          "wikivoyage_en_all_maxi_2022-06.zim"
          "wiktionary_en_all_maxi_2022-02.zim"
        ];
      };
    };
}
