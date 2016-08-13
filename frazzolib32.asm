;to include in kernel
;all functions are cdecl

VDC_INDEX equ 0x3D4
VDC_DATA equ 0x3D5

print: ;lpString, bColor
  push ebp
  mov ebp, esp

  push es

  mov ax, sel_videoRAM ;selector for video ram
  mov es, ax

  mov ah, [ebp+12]
  shl ax, 4
  shl al, 4
  cmp al, ah
  je $ ;.error_invalid_color
  mov ah, [ebp+12]

  mov esi, [ebp+8]
  mov edi, [g_cursor]
  lodsb
  xor ecx, ecx
  jmp .check
  .loop:
   stosw
   cmp edi, 80*25*2
   cmovae edi, ecx
   lodsb
    .check:
   test al, al
   jnz .loop
  mov [g_cursor], edi
  call UpdateCursor
  pop es

  mov esp, ebp
  pop ebp
  ret

crlf:
  mov cx, 0
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

strlen: ;lpString ;return in ecx cause yes
  mov edi, [esp+4]
  xor al, al
  mov ecx, -1
  repnz scasb
  xor ecx, -1
  dec ecx
  ret

macro p10 dest, exp {
  dest = 1
  if exp > 9
    display 'too large for a dword!', 13, 10
    abort
  end if
  if exp > 0
    repeat exp
      dest = dest * 10
    end repeat
  end if
}

;int2str: ;dwNumber, lpString
;  mov ebx, [esp+4]
;  mov edi, [esp+8]

;  p10 var, 9
;  mov eax, var-1
;  mov ecx, 10
;  .sizing:
;   cmp ebx, eax
;   ja .sized
;   xor edx, edx
;   mov esi, 10
;   div esi
;   dec ecx
;   .sized:
;  ret

int2hex: ;dwNumber, lpString
  mov edx, [esp+4]
  mov edi, [esp+8]
  test edx, edx
  jz .zero
  mov ecx, 0x00ffffff
  mov eax, 0x0400
  .sizing:
   cmp edx, ecx
   cmova ecx, eax
   ja .sorting
   shr ecx, 8
   dec ah
   jmp .sizing
  .sorting:
   rol edx, 8
   inc ah
   cmp ah, 4
   jne .sorting
  .loop:
   rol edx, 8
   mov al, dl
   call hex1
   stosw
   dec ch
   jnz .loop
  .end:
  xor al, al
  stosb
  ret
  .zero:
  mov ax, (('0' * 256) + '0')
  stosw
  jmp .end
 hex1:
  mov cl, al
  shr al, 4
  cmp al, 10 ;decimal
  sbb al, 69h
  das
  mov ah, al
  mov al, cl
  ror al, 4
  shr al, 4
  cmp al, 10
  sbb al, 69h
  das
  ror ax, 8
  ret
