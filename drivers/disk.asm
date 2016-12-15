kernel ;trap

;primary
;0x1F0 -> 0x1F7
;0x3F6
;irq14
;secondary
;0x170 -> 0x177
;0x376
;irq15

P_DATA equ 0x1F0 ;16bit port
P_SECTORCOUNT equ 0x1F2
P_LBALO equ 0x1F3
P_LBAMID equ 0x1F4
P_LBAHI equ 0x1F5
P_DRIVE_SEL equ 0x1F6
P_CMD equ 0x1F7
P_DCR_AS equ 0x3F6

SEL_MASTER equ 0xA0
SEL_SLAVE equ 0xB0
SEL_TR_MASTER equ 0xE0
SEL_TR_SLAVE equ 0xF0

CMD_READ_SECTORS equ 0x20
CMD_WRITE_SECTORS equ 0x30
CMD_FLUSH equ 0xE7
CMD_IDENTIFY equ 0xEC

macro outw port, data {
  mov dx, port
  out dx, data
}
macro inw data, port {
  mov dx, port
  in data, dx
}

disk_init:
  ;select hard disk
  mov al, SEL_MASTER
  outw P_DRIVE_SEL, al
  mov [disk_plstsel], byte 0 ;primary master
  ;identify

;  xor eax, eax
;  outw P_SECTORCOUNT, eax ;hackish

  mov al, 0
  mov dx, P_SECTORCOUNT
  out dx, al
  repeat 3
   inc dx
   out dx, al
  end repeat

  mov al, CMD_IDENTIFY
  outw P_CMD, al
  in al, dx
  test al, al
  jz error1
  mov cx, 20000
  .poll1:
   in al, dx
   dec cx
   jz error2
   test al, 0x80
   jnz .poll1
  inw al, P_LBAMID
  test al, al
  jnz error3
  inw al, P_LBAHI
  test al, al
  jnz error3
  mov dx, P_CMD
  .poll2:
   in al, dx
   test al, 0x01
   jnz error4
   test al, 0x08
   jz .poll2
  mov ecx, 256
  mov edi, space
  mov dx, P_DATA
  rep insw

  ;fill DD structure for hard disk
  mov ax, [space+3*2]
  mov [hdd_data.heads], ax
  mov ax, [space+1*2]
  mov [hdd_data.cylinders], ax
  mov ax, [space+6*2]
  mov [hdd_data.sectors], ax
  mov eax, [space+60*2]
  mov [hdd_data.lba28], eax
  mov ax, [space+83*2]
  test ax, 1 shl 10
  jz .zero
  mov eax, [space+100*2]
  mov dword [hdd_data.lba48], eax
  mov eax, [space+102*2]
  mov dword [hdd_data.lba48+4], eax
  jmp .ok
  .zero:
  xor eax, eax
  mov dword [hdd_data.lba48], eax
  mov dword [hdd_data.lba48+4], eax
  .ok:
  ;size up to 128GB for now
  mov eax, [hdd_data.lba28]
  xor edx, edx

  test eax, eax
  jz bigger48

  cmp eax, 64*GB/512
  jae .gb
  cmp eax, 64*MB/512
  jae .mb
  cmp eax, 64*KB/512
  jae .kb
  ;.b
  mov dl, 0
  shl eax, 9;eax*512
  jmp .common
  .kb:
  mov dl, 1
  shr eax, 1;eax*512/1024
  jmp .common
  .mb:
  mov dl, 2
  shr eax, 11;eax*512/(1024*1024)
  jmp .common
  .gb:
  mov dl, 3
  shr eax, 21
  ;jmp .common
  .common:
  ror edx, 8
  or edx, eax
  mov [hdd_data.size], edx
  ret

  bigger48:
  mov eax, dword [hdd_data.lba48]
  mov ebx, dword [hdd_data.lba48+4]

  cmp eax, 64*KB/512
  jb .b
  cmp eax, 64*MB/512
  jb .kb
  cmp eax, 64*GB/512
  jb .mb
  cmp ebx, 0x20 ;64 TB
  jb .gb
  jmp 0xDEADC0DE ;larger than 64 TB

