alone ;trap

SECT_BOOT equ 1
SECT_FRFS equ 1
SECT_BOOT_II equ 1

SECT_PREKERNEL equ (SECT_BOOT + SECT_FRFS + SECT_BOOT_II)
SECT_KCODE equ 2
SECT_KDATA equ 1
SECT_KERNEL equ (SECT_KCODE + SECT_KDATA)

KERNEL_LOAD_ADDRESS equ 0x20000

macro displayf num {
  if num > 0
   local param, pot, cond, a, b, c
   param = num
   pot = 1000000000
   cond = 0
   repeat 10
    a = param mod pot
    b = (param - a)
    c = b / pot
    if (cond > 0) | (c > 0)
     cond = 1
     c = c + '0'
     display c
    end if
    param = a
    pot = pot / 10
   end repeat
  else
   display '0'
  end if
}
macro displayfnl num {
  displayf num
  display 13, 10
}
macro pad512 {
  a = 512 - (($-$$) mod 512)
  if a > 0
    times a db 0
  end if
  displayfnl ($-$$)/512
}
macro align value {
  if $ mod value > 0
   times $ mod value db 0
  end if
}
macro calign value { ;fill with instrunctions instead of zeroes
  a = $ mod value
  repeat a / 7
   db 0x8D, 0xB4, 0x26, 0, 0, 0, 0 ;lea esi, [esi+0]
   a = a - 7
  end repeat
  repeat a / 2
   mov edi, edi
   a = a - 2
  end repeat
  repeat a
   nop
  end repeat
}
macro ccall func, [args] {
  common index = 0
  forward
    mov [esp+index], args
    index = index + 4
  common call func
}

macro gdt_entry base, size, access_byte, flags {
  dw (size and 0xffff)
  dw (base and 0xffff)
  db ((base shr 16) and 0xff)
  db access_byte
  db ( ((size shr 16) and 0xf) or (flags shl 4) )
  db ((base shr 24) and 0xff)
}
SEL_KCODE equ 0x08
SEL_KDATA equ 0x10
SEL_KSTACK equ 0x18
SEL_VIDEORAM equ 0x20
SEL_1stMB equ 0x28
SEL_RELOC equ 0x30

macro fb alabel, [data] {
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