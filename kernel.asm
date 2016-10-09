use32
org 0x00100000
alone equ
include 'frazzo.inc'

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

  ;set up an IDT
  lidt [idtr]

  call PIC_init ;setup PICs

  call KB_setup ;setup keyboard

  ;enable interrupts
  sti

  mov byte [g_color], byte 0x0b
  mov [esp], dword str_hello
  call print
  call crlf

  ;check of APIC
;  mov eax, 1
;  cpuid
;  test edx, (1 shl 9)
;  jz 0xBADC0DE;error_bad_apic

  mov [esp], dword 0xDEADC0DE
  call printx

  jmp $

kernel equ
include 'frazzolib.asm'
include 'drivers\textmode.asm'
include 'drivers\exceptions.asm'
include 'drivers\pic.asm'
include 'drivers\keyboard.asm'

pad512
org 0x00102000
;data_segment = $-$$
;dd 0xDEADC0DE
str_hello db 'Hello from the Kernel!', 0
;fb str_hello, 'Hello from the Kernel!', 0
align 4
;fb g_buffer, 32 dup 0
g_buffer db 32 dup 0
;fd g_cursor, 160
g_cursor dd 80
;fd g_color, 0ah
g_color dd 0ah
align 16
;fb space, 0
space:

pad512
org 0x00104000
gdtr: ;first empty entry used to point the table itself
  dw gdt_end - gdtr - 1
  dd gdtr
  dw 0
gdt_index = 8
gdt_entry sel_kcode, 0, 0xFFFFF, 0x9A, 0xC ;kcode
gdt_entry sel_kdata, 0, 0xFFFFF, 0x92, 0xC ;kdata
gdt_end:

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
idt_entry sel_kcode, irq0, 0x8E ;PIT
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

kb_scancode_to_character:
db   0,   0, '1', '2', '3', '4', '5', '6'
db '7', '8', '9', '0', "'", 'ì',   8,	9 ;backspace, tab
db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'
db 'o', 'p', 'è', '+',	10,   0, 'a', 's'
db 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ò'
db 'à',   0,   1, 'ù', 'z', 'x', 'c', 'v'
db 'b', 'n', 'm', ',', '.', '-',   1, '*'

kb_size dd 0
kb_index dd 0
kb_buffer:

pad512