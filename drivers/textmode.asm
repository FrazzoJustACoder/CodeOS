;to include in kernel
kernel ;trap

VDC_INDEX equ 0x3D4
VDC_DATA equ 0x3D5

putc: ;char
  mov al, [esp+4]
  mov ah, byte [g_color]
  mov edi, [g_cursor]
  shl edi, 1
  add edi, 0xB8000
  stosw
  inc word [g_cursor]
  call UpdateCursor
  ret

printd: ;dwNumber
  mov eax, [esp+4]
  pushd g_buffer
  pushd eax
  call int2str
  add esp, 4
  call print
  add esp, 4
  ret

printx: ;dwNumber
  mov eax, [esp+4]
  pushd g_buffer
  pushd eax
  call int2hex
  add esp, 4
  call print
  add esp, 4
  ret

print: ;lpString
  mov esi, [esp+4]
  mov edi, [g_cursor]
  shl edi, 1
  add edi, 0x000B8000
  mov ah, byte [g_color]
  lodsb
  jmp .check
  .loop:
   stosw
   lodsb
    .check:
   test al, al
   jnz .loop
  sub edi, 0x000B8000
  shr edi, 1
  mov [g_cursor], edi
  call UpdateCursor
  ret

crlf:
  mov ax, word [g_cursor]
  xor dx, dx
  mov bx, 80
  div bx
  inc ax
  mul bx
  mov word [g_cursor], ax
  call UpdateCursor
  ret

cls:
  mov edi, 0x000B8000
  mov ecx, 80*25*2/4
  xor eax, eax
  rep stosd
  ret

UpdateCursor:
  mov ebx, [g_cursor]
  cmp ebx, 80*25
  jnae .ok
    xor ebx, ebx
    mov [g_cursor], ebx
    call cls
  .ok:
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