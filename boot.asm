alone equ
include 'frazzo.inc'

org 0x7C00

  mov [bootdev], dl

  ;get drive parameters
  mov ah, 08h
  xor di, di
  mov ds, di ;hack to save bytes
  mov es, di
  int 13h
  jc error_bad_drive

  ;store results
  mov ax, cx
  and ax, 0xffc0
  ror ax, 8
  mov [TracksPerHead], ax
  and cl, 0x3f
  mov byte [SectorsPerTrack], cl
  inc dh
  mov [Sides], dh

  ;load 2nd-stage bootloader
  mov ax, SECT_BOOT + SECT_FRFS
  call l2hts
  mov ax, 0x0200 or SECT_BOOT_II
  xor bx, bx
  mov es, bx
  mov bx, 0x7E00
  int 13h
  jc error_bad_boot

  ;load kernel
  mov ax, SECT_PREKERNEL
  call l2hts
  mov ax, 0x0200 or SECT_KERNEL
  mov bx, 0x2000
  mov es, bx
  xor bx, bx
  int 13h
  jc error_bad_kernel

  ;detect RAM
  mov ax, 0x1000 ;data at 0x00010080
  mov ds, ax
  mov es, ax
  mov di, 0x0080
  magic_number equ 0x534D4150
  mov edx, magic_number
  mov [0x0000], dword 0x00010080
  mov [0x0004], dword 0
  detecting:
  mov eax, 0xE820
  mov ecx, 24
  int 15h
  jc error_bad_ram
  test ebx, ebx
  jz .end
  cmp eax, magic_number
  jne error_bad_ram
  inc word [0x0004]
  add di, 24
  jmp detecting
  .end:

  mov bl, 0x09
  mov si, str_ok
  call print

  ;jump to 2nd-stage bootloader
  jmp 0x7E00

l2hts:
  xor dx, dx
  div word [SectorsPerTrack]
  add dl, 1 ;phisical sectors start at 1
  mov cl, dl
  xor dx, dx
  div word [Sides]
  mov ch, al ;Track
  mov dh, dl ;Head
  mov dl, [bootdev]
  ret

error_bad_drive:
  mov bl, 0x0c
  mov si, str_bad_drive
  call print
  jmp stop
error_bad_boot:
  mov bl, 0x0c
  mov si, str_bad_boot
  call print
  jmp stop
error_bad_kernel:
  mov bl, 0x0c
  mov si, str_bad_kernel
  call print
  jmp stop
error_bad_ram:
  mov bl, 0x0c
  mov si, str_bad_ram
  call print
;  jmp stop
stop:
  hlt
  jmp stop

print: ;00:si, bl
  mov dx, es
  mov ax, 0xB800
  mov es, ax
  xor di, di
  mov ds, di
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

  str_bad_drive db 'Error: invalid booting drive', 0
  str_bad_boot db "Error: can't load 2nd-stage bootlaoder", 0
  str_bad_kernel db "Error: can't load kernel", 0
  str_bad_ram db "Error:, can't detect ram", 0
  str_ok db 'Successfully 1st-stage Booted', 0

  bootdev db ?
  SectorsPerTrack dw ?
  TracksPerHead dw ?
  Sides db ?

displayfnl ($-$$)
times 510-($-$$) db 0
dw 0xAA55