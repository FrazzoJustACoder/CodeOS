kernel ;trap

PIT_ch0 equ 0x40
PIT_cmd equ 0x43

PIT_begintimer: ;bx has to be the reload value = PIT frequency / needed frequency
;if esi is != 0 then [esi] is jmped to in the handler
  mov [PIT_handler], esi
  pushfd
  cli
  mov al, 00110100b ;channel 0, lo/hi, rate generation mode
  out PIT_cmd, al
  mov al, bl
  out PIT_ch0, al
  mov al, bh
  out PIT_ch0, al
  popfd
  ret

irq_PIT:
;  cmp dword [PIT_handler], 0
;  je .norm
;  call [PIT_handler]
;  .norm:
  jmp 0xDEADC0DE
  mov byte [PIT_handler], 1
  send_eoi 0
;  iret