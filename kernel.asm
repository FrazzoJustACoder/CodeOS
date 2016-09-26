use32
alone equ
include 'frazzo.inc'

;  jmp 0xDEADC0DE
  sub esp, 24

  mov [g_color], byte 0x0b
  mov [esp], dword str_hello
  call print

  mov [g_color], byte 0x0a
  mov [esp], dword 123456789
  call printd
  jmp $

kernel equ
include 'frazzolib.asm'
include 'drivers\textmode.asm'

pad512
data_segment = $-$$
dd 0xDEADC0DE
fb str_hello, 'Hello from the Kernel!', 0
align 4
fb g_buffer, 32 dup 0
fd g_cursor, 160
fd g_color, 0ah

pad512