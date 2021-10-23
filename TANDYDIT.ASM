   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA
   .CODE
   
   ; set up TGA segment
   mov ax, 0b800h
   mov es, ax

   ; video mode 9 = 320x200 16 colour mode
   mov ax, 9
   int 10h

   ; set offset
   xor di, di
   
   xor bx, bx
   mov dx, 0f00fh

page_loop:

   mov si, 12
block_loop:

line_loop:
   
   mov ax, dx
   and ax, bx
   
   ; draw pixels
   mov cx, 10
   add al, ah
   rep stosb

   add bl, 17
   jnc line_loop

   xor bl, bl

   not dx
   add di, 8032

   cmp di, 32768
   jb skip_dec
   sub di, 32768-160
skip_dec:

   dec si
   jnz block_loop

   add bh, 17
   jnc page_loop

   ; wait for keypress
   xor ah, ah
   int 16h
   
   ; restore video mode
   mov ax, 3
   int 10h

   mov  ah, 4ch                     ;DOS terminate program function
   int  21h                         ;terminate the program
   END
