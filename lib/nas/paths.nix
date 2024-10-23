{ lib, ... }:

paths:
with paths; {
  mkConf = name: config + "/" + name + ":/config";
  mkData = name: data + "/" + name + ":/data";
  mkDl = name: downloads + "/" + name + ":/downloads";
  downloads = downloads + ":/downloads";
  media = media + ":/media";
}
