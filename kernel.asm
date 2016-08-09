include 'frazzo.inc'

KernelStart:
  mov ebp, esp
  sub esp, 24
  mov [bg_color], byte 1
  call cls
  call loadbuffer
  mov [esp], word ball
  mov [esp+4], dword 0
  mov [esp+8], dword 0
  mov [esp+12], dword 14
  mov [esp+16], dword 14

  .loop:
  call cls
  call bitblt
  call loadbuffer
  inc word [esp+4]
  cmp word [esp+4], 320-14
  jb .loop
  mov word [esp+4], 0
  add word [esp+8], 14
  cmp word [esp+8], 200-14
  jb .loop
  mov word [esp+8], 0
  jmp .loop

bitblt:
  push ebp
  mov ebp, esp
  source equ ebp+6
  posx equ ebp+10
  posy equ ebp+14
  dimx equ ebp+18
  dimy equ ebp+22

  mov eax, [posx]
  cmp eax, 320
  jae .error_out_of_screen
  add eax, [dimx]
  cmp eax, 320
  jae .error_out_of_border
  mov eax, [posy]
  cmp eax, 200
  jae .error_out_of_screen
  add eax, [dimy]
  cmp eax, 200
  jae .error_out_of_border

  xor eax, eax
  mov si, [source]
  mov ax, [posy]
  mov dx, 320
  mul dx
  add ax, [posx]
  mov bx, [dimy]
  .loop:
   lea di, [eax+VIDEO_BUFFER]
   mov cx, [dimx]
   rep movsb
   add ax, 320
   dec bx
   jnz .loop

  mov esp, ebp
  pop ebp
  retw

  .error_out_of_screen:
   pushd str_error_oos
   call error
   retw
  .error_out_of_border:
   pushd str_error_oos
   call error
   retw

cls:
  mov di, VIDEO_BUFFER
  mov al, [bg_color]
  mov ah, al
  push ax
  shl eax, 16
  pop ax
  mov ecx, 320*200/4
  rep stosd
  retw

loadbuffer:
  push es
  mov di, 0xA000
  mov es, di
  mov si, VIDEO_BUFFER
  xor di, di
  mov ecx, 320*200 / 4
  rep movsd
  pop es
  retw

error:
  mov ax, 0003h
  int 10h
  mov esi, [esp+2]
  push esi
  call strlen
  pop esi
  push es
  mov di, 0xB800
  mov es, di
  xor di, di
  mov ah, 0ch
  lodsb
  jmp .check
  .loop:
   stosw
   lodsb
    .check:
   test al, al
   jnz .loop
;  retw
  jmp $

strlen:
  mov di, [esp+2]
  xor al, al
  mov ecx, -1
  repnz scasb
  xor ecx, -1
  dec ecx
  retw

bg_color db 1
str_error_oos db 'Errore: si è tentato di disegnare fuori dallo ', \
		 'schermo!', 0
ball db 1, 1, 1, 1, 1, 3, 3, 3, 3, 1, 1, 1, 1, 1, \
	1, 1, 1, 3, 3, 2, 2, 2, 2, 3, 3, 1, 1, 1, \
	1, 1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, 1, \
	1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, \
	1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, \
	3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, \
	3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, \
	3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, \
	3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, \
	1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, \
	1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, \
	1, 1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1, 1, \
	1, 1, 1, 3, 3, 2, 2, 2, 2, 3, 3, 1, 1, 1, \
	1, 1, 1, 1, 1, 3, 3, 3, 3, 1, 1, 1, 1, 1

SectorAlign

VIDEO_BUFFER:; db 320*200 dup 0
