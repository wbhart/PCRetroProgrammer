   DOSSEG
   .MODEL SMALL
   .STACK 100h
   
   .DATA

   iter    DB 0
   endline DW 0

   .CODE
   
   ; set up data segment
   mov ax, @data
   mov ds, ax
   
   ; change to VGA mode 13h (320x200 256 colours)
   mov ax, 13h
   int 10h

   ; Mandelbrot set iterates z -> z^2 + c in the
   ; complex numbers, starting with z = 0, and
   ; where c = a + bi is a complex number with
   ; -2 <= a <= 2 and -2 <= b <= 2
   ; (this region is a square in the complex plane)

   ; We draw this square on the screen, setting
   ; the pixel colour to the number of iterations
   ; it takes for the iteration to leave the circle
   ; of radius 2 in the complex plane. We set the
   ; pixel to black if it does not leave the circle
   ; after a certain number of iterations

   ; We will divide all values by 4 and use the
   ; iteration Z -> 4Z^2 + C which means we'll need
   ; values from -0.5 to 0.5 instead of -2.0 to 2.0
   ; We use 16 bit values

   ; DX:AX = accum, result of multiplication
   ; DI = offset in VRAM, BX = a, CX = b, SI = x, BP = y
   ; where Z = x + yi and C = a + bi 
   ; DS:[iter] = iterations (counting down to zero)
   ; DS:[endline] = offset of end of current line

   ; Pixel aspect ratio is 1:1.2, so we will use 240x200
   ; pixel region
   ; Moving in x-direction will add 1/240 = 0.0111h
   ; Moving in y-direction will add 1/200 = 0.0148h

   ; set up VRAM segment
   mov ax, 0a000h
   mov es, ax

   ; offset of first pixel
   xor di, di

   ; set a = -0.5 and b = -0.5
   mov bx, 8000h
   mov cx, bx

   ; set up offset of line end
   mov WORD PTR [endline], 240

pixel_loop:
   
   ; Z -> Z^2 + C   
   ;
   ;

   inc di
   cmp di, [endline]
   je end_of_line

   ; update a
   add bx, 0111h

next_line:

   cmp di, 64000
   jne pixel_loop

   ; wait for keypress
   xor ah, ah
   int 16h

   ; change back to text mode
   mov ax, 3
   int 10h

   ; terminate program
   mov ah, 4ch
   int 21h
   
end_of_line:
   ; move to start of next line
   add di, 80

   ; update a and b
   mov bx, 8000h
   add cx, 0148h 
    
   ; update endline
   add WORD PTR [endline], 320

   jmp next_line

   END
