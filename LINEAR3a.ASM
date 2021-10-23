   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .CODE

   ; set up CGA segment
   mov ax, 0b800h
   mov es, ax

   ; wait for keypress
   xor ah, ah
   int 16h

   ; intercept timer interrupt
   cli
   xor ax, ax
   mov ds, ax
   mov ax, WORD PTR ds:[4*8]
   mov cs:[irq_off_save], ax
   mov ax, WORD PTR ds:[4*8+2]
   mov cs:[irq_seg_save], ax
   mov WORD PTR ds:[8*4], offset irq0_handler
   mov WORD PTR ds:[8*4+2], cs
   sti

   ; change into CGA mode 4
   mov ax, 4
   int 10h

   mov dx, 03d4h
   mov ax, (256*3)+5  ; vertical adjust = 3 
   out dx, ax
   mov ax, (256*0)+9  ; max char scanline = 0
   out dx, ax
   mov ax, (256*109)+7 ; vertical sync = 109
   out dx, ax

   ; offset = 0
   xor di, di

   ; draw vertical lines at edges of active region
   mov bx, 100

bar_loop:   
   mov al, 0c0h       ; left bar
   stosb              ; draw bar, inc. offset

   add di, 78

   mov al, 03h        ; right bar
   stosb
   
   dec bx
   jnz bar_loop

   mov cx, 10000
   mov dx, 03dah
   
   cli

frame_loop:
await_vertical_retrace:
   in al, dx   
   test al, 8
   jz await_vertical_retrace

   dec dx             ; set green background
   mov al, 10
   out dx, al

   inc dx
await_no_vertical_retrace:
   in al, dx
   test al, 8
   jnz await_no_vertical_retrace 
   
   dec dx
   mov al, 12         ; set red background
   out dx, al

   mov bx, 100
   inc dx
active_loop:
await_active:   
   in al, dx
   test al, 1
   jnz await_active
   
   dec dx
   mov al, 9          ; set blue background
   out dx, al

   inc dx
await_no_active:
   in al, dx
   test al, 1
   jz await_no_active

   dec dx
   mov al, 13          ; set magenta background
   out dx, al

   inc dx
   dec bx
   jnz active_loop

   loop frame_loop

   sti
   
   mov ax, cs:[irq_off_save]
   mov WORD PTR ds:[4*8], ax
   mov ax, cs:[irq_seg_save]
   mov WORD PTR ds:[4*8+2], ax

   ; restore text mode
   mov ax, 3
   int 10h

   ; exit to DOS
   mov ah, 4ch
   int 21h

   irq_off_save DW ?
   irq_seg_save DW ?

irq0_handler:
   ; acknowledge interrupt
   push ax
   mov al, 020h
   out 020h, al
   pop ax
   iret

   END

