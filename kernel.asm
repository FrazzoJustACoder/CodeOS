include 'frazzo.inc'
use32

  mov ax, 0
  mov ds, ax
  mov si, word stringa
  call word print16
  jmp $

  ;load a gdt and enter protected mode:
  cli
  lgdt [GDT]
  mov eax, cr0
  or al, 1 ;set PE bit
  mov cr0, eax

  ;load right selectors
  mov ax, 10h
  mov ds, ax
  mov es, ax
  jmp $

  jmp 08h:pmode
  pmode:

  jmp $

print16:
  push es
  mov ax, 0xB800
  mov es, ax
  xor di, di
  lodsb
  mov ah, 72h
  jmp .check
  .loop:
   stosw
   lodsb
    .check:
   test al, al
   jnz .loop
  pop es
  retw

stringa db 'Hello from the Kernel!', 0

GDT:
dw 8 * 3 - 1
dd GDT
dw 0
gdt_entry 0x00010000, 0x1ff, 0x9A, 4
gdt_entry 0x00011000, 0x1ff, 0x92, 4

SectorAlign

