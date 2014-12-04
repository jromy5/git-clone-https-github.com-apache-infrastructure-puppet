# adjust APXS, INCLUDES, and LDFLAGS to match your install
APXS=/usr/local/apache2-install/vc.apache.org/httpd-$(hver)/bin/apxs
INCLUDES=-I /usr/local/svn-install/svn-$(sver)-$(hver)/include/subversion-1
LDFLAGS=-L /usr/local/svn-install/svn-$(sver)-$(hver)/lib

# the rest aren't really user serviceable other than LOGGING if you want it
WCFLAGS=-Wc,-Wall -Wc,-Werror -Wc,-pedantic -Wc,-std=c99
LIBS=-l svn_fs-1 -l svn_repos-1 -l svn_subr-1 
#LOGGING=-D HEADER_LOGGING=1
LOGGING=
FILTERING=-D FILTERING=1
#FILTERING=

all: mod_svn_check_path.la

mod_svn_check_path.la:  mod_svn_check_path.c Makefile
	$(APXS) $(WCFLAGS) -c $(LOGGING) $(FILTERING) $(INCLUDES) $(LDFLAGS) $(LIBS) *.c

clean:
	rm -f mod_svn_check_path.la
	rm -f mod_svn_check_path.lo
	rm -f mod_svn_check_path.slo
	rm -f mod_svn_check_path.o
	rm -rf .libs

install: all
	$(APXS) -i *.la
