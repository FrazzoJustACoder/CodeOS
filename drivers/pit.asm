kernel ;trap

PIT_ch0 equ 0x40
PIT_cmd equ 0x43

PIT_frequency equ 1193182 ;MHz frequency of PIT's oscillator

;PIT_setup:
;  pushd 0
;  call PIC_clear_mask
;  add esp, 4
;  ret ;PIT is unused unless the kernel start a timer

PIT_begintimer: ;bx has to be the reload value = PIT frequency / needed frequency
;if esi is != 0 then [esi] is called by the handler
  mov [PIT_handler], esi
  pushfd
  cli
  pushd 0
  call PIC_clear_mask ;unmask from PIC
  add esp, 4
  mov al, 00110100b ;channel 0, lo/hi, rate generation mode
  out PIT_cmd, al
  mov al, bl
  out PIT_ch0, al
  mov al, bh
  out PIT_ch0, al
  popfd
  ret

PIT_killtimer:
  pushf
  cli
  pushd 0
  call PIC_set_mask ;disable PIT IRQs
  add esp, 4
;  mov al,
  popf
  ret

PIT_oneshot: ;bx has to be the top value = PIT_frequency*time(seconds) (max2^16)
;if esi != 0 then [esi] is called by the handler
  mov [PIT_handler], esi
  pushfd
  cli
  pushd 0
  call PIC_clear_mask
  add esp, 4
  mov al, 00110000b ;channel 0, lo/hi, rate generation mode
  out PIT_cmd, al
  mov al, bl
  out PIT_ch0, al
  mov al, bh
  out PIT_ch0, al
  popfd
  ret

irq_PIT:
  pushad
  cmp dword [PIT_handler], 0
  je .norm
  call [PIT_handler]
  .norm:
  send_eoi 0
  popad
  iret