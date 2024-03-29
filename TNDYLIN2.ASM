   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA
   .CODE
   
_tga_point PROC   
   ARG x:WORD, y:WORD, colour:BYTE
   push bp
   mov bp, sp
   push di

   ; set up TGA segment
   mov ax, 0b800h
   mov es, ax

   ; offset = 2*160*y
   mov ax, y
   xchg ah, al
   mov di, ax
   shr ax, 1
   shr ax, 1
   add di, ax
   
   ; compute x mod 2 and divide di by 2
   add di, x
   shr di, 1

   ; compute colour and mask
   sbb bl, bl
   xor bl, 0fh

   mov bh, colour
   mov al, bh
   shl al, 1
   shl al, 1
   shl al, 1
   shl al, 1
   add bh, al

   ; draw pixels
   mov ax, bx
   and al, es:[di]
   not bl
   and ah, bl
   or al, ah 
   stosb

   pop di
   pop bp
   ret
_tga_point ENDP

start:

   ; set TGA video mode 9 = 320x200 16 colours
   mov ax, 9
   int 10h

   mov dx, 15

colour_loop:
   mov si, 199

point_loop:
   push dx
   push si
   add si, dx
   push si
   sub si, dx
   call _tga_point
   add sp, 6

   dec si
   jns point_loop

   dec dx
   jnz colour_loop

   ; wait for keypress
   xor ah, ah
   int 16h

   ; wait for vertical retrace
   mov dx, 03dah
wait_retrace:
   in al, dx
   test al, 8
   jz wait_retrace

   ; get current CRT/CPU page register
   ; BH = CRT page, BL = CPU page
   mov ax, 0580h
   int 10h

   ; set CPU/CRT page register
   mov al, bl            ; CPU page
   mov cl, 3
   shl al, cl
   or al, bh             ; CRT page
   mov dx, 3dfh
   out dx, al

   ; set extended RAM page register
   mov al, 1             ; extended addressing mode bit
   mov dx, 3ddh
   out dx, al

   ; wait for active region
   mov dx, 03dah
wait_active:
   in al, dx
   test al, 1
   jnz wait_active
   
   mov dl, 0d4h
   
   mov ax, 0*256+9      ; max. char scanline
   out dx, ax
   mov ax, 255*256+4    ; vert. total chars 
   out dx, ax
   mov ax, 200*256+6    ; vert. disp. chars
   out dx, ax
   mov ax, 224*256+7    ; vert. sync. posn.
   out dx, ax
   
   ; wait for keypress
   xor ah, ah
   int 16h
   
   ; wait for vertical retrace
   mov dx, 03dah
wait_retrace2:
   in al, dx
   test al, 8
   jz wait_retrace2

   ; get current CRT/CPU page register
   ; BH = CRT page, BL = CPU page
   mov ax, 0580h
   int 10h

   ; set CPU/CRT page register
   mov al, bl            ; CPU page
   mov cl, 3
   shl al, cl
   or al, bh             ; CRT page
   xor al, 192           ; set bits 6 and 7
   mov dx, 3dfh
   out dx, al

   ; set extended RAM page register
   xor al, al             ; extended addressing mode bit
   mov dx, 3ddh
   out dx, al

   ; wait for active region
   mov dx, 03dah
wait_active2:
   in al, dx
   test al, 1
   jnz wait_active2
   
   mov dl, 0d4h
   
   mov ax, 3*256+9      ; max. char scanline
   out dx, ax
   mov ax, 63*256+4    ; vert. total chars 
   out dx, ax
   mov ax, 50*256+6    ; vert. disp. chars
   out dx, ax
   mov ax, 56*256+7    ; vert. sync. posn.
   out dx, ax

   ; wait for keypress
   xor ah, ah
   int 16h

   ; restore video mode
   xor ah, ah
   mov al, 3
   int 10h

   mov  ah,4ch                      ;DOS terminate program function
   int  21h                         ;terminate the program
   END start
