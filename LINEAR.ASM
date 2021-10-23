   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; change into CGA mode 4
   mov ax, 4
   int 10h

   mov dx, 03d4h
   mov ax, (256*3)+5  ; vertical adjust = 3 
   out dx, ax
   mov ax, (256*0)+9  ; max char scanline = 0
   out dx, ax

   ; offset = 0
   xor di, di

   ; draw horizontal bars at byte i on line i
   mov cx, 80
   mov al, 0ffh       ; four white pixels
bar_loop:
   stosb              ; draw bar, inc. offset

   add di, 80         ; offset += 80
   loop bar_loop

   ; wait for keypress
   mov ah, ah
   int 16h

   ; restore text mode
   mov ax, 3
   int 10h

   ; exit to DOS
   mov ah, 4ch
   int 21h
   END

