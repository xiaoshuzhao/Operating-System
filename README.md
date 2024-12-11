### Team: Xiaoshu Zhao (Individual)

### **Purpose of the Operating System**

The operating system is designed as a foundational project to learn and demonstrate the principles of OS development. Its primary purpose is to provide basic hardware abstraction, input/output management, and a structured environment to build more advanced OS features in the future. It serves as a starting point for features like multitasking, memory management, and peripheral interaction while enabling debugging and experimentation.

### **Implemented Functions**

1. **Bootloader**
    - Initializes the system, loads the kernel into memory, and transfers control to it.
    - Supports reading files from a FAT12 filesystem and uses BIOS disk services to load additional stages.
2. **Hardware Abstraction Layer (HAL)**
    - Initializes essential hardware components such as GDT (Global Descriptor Table), IDT (Interrupt Descriptor Table), and VGA text mode for screen output.
3. **Memory Management**
    - Provides basic memory manipulation functions like `memcpy`, `memset`, and `memcmp`.
    - Clears the `.bss` section during kernel initialization.
4. **Input/Output Management**
    - Implements basic input/output functions through a standard I/O interface (`printf`, `puts`, `fputc`).
    - Outputs data to screen and debug ports using a virtual file system (VFS) abstraction.
5. **File Access**
    - Includes a FAT12 filesystem reader to access files like `kernel.bin` during bootloading.
6. **Interrupt and Timer Handlers (Partially Implemented)**
    - Placeholder for interrupt and timer handling to support multitasking or real-time systems in the future.

---

### **Total Number of Lines of Code**

Based on the provided code snippets across all files, including comments and blank lines, the approximate total number of lines is **3,200 lines**. This includes:

- **Bootloader (assembly and supporting code)**: ~1,200 lines
- **Kernel (C files)**: ~1,500 lines
- **Supporting Files (e.g., FAT, HAL, memory)**: ~500 lines


### Screenshot 

! [runing screenshot](./GorillaOS_run.png)
