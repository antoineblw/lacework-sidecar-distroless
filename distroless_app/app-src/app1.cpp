#include <stdio.h>
#include <unistd.h>

int main()
{
   int counter = 0;
   while (1)
   {
      printf("App1: Hello world %d ***\n", counter++);
      fflush(stdout);
      sleep(1);
   }
}
