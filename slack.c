/* See LICENSE file for copyright and license details. */
#include <sys/prctl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "arg.h"

#define NS (1L)
#define US (1000L)
#define MS (1000L * 1000L)
#define S  (1000L * 1000L * 1000L)


char *argv0;

static void
usage(void)
{
	fprintf(stderr, "usage: %s [-f] ('get' | 'GET' | (('reset' | interval) command [argument] ...))\n", argv0);
	exit(1);
}

int
main(int argc, char **argv)
{
	int fatal;
	long int slackvalue;
	const char *suffix;
	char *end;
	int r;

	ARGBEGIN {
	case 'f':
		fatal = 1;
		break;
	default:
		usage();
	} ARGEND;

	if (!argc)
		usage();

	if (!strcmp(*argv, "get") || !strcmp(*argv, "GET")) {
		if (argc > 1)
			usage();
		r = prctl(PR_GET_TIMERSLACK);
		if (r < 0)
			return fprintf(stderr, "%s: prctl PR_GET_TIMERSLACK: %s\n", argv0, strerror(errno)), 1;
		if (!strcmp(*argv, "GET")) suffix = "";
		else if (r %  S == 0)      suffix =  "s", r /=  S;
		else if (r % MS == 0)      suffix = "ms", r /= MS;
		else if (r % US == 0)      suffix = "µs", r /= US;
		else                       suffix = "ns";
		printf("%i%s\n", r, suffix);
		return 0;
	}

	if (argc < 2)
		usage();

	if (!strcmp(*argv, "reset")) {
		slackvalue = 0;
	} else {
		slackvalue = strtol(*argv, &end, 10);
		if (end == *argv)
			return fprintf(stderr, "%s: no slack value specified\n", argv0), 1;
		if      (!strcmp(end, "n") || !strcmp(end, "ns") || !strcmp(end, ""))  slackvalue *= NS;
		else if (!strcmp(end, "µ") || !strcmp(end, "µs"))                      slackvalue *= US;
		else if (!strcmp(end, "u") || !strcmp(end, "us"))                      slackvalue *= US;
		else if (!strcmp(end, "m") || !strcmp(end, "ms"))                      slackvalue *= MS;
		else if (!strcmp(end, "s"))                                            slackvalue *=  S;
		else
			return fprintf(stderr, "%s: unrecognised suffix for slack value\n", argv0), 1;
		if (slackvalue <= 0)
			return fprintf(stderr, "%s: invalid slack value: %lins\n", argv0, slackvalue), 1;
	}

	r = prctl(PR_SET_TIMERSLACK, slackvalue);
	if (r < 0) {
		fprintf(stderr, "%s: prctl PR_SET_TIMERSLACK %li: %s\n", argv0, slackvalue, strerror(errno));
		if (fatal)
			return 1;
	}

	argv++;
	execvp(*argv, argv);
	fprintf(stderr, "%s: execvp %s: %s\n", argv0, *argv, strerror(errno));
	return 1;
}
