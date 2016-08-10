include 'frazzo.inc'

org 0x7C00

  xor ax, ax
  mov ss, ax
  mov esp, 7C00h

  mov [bootdev], dl

  mov ah, 08h
  xor di, di
  mov es, di
  int 13h ;get drive parameters
  mov si, str_error_AH8
  jc errore

  ;store results cause yes
  mov byte [TracksPerHead], ch
  mov ch, cl
  and ch, 0xc0
  shr ch, 6
  mov byte [TracksPerHead+1], ch
  and cl, 63
  mov byte [SectorsPerTrack], cl
  mov byte [DrivesCount], dl
  xor dl, dl
  inc dh
  ror dx, 8
  mov [Sides], dx

  mov ax, 2 ;logical 2: kernel
  call l2hts
  mov ax, (0x0200 or SECTORSFORKERNEL)
  mov bx, 1000h
  mov es, bx
  xor bx, bx
  int 13h ;load sectors from disk
  mov si, str_error_AH2
  jc errore

  ;enable A20 line:
  mov ax, 2401h ;a20 gate activate
  mov si, str_error_A20
  int 15h
  jb errore
  test ah, ah
  jne errore

  ; test if A20 was successfully enabled
  a = $-6
  mov ax, 0xffff
  mov gs, ax
  mov ax, [a]
  cmp ax, word [gs:a+1]
  mov si, str_error_A20
  je errore

  jmp 1000h:0000h

  ;load a gdt and enter protected mode:
;  cli
;  lgdt [GDT]
;  mov eax, cr0
;  or al, 1 ;set PE bit
;  mov cr0, eax

;  use32

  ;load right selectors
;  mov ax, 10h
;  mov ds, ax
;  mov es, ax
;  mov fs, ax
;  mov gs, ax

;  jmp 08h:00

;GDT: ;the global descriptor table
;;entry 0: a pointer to himself (real mode format)
;dw 8 * 3 - 1 ;size
;dd GDT ;offset
;dw 0 ;fill
;gdt_entry 0x0010000, 0x02ff, 0x9A, 0xC;0b10011010, 0b0100 ;kernel code
;gdt_entry 0x0011000, 0x01ff, 0x92, 0xC;0b10010010, 0b0100 ;kernel data

;use16

errore:
  push es
  mov ax, 0xB800
  mov es, ax
  xor di, di
  lodsb
  mov ah, 0ch
  jmp .check
  .loop:
   stosw
   lodsb
    .check:
   test al, al
   jnz .loop
  xor ax, ax
  int 16h
  xor ax, ax
  int 19h ;reboot

  str_error_AH8 db 'Error ah=8', 0
  str_error_AH2 db 'Error ah=2', 0
  str_error_A20 db 'Error A20', 0
  str_frazzo db 'PROGRAMMERS NEVER DIE!', 0

  bootdev db 0
  TracksPerHead dw 0
  SectorsPerTrack dw 0
  Sides dw 0
  DrivesCount dw 0

l2hts:			; Calculate head, track and sector settings for int 13h
			; IN: logical sector in AX, OUT: correct registers for int 13h
	push bx
	push ax

	mov bx, ax			; Save logical sector

	mov dx, 0			; First the sector
	div word [SectorsPerTrack]
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0			; Now calculate the head
	div word [SectorsPerTrack]
	mov dx, 0
	div word [Sides]
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

	mov dl, byte [bootdev]		; Set correct device

	ret

times 510-($-$$) db 0
dw 0xAA55