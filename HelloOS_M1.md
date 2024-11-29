在M1主机上安装软件：

- Docker：用于创建和运行 x86 容器，可以在官网下载安装包。
- QEMU：模拟完整的 x86 虚拟机，加载和运行内核

#### **1. 准备主机目录**

1. 确保主机当前目录是你的项目目录（自己创建一个文件夹），例如：

   ```bash
   cd /Users/xxx/Documents/projects/os
   ```

   1. 启动容器，并挂载主机目录到 `/workdir`，将容器的 `/workdir` 和主机的`os` 目录内容同步：

   ```bash
   docker run --rm -it --platform linux/amd64 --privileged -v "$(pwd)":/workdir ubuntu:20.04
   
   # 需要加--privileged
   # 我使用的ubuntu 20.04，之前使用最新版，但parte用不了
   # M1 的 Docker 默认运行 ARM 架构容器，这里通过指定 `--platform` 运行 x86 架构的 Ubuntu 系统，为后续操作提供环境。
   ```

------

#### **2. 安装必要工具**

进入 Docker 容器后，安装分区和 GRUB 所需工具：

```bash
apt-get update && apt-get install -y parted grub2 file udev

# 每次安装要先更新容器内的软件包索引
# parted：用于分区磁盘。
# grub2：安装引导加载程序。
# file：用于检查文件系统类型。
```

**验证**

```bash
parted --version
grub-install --version
file --version

parted (GNU parted) 3.3
grub-install (GRUB) 2.04-1ubuntu26.17
file-5.38
```

------

#### **3. 确保进入 `/workdir`**

所有后续操作都必须在 `/workdir` 目录下进行。

```bash
cd /workdir
```

------

#### **4. 创建磁盘镜像**

在 `/workdir` 中创建一个 32MB 的磁盘镜像文件 `disk.img` 来存储文件系统和引导程序（GRUB）, 后续所有分区和文件系统的操作都基于这个镜像文件, 主机也是运行disk.img：

```bash
dd if=/dev/zero of=disk.img bs=512 count=$((32 * 1024 * 1024 / 512))

# 创建一个 32MB 的空白二进制文件，用作虚拟硬盘，初始内容全是 0。
# bs=512：块大小为 512B。
# count=...：总大小为 32MB。
```

**验证：**

```bash
# 可随时用这个命令在主机和磁盘中验证时间，主机是否更新disk.img
ls -lh disk.img

# 输出
-rw-r--r-- 1 root root 32M <timestamp> disk.img
# 如：-rw-r--r-- 1 root root 32M Nov 29 15:57 disk.img
```

------

#### **5. 分区磁盘镜像**

使用 `parted` 创建分区表和分区：

```bash
parted -s disk.img mklabel msdos
parted -s disk.img mkpart primary 2048s 100%
parted -s disk.img set 1 boot on

# 分区表用于管理硬盘空间，定义了哪些区域可用作存储。
# 引导分区是启动操作系统的必需部分，BIOS 或 GRUB 会从这里读取引导程序。
# 从 2048s 开始分区，保留前 1 MB 空间给 GRUB（嵌入段）。
```

**验证分区表：**

```bash
parted -s disk.img print

# 输出
Model:  (file)
Disk /workdir/disk.img: 33.6MB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start   End     Size    Type     File system  Flags
 1      1049kB  33.6MB  32.5MB  primary               boot
```

每个扇区的大小是 512 B。

`总大小 = 扇区大小 × 总扇区数`

如果磁盘有 65,536 个扇区，磁盘总大小为：

512 B/扇区 × 65,536 扇区 = 33,554,432 B（32 MiB）

------

#### **6. 绑定回环设备**

将磁盘镜像文件映射为回环设备，并分配分区。 回环设备是 Linux 的一种虚拟设备，可以让文件（如 `disk.img`）模拟硬件设备：

```bash
losetup --find --show --partscan disk.img

# 记录输出的设备名，例如 `/dev/loop0`。
```

**验证绑定：**

```bash
lsblk

# 输出
# 在较新的 Linux 内核中，分区设备的主设备号MAJ常常不与父设备号一致，而是使用动态分配的编号（例如 259）
# /dev/loop0p1 259:0 它依然是回环设备 /dev/loop0 的第一个分区。
NAME      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0       7:0    0    32M  0 loop 
`-loop0p1 259:0    0    31M  0 part 
vda       254:0    0  59.6G  0 disk 
`-vda1    254:1    0  59.6G  0 part /etc/hosts
vdb       254:16   0 504.4M  1 disk 
```



------

#### **7. 格式化分区**

格式化刚创建的分区为 `ext4` 文件系统：

```bash
mkfs.ext4 /dev/loop0p1
```

**问题1:**

```bash
root@e00635fe3648:/workdir# losetup --find --show --partscan disk.img
losetup: cannot find an unused loop device: No such file or directory
```

这个错误 losetup: cannot find an unused loop device: No such file or directory 通常发生在 Docker 容器中，因为容器的环境默认没有加载 loop 设备模块，或者缺少必要的设备文件。

1. 检查是否有可用的回环设备

```bash
ls /dev/loop*
```



**问题2: 有时候lsblk输出是“看起来像是创建好了，但是实际当mkfs.ext4 -q /dev/loop0p1格式化的时候会显示：**

