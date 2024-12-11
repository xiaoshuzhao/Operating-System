Binutils download link (.tar.gz)  https://ftp.gnu.org/gnu/binutils/?C=M;O=D

GNU/GCC download link  https://ftp.gnu.org/gnu/gcc/?C=M;O=D

https://wiki.osdev.org/GCC_Cross-Compiler

https://wiki.osdev.org/Disk_Images

```bash
brew install wget bison flex gmp libmpc mpfr texinfo

wget https://ftp.gnu.org/gnu/binutils/binutils-2.43.1.tar.gz
wget https://ftp.gnu.org/gnu/gcc/gcc-13.3.0/gcc-13.3.0.tar.gz

brew install mtools nasm qemu

brew list --versions qemu mtools nasm
mtools 4.0.46
nasm 2.16.03
qemu 9.1.2

tar -xvzf binutils-2.43.1.tar.gz
tar -xvzf gcc-13.3.0.tar.gz

mkdir binutils-build
mkdir gcc-build

cd binutils-build
# i686 represents the Intel x86 32-bit processor architecture, commonly used for developing 32-bit operating systems.
# elf specifies that the target file format is ELF (Executable and Linkable Format), a common binary file format in Unix-like systems.
export PREFIX="$HOME/gorilla/Toolchain/i686-elf"
# $HOME is equivalent to /Users/sugar

# Informs the toolchain (e.g., binutils or gcc) that the target platform is i686-elf.
# The toolchain generates binary files suitable for the target platform.
export TARGET=i686-elf

# PATH is an environment variable used to store a set of paths, where the operating system looks for executable files.
# $PATH appends the current PATH value to the new path to ensure that previous system paths are not lost.
# Adds the bin directory of the cross-compilation toolchain to the PATH environment variable so that these tools can be run directly.
export PATH="$PREFIX/bin:$PATH"
echo $PATH
# /Users/sugar/gorilla/Toolchain/i686-elf/bin:/Users/sugar/gorilla/Toolchain/i686-elf/bin

# ../binutils-2.43.1/configure indicates navigating to the parent directory, finding the binutils-2.43.1 folder, and running the configure script within it.
# --option=value
# --with-sysroot: Informs binutils to look for the root file system (sysroot) of the target platform. For cross-compilation toolchains, sysroot is a simulated environment for the target platform used for locating header files and libraries.
# --disable-nls: Disables Native Language Support (NLS).
# --disable-werror: Disables treating warnings as errors during compilation. These warnings are ignored, and compilation proceeds.
../binutils-2.43.1/configure --target="$TARGET" --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror

make -j4 && make install

cd ..
cd gcc-build

../gcc-13.3.0/configure --target="$TARGET" --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
# gmp, mpfr, mpc are located in /opt/homebrew/opt
# Install and check paths
brew install gmp mpfr libmpc
brew --prefix gmp
brew --prefix mpfr
brew --prefix libmpc

../gcc-13.3.0/configure \
  --target="$TARGET" \
  --prefix="$PREFIX" \
  --disable-nls \
  --enable-languages=c,c++ \
  --without-headers \
  --with-gmp=$(brew --prefix gmp) \
  --with-mpfr=$(brew --prefix mpfr) \
  --with-mpc=$(brew --prefix libmpc)
# Output...
# configure: creating ./config.status
# config.status: creating Makefile

# Compile the core parts of the GCC compiler and runtime libraries for the target platform.
make -j4 all-gcc && make -j4 all-target-libgcc

make install-gcc
make install-target-libgcc

# Make and Run

cd gorillaOS
export TOOLCHAIN="$HOME/gorilla/Toolchain/i686-elf"

make
./run.sh
```
