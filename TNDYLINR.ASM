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

   ; offset += 2*8192*bank
   mov ax, y
   ror ax, 1
   ror ax, 1
   mov di, ax
   xor ah, ah
   sub di, ax

   ; add 2*160*(y/4) to offset
   xchg ah, al
   add di, ax
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
   
   ; restore video mode
   xor ah, ah
   mov al, 3
   int 10h

   mov  ah,4ch                      ;DOS terminate program function
   int  21h                         ;terminate the program
   END start
