include 'frazzo.inc'

F_NORMALFILE equ 0
F_EXECUTABLE equ 0x01
F_READONLY equ 0x02
F_CESARCRYPTED equ 0x04 ;lol
F_SEQCRYPTED equ 0x08 ;lol
F_DIRECTORY equ 0x10
;F_FRAZZO equ ;= all permissions

macro entry name, address, size, flags { ;max size of name: 15,
     ;give the logical addres, size in sectors
     ;use 'or' for multiple flags
  a = $
  db name
  b = $ - a
  if b > 15
    display name, 13, 10, 'Nome troppo lungo', 0
    abort ;unexisting istruction to stop the assembly process
  end if
  times b db 0
  if address > 0
    dd address
  else
    dd now
    now = now + 1
  end if
  dd flags
}

file 'boot.bin'

;frfs custom frazzo filesystem (always at logical 1)
a = $
db 'FRFS' ;signature for frfs
dw 32 ;size (in bytes) of this header
db 1 ;size of the filesystem (in sectors)
dw 2 ;sectors reserved for kernel after this filesystem
db 24 ;size of each entry (in bytes)
times 16 - ($ - a) db 0
a = $
db 'FrazzoOS', 0 ;label of the disk
times 16 - ($ - a) db 0

now = SECTORSFORKERNEL + SECTORSFORBOOT + SECTORSFORFRFS

;kernel and bootleader are not linked in the filesystem

entry 'edit.bin', 0, 1, F_EXECUTABLE;I'll try to execute programsin future

SectorAlign

file 'kernel.bin'
file 'programs\edit.bin'

FLOPPY equ 1474560 ;size in bytes of a 1.44MB floppy disk

times FLOPPY - ($-$$) db 0

;to build on windows:
;copy /Y /B FrazzoOS.bin FrazzoOS.img
;you'll obtain a bootable floppy image