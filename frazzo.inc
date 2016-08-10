macro displayf arg {
  a = arg
  p = 1000000000
  repeat 10
    d = a - (a mod p)
    a = a - d
    c = d / p + '0'
    display c
    p = p/10
  end repeat
}

macro SectorAlign {
  t = 512 - (($-$$) mod 512)
  if t > 0
    times t db 0
  end if
  displayf ($-$$)/512
  display 13, 10
}

macro gdt_entry base, limit, access_byte, flags {
  dw (limit and 0xffff)
  dw (base and 0xffff)
  db ((base shr 16) and 0xff)
  db access_byte
  db ( ((limit shr 16) and 0xf) or (flags shl 4) )
  db ((base shr 24) and 0xff)
}

macro ccall func, [args] {
  forward
    mov [esp+%*4], args
  common call func
}

SECTORSFORBOOT equ 1
SECTORSFORFRFS equ 1
SECTORSFORKERNEL equ 1