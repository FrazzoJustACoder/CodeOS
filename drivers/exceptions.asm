kernel ;trap

isr0:
  pushad
  pushd [g_color]
  mov byte [g_color], 0x0C
  call crlf
  call .print
  db 'Division by 0 exception caught at address ', 0
  .print:
  call print
  mov eax, [esp+40]
  mov [esp], eax
  call printx
  .stop:
    hlt
    jmp .stop
isr1:
isr2:
isr3:
isr4:
isr5:
  pushad
  call crlf
  call .print
  db 'int happened', 0
  .print:
  call print
  add esp, 4
  call crlf
  popad
  iret

undefined_opcode_exception:
  pushad
  pushd [g_color]
  mov byte [g_color], 0x0C
  call crlf
  call .print
  db 'Undefined opcode exception caught at address ', 0
  .print:
  call print
  mov eax, [esp+40]
  mov [eax], word 0x9090 ;nop nop
  mov [esp], eax
  call printx
  add esp, 4
  call crlf
  popd [g_color]
  popad
  iret

isr7:
  jmp isr5
isr8e: ;double fault
  call crlf
  call .print
  db 'Double fault exception caught :C ', 0
  .print:
  mov byte [g_color], 0x0C
  call print
  add esp, 4
  call printx
  sub esp, 4
  .stop:
    hlt
    jmp .stop
isr9:
  jmp isr5
isr10e:
isr11e:
isr12e:
  popd [esp-4]
  iret
isr13e: ;gpf
  call crlf
  call .print
  db 'General protection fault caught at address ', 0
  .print:
  call print
  mov eax, [esp+8]
  mov [esp], eax
  call printx
  call .print2
  db ' and error code ', 0
  .print2:
  call print
  add esp, 8
  call printx
  .stop:
    hlt
    jmp .stop
isr14e:
  popd [esp-4]
isr16:
  jmp isr5
isr17e:
  popd [esp-4]
isr18:
isr19:
isr20:
  jmp isr5
isr30e:
  popd [esp-4]
isr_res:
  jmp isr5