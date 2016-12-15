alone equ
include 'frazzo.inc'

org 0x7E00

  ;VESA stuff
  VESA:
  xor ax, ax
  mov es, ax
  mov ds, ax

  mov ax, 4F00h ;get VESA controller info
  mov di, 0xF000
  int 10h
  cmp ax, 004Fh
  jne .novesa
  mov si, [0xF00E] ;fk it, use last mode
  push ds
  mov ds, [0xF010]
  .searchforlast:
  lodsw
  cmp ax, 0xFFFF
  jne .searchforlast
  mov cx, [si-4]
  pop ds
  mov ax, 4F01h
  mov di, 0xF200
  int 10h
  test byte [0xF200], 1
  jz .novesa ;not supported by hardware -> "fottesega"
  mov ax, 4F02h
  mov bx, cx
  or bx, 0x4000
  int 10h
  push es
  mov di, 1000h
  mov es, di
  mov si, 0xF210
  mov di, 0x0010 ;pitch
  movsw
;  mov di, 0x000C ;width and height
  sub di, 12h-0Ch
  movsd
  add di, 2 ;bpp
  add si, 3
  movsb
  mov al, [0xF200] ;some flags
  stosb
  add si, 28h-1Ah
  sub di, 14h-8
  movsd
  mov [es:0x0014], dword 0xBEEFBEEF
  pop es
  jmp .ok
  .novesa:
  mov ax, 13h ;use 320x200x256 VBE graphics mode
  int 10h
  push es
  mov di, 0xA000
  mov es, di
  xor di, di
  mov cx, 32000
  mov eax, 0x07070707
  rep stosd
  pop es
  mov [0x0008], dword 0x000A0000
  mov [0x000C], dword (320 + (200*256*256))
  mov [0x0010], dword (320 + (8*256*256))
  .ok:

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
  inc ax
  mov fs, ax
  mov ax, [fs:a]
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

px: ;print contents of dx
  push es
  mov di, 0xB800
  mov es, di
  mov di, [cs:.cursor]
  mov cl, 12
  .loop:
  mov bx, dx
  shr bx, cl
  and bx, 15
  mov al, [cs:bx+.oca]
  mov ah, 15
  stosw
  sub cl, 4
  jns .loop
  mov [cs:.cursor], di
  pop es
  ret
  .oca db '0123456789ABCDEF'
  .cursor dw 0

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