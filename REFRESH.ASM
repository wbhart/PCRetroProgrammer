   DOSSEG
   .MODEL tiny
   .STACK 100h

   .DATA

   handler_offset  DW 0
   handler_segment DW 0
   imr_save        DB 0

   .CODE

_refresh PROC
   rept 256
   nop
   endm
   ret
_refresh ENDP

_wait_floppy_motor PROC
   push ax
   push ds

   mov ax, 040h         ; BIOS data area
   mov ds, ax

check_motor_status:
   mov al, ds:[03fh]
   test al, 0fh ; test if motor is running
   jnz check_motor_status

   pop ds
   pop ax
   ret
_wait_floppy_motor ENDP

start:
   call _wait_floppy_motor

   mov ax, 4            ; CGA mode 4
   int 10h

   cli                  ; clear interrupts

   xor ax, ax           ; set segment for interrupt vector table
   mov ds, ax

   mov bx, WORD PTR ds:[8*4]   ; get IRQ0 handler offset
   mov dx, WORD PTR ds:[8*4+2] ; get IRQ0 handler segment

   mov WORD PTR ds:[8*4], offset irq0_handler ; set offset of IRQ0 handler
   mov WORD PTR ds:[8*4+2], cs ; set segment of IRQ0 handler
   
   mov ax, cs           ; restore DS
   mov ds, ax

   mov WORD PTR handler_offset, bx  ; save handler offset
   mov WORD PTR handler_segment, dx ; save handler segment

   mov dx, 03dah        ; CGA status register

wait_vertical_sync:
   in al, dx
   test al, 8
   jz wait_vertical_sync

wait_display_enable:
   in al, dx
   test al, 1
   jnz wait_display_enable

   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop

   mov al, 034h         ; PIT channel 0, lo/hi byte, mode 2, binary         
   out 043h, al         ; PIT mode/command register

   mov al, 200          ; low byte = 200
   out 040h, al         ; channel 0 data port
   mov al, 77           ; hi byte = 77 (77*256 + 200 = 19912)
   out 040h, al

   ; disable individual interrupts
   in al, 21h    ; get IMR
   mov BYTE PTR [imr_save], al
   or al, 0feh   ; disable everything except IRQ0
   out 21h, al

   ; disable DRAM refresh
   mov al, 072h         ; PIT channel 1, lo/hi byte, mode 1, binary
   out 43h, al
   mov al, 01           ; low byte = 1
   out 41h, al          ; channel 1 data port
   xor al, al           ; high byte = 0
   out 41h, al
  
   sti

frame_loop:
   hlt                  ; halt the CPU and wait for interrupt

   mov al, 0ah          ; select IRR
   out 20h, al
   in al, 20h           ; get IRR
   test al, 02h         ; check if IRQ1
   jz no_key
   jmp key_pressed
no_key:

   call _refresh

   jmp frame_loop

key_pressed:   
   in al, 60h    ; read keyboard buffer
   mov dl, al

   in al, 61h    ; get system crtl port
   mov ah, al
   or al, 80h    ; reset keyboard
   out 61h, al
   mov al, ah    ; rewrite original byte
   out 61h, al

   shl dl, 1     ; ignore key release
   jnc no_release
   jmp frame_loop
no_release:
   shr dl, 1

   cmp dl, 16    ; q = quit
   je exit
   jmp frame_loop
exit:

   cli

   ; enable individual interrupts
   mov al, BYTE PTR [imr_save]
   out 21h, al

   mov bx, handler_offset  ; retrieve old handler offset
   mov dx, handler_segment ; retrieve old handler segment

   xor ax, ax           ; set up offset for interrupt vector table
   mov ds, ax

   mov WORD PTR ds:[8*4], bx   ; restore old handler offset
   mov WORD PTR ds:[8*4+2], dx ; restore old handler segment

   mov al, 0ffh         ; low byte = FF
   out 040h, al         ; channel 0 data port
   mov al, 0ffh         ; hi byte = FF
   out 040h, al

   ; enable DRAM refresh
   mov al, 074h         ; PIT channel 1, lo/hi byte, mode 2, binary
   out 43h, al
   mov al, 18           ; low byte = 18
   out 41h, al          ; channel 1 data port
   xor al, al           ; high byte = 0
   out 41h, al

   sti                  ; enable interrupts

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

   mov ax, 3            ; back to text mode
   int 10h

   mov ah, 04ch         ; return to DOS
   int 21h

irq0_handler:
   push ax
   push dx

   mov dx, 03d9h         ; background colour
 
   mov al, 12            ; light red
   out dx, al

   xor al, al            ; black
   out dx, al

   pop dx
   mov al, 020h          ; EOI (End Of Interrupt)
   out 020h, al          ; master PIC command register
   pop ax

   iret

   END start
