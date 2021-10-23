   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA
   .CODE
   
_cga_point PROC   
   ARG x:WORD, y:WORD, colour:BYTE
   push bp
   mov bp, sp
   push di

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; offset += 4*8192 if y odd
   xor di, di
   mov ax, y
   shr ax, 1
   rcr di, 1

   ; add 4*80*(y/2) to offset
   xchg ah, al
   add di, ax
   shr ax, 1
   shr ax, 1
   add di, ax
   
   ; compute x mod 4 and divide di by 4
   mov cx, x
   add di, cx
   and cl, 3
   shr di, 1
   shr di, 1

   ; compute colour and mask
   mov ah, colour
   mov al, 03fh
   shl cl, 1
   ror al, cl
   inc cl
   inc cl
   ror ah, cl

   ; draw pixels
   and al, es:[di]
   or al, ah 
   stosb

   pop di
   pop bp
   ret
_cga_point ENDP

start:

   mov ax, 4
   int 10h

   mov si, 199

point_loop:
   mov al, 1
   push ax
   push si
   push si
   call _cga_point
   add sp, 6

   dec si
   jns point_loop

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
