   DOSSEG
   .MODEL SMALL
   
   .STACK 100h
   .DATA

   .CODE
   
DECIMAL_TOP MACRO
   ; assumes binary number n in range [0, 65535] is in ax
   ; returns first two decimal digits (from the left) in
   ; unpacked BCD in ah, al and remainder in dx
   
   push bx
   
   xor dx, dx           ; n = al*1000 + dx
   mov bx, 1000

   div bx
   
   aam
   pop bx
ENDM

DECIMAL_BOTTOM MACRO
   ; assumes binary number n in range [0, 999] is in ax
   ; returns three decimal digits (from the left) in
   ; unpacked BCD in ah, al, dl

   mov dl, 10
   div dl

   mov dl, ah          ; n = ah*100 + al*10 + dl
   aam
ENDM

print_decimal PROC
   ; assumes value to print is in AX
   push ax
   push bx
   push dx

   DECIMAL_TOP          ; get top two digits

   mov bx, dx           ; save remainder

   xchg ah, al
   mov dx, ax
   add dx, 3030h        ; convert to ASCII

   mov ah, 02h          ; print character
   int 21h

   mov dl, dh           ; print character
   int 21h

   mov ax, bx

   DECIMAL_BOTTOM       ; get bottom 3 characters

   mov bx, dx           ; save dx

   xchg ah, al
   mov dx, ax

   add dx, 3030h        ; convert to ASCII

   mov ah, 02h          ; print character
   int 21h

   mov dl, dh           ; print character
   int 21h

   mov dx, bx
   
   add dl, 30h          ; convert to ASCII

   int 21h              ; print character

   pop dx
   pop bx
   pop ax
   ret
print_decimal ENDP

start:   
   xor ax, ax   

integer_loop:
   call print_decimal

   mov bx, ax
   
   mov ah, 02h

   mov dl, 13           ; print CR LF
   int 21h

   mov dl, 10
   int 21h

   mov ax, bx

   inc ax
   jnz integer_loop

   ; wait for keypress
   mov ah, 0
   int 16h
   
   ; exit to DOS
   mov ah, 4ch
   int 21h
   
   END start
