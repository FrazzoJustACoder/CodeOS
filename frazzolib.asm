;to include in kernel
;all functions are cdecl/bdecl

kernel ;trap

strlen: ;edi -> ecx
  mov al, 0
  mov ecx, -1
  repnz scasb
  not ecx
  dec ecx
  ret

int2hex: ;dwNumber, lpString (cdecl)
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

hex1: ;bdecl: al -> ax (ah = high)
  mov cl, al
  shr al, 4
  cmp al, 10
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

int2str: ;dwNumber, lpString
  push ebp
  mov ebp, esp
  sub esp, 8
  p10 equ ebp-4
  num equ ebp-8
  mov edi, [ebp+12]
  mov eax, 1000000000
  mov ecx, 10
  mov esi, [ebp+8]
  mov ebx, ecx
  .counting:
  cmp esi, eax
  jae .counted
  xor edx, edx
  div ebx
  dec ecx
  jmp .counting
  .counted:
  test ecx, ecx
  jz .zero
  mov [p10], eax
  mov [num], esi
  .loop:
   mov ebx, [p10]
   mov eax, [num]
   xor edx, edx
   div ebx
   mov [num], edx
   add al, '0'
   stosb
   dec ecx
   jz .end
   mov eax, [p10]
   mov ebx, 10
   xor edx, edx
   div ebx
   mov [p10], eax
   jmp .loop
  .zero:
   xor al, al
   stosb
  .end:
  mov esp, ebp
  pop ebp
  ret

str2int: ;lpString
  push ebp
  mov ebp, esp
  sub esp, 12
  p10 equ ebp-4
  res equ ebp-8
  mov [res], dword 0
  mov [p10], dword 1
  mov edi, [ebp+8]
  call strlen
  test ecx, ecx
  jz .null
  mov edi, [ebp+8]
  lea esi, [edi+ecx-1]
  std
  .loop:
   lodsb
   sub al, '0'
   jb .null
   cmp al, 9
   ja .null
   movzx eax, al
   mov edx, [p10]
   mul edx
   add [res], eax
   mov eax, [p10]
   mov edx, 10
   mul edx
   mov [p10], eax
   dec ecx
   jnz .loop
  mov eax, [res]
  .end:
  cld
  mov esp, ebp
  pop ebp
  ret
  .null:
  xor eax, eax
  jmp .end