```bash
The file /dev/loop0p1 does not exist and no size was specified.

# 进行手动创建设备文件
mknod /dev/loop0p1 b 259 0
```

这是因为：lsblk 命令展示的内容基于 内核中的设备映射状态，而非实际文件系统中的设备文件。
即使 /dev/loop0p1 在文件系统中不存在，内核仍然知道 /dev/loop0 的分区（loop0p1）。
因此，lsblk 输出显示 loop0p1 的信息，但并不代表分区设备文件 /dev/loop0p1 已实际存在于文件系统中。



**验证：**

```bash
file -s /dev/loop0p1

# 输出
/dev/loop0p1: Linux rev 1.0 ext4 filesystem data, UUID=cd57a2db-b704-4458-8cb5-b606610eed60 (extents) (64bit) (large files) (huge files)
```

------

#### **8. 挂载分区**

创建挂载点并挂载分区，挂载后的 `ISO` 是分区 `/dev/loop0p1` 的文件系统视图，主机上同步挂载的ISO文件夹不会更新，因为主机只能访问 `disk.img`，无法直接查看 Docker 容器内的挂载状态。：

```bash
mkdir -p ISO

# 把分区 /dev/loop0p1 挂载到 ISO 目录，便于访问。
mount /dev/loop0p1 ISO
```

**验证挂载：**

```bash
mount | grep ISO

# 输出
/dev/loop0p1 on /workdir/ISO type ext4 (rw,relatime)
```

```bash
ls ISO

# 输出
# lost+found 是 EXT 文件系统的默认目录，用于存放在文件系统检查中恢复的损坏或丢失的文件。
# 在格式化分区时（使用 mkfs.ext4），这个目录会自动创建。
lost+found
```

------

#### **9. 安装 GRUB**

在分区中安装 GRUB：

1. 创建 GRUB 必需的目录：

   ```bash
   mkdir -p ISO/boot/grub
   ```

2. 安装 GRUB 引导程序：

   ```bash
   grub-install --boot-directory=ISO/boot --force --allow-floppy --target=i386-pc /dev/loop0
   ```

   这里需要保证安装成功，否则grub无法正常启动

**验证 GRUB 安装：** 检查 `/boot/grub` 目录是否包含以下文件：

```bash
ls ISO/boot/grub

# 输出
fonts  grubenv  i386-pc

# 缺少 core.img 文件
# 是 GRUB 引导链中的一个重要文件，位于 MBR（Master Boot Record）之后，用于加载 GRUB 的完整功能模块。
```

我在上面安装了grub后，但是没有 `core.img` , 然后使用 `grub-mkimage` 手动生成 `core.img`，确保包含必要模块

```bash
grub-mkimage -O i386-pc -o ISO/boot/grub/core.img -p /boot/grub biosdisk part_msdos ext2
```

------

#### **10. 创建并拷贝 `grub.cfg`**

1. 在容器的 `workdir` 内创建 `grub.cfg` 文件，通过配置 `grub.cfg`，GRUB 知道从磁盘的哪个位置加载操作系统。：

   ```bash
   cat > grub.cfg <<EOF
   menuentry 'HelloOS' {
       insmod part_msdos
       insmod ext2
       set root='hd0,msdos1'
       multiboot2 /boot/HelloOS.eki
       boot
   }
   set timeout_style=menu
   if [ "${timeout}" = 0 ]; then
       set timeout=10  #等待10秒钟自动启动
   fi
   EOF
   ```

2. 拷贝配置文件到 GRUB 目录：

   ```bash
   cp grub.cfg ISO/boot/grub/
   ```

**验证：**如果输出中有 grub.cfg，说明复制成功。

```bash 
ls ISO/boot/grub
```

------

#### **11. 测试磁盘镜像**

可以先开另一个terminal在主机上运行以下命令（在主机对应项目的文件及目录下运行），使用 QEMU 测试磁盘镜像：

```bash
qemu-system-i386 -m 1024 -drive format=raw,file=disk.img
```

------

#### **12. 退出之前卸载分区和释放回环设备**

1. 卸载分区：

   ```bash
   umount ISO
   ```

2. 释放回环设备：

   ```bash
   losetup -d /dev/loop0
   ```

3. 如果 `/dev/loop0p1` 是手动创建的（用 `mknod`），删除它：

   ```bash
   mount | grep loop
   losetup -l 
   # 只要回环设备已经被正确释放（losetup -l 显示为空），挂载和 QEMU 测试都不会受到影响。
   
   # /dev/loop0p1 是你在之前手动使用 mknod 创建的设备节点。如果你不需要这些设备节点，可以手动删除
   ls /dev/loop*
   rm -f /dev/loop0p1
   ```

------

### 常见问题排查

1. **主机中检查文件内容是否更新**： 使用 `qemu-img` 验证主机镜像文件：

   ```bash
   qemu-img info /path/to/disk.img
   ```

缓存问题，我就一次次清理完全部然后重来，确保每个环节验证正确，最后排查出grub安装错误

GRUB 安装失败

Docker 容器与主机文件同步问题，虽然容器内修改了 `disk.img` 和 `ISO`，但主机上的文件没有同步更新。主机上的 `ISO` 文件夹内容与 Docker 容器内的挂载点不同步。