/*
Picolibc.ld defines only two memory regions: flash and ram. Flash is an addressable region of read-only memory which holds program text, constant data and initializers for read-write data. Ram is read-write memory which needs to be initialized before your application starts.
__flash specifies the lowest address in read-only memory used by your application. This needs to be in flash, but need not be the start of actual flash in the device.
__flash_size specifies the amount of read-only memory you want to allow the application to fill. This need not be all of the available memory.
__ram specifies the lowest address you want the linker to allocate to read-write data for the application.
__ram_size specifies the maximum amount of read-write memory you want to permit the application to use.
__stack_size reserves this much space at the top of ram for the initial stack.
__heap_size_min is an optional value that you can set to ensure there is at least this much memory available for the heap used by malloc. Malloc will still be able to use all memory between the end of pre-allocate data and the bottom of the stack area.
*/

__flash = 0x08000000;
__flash_size = 1024K;
__ram = 0x20000000;
__ram_size = 96K;
__stack_size = 512;

/* Provide the second memory area for user application */
MEMORY
{
	ram2 (w!rx) :
		ORIGIN = 0x10000000,
		LENGTH = 32K
}

PHDRS
{
	ram2 PT_LOAD;
}

SECTIONS
{
  .ram2 (NOLOAD) : {
        *(.ram2)
        *(.ram2*)
        . = ALIGN(4);
        __ram2_end = .;
  } >ram2 AT>ram2 :ram2
  PROVIDE( __ram2_start = ADDR(.ram2));
  PROVIDE( __ram2_size = __ram2_end - __ram2_start );

}

/* Printf and Scanf Options. Equivalent to --defsym  */
vfprintf = __m_vfprintf; /*disable*/
vfscanf = __m_vfscanf; /*disable*/

INCLUDE ../../../libraries/picolibc/thumbv7e+fp/lib/picolibc.ld
