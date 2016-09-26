alone equ
include 'frazzo.inc'

file 'boot.bin'

  db 0
pad512

displayf ($-$$)/512
display ' bootII', 13, 10
file 'boot2.bin'

displayf ($-$$)/512
display ' kernel', 13, 10
file 'kernel.bin'

times 1474560 - ($-$$) db 0