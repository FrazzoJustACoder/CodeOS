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
  jc errore

  call ordinare

  mov ax, 2 ;logical 2: kernel
  call l2hts
  mov ax, 0202h ;2 sectors for kernel
  mov bx, 1000h ;we'll relocate it after
  mov es, bx
  xor bx, bx
  int 13h ;load sectors from disk
  jc errore

;  mov ax, 0013h
;  int 10h ;grapchics mode 320x200

  ;enable A20 line:
  mov ax, 2401h ;a20 gate activate
  int 15h
  jb .error
  test ah, ah
  jne .error

  a = $-6
  mov ax, 0xffff
  mov gs, ax
  mov ax, [a]
  cmp ax, word [gs:a+1]
  jne A20ok

  .error:
   mov si, str_error_A20
   call print
   jmp $

  str_error_A20 db 'Can', "'", 't enable A20 gate', 0

  print:
    mov ah, 0eh
    lodsb
    jmp .check
    .loop:
     int 10h
     lodsb
      .check:
     test al, al
     jnz .loop
    retw

  A20ok:

  ;load a gdt and enter protected mode:
  cli
  lgdt [GDT]
  mov eax, cr0
  or al, 1 ;set PE bit
  mov cr0, eax

  ;relocate the kernel:
  mov ax, 20h
  mov ds, ax
  mov es, ax
  mov esi, 0x10000
  mov edi, 0x100000
  mov ecx, 1024 / 4 ;2 sectors
  rep movsd
  mov edi, [GDT+20h]
  xor eax, eax
  stosd
  stosd

  ;load right selectors
  mov ax, 10h
  mov ds, ax
  mov es, ax
  mov ax, 18h
  mov ss, ax

  jmp 08h:lol
  lol:
  jmp dword 0x00100000

GDT: ;the global descriptor table
;entry 0: a pointer to himself (in format of real mode)
dw 8 * 3 - 1 ;size
dd GDT ;offset
dw 0 ;fill
gdt_entry 0x00100000, 0xffff, 0x9A, 0x4;0b10011010, 0b0100 ;kernel code
gdt_entry 0x00110000, 0xffff, 0x92, 0x4;0b10010010, 0b0100 ;kernel data
gdt_entry 0x001fffff, 0xffff, 0x96, 0x4;0b10010110, 0b0100 ;kernel stack
gdt_entry 0x0, 0xfffff, 0x92, 4+8; just to relocate

  ordinare:
  mov byte [TracksPerHead], ch
  mov ch, cl
  and ch, 128+64
  shr ch, 6
  mov byte [TracksPerHead+1], ch
  and cl, 63
  mov byte [SectorsPerTrack], cl
  mov byte [DrivesCount], dl
  xor dl, dl
  inc dh
  ror dx, 8
  mov [Sides], dx
  ret

errore:
  xor ax, ax
  int 19h ;reboot

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