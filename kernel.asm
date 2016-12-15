use32
org 0x00100000
alone equ
include 'frazzo.inc'

;LOW KERNEL

;  jmp 0xDEADC0DE
  sub esp, 24

  ;set up a new GDT
  mov ebx, 0x00002000
  lgdt [ds:ebx]

  ;load new selectors
  jmp sel_kcode:newgdt
  newgdt:
  mov ax, sel_kdata
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  ;new stack
  mov ss, ax
  mov esp, 0x001FFFFC
  mov ebp, esp
  sub esp, 32

  ;set up an IDT
  lidt [idtr]

  call PIC_init ;setup PICs

  call KB_setup ;setup keyboard

  call disk_init ;setup hard disk

  call graphics_init ;init VESA variables

  ;enable interrupts
  sti

;PLAY AROUND HERE:

  mov eax, 0x00FFFF00
  call gp_background

  ;set up PIT timer to have a frequency of 60Hz
  mov bx, 19886
  call PIT_begintimer

  lel:
    mov [esp], dword 0
    mov [esp+4], dword 0
    mov [esp+8], dword 30
    mov [esp+12], dword 20
;    mov [esp+16], dword bmp
;    mov [esp+16], dword 0
    .loop:
      mov [esp+16], dword 0x00FFFF00
      call rect
      inc dword [esp]
      mov [esp+16], dword 0x0000FFFF
      call rect
      hlt
;      hlt ;;;;
;      .hlt:
      cmp byte [PIT_handler], 1
      je $
;      mov byte [PIT_handler], 0
      cmp dword [esp], 0x300*0x400
      jb .loop
    mov [esp], dword 16
    call rect

  _hlt:
    hlt
    jmp _hlt


kernel equ
include 'frazzolib.asm'
include 'drivers\textmode.asm'
include 'drivers\exceptions.asm'
include 'drivers\pic.asm'
include 'drivers\keyboard.asm'
include 'drivers\disk.asm'
include 'drivers\graphics.asm'
include 'drivers\pit.asm'

pad512
org 0x00102000
str_hello db 'Hello from the Kernel!', 0
align 4
g_buffer db 32 dup 0
g_cursor dd 80
g_color dd 0ah

delete1 db 'Error'
delete2 db 0, 0

align 16
space:
db 'FRAZZO', 0, 0

pad512
org 0x00104000
;GLOBAL DESCRIPTOR TABLE
gdtr: ;first empty entry used to point the table itself
  dw gdt_end - gdtr - 1
  dd gdtr
  dw 0
gdt_index = 8
gdt_entry sel_kcode, 0, 0xFFFFF, 0x9A, 0xC ;kcode
gdt_entry sel_kdata, 0, 0xFFFFF, 0x92, 0xC ;kdata
gdt_end:

;INTERRUPT DESCRIPTOR TABLE
idtr:
  dw idt_end - IDT - 1
  dd IDT
  dw 0
IDT:
idt_entry sel_kcode, isr0, 0x8F ;0 div
idt_entry sel_kcode, isr1, 0x8F ;debug
idt_entry sel_kcode, isr2, 0x8F ;nmi
idt_entry sel_kcode, isr3, 0x8F ;breakpoint
idt_entry sel_kcode, isr4, 0x8F ;overflow
idt_entry sel_kcode, isr5, 0x8F ;out of bounds
idt_entry sel_kcode, undefined_opcode_exception, 0x8F ;ud
idt_entry sel_kcode, isr7, 0x8F ;no coprocessor (should never happen)
idt_entry sel_kcode, isr8e, 0x8F ;double fault
idt_entry sel_kcode, isr9, 0x8F ;free
idt_entry sel_kcode, isr10e, 0x8F ;invalid tss
idt_entry sel_kcode, isr11e, 0x8F ;segment not present
idt_entry sel_kcode, isr12e, 0x8F ;stack fault
idt_entry sel_kcode, isr13e, 0x8F ;general protection fault
idt_entry sel_kcode, isr14e, 0x8F ;page fault
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr16, 0x8F ;x87 fp exception
idt_entry sel_kcode, isr17e, 0x8F ;alignment check
idt_entry sel_kcode, isr18, 0x8F ;machine check (disabled)
idt_entry sel_kcode, isr19, 0x8F ;SIMD fp exception
idt_entry sel_kcode, isr20, 0x8F ;virtualization exception
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, isr30e, 0x8F ;security exception
idt_entry sel_kcode, isr_res, 0x8F ;reserved
idt_entry sel_kcode, irq_PIT, 0x8E ;PIT
idt_entry sel_kcode, irq_keyboard, 0x8E ;keyboard
idt_entry sel_kcode, cascade, 0x8E ;cascade
idt_entry sel_kcode, irq3, 0x8E ;com2
idt_entry sel_kcode, irq4, 0x8E ;com1
idt_entry sel_kcode, irq5, 0x8E ;lpt2
idt_entry sel_kcode, irq6, 0x8E ;floppy disk
idt_entry sel_kcode, irq7, 0x8E ;lpt1 / spurious
idt_entry sel_kcode, irq8, 0x8E ;CMOS clock
idt_entry sel_kcode, irq9, 0x8E ;
idt_entry sel_kcode, irq10, 0x8E ;
idt_entry sel_kcode, irq11, 0x8E ;
idt_entry sel_kcode, irq12, 0x8E ;PS2 mouse
idt_entry sel_kcode, irq13, 0x8E ;FPU/coprocessor/inter-processor
idt_entry sel_kcode, irq14, 0x8E ;primary ATA hard disk
idt_entry sel_kcode, irq15, 0x8E ;secondary ATA hard disk / spurious
idt_end:

align 4

;DISK DRIVER DATA
disk_plstsel db ?
disk_slstsel db ?

struc DD { ;disk data (size: 24 bytes)
  .size dd ? ;ff00ssss ff B,KB,MB,GB; ssss size
  .format dw ?
  .heads dw ?
  .cylinders dw ?
  .sectors dw ?
  .lba28 dd ? ;supported if non-zero
  .lba48 dq ? ;supported if non-zero
}

hdd_data DD

align 16

gp_lfb dd ? ;linear framebuffer
gp_width dw ?
gp_height dw ?
gp_pitch dw ? ;bytes in a line (not always height * bpp)
gp_bpp db ?
db ?
gp_totalsize dd ? ;size in bytes of linear framebuffer
gp_pixels dd ? ;size in pixels of linear framebuffer

PIT_handler dd 0

align 16
;KEYBOARD DRIVER DATA
kb_sc2character:
db   0,   2, '1', '2', '3', '4', '5', '6'
db '7', '8', '9', '0', "'", 'ì',   8,	9 ;backspace, tab
db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'
db 'o', 'p', 'è', '+',	10,   3, 'a', 's' ;enter
db 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ò'
db 'à',   0,   1, 'ù', 'z', 'x', 'c', 'v'
db 'b', 'n', 'm', ',', '.', '-',   1, '*'

kb_size dd 0
kb_index dd 0
kb_mode dd KB_MODE_ONLYCHAR
kb_bufsize dd 256
kb_status dd 0
kb_buffer:

pad512