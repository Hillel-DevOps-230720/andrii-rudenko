# Decrease the size of EBS root volume t2.micro

```bash
lsblk

NAME     MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0      7:0    0  24.4M  1 loop /snap/amazon-ssm-agent/6312
loop1      7:1    0  55.6M  1 loop /snap/core18/2745
loop2      7:2    0  63.3M  1 loop /snap/core20/1879
loop3      7:3    0 111.9M  1 loop /snap/lxd/24322
loop4      7:4    0  53.2M  1 loop /snap/snapd/19122
xvda     202:0    0     8G  0 disk
├─xvda1  202:1    0   7.9G  0 part /
├─xvda14 202:14   0     4M  0 part
└─xvda15 202:15   0   106M  0 part /boot/efi
xvdf     202:80   0     8G  0 disk
├─xvdf1  202:81   0   7.9G  0 part
├─xvdf14 202:94   0     4M  0 part
└─xvdf15 202:95   0   106M  0 part
xvdg     202:96   0     4G  0 disk

sudo fdisk /dev/xvdf

Disk /dev/xvdf: 8 GiB, 8589934592 bytes, 16777216 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 1D8CDFAF-5C13-49B4-AD13-5DBDDECD97FE

Device       Start      End  Sectors  Size Type
/dev/xvdf1  227328 16777182 16549855  7.9G Linux filesystem
/dev/xvdf14   2048    10239     8192    4M BIOS boot
/dev/xvdf15  10240   227327   217088  106M EFI System

sudo dd bs=16M if=/dev/xvdf of=/dev/xvdg count=100

sudo gdisk /dev/xvdg
Command (? for help): p
Command (? for help): d
Command (? for help): w

sudo gdisk /dev/xvdg
Command (? for help): n
Command (? for help): w

sudo gdisk /dev/xvdg

Disk /dev/xvdg: 8388608 sectors, 4.0 GiB
Sector size (logical/physical): 512/512 bytes
Disk identifier (GUID): 1D8CDFAF-5C13-49B4-AD13-5DBDDECD97FE
Partition table holds up to 128 entries
Main partition table begins at sector 2 and ends at sector 33
First usable sector is 34, last usable sector is 8388574
Partitions will be aligned on 2048-sector boundaries
Total free space is 2014 sectors (1007.0 KiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   1          227328         8388574   3.9 GiB     8300  Linux filesystem
  14            2048           10239   4.0 MiB     EF02
  15           10240          227327   106.0 MiB   EF00

sudo e2fsck -f /dev/xvdf1

sudo resize2fs -M -p /dev/xvdf1
resize2fs 1.46.5 (30-Dec-2021)
Resizing the filesystem on /dev/xvdf1 to 712322 (4k) blocks.
Begin pass 2 (max = 204)
Relocating blocks             XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Begin pass 3 (max = 64)
Scanning inode table          XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Begin pass 4 (max = 8177)
Updating inode references     XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
The filesystem on /dev/xvdf1 is now 712322 (4k) blocks long.

(712322 * 4) / (16 * 1024) = 712322 / 4096 = 173.906... = 180

sudo dd bs=16M if=/dev/xvdf1 of=/dev/xvdg1 count=180

sudo resize2fs -M -p /dev/xvdg1

sudo e2fsck -f /dev/xvdg1

sudo gdisk /dev/xvdf
Command (? for help): i
Partition number (1-15): 1
Partition GUID code: 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux filesystem)
Partition unique GUID: 0F687D73-F2AA-4143-B9BE-B065FA2D72DE
First sector: 227328 (at 111.0 MiB)
Last sector: 16777182 (at 8.0 GiB)
Partition size: 16549855 sectors (7.9 GiB)
Attribute flags: 0000000000000000
Partition name: ''

sudo gdisk /dev/xvdg

Command (? for help): x
Command (? for help): x
Command (? for help): c
0F687D73-F2AA-4143-B9BE-B065FA2D72DE
Command (? for help): w

sudo gdisk /dev/xvdg

Command (? for help): i
Partition number (1-15): 1
Partition GUID code: 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux filesystem)
Partition unique GUID: 0F687D73-F2AA-4143-B9BE-B065FA2D72DE
First sector: 227328 (at 111.0 MiB)
Last sector: 8388574 (at 4.0 GiB)
Partition size: 8161247 sectors (3.9 GiB)
Attribute flags: 0000000000000000
Partition name: 'Linux filesystem'

Ubuntu 22 Gold root volume

lsblk

NAME     MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0      7:0    0  24.4M  1 loop /snap/amazon-ssm-agent/6312
loop1      7:1    0  55.6M  1 loop /snap/core18/2745
loop2      7:2    0  63.3M  1 loop /snap/core20/1879
loop3      7:3    0 111.9M  1 loop /snap/lxd/24322
loop4      7:4    0  53.2M  1 loop /snap/snapd/19122
xvda     202:0    0     4G  0 disk
├─xvda1  202:1    0   3.9G  0 part /
├─xvda14 202:14   0     4M  0 part
└─xvda15 202:15   0   106M  0 part /boot/efi

df -h

Filesystem      Size  Used Avail Use% Mounted on
/dev/root       3.7G  1.6G  2.2G  43% /
tmpfs           483M     0  483M   0% /dev/shm
tmpfs           194M  820K  193M   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/xvda15     105M  6.1M   99M   6% /boot/efi
tmpfs            97M  4.0K   97M   1% /run/user/1000
```
