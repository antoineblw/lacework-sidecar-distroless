#include <stdio.h>
#include <unistd.h>

int main(int argc, char ** argv)
{
   int counter = 0;
   for (int i = 0; i < argc; i++)
   {
	   printf("Arg %d is %s\n", i, argv[i]);
   }
   while (1)
   {
      printf("App1: Hello world %d ***\n", counter++);
      fflush(stdout);
      sleep(20);
   }
}
