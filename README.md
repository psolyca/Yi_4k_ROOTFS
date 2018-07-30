# Repository of Yi 4k Linux filesystem #

The goal is to optimize / debug Yi 4k Linux filesystem.

**Only Yi 4k (aka Z16V13L****)

ToDo :

  - ~~debug wifi mode (ap/sta)~~ commit #[7e9382e](https://github.com/psolyca/Yi_4k_ROOTFS/commit/7e9382e556f670d2be3abeffc287ee5276b95c62)
  - debug wifi freq (2,4/5GHz)

Firmware releases proposed here are built from this repository as-is.

If your not sure of the binary file provided here, you can follow these steps to compare with original ones or make your own.

To get the Linux filesystem from a original firmware :

```
$wget https://github.com/psolyca/Xiaomi_Yi_4k_Camera/blob/unpacker/firmware_unpacker/amba_fwpak_yi.py
$./amba_fwpak_yi.py -x -f yourfirmware.bin
$mkdir rootfs
$unsquashfs firmwaresubfolder/_part_rfs.a9s rootfs/
```

You can modify your filesystem or compare versions.

To get a modified firmware :

```
$mksquashfs rootfs/ firmwaresubfolder/_part_rfs.a9s -comp lzo -no-xattrs
$./amba_fwpack_yi.py -p -f yourmodifiedfirmware.bin -d firmwaresubfolder
```

**DO NOT USE THIS REPOSITORY AS-IS.**
Some special files are missing and files permission are not kept during git transfers.

The script ```build.sh``` is available to add missing folders, change permissions and ownership before building the filesystem.
This script has been tested... so many times, no reason it will break your cam.

By the way, if an update is not going to the end, follow instruction [here](https://www.youtube.com/watch?v=tZnC3hgPUqI)

