include 'frazzo.inc'

org 0x7C00

  xor ax, ax
  mov ss, ax
  mov ds, ax
  mov esp, 7C00h

  mov [bootdev], dl

  ;get drive parameters
  mov dl, [bootdev]
  mov ah, 08h
  xor di, di
  mov es, di
  int 13h
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

  ;load kernel into memory
  mov ax, 2 ;logical 2: kernel
  call l2hts
  mov ax, (0x0200 or SECTORSFORKERNEL)
  mov bx, 2000h ;phisical 20000h
  mov es, bx
  xor bx, bx
  int 13h ;load sectors from disk
  mov si, str_error_AH2
  jc errore

  ;detect available RAM
  push ds
  mov ax, 1000h
  mov ds, ax
  mov es, ax
  mov di, 0x0100
  magic_number equ 0x534D4150
  mov edx, magic_number
  mov [0x0000], dword 0x00010100
  mov [0x0004], dword 0
  detecting:
  mov eax, 0xE820
  mov ecx, 24
  int 15h
  mov si, str_error_RAM
  jc errore
  test ebx, ebx
  jz .end
  cmp eax, magic_number
  jne errore
  cmp cl, 20
  jne $ ;should never happen
  inc word [0x0004]
  add di, 20
  jmp detecting
  .end:
  pop ds

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

  ;load a gdt and enter protected mode:
  cli
  lgdt [gdtr]
  mov eax, cr0
  or al, 1 ;set PE bit
  mov cr0, eax

  ;relocate the kernel
  mov ax, sel_1stMB
  mov ds, ax
  mov ax, sel_reloc
  mov es, ax
  mov ecx, 0x200 * OFWHICHCODE / 4
  mov esi, 0x00020000
  mov edi, 0x00000000
  rep movs dword [edi], [esi]

  mov ecx, 0x200 * (SECTORSFORKERNEL - OFWHICHCODE) / 4
  mov edi, 0x00002000
  rep movs dword [edi], [esi]

  ;load right selectors
  mov ax, sel_kdata
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  mov ax, sel_kstack
  mov ss, ax
  mov esp, 0x7ffc

  push dword 0x00010000
;a long pointer to a structure:
;{ dwOffset, dwSize } describing the RAM detection table

  mov ebp, esp ;initialize a stack frame
  ;jump to kernel
  jmp sel_kcode:00 ;yes, it's 16 bit code but still load right
		   ;values into cs and eip

gdtr:
  dw 8 * 7 - 1
  dd GDT

GDT: ;the global descriptor table
gdt_entry 0, 0, 0, 0
gdt_entry 0x00100000, 0x1fff, 0x9A, 0x4;Pr|Ex|RW, Sz ;kernel code
gdt_entry 0x00102000, 0x0fff, 0x92, 0x4;Pr|RW ;kernel data
gdt_entry 0x0010ffff, 0x7fff, 0x96, 0x4;Pr|DC|RW ;kernel stack
gdt_entry 0x000B8000, 0x07ff, 0x92, 0x4;Pr|RW ;video RAM
gdt_entry 0x00000000, 0xfffff, 0x90,0x4;Pr ;1st MB
gdt_entry 0x00100000, 0xffff, 0x92, 0x4;reloc

errore:
  mov ax, 0xB800
  mov es, ax
  xor di, di
  lodsb
  mov ah, 0ch
  jmp word .check
  .loop:
   stosw
   lodsb
    .check:
   test al, al
   jnz word .loop
  xor ax, ax
  int 16h
  xor ax, ax
  int 19h ;reboot

  str_error_AH8 db 'Error ah=8', 0
  str_error_AH2 db 'Error ah=2', 0
  str_error_RAM db 'Error RAM', 0
  str_error_A20 db 'Error A20', 0

  bootdev db 0
  TracksPerHead dw 0
  SectorsPerTrack dw 0
  Sides dw 0
  DrivesCount dw 0

l2hts: ; Calculate head, track and sector settings for int 13h
       ; IN: logical sector in AX, OUT: correct registers for int 13h
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

	mov dl, byte [bootdev]		; Set correct device

	ret

times 510-($-$$) db 0
dw 0xAA55