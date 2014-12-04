#include <sys/types.h>
#include <signal.h>
#include "ourhdr.h"
#include <string.h>
#include <unistd.h>
#define BUFFSIZE 4096

static void sig_term(int);
static volatile sig_atomic_t termcaught;

void
loop(int ptym, int ignoreeof, int delay)
{
    pid_t child;
    int nread;
    char buff[BUFFSIZE], ctrl_d = 4;
    Sigfunc* oldsig;

    oldsig = signal_intr(SIGTERM, sig_term);
    if (oldsig == SIG_ERR)
        err_sys("signal_intr error for SIGTERM");

    if ( (child = fork()) < 0)
        err_sys("fork error");

    else if (child == 0) { /* child copies stdin to ptym */
        if (signal_intr(SIGTERM, oldsig) == SIG_ERR)
            err_sys("signal_intr error for SIGTERM");

        sleep(delay); /* wait for other jobs to settle */

        for ( ; ; ) {
            if ( (nread = read(STDIN_FILENO, buff, BUFFSIZE)) < 0)
                err_sys("read error from stdin");
            else if (nread == 0) {
                write(ptym, &ctrl_d, 1); /* send 'EOF' char to term */
                break;  /* EOF on stdin means we're done */
            }
            if (writen(ptym, buff, nread) != nread)
                err_sys("writen error to master pty");
        }

        /* We always terminate when we encounter an EOF on stdin,
           but we only notify the parent if ignoreeof is 0. */
        if (ignoreeof == 0) {
            sleep(1);
            kill(getppid(), SIGTERM); /* notify parent */
        }
        exit(0); /* and terminate; child can't return */
    }

    /* parent copies ptym to stdout */
    for ( ; ; ) {
        if ((nread = read(ptym, buff, BUFFSIZE)) <= 0)
            break;  /* signal caught, error, or EOF */

        if (writen(STDOUT_FILENO, buff, nread) != nread)
            err_sys("writen error to stdout");
    }

    /* There are three ways to get here: sig_term() below caught the
     * SIGTERM from the child, we read an EOF on the pty master (which
     * means we have to signal the child to stop), or an error. */

    if (termcaught == 0) /* tell child if it didn't send us the signal */
        kill(child, SIGTERM);
    return;  /* parent returns to caller */
}

/* The child sends us a SIGTERM when it receives an EOF on
 * the pty slave or encounters a read() error. */

static void
sig_term(int signo)
{
    termcaught = 1;  /* just set flag and return */
    return;    /* probably interrupts read() of ptym */
}
