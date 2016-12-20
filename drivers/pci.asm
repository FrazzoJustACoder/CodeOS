kernel ;trap

CONFIG_ADDRESS equ 0xCF8
CONFIG_DATA equ 0xCFC

PciPrepareAddress: ;bBusNumber, bDeviceNumber, bFunctionNumber,bRegNumber<-packed
  mov ebx, [esp+4]
  or al, 1 ;bit31 -> actual bit0
  shl eax, 15 ;bit16 -> actual bit0
  mov al, bl
  shl eax, 5 ;bit11 -> 0
  and bh, 0x1F
  or al, bh
  rol ebx, 16
  shl eax, 3 ;bit8 -> 0
  and bl, 7
  or al, bl
  shl eax, 8 ;bit0 ->0
  and bh, 0xFC
  or al, bh
  ret

PciWriteDwReg: ;bBusNumber, bDeviceNumber, bFunctionNumber, bRegNumber, dwValue
;  mov ebx, esp
;  pushd [ebx+4]
  pushd [esp+4]
  call PciPrepareAddress
  add esp, 4
  mov dx, CONFIG_ADDRESS
  out dx, eax
  mov dx, CONFIG_DATA
  mov eax, [esp+8]
  out dx, eax
  ret

PciWriteBReg: ;bBusNumber,bDeviceNumber,bFunctionNumber,bRegNumber,bValue
;  mov ebx, esp
;  pushd [ebx+4]
  pushd [esp+4]
  call PciReadDwReg
  mov cl, [esp+8+3]
  and cl, 3
  mov ebx, 0xFFFFFF00
  shl cl, 3
  rol ebx, cl
  and eax, ebx
  ror eax, cl
  mov al, [esp+8+4]
  rol eax, cl
  mov [esp], eax
;  mov ebx, [esp+8]
;  push ebx
  pushd [esp+8]
  call PciWriteDwReg
  add esp, 8
  ret

PciWriteWReg: ;bBusNumber,bDeviceNumber,bFunctionNumber,bRegNumber,wValue
;  mov ebx, esp
;  pushd [ebx+4]
  pushd [esp+4]
  call PciReadDwReg
  mov cl, [esp+8+3]
  and cl, 2
  mov ebx, 0xFFFF0000
  shl cl, 3
  rol ebx, cl
  and eax, ebx
  ror eax, cl
  mov ax, [esp+8+4]
  rol eax, cl
  mov [esp], eax
;  mov ebx, [esp+8]
;  push ebx
  pushd [esp+8]
  call PciWriteDwReg
  add esp, 8
  ret

PciReadDwReg: ;bBusNumber, bDeviceNumber, bFunctionNumber, bRegNumber
;  mov ebx, esp
;  pushd [ebx+4]
  pushd [esp+4]
  call PciPrepareAddress
  add esp, 4
  mov dx, CONFIG_ADDRESS
  out dx, eax
  mov dx, CONFIG_DATA
  in eax, dx
  ret

PciReadBReg: ;bBusNumber, bDeviceNumber, bFunctionNumber, bRegNumber
  pushd [esp+4]
  call PciReadDwReg
  add esp, 4
  mov cl, [esp+7]
  and cl, 3
  shl cl, 3
  shr eax, cl
  movzx eax, al
  ret

PciReadWReg: ;bBusNumber, bDeviceNumber, bFunctionNumber, bRegNumber
  pushd [esp+4]
  call PciReadDwReg
  add esp, 4
  mov cl, [esp+7]
  and cl, 2
  shl cl, 3
  shr eax, cl
  movzx eax, ax
  ret

scout: ;bBusNumber, bDeviceNumber
;  mov ebx, esp
;  pushd [ebx+4]
  pushd [esp+4]
  mov [esp+2], word 0 ;function 0, register 0
  call PciReadDwReg
  cmp ax, 0xFFFF
  je .ret
  mov [esp+2], word 0x0800 ;function 0, register 08h
  call PciReadDwReg
  .ret:
  add esp, 4
  ret

BIST: ;bBusNumber, bDeviceNumber ;built-in self test
  pushd 0x40
  pushd [esp+8]
  mov [esp+3], byte 0Ch
  call PciWriteBReg
  mov esi, BIST_int
  mov bx, -1 ;18Hz
  call PIT_begintimer
  xor ebx, ebx
  .poll:
    call PciReadBReg
    test al, 0x40
    jz .passed
    cmp ebx, 36
    jl .poll ;after 2 seconds the drive fails
  .unsupported:
  .unpassed:
  xor eax, eax
  dec eax
  jmp .common
  .passed:
  test al, 0x80
  jz .unsupported
  test al, 15
  jnz .unpassed
  xor eax, eax
  .common:
  add esp, 8
  call PIT_killtimer
  ret

BIST_int:
  inc byte [esp+20] ;ebx pushed by pushad
  ret