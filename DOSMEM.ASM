   DOSSEG
   .MODEL tiny
   .STACK 100h
   .CODE

_print_hex PROC
   ; expects 16 bit value to print in dx
   push ax
   push bx
   push cx

   mov cx, 4
print_loop:
   rol dx, 1
   rol dx, 1
   rol dx, 1
   rol dx, 1
   mov al, dl
   and al, 0fh
   cmp al, 9
   ja letter
   add al, 30h
   jmp print
letter:
   add al, 37h
print:
   mov ah, 0eh
   mov bx, 1
   int 10h
   loop print_loop

   mov ah, 0eh
   mov al, 13
   mov bx, 1
   int 10h

   pop cx
   pop bx
   pop ax
   ret
_print_hex ENDP

start:
   mov dx, cs           ; get current code segment address

   call _print_hex      ; print segment address to screen in hex

   xor ah, ah           ; wait for keypress
   int 16h

   mov ah, 04ch         ; exit to DOS
   int 21h

   END start