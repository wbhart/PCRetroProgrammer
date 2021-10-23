   DOSSEG
   .MODEL small
   
   .CODE

   PUBLIC _mcga_start_address
_mcga_start_address PROC
   ARG addr:WORD
   push bp
   mov bp, sp

   mov ax, addr
   mov cl, al
   mov al, 0ch

   mov dx, 03d4h

   out dx, ax

   inc al
   mov ah, cl
   out dx, ax

   pop bp
   ret
_mcga_start_address ENDP
   
   PUBLIC _mcga_scroll
_mcga_scroll PROC
   ARG buff:DWORD
   push bp
   mov bp, sp
   push di
   push si
   push ds

   lds si, buff
   add si, 320

   mov ax, 0a000h
   mov es, ax
   mov di, 320

   xor ax, ax ; start address

   mov bx, 320
scroll_loop:

   push si
   push di
   push ax

   mov cx, ax

   mov dx, 03dah

wait_no_retrace:
   in al, dx
   test al, 8
   jnz wait_no_retrace

   push cx
   call _mcga_start_address
   add sp, 2

   mov dx, 03dah

wait_retrace:   
   in al, dx
   test al, 8
   jz wait_retrace
   
   mov cx, 50
scroll_loop1:
   movsw
   add si, 958
   add di, 318
   loop scroll_loop1

   mov ax, ds
   add ax, 3000
   mov ds, ax

   mov ax, es
   add ax, 1000
   mov es, ax

   sub si, 48000
   sub di, 16000
   
   mov cx, 50
scroll_loop2:
   movsw
   add si, 958
   add di, 318
   loop scroll_loop2

   mov ax, ds
   add ax, 3000
   mov ds, ax

   mov ax, es
   add ax, 1000
   mov es, ax

   sub si, 48000
   sub di, 16000
   
   mov cx, 50
scroll_loop3:
   movsw
   add si, 958
   add di, 318
   loop scroll_loop3

   mov ax, ds
   add ax, 3000
   mov ds, ax

   mov ax, es
   add ax, 1000
   mov es, ax

   sub si, 48000
   sub di, 16000
   
   mov cx, 50
scroll_loop4:
   movsw
   add si, 958
   add di, 318
   loop scroll_loop4

   pop ax
   pop di
   pop si

   inc ax
   
   inc si
   inc si
   inc di
   inc di

   mov cx, ds
   sub cx, 9000
   mov ds, cx

   mov cx, es
   sub cx, 3000
   mov es, cx

   dec bx
   jz scroll_done
   jmp scroll_loop

scroll_done:

   pop ds
   pop si
   pop di
   pop bp
   ret
_mcga_scroll ENDP

   PUBLIC _mcga_invert
_mcga_invert PROC
   ARG buff:DWORD

   push bp
   mov bp, sp
   push di
   push si
   push ds

   lds si, buff

   mov ax, ds
   add ax, 9000
   mov es, ax

   mov di, 47040

   mov dx, 50
invert_loop1:
      
   mov cx, 480
swap_loop1:

   mov ax, [si]
   xchg ax, es:[di]
   mov WORD PTR [si], ax

   inc si
   inc si
   inc di
   inc di

   loop swap_loop1

   sub di, 960*2

   dec dx
   jnz invert_loop1

   mov ax, ds
   add ax, 3000
   mov ds, ax

   sub si, 48000

   mov ax, es 
   sub ax, 3000
   mov es, ax

   mov di, 47040

   mov dx, 50
invert_loop2:
      
   mov cx, 480
swap_loop2:

   mov ax, [si]
   xchg ax, es:[di]
   mov WORD PTR [si], ax

   inc si
   inc si
   inc di
   inc di

   loop swap_loop2

   sub di, 960*2

   dec dx
   jnz invert_loop2

   pop ds
   pop si
   pop di
   pop bp
   ret
_mcga_invert ENDP

   PUBLIC _mcga_wide_load
_mcga_wide_load PROC
   ARG buff:DWORD

   push bp
   mov bp, sp
   push di
   push si
   push ds

   mov ax, 0a000h
   mov es, ax

   xor di, di

   lds si, buff

   mov bx, 50
wide_loop1:

   mov cx, 160
   rep movsw

   add si, 640

   dec bx
   jnz wide_loop1

   mov ax, ds
   add ax, 3000
   mov ds, ax

   xor si, si

   mov bx, 50
wide_loop2:

   mov cx, 160
   rep movsw

   add si, 640

   dec bx
   jnz wide_loop2

   mov ax, ds
   add ax, 3000
   mov ds, ax

   xor si, si

   mov bx, 50
wide_loop3:

   mov cx, 160
   rep movsw

   add si, 640

   dec bx
   jnz wide_loop3

   mov ax, ds
   add ax, 3000
   mov ds, ax

   xor si, si

   mov bx, 50
wide_loop4:

   mov cx, 160
   rep movsw

   add si, 640

   dec bx
   jnz wide_loop4

   pop ds
   pop si
   pop di
   pop bp
   ret
_mcga_wide_load ENDP

   END