;  cmp eax, 64*GB/512
;  jae .gb
;  cmp eax, 64*MB/512
;  jae .mb
;  cmp eax, 64*KB/512
;  jae .kb
  .b:
  mov dl, 0
  shl eax, 9;eax*512
  jmp .common
  .kb:
  mov dl, 1
  shr eax, 1;eax*512/1024
  jmp .common
  .mb:
  mov dl, 2
  shr eax, 11;eax*512/(1024*1024)
  jmp .common
  .gb:
  mov dl, 3
  shr eax, 21
  ror ecx, 21
  or eax, ecx
  ;jmp .common
  .common:
  ror edx, 8
  or edx, eax
  mov [hdd_data.size], edx
  ret



error1:
  mov [delete2], byte '1'
  jmp errorc
error2:
  mov [delete2], byte '2'
  jmp errorc
error3:
  mov [delete2], byte '3'
  jmp errorc
error4:
  mov [delete2], byte '4'
  ;jmp errorc
errorc:
  mov [esp], dword delete1
  call print
  jmp _hlt

;SelDisk:
;  [disk_last_selected]
ReadDisk: ;dwLba28, bSectCount, lpPoiner ;just for reading the hard disk atm
  mov ebx, [esp+4]
  mov edi, [esp+8]
  call DiskSendLba28

  mov dx, P_CMD
  mov al, CMD_READ_SECTORS
  out dx, al
  call DiskPoll
  test al, al
  jnz 0xDEADC0DE
  mov ebx, [esp+8]
  mov edi, [esp+12]
  mov dx, P_DATA
  xor eax, eax
  .reading:
    mov ecx, 256
    rep insw
    dec ebx
    jz .end
    call DiskPoll
    test al, al
    jz .reading
  mov eax, -1
  .end:
  ret

WriteDisk: ;dwLba28, bSectCount, lpBuffer
  mov ebx, [esp+4]
  mov edi, [esp+8]
  call DiskSendLba28

  mov dx, P_CMD
  mov al, CMD_WRITE_SECTORS
  out dx, al
  call DiskPoll
  test al, al
  jnz 0xDEADC0DE
  mov ebx, [esp+8]
  mov esi, [esp+12]
  mov dx, P_DATA
  xor eax, eax
  .writing:
    mov ecx, 256
    .rep:
      outsw
      mov esi, esi
      loop .rep
    dec ebx
    jz .end
    call DiskPoll
    test al, al
    jz .writing
  mov eax, -1
  .end:
  push eax
  mov al, CMD_FLUSH
  mov dx, P_CMD
  out dx, al
  pop eax
  ret

DiskSendLba28:
  and ebx, 0x0FFFFFFF
  mov al, SEL_TR_MASTER
  mov ecx, ebx
  shl ecx, 24
  or al, cl
  mov dx, P_DRIVE_SEL
  out dx, al

  mov dx, P_SECTORCOUNT
  mov eax, edi ;[esp+8]
  out dx, al

  mov ecx, 3
  .writelba:
   inc dx
   mov al, bl
   out dx, al
   shr ebx, 8
   loop .writelba
  ret

DiskPoll:
  mov dx, P_CMD
   xor eax, eax
  .poll:
    in al, dx
    test al, 0x80
    jnz .poll
  .poll2:
    in al, dx
    test al, 0x21
    jnz .error
    test al, 0x8
    jz .poll2
   mov al, 0
   .error:
   ret

FormatDisk: ;szLabel
  push ebp
  mov ebp, esp
  sub esp, 16

  mov edi, space
  xor eax, eax
  mov ecx, 128
  rep stosd

  mov dword [space], 'F'*256*256 + 'R'*256*256*256
  mov dword [space+4], 'F' + 'S'*256 + 24*256*256
  mov edi, space+8
  mov esi, [ebp+8]
  mov ecx, 2
  rep movsd
  mov dword [space+16], 24 + 1*256*256
  mov dword [space+20], 0

  mov [esp], dword 0
  mov [esp+4], dword 1
  mov [esp+8], dword space
  call WriteDisk

  call .param
  db 'Disk successfully formatted.', 0
  .param:
  call print
  call crlf

  leave
  ret