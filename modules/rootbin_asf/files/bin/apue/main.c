#include <sys/types.h>
#include <sys/ioctl.h>
#include <termios.h>
#ifndef TIOCGWINSZ
#include <sys/ioctl.h> /* 44BSD requires this too */
#endif
#include "ourhdr.h"
#include <sys/wait.h>
#include <getopt.h>
#include <signal.h>
#if defined(__linux__) || defined(__CYGWIN__)
#include <pty.h>
#endif
#ifdef __FreeBSD__
#include <libutil.h>
#endif
#ifdef __APPLE__
#include <util.h>
#endif

static void set_noecho(int); /* at the end of this file */
pid_t do_driver(char *); /* in the file driver.c */
void loop(int, int, int);         /* in the file loop.c */

int
main(int argc, char *argv[])
{
    int fdm, c, ignoreeof, interactive, noecho, verbose, status, delay;
    pid_t pid, d_pid = 0;
    char *driver, slave_name[20];
    struct termios orig_termios;
    struct winsize size;

    interactive = isatty(STDIN_FILENO);
    ignoreeof = 0;
    noecho = 0;
    verbose = 0;
    driver = NULL;
    delay = 1;

    opterr = 0;  /* don't want getopt() writing to stderr */
    while ( (c = getopt(argc, argv, "d:einvt:h")) != EOF) {
        switch (c) {
        case 'd':  /* driver for stdin/stdout */
            driver = optarg;
            break;

        case 'e':  /* noecho for slave pty's line discipline */
            noecho = 1;
            break;

        case 'i':  /* ignore EOF on standard input */
            ignoreeof = 1;
            break;
        case 'n':  /* not interactive */
            interactive = 0;
            break;

        case 'v':  /* verbose */
            verbose = 1;
            break;

        case 't':  /* time delay */
            delay = atoi(optarg);
            break;

        case 'h':
            printf("%s\n-------\n", "Options");
            printf("  -d (cmd) %s\n", "Driver for stdin/stdout; stderr redirects to stdout");
            printf("  -e       %s\n", "Noecho for slave pty's line discipline");
            printf("  -i       %s\n", "Ignore EOF on stdin");
            printf("  -n       %s\n", "Not interactive");
            printf("  -v       %s\n", "Verbose");
            printf("  -t (sec) %s\n", "Delay reading from stdin (defaults to 1 sec)");
            printf("  -h       %s\n", "This help menu");
            exit(0);

        case '?':
            err_quit("unrecognized option: -%c", optopt);
        }
    }
    if (optind >= argc)
        err_quit("usage: pty [ -d driver -einvh -t timeout ] program [ arg ... ]");

    if (interactive) { /* fetch current termios and window size */
        if (tcgetattr(STDIN_FILENO, &orig_termios) < 0)
            err_sys("tcgetattr error on stdin");
        if (ioctl(STDIN_FILENO, TIOCGWINSZ, (char *) &size) < 0)
            err_sys("TIOCGWINSZ error");
        pid = forkpty(&fdm, slave_name, &orig_termios, &size);

    } else
        pid = forkpty(&fdm, slave_name, NULL, NULL);

    if (pid < 0)
        err_sys("fork error");

    else if (pid == 0) {  /* child */
        if (noecho)
            set_noecho(STDIN_FILENO); /* stdin is slave pty */

        if (execvp(argv[optind], &argv[optind]) < 0)
            err_sys("can't execute: %s", argv[optind]);
    }

    if (verbose) {
        fprintf(stderr, "slave name = %s\n", slave_name);
        if (driver != NULL)
            fprintf(stderr, "driver = %s\n", driver);
    }

    if (interactive && driver == NULL) {
        if (tty_raw(STDIN_FILENO) < 0) /* user's tty to raw mode */
            err_sys("tty_raw error");
        if (atexit(tty_atexit) < 0)  /* reset user's tty on exit */
            err_sys("atexit error");
    }

    if (driver)
        d_pid = do_driver(driver); /* changes our stdin/stdout */

    loop(fdm, ignoreeof, delay); /* copies stdin -> ptym, ptym -> stdout */
        
    if (close(fdm) != 0)
        err_sys("close failed");

    if (driver && waitpid(d_pid, &status, WNOHANG) != d_pid) {
        sleep(1); /* let io settle */
        kill(d_pid, SIGTERM);
    }

    waitpid(pid, &status, 0);
    exit(WEXITSTATUS(status));
}
static void
set_noecho(int fd)  /* turn off echo (for slave pty) */
{
    struct termios stermios;

    if (tcgetattr(fd, &stermios) < 0)
        err_sys("tcgetattr error");

    stermios.c_lflag &= ~(ECHO | ECHOE | ECHOK | ECHONL);

    if (tcsetattr(fd, TCSANOW, &stermios) < 0)
        err_sys("tcsetattr error");
}
