kernel ;trap

KEYBOARD equ 0x60 ;ps2 controller's port
KB_MODE_ONLYCHAR equ 1
KB_MODE_NORMAL equ 2
KB_MODE_EXTENDED equ 4

KB_setup: ;setup keyboard
  mov edi, kb_buffer ;clear keyboard buffer
  mov ecx, 64
  xor eax, eax
  rep stosd
  pushd 1
  call PIC_clear_mask
  add esp, 4
  ret

getc: ;get character from buffer
  cmp [kb_size], 0
  je .zero
  mov esi, kb_buffer
  add esi, [kb_index]
  cmp byte [kb_mode], KB_MODE_EXTENDED
  je .extended
  cmp byte [kb_mode], KB_MODE_NORMAL
  je .normal
  xor eax, eax
  lodsb
  dec dword [kb_size]
  mov ebx, [kb_index]
  inc ebx
  cmp ebx, [kb_bufsize]
  jb .ok
   xor ebx, ebx
  .ok:
  mov [kb_buffer], ebx
  test al, 0x80
  jnz .zero ;discard key released
  ret
  .zero:
  xor eax, eax
  .extended: ;not yet implemented
  .normal:
  ret

irq_keyboard:
  push eax
  in al, KEYBOARD
  pushad
  mov bl, al ;get right offset in the buffer
  mov edi, kb_buffer
  mov eax, [kb_size]
  cmp eax, [kb_bufsize]
  jae .end ;buffer is full
  add eax, dword [kb_index]
  xor edx, edx
  div dword [kb_bufsize]
  add edi, edx
  mov al, bl

  ;comments describe the entries format
  test byte [kb_mode], KB_MODE_EXTENDED
  jnz .expanded
  test byte [kb_mode], KB_MODE_NORMAL
  jnz .normal
  .onlychar: ;bChar: the corresponding character, unused chars are special keys
  cmp al, 0xE0
  je .ocE0
  movzx eax, al
  mov al, [kb_sc2character+eax]
  test al, al
  jz .end
  stosb
  inc dword [kb_size]
  .end:
  send_eoi 1
  popad
  pop eax
  iret
  .ocE0:
  in al, KEYBOARD
  jmp .end ;discard it for now
  ;not yet implemented
  .normal:
  .expanded: