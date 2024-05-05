   DOSSEG
   .MODEL tiny
   .STACK 100h
   .CODE

start:
   cli

   mov al, 074h         ; PIT channel 1, lo/hi byte, mode 2, binary
   out 43h, al
   mov al, 72           ; low byte = 72
   out 41h, al          ; channel 1 data port
   xor al, al           ; high byte = 0
   out 41h, al

   sti

   mov ah, 04ch
   int 21h

   END start