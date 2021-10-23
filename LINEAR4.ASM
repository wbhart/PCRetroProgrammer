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
   mov ax, WORD PTR ds:[4*8] ; save old handler
   mov cs:[irq_off_save], ax
   mov ax, WORD PTR ds:[4*8+2]
   mov cs:[irq_seg_save], ax
   mov WORD PTR ds:[8*4], offset irq0_handler1
   mov WORD PTR ds:[8*4+2], cs

   ; change into CGA mode 4
   mov ax, 4
   int 10h

   ; wait for vertical retrace
   mov dx, 03dah
wait_retrace:
   in al, dx
   test al, 8
   jz wait_retrace

   ; wait for active region
wait_active:
   in al, dx
   test al, 1
   jnz wait_active

   ; set up timer for repeat
   mov al, 034h
   out 043h, al
   
   ; wait 120 scanlines
   mov al, 160
   out 040h, al
   mov al, 35
   out 040h, al

   mov dx, 03d4h
   mov ax, (256*0)+9     ; max char scanline = 0
   out dx, ax
   mov ax, (256*6)+5     ; vertical adjust = 6
   out dx, ax
   mov ax, (256*127)+4   ; vertical total = 127
   out dx, ax
   mov ax, (256*127)+6   ; vertical displayed = 127
   out dx, ax
   mov ax, (256*127)+7   ; vertical sync position = 127
   out dx, ax

   ; delay = 113 scanlines
   mov al, 140
   out 040h, al
   mov al, 33
   out 040h, al

   sti

   ; offset = 0
   xor di, di

   ; draw vertical lines at edges of active region
   mov bx, 100

bar_loop1:   
   mov al, 0c0h       ; left bar
   stosb              ; draw bar, inc. offset

   mov cx, 78         ; blank remainder of line
   xor al, al
   rep stosb

   mov al, 03h        ; right bar
   stosb
   
   dec bx
   jnz bar_loop1

   ; draw vertical lines at edges of active region
   mov bx, 100

bar_loop2:   
   mov al, 080h       ; left bar
   stosb              ; draw bar, inc. offset

   mov cx, 78         ; blank remainder of line
   xor al, al
   rep stosb

   mov al, 02h        ; right bar
   stosb
   
   dec bx
   jnz bar_loop2

e: jmp e

   ; wait for keypress
   mov ah, ah
   int 16h

   ; restore timer interrupt
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

irq0_handler1:
   push ax
   push ds
   push dx

   mov dx, 03d4h
   mov ax, (256*110)+4   ; vertical total = 110
   out dx, ax
   mov ax, (256*72)+6   ; vertical displayed = 72
   out dx, ax
   mov ax, (256*95)+7   ; vertical sync position = 95
   out dx, ax

   ; wait 149 scanlines
   mov al, 60
   out 040h, al
   mov al, 44
   out 040h, al
   
   ; set handler 2
   xor ax, ax
   mov ds, ax
   mov WORD PTR ds:[8*4], offset irq0_handler2

   pop dx
   pop ds

   ; acknowledge interrupt
   mov al, 020h
   out 020h, al
   pop ax
   iret

irq0_handler2:
   push ax
   push ds
   push dx
   
   mov dx, 03d4h
   mov ax, (256*127)+4   ; vertical total = 127
   out dx, ax
   mov ax, (256*127)+6   ; vertical displayed = 127
   out dx, ax
   mov ax, (256*127)+7   ; vertical sync position = 127
   out dx, ax

   ; delay = 113 scanlines
   mov al, 140
   out 040h, al
   mov al, 33
   out 040h, al

   ; set handler 1
   xor ax, ax
   mov ds, ax
   mov WORD PTR ds:[8*4], offset irq0_handler1

   pop dx
   pop ds

   ; acknowledge interrupt
   mov al, 020h
   out 020h, al
   pop ax
   iret

   END

