alone equ
include 'frazzo.inc'

org 0x7E00

  ;enable A20 line:
  mov ax, 0x2401
  int 15h
  jb error_bad_A20
  test ah, ah
  jne error_bad_A20

  ;test A20
  a = $-6
  mov ax, 0xffff
  mov gs, ax
  mov ax, [a]
  cmp ax, word [gs:a+1]
  je error_bad_A20

  ;load a gdt and enter pmode
  cli
  lgdt [gdtr]
  mov eax, cr0
  or al, 1 ;PE bit
  mov cr0, eax

  ;relocate the kernel
  mov ax, 0x18
  mov ds, ax
  mov ax, 0x20
  mov es, ax
  mov esi, 0x00020000
  xor edi, edi
  mov ecx, SECT_KCODE * 128
  rep movs dword [edi], [esi]

  mov edi, 0x00002000
  mov ecx, SECT_KDATA * 128
  rep movs dword [edi], [esi]

  mov edi, 0x00004000
  mov ecx, SECT_SYS * 128
  rep movs dword [edi], [esi]

  ;load selector for next gdt
  mov ax, 0x10
  mov ds, ax

;  pushd 0x00010000
  mov eax, 0x00010000 ;long pointer to some data
;  mov ebp, esp

  ;jump to kernel
  jmp 0x08:0x0000

error_bad_A20:
  mov si, str_bad_A20
  mov bl, 0x0c
  call print
  ;jmp stop
stop:
  hlt
  jmp stop

print: ;00:si, bl
  mov dx, es
  xor ax, ax
  mov ds, ax
  mov ax, 0xB800
  mov es, ax
  mov di, 160
  mov ah, bl
  lodsb
  jmp .check
  .loop:
   stosw
   lodsb
    .check:
   test al, al
   jnz .loop
  mov es, dx
  ret

str_bad_A20 db "Error: can't enable A20 gate", 0
str_ok db 'Successfully 2nd-stage booted', 0

gdtr:
  dw gdt_end - (GDT + 1)
  dd GDT
GDT:
gdt_index = 0
gdt_entry a, 0, 0, 0, 0
gdt_entry a, 0x00100000, 0x1fff, 0x9A, 0x4 ;kernel code
gdt_entry a, 0x00102000, 0x3fff, 0x92, 0x4 ;kernel data and structures
gdt_entry a, 0x00000000, 0xfffff, 0x92, 0x4;1st MB
gdt_entry a, 0x00100000, 0xffff, 0x92, 0x4 ;reloc
gdt_end:

displayfnl ($-$$)
pad512