   DOSSEG
   .MODEL tiny
   .STACK 100h

   ITERS_BASE EQU 6600
   ITERS      EQU 11

   .DATA
   
   buffer DB 256 DUP  (0)
   errors DB 1024 DUP (0ffh)

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
   mov al, 32
   mov bx, 1
   int 10h

   pop cx
   pop bx
   pop ax
   ret
_print_hex ENDP

start:
   mov ax, @data
   mov ds, ax
   mov es, ax
   mov si, offset buffer
   mov di, offset buffer
   mov bx, offset errors
   xor bp, bp
   xor dx, dx

   in al, 0a0h          ; disable NMI
   and al, 07fh
   out 0a0h, al

   ; turn off DRAM refresh
   mov al, 072h         ; PIT channel 1, lo/hi byte, mode 1, binary
   out 43h, al
   mov al, 1            ; low byte = 1
   out 41h, al          ; channel 1 data port
   xor al, al           ; high byte = 0
   out 41h, al

   mov ax, ds
   add ax, 1000h
   mov ds, ax
   mov es, ax

   mov cx, 256
   mov al, 0ffh
   rep stosb

   mov di, offset buffer

iter_loop1:
   mov cx, 256
   xor ax, ax
check_loop:
   lodsb
   cmp al, 0ffh
   je no_error
   inc ah
no_error:
   loop check_loop

   mov cx, 256
   mov al, 0ffh
;   rep stosb

   mov cx, ds
   sub cx, 1000h
   mov ds, cx
   mov es, cx

   mov [bx], ah
   inc bx
   inc bp
   cmp bp, ITERS
   jne not_done
   jmp done
not_done:

   mov dx, bp
   add dx, ITERS_BASE
   mov si, offset buffer

   mov di, offset buffer

iter_loop2:
   rept 256
   nop
   endm

   rept 16       ; 1ms delay
   mov cl, 56
   shl ax, cl
   endm

   dec dx
   jz done_iter2
   jmp iter_loop2
done_iter2:

   mov ax, ds
   add ax, 1000h
   mov ds, ax
   mov es, ax

   jmp iter_loop1

done:

   ; turn on DRAM refresh
   mov al, 074h         ; PIT channel 1, lo/hi byte, mode 2, binary
   out 43h, al
   mov al, 18           ; low byte = 18
   out 41h, al          ; channel 1 data port
   xor al, al           ; high byte = 0
   out 41h, al

   mov bx, 1000h        ; blank memory, starting at second bank of 64kb
   mov es, bx
   xor di, di
   xor ax, ax
   mov dx, 9

clear_mem_loop:
   mov cx, 8000h
   rep stosw
   add bx, 1000h
   mov es, bx
   dec dx
   jnz clear_mem_loop

   mov cx, ITERS
   mov bx, offset errors

error_print_loop:
   xor dx, dx
   mov dl, [bx]
   inc bx

   push bx

   call _print_hex
   pop bx

   loop error_print_loop

   xor ah, ah           ; wait for keypress
   int 16h

;   in al, 0a0h          ; enable NMI
;   or al, 080h
;   out 0a0h, al

   mov ah, 04ch         ; exit to DOS
   int 21h

   END start