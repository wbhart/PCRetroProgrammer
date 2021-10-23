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

   ; palette 0
   xor al, al
   mov dx, 03d9h
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

   ; colour 1
   mov al, 85
   
   xor di, di

   ; fill first bank
   mov bx, 2
hires_loop1:
   mov dx, 25
scanline_loop1:
   mov cx, 160
   rep stosb
   dec dx
   jnz scanline_loop1

   add al, 85
   dec bx 
   jnz hires_loop1

   ; blank remaining bytes
   xor al, al
   mov cx, 192
   rep stosb

   mov al, 170

   ; fill second bank
   mov bx, 2
hires_loop2:
   mov dx, 25
scanline_loop2:
   mov cx, 160
   rep stosb
   dec dx
   jnz scanline_loop2

   add al, 85
   dec bx 
   jnz hires_loop2

   ; blank remaining bytes
   xor al, al
   mov cx, 192
   rep stosb

   ; get keypress
   xor ah, ah
   int 16h

   xor di, di
   
   mov bl, es:[di]
   mov BYTE PTR es:[di], 0

cursor_loop:   
   ; get keypress
   xor ah, ah
   int 16h

   ; check for q = quit
   cmp al, 113
   je hires_done

   ; check for d = next byte
   cmp al, 100
   jne cursor_not_d

   mov es:[di], bl
   inc di
   mov bl, es:[di]
   mov BYTE PTR es:[di], 0

   jmp cursor_loop

cursor_not_d:
   ; check for s = next scanline
   cmp al, 115
   jne cursor_loop

   mov es:[di], bl
   sub di, 8032
   jnc d_even
   add di, 16224
d_even:
   mov bl, es:[di]
   mov BYTE PTR es:[di], 0
   
   jmp cursor_loop

hires_done:   
   ; restore video mode
   xor ah, ah
   mov al, 3
   int 10h

   ; exit to DOS
   mov  ah,4ch
   int  21h
   END
