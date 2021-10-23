   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA
   .CODE
   
   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; video mode 4
   mov ax, 4
   int 10h

   ; set palette = 0
   mov ah, 0bh
   mov bx, 0100h
   int 10h

   ; set offset
   xor di, di
   
   ; draw pixels
   mov al, 081h    ; 10000001
   stosb

   ; wait for keypress
   xor ah, ah
   int 16h
   
   ; restore video mode
   mov ax, 3
   int 10h

   mov  ah, 4ch                     ;DOS terminate program function
   int  21h                         ;terminate the program
   END
