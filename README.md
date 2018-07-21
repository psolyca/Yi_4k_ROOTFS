Repository of Yi 4k root filesystem.

The goal is to optimize / debug Yi 4k root filesystem.
Only Yi 4k (aka Z16V13L****)

ToDo :

  - debug wifi mode (ap/sta)
  - debug wifi freq (2,4/5GHz)

To get the root filesystem from a original firmware :

```
$wget https://github.com/psolyca/Xiaomi_Yi_4k_Camera/blob/unpacker/firmware_unpacker/amba_fwpak_yi.py
$./amba_fwpak_yi.py -x -f yourfirmware.bin
$mkdir rootfs
$unsquashfs firmwaresubfolder/_part_rfs.a9s rootfs/
```

You can modify your filesystem.

To get a modified firmware :

```
$mksquashfs rootfs/ firmwaresubfolder/_part_rfs.a9s -comp lzo -no-xattrs
$./amba_fwpack_yi.py -p -f yourmodifiedfirmware.bin -d firmwaresubfolder
```

**DO NOT USE THIS REPOSITORY AS-IS.**
Some special files are missing and files permission are not kept during git transfert.
A script is available to change permissions and owner but it is not completely tested for now.
Missing devices in dev folder.
