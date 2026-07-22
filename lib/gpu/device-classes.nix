# source: https://kernel.googlesource.com/pub/scm/utils/pciutils/pciutils/+/a9df1d1baccbafcd1f4bd7622dd20d3ea684fb75/pci.ids
# https://pci-ids.ucw.cz/

{ lib, ... }:

let
  # TODO: add a lot more devices to this list
  data = {
    discrete = [
      {
        # AMD Navi 33 [Radeon RX 7700S/7600/7600S/7600M XT/PRO W7600]
        vendor = "1002";
        device = "7480";
      }
      {
        # AMD Navi 31 [Radeon RX 7900 XT/7900 XTX/7900M]
        vendor = "1002";
        device = "744c";
      }
    ];

    integrated = [
      {
        # AMD Phoenix1
        vendor = "1002";
        device = "15bf";
      }
      {
        # Intel HD Graphics 530
        vendor = "8086";
        device = "1912";
      }
    ];
  };
in
{
  # returns a list of devices in the given class
  devicesInClass =
    class: facterReport:
    lib.filter (
      device:
      lib.any (
        classDevice: device.vendor.hex == classDevice.vendor && device.device.hex == classDevice.device
      ) data.${class}
    ) facterReport.hardware.graphics_card;
}
