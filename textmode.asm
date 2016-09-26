;to include in kernel
kernel ;trap

VDC_INDEX equ 0x3D4
VDC_DATA equ 0x3D5

printd: ;dwNumber
  mov eax, [esp+4]
  sub esp, 8
  mov [esp], eax
  mov [esp+4], dword g_buffer
  call int2str
  add esp, 4
  call print
  add esp, 4
  ret

printx: ;dwNumber
  mov eax, [esp+4]
  sub esp, 8
  mov [esp], eax
  mov [esp+4], dword g_buffer
  call int2hex

;cdecl
print: ;lpString
  mov esi, [esp+4]
  push es
  mov di, SEL_VIDEORAM
  mov es, di
  mov edi, [g_cursor]
  mov ah, [g_color]
  lodsb
  jmp .check
  .loop:
   stosw
   lodsb
    .check:
   test al, al
   jnz .loop
  mov [g_cursor], edi
  call UpdateCursor
  pop es
  ret

crlf:
  xor cx, cx
  mov ax, [g_cursor]
  shr ax, 1
  xor dx, dx
  mov bx, 80
  div bx
  inc ax
  cmp ax, 25
  cmovae ax, cx
  mul bx
  shl ax, 1
  mov [g_cursor], ax
  call UpdateCursor
  ret

UpdateCursor:
  xor eax, eax
  mov ebx, [g_cursor]
  shr ebx, 1
  cmp ebx, 80*25
  cmovae ebx, eax
  mov dx, VDC_INDEX
  mov al, 14 ;cursor index (high byte)
  out dx, al
  inc dx ;mov dx, VDC_DATA
  mov al, bh
  out dx, al
  dec dx ;mov dx, VDC_INDEX
  mov al, 15
  out dx, al
  inc dx ;mov dx, VDC_DATA
  mov al, bl
  out dx, al
  ret

;data section:
;g_cursor