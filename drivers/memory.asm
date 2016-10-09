kernel ;trap

memInit: ;
  ;PSE bit allows pages being 4MB size
  mov eax, cr4
  or eax, 0x00000010
  mov cr4, eax
  ret

memLock;dwSize: lpMemBlock
memFree;lpMemBlock