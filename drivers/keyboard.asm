kernel ;trap

KEYBOARD equ 0x60 ;ps2 controller's port
ACK equ 0xFA
RESEND equ 0xFE

KB_setup: ;setup keyboard
  pushd 1
  call PIC_clear_mask
  add esp, 4
  mov edi, kb_buffer ;clear keyboard buffer
  mov ecx, 64
  xor eax, eax
  rep stosd
  ret

irq_keyboard:
  in al, KEYBOARD
;  mov edi, kb_buffer
;  mov ebx, [kb_size]
  movzx eax, al
  push eax
  call printx
  mov [esp], byte 0
  call putc
  add esp, 4
  send_eoi 1
  iret