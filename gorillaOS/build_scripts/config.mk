export CFLAGS = -std=c99 -g
export ASMFLAGS =
export CC = gcc
export CXX = g++
export LD = gcc
export ASM = nasm
export LINKFLAGS =
export LIBS =

export TARGET = i686-elf
export TARGET_ASM = nasm
export TARGET_ASMFLAGS =
export TARGET_CFLAGS = -std=c99 -g #-O2
export TARGET_CC = $(TARGET)-gcc
export TARGET_CXX = $(TARGET)-g++
export TARGET_LD = $(TARGET)-gcc
export TARGET_LINKFLAGS =
export TARGET_LIBS =

export SOURCE_DIR = $(abspath .)
export BUILD_DIR = $(abspath build)

BINUTILS_VERSION = 2.43.1
BINUTILS_URL = https://ftp.gnu.org/gnu/binutils/binutils-2.43.1.tar.gz

GCC_VERSION = 13.3.0
GCC_URL = https://ftp.gnu.org/gnu/gcc/gcc-13.3.0/gcc-13.3.0.tar.gz