   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; switch to +HRES+GRPH-1BPP
   mov al, 0bh
   mov dx, 03d8h
   out dx, al

   ; vertical total = 127
   mov dx, 03d4h
   mov ax, 127*256+4
   out dx, ax
   
   ; vertical displayed = 50
   mov ax, 50*256+6
   out dx, ax

   ; vertical sync = 87
   mov ax, 87*256+7
   out dx, ax

   ; max char scanline = 1
   mov ax, 1*256+9
   out dx, ax

   ; fill video RAM
   xor di, di
   xor ax, ax

   mov bx, 50
fill_loop:
   mov cx, 10
   rep stosb

   inc al
   and al, 15
   mov ah, al
   shl ah, 1
   shl ah, 1
   shl ah, 1
   shl ah, 1
   add al, ah

   jnz fill_loop
   dec bx
   jnz fill_loop

   ; zero remaining bytes
   mov cx, 192
   rep stosb

   mov bx, 50

   cmp di, 16384
   jne fill_loop 

   ; iterate bg, intensity and palettes
   mov cx, 64
   mov dx, 03d9h
bgpal_loop:
   mov al, cl
   dec al
   out dx, al

   ; wait for keypress
   xor ah, ah
   int 16h

   loop bgpal_loop

   ; switch to undoc. palette
   mov al, 0fh
   mov dx, 03d8h
   out dx, al

   mov dx, 03d9h
   mov cx, 32
bgpal_loop2:
   mov al, cl
   add al, 31
   out dx, al

   ; wait for keypress
   xor ah, ah
   int 16h

   loop bgpal_loop2

   ; restore video mode
   xor ah, ah
   mov al, 3
   int 10h

   ; exit to DOS
   mov  ah,4ch
   int  21h
   END
