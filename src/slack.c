/**
 * slack — Spawn processes with customised timer slack
 * Copyright © 2014  Mattias Andrée (maandree@member.fsf.org)
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/prctl.h>



#define NS  (1L)
#define US  (1000L)
#define MS  (1000L * 1000L)
#define S   (1000L * 1000L * 1000L)


static void usage(void)
{
  printf("USAGE: slack (get | GET | ((reset | <interval>) [--fatal] [--] <command...>))\n");
  printf("\n");
  printf("The <interval> must be a positive number optionally with a suffix:\n");
  printf("  ns  n           nanoseconds (default)\n");
  printf("  µs  µ  us  u    microseconds\n");
  printf("  ms  m           milliseconds\n");
  printf("  s               seconds\n");
  printf("\n");
  printf("If `GET' is used rather than `get', the timer slack value will be printed in\n");
  printf("nanoseconds without suffix. `GET' and `get' prints the current timer slack\n");
  printf("value and exits.\n");
  printf("\n");
  printf("`reset` reset the timer slack value to the default (the time slack value for\n");
  printf("the init process (PID 1) has.)\n");
  printf("\n");
  printf("Unless `--fatal` is used, the program will run <command> even if the timer\n");
  printf("slack could not be set.\n");
  printf("\n");
}


int main(int argc, char** argv)
{
  long slackvalue, r;
  int i, j, fatal = 0;
  char** exec_argv;
  
  if ((argc < 2) || !strcmp(argv[1], "--help") || !strcmp(argv[1], "help"))
    return usage(), argc < 2 ? 1 : 0;
  
  if (!strcmp(argv[1], "get") || !strcmp(argv[1], "GET"))
    {
      const char* suffix;
      if (r = prctl(PR_GET_TIMERSLACK), r < 0)
	perror(*argv);
      else
	{
	  if (!strcmp(argv[1], "GET"))
	    suffix = "";
	  else if (r %  S == 0)  suffix =  "s", r /=  S;
	  else if (r % MS == 0)  suffix = "ms", r /= MS;
	  else if (r % US == 0)  suffix = "µs", r /= US;
	  else                   suffix = "ns";
	  printf("%li%s\n", r, suffix);
	}
      return r > 0 ? 0 : 1;
    }
  
  for (i = 2; i < argc; i++)
    if (!strcmp(argv[i], "--fatal"))
      fatal = 1;
    else if (!strcmp(argv[i], "--"))
      {
	i++;
	break;
      }
    else if (strstr(argv[i], "-") == argv[i])
      return usage(), 1;
    else
      break;
  
  if (i == argc)
    return usage(), 1;
  
  exec_argv = malloc((argc - i + 1) * sizeof(char*));
  if (exec_argv == NULL)
    return perror(*argv), 2;
  exec_argv[argc - i] = NULL;
  for (j = 0; i < argc; j++, i++)
    exec_argv[j] = argv[i];
  
  if (!strcmp(argv[1], "reset"))
    slackvalue = 0;
  else
    {
      char* end;
      
      slackvalue = strtol(argv[1], &end, 10);
      if (end == argv[1])
	return fprintf(stderr, "No slack value specified."), free(exec_argv), 1;
      
      if      (!strcmp(end, "n") || !strcmp(end, "ns") || !strcmp(end, ""))  slackvalue *= NS;
      else if (!strcmp(end, "µ") || !strcmp(end, "µs"))                      slackvalue *= US;
      else if (!strcmp(end, "u") || !strcmp(end, "us"))                      slackvalue *= US;
      else if (!strcmp(end, "m") || !strcmp(end, "ms"))                      slackvalue *= MS;
      else if (!strcmp(end, "s"))                                            slackvalue *=  S;
      else
	return fprintf(stderr, "Unrecognised suffix for slack value."), free(exec_argv), 1;
      
      if (slackvalue <= 0)
	return fprintf(stderr, "Invalid slack value: %lins", slackvalue), free(exec_argv), 1;
    }
  
  if (r = prctl(PR_SET_TIMERSLACK, slackvalue), r < 0)
    if (perror(*argv), fatal)
      return free(exec_argv), 2;
  
  execvp(*exec_argv, exec_argv);
  perror(*argv);
  free(exec_argv);
  return 2;
}

