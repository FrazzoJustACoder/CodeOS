kernel ;trap

;IA32_APIC_BASE_MSR equ 0x1B
;IA32_APIC_BASE_MSR_BSP equ 0x100
;IA32_APIC_BAS_MSR_ENABLE equ 0x800

MPIC_CMD equ 0x20 ;master PIC
MPIC_DATA equ 0x21
SPIC_CMD equ 0xA0 ;slave PIC
SPIC_DATA equ 0xA1
PIC_EOI equ 0x20 ;end of interrupt command
macro send_eoi irq {
  mov al, PIC_EOI
  if irq > 7
    out SPIC_CMD, al
  end if
  out MPIC_CMD, al
}

PIC_init:
  mov al, 0x01 or 0x10 ;4th command byte | init
  out MPIC_CMD, al
;  nop7
  mov esi, esi
  out SPIC_CMD, al
  nop7
  mov al, 0x20 ;new offset of IRQs from master PIC
  out MPIC_DATA, al
;  nop7
  mov al, 0x28 ;new offset of IRQs from slave PIC
  out SPIC_DATA, al
  nop7
  mov al, 4 ;slave PIC at IRQ2
  out MPIC_DATA, al
;  nop7
  mov al, 2 ;tell slave about cascade
  out SPIC_DATA, al
  nop7
  mov al, 0x01 ;8086/88 mode
  out MPIC_DATA, al
;  nop7
  out SPIC_DATA, al
  nop7
  mov al, 0xFF
  out MPIC_DATA, al
  out SPIC_DATA, al
  ret

PIC_set_mask: ;bIRQ
  mov cl, [esp+4]
  and cl, 0x0F
  test cl, 0x08
  jz .master
  mov dx, SPIC_DATA
  jmp .ok
  .master:
  mov dx, MPIC_DATA
  .ok:
  in al, dx
  mov ah, 1
  shl ah, cl
  or al, ah
  out dx, al
  ret

PIC_clear_mask: ;bIRQ
  mov cl, [esp+4]
  and cl, 0x0F
  test cl, 0x08
  jz .master
  mov dx, SPIC_DATA
  jmp .ok
  .master:
  mov dx, MPIC_DATA
  .ok:
  in al, dx
  mov ah, 1
  shl ah, cl
  not ah
  and al, ah
  out dx, al
  ret

irq0:
;irq1:
cascade:
irq3:
irq4:
irq5:
irq6:
irq7:
  ud2
  send_eoi 0
  iret
irq8:
irq9:
irq10:
irq11:
irq12:
irq13:
irq14:
irq15:
  ud2
  send_eoi 8
  iret