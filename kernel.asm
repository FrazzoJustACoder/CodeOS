macro fb alabel, [data] { ;frazzo byte (custom define byte)
  common alabel = $ - data_segment
  forward db data
}
macro fw alabel, [data] {
  common alabel = $ - data_segment
  forward dw data
}
macro fd alabel, [data] {
  common alabel = $ - data_segment
  forward dd data
}

include 'frazzo.inc'
use32
  sub esp, 64
  rdt equ ebp ;RAM detection table

  mov ax, sel_1stMB
  mov fs, ax

  mov [esp], dword hello
  mov [esp+4], byte 72h
  call print
  call crlf

  mov [esp], dword prompt
  mov [esp+4], byte 0x0b
  call print

  mov ebx, [rdt]
  mov eax, [fs:ebx+4]

  mov [esp], eax
  mov [esp+4], dword buffer
  call int2hex

  mov [esp], dword buffer
  mov [esp+4], byte 0ah
  call print
  call crlf

  mov ebx, [rdt]
  mov eax, [fs:ebx+4]
  mov [ebp-8], eax
  mov eax, [fs:ebx]
  mov [ebp-4], eax

  .reading:

  mov [ebp-12], byte 2

  .64entry:

  mov esi, [ebp-4]
  add esi, 4
  lods dword [fs:esi]
  mov [ebp-4], esi
  mov [esp], eax
  mov [esp+4], dword buffer
  call int2hex
  mov [esp], dword buffer
  mov [esp+4], byte 0x0f
  call print

  mov esi, [ebp-4]
  sub esi, 8
  lods dword [fs:esi]
  add esi, 4
  mov [ebp-4], esi
  mov [esp], eax
  mov [esp+4], dword buffer
  call int2hex
  mov [esp], dword buffer
  mov [esp+4], byte 0x0f
  call print

  add [g_cursor], word 2

  dec byte [ebp-12]
  cmp byte [ebp-12], 0
  ja .64entry

  mov esi, [ebp-4]
  lods dword [fs:esi]
  mov [ebp-4], esi
  mov [esp], eax
  mov [esp+4], dword buffer
  call int2hex
  mov [esp], dword buffer
  mov [esp+4], byte 0x0f
  call print

  call crlf

  dec dword [ebp-8]
  cmp dword [ebp-8], 0
  ja .reading

  jmp $

include 'frazzolib32.asm'

SectorAlign

data_segment = $
fd g_cursor, 0
fb hello, 'Hello from the Kernel!', 0
fb prompt, 'RAM blocks detected by the bootloader: ', 0
fb buffer, 10 dup 0

SectorAlign

