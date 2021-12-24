#include <graphics.h>
#include <conio.h>
#include <stdlib.h>
#include <dos.h>

int main(int ac, char ** av)
{
   int i, gd = CGA, gm = CGAC0;
   int x0, y0, x1, y1;
   struct time time1;   
   double t;
   
   if (ac != 5)
   {
      printf("Usage:\n");
      printf("  bgiline x0 y0 x1 y1\n");
      abort();
   }

   x0 = atoi(av[1]);
   y0 = atoi(av[2]);
   x1 = atoi(av[3]);
   y1 = atoi(av[4]);

   time1.ti_hour = 0;
   time1.ti_min = 0;
   time1.ti_sec = 0;
   time1.ti_hund = 0;

   initgraph(&gd, &gm, "");
   cleardevice();
   
   settime(&time1);

   for (i = 0; i < 10000; i++)
      line(x0, y0, x1, y1);

   gettime(&time1);

   t = 60.0*time1.ti_min;
   t += time1.ti_sec;
   t += (time1.ti_hund/100.0);
   t *= 18.206;

   printf("%f\n", t); 
   
   getch();
   closegraph();

   return 0;
}
 
