   DOSSEG
   .MODEL SMALL
   .STACK 100h
   .DATA

   .CODE

   old_timer_handler DD 0
   ticks             DW 0
   timer_on          DB 0

_hook_timer PROC
   cli
   
   ; set ES to interrupt vector table segment
   xor ax, ax
   mov es, ax
   
   ; get old vector
   mov bx, es:[4*1ch]
   mov dx, es:[4*1ch+2]

   ; insert new vector
   mov WORD PTR es:[4*1ch], offset _timer_interrupt
   mov es:[4*1ch+2], cs

   ; save old vector
   mov WORD PTR cs:[old_timer_handler], bx
   mov WORD PTR cs:[old_timer_handler+2], dx

   sti

   ret
_hook_timer ENDP

_unhook_timer PROC
   cli

   ; get old vector
   mov bx, WORD PTR cs:[old_timer_handler]
   mov dx, WORD PTR cs:[old_timer_handler+2]

   ; set ES to interrupt vector table segment
   xor ax, ax
   mov es, ax

   ; reinsert old vector
   mov es:[1ch*4], bx
   mov es:[1ch*4+2], dx

   sti

   ret
_unhook_timer ENDP

_timer_interrupt PROC
   pushf
   call DWORD PTR cs:[old_timer_handler]

   ; if timer is on
   cmp BYTE PTR cs:[timer_on], 0
   je skip_tick
   
   ; increment timer
   inc WORD PTR cs:[ticks]

skip_tick:

   iret
_timer_interrupt ENDP

_timer_start PROC
   mov WORD PTR cs:[ticks], 0
   mov BYTE PTR cs:[timer_on], 1

   ret
_timer_start ENDP

_timer_stop PROC
   mov BYTE PTR cs:[timer_on], 0

   ret
_timer_stop ENDP

_print_hex PROC
   ; value to print in AX

   mov cx, 4
digit_loop:

   ; get leftmost digit in al
   rol ax, 1
   rol ax, 1
   rol ax, 1
   rol ax, 1

   ; convert to character
   mov dl, al
   and dl, 0fh
   add dl, '0'

   ; deal with digits A..F
   cmp dl, '9'
   jbe digit_is_number

   ; convert to letter
   add dl, 7

digit_is_number:

   mov bx, ax

   ; DOS print character to stdout
   mov ah, 2
   int 21h

   mov ax, bx

   loop digit_loop
   ret
_print_hex ENDP

start:   
   ; setup data segment
   mov  ax, @data
   mov  ds, ax
   
   ; hook new timer interrupt handler
   call _hook_timer

   ; start timer
   call _timer_start

   ; wait for keypress
   mov ah, 0
   int 16h
   
   ; stop timer
   call _timer_stop
   
   ; print hex ticks
   mov ax, cs:[ticks]
   call _print_hex

   ; restore old timer interrupt handler
   call _unhook_timer

   ; exit to DOS
   mov ah, 4ch
   int 21h

   END start
