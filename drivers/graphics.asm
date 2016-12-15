kernel ;trap

graphics_init:
;  mov ebx, [ebp]
  mov ebx, 0x00010000
  lea esi, [ebx+8]
  lodsd
  mov [gp_lfb], eax
  lodsd
  mov dword [gp_width], eax
  lodsd
  mov dword [gp_pitch], eax
  mul word [gp_height]
  shl edx, 16
  mov dx, ax
  xchg eax, edx
  mov [gp_pixels], eax
  movzx edx, byte [gp_bpp]
  mul edx
  mov [gp_totalsize], eax
  ret

gp_background: ;eax color data
  mov edi, [gp_lfb]
  mov ecx, [gp_pixels]
  cmp byte [gp_bpp], 8
  jne .32
  rep stosb
  ret
  .32:
  rep stosd
  ret

gp_select: ;esp+8 pointing to RECT structure (x,y,w,h) -> regs filled (right edi,
	   ;ebx width, edx height, ebp pitch-w)
  mov eax, [esp+12]
  mul dword [gp_pitch]
  mov edi, [esp+8]
  shl edi, 2
  add edi, eax
  add edi, [gp_lfb]
  mov ebx, [esp+16]
  mov edx, [esp+20]
  movzx ebp, word [gp_pitch]
  mov eax, ebx
  shl eax, 2
  sub ebp, eax
  ret

rect: ;x, y, w, h, color
  call gp_select
  mov eax, [esp+20]
  .fill:
   mov ecx, ebx
   rep stosd
   add edi, ebp
   dec edx
   jnz .fill
  ret

bitblt: ;x, y, w, h, px
  mov esi, [esp+20]
  call gp_select
  .transfer:
   mov ecx, ebx
   rep movsd
   add edi, ebp
   dec edx
   jnz .transfer
  pop ebp
  ret