#!/usr/bin/python
#
# Originally based on the CIA bot by Micah Dowty at
#  http://cia.navi.cx/clients/svn/ciabot_svn.py
#
# Add this File to your post-commits hook:
#      REPOS="$1"
#      REV="$2"
#      $REPOS/hooks/ciabot_svn.py "$REPOS" "$REV" &
#
# Edit the Project Defs
#


class global_config:
    # Project Defs.
    # Fields: Project Name, Project Path (as in subversion)
    # If the path does not match, it will not send anything.
    # Therefore, projects must be added by hand, and it will default
    # to sending nothing.
    projects = [
                ['APR', 'apr/apr/'],
                ['APR-Util','apr/apr-util/'],
                ['httpd','httpd/httpd/']
            ]
    # If your repository is accessable over the web, put its base URL here
    # and 'uri' attributes will be given to all <file> elements. This means
    # that in CIA's online message viewer, each file in the tree will link
    # directly to the file in your repository
    repositoryURI = "http://svn.apache.org/repos/asf/"

    # This can be the http:// URI of the CIA server to deliver commits over
    # XML-RPC, or it can be an email address to deliver using SMTP. The
    # default here should work for most people. If you need to use e-mail
    # instead, you can replace this with "cia@cia.navi.cx"
    #server = "cia@cia.navi.cx" <- does not work.  needs to be fixed - jre
    #server = "http://cia.navi.cx"
    # NOTES (2012):
    #  - email notification works for git-wip-us.a.o
    #  - above hostname needs to be changed - INFRA-5218
    server = syntax error


    # When nonzero, print the message to stdout instead of delivering it to CIA
    debug = 0


############# Normally the rest of this won't need modification

import sys, os, re, urllib
import xmlrpclib, string

class File:
    """A file in a Subversion repository. According to our current
    configuration, this may have a module, branch, and URI in addition
    to a path."""

    def __init__(self, fullPath):
        self.fullPath = fullPath
        self.path = fullPath

    def getURI(self, repo):
        """Get the URI of this file, given the repository's URI. This
        encodes the full path and joins it to the given URI."""
        quotedPath = urllib.quote(self.fullPath)
        if quotedPath[0] == '/':
            quotedPath = quotedPath[1:]
        if repo[-1] != '/':
            repo = repo + '/'
        return repo + quotedPath

    def makeTag(self, config):
        """Return an XML tag for this file, using the given config"""
        attrs = {}

        if config.repositoryURI is not None:
            attrs['uri'] = self.getURI(config.repositoryURI)

        attrString = ''.join([' %s="%s"' % (key, escapeToXml(value,1))
                              for key, value in attrs.iteritems()])
        return "<file%s>%s</file>" % (attrString, escapeToXml(self.path))

class SvnClient:
    """A CIA client for Subversion repositories. Uses svnlook to
    gather information"""
    name = 'CIA+SVN Client in Python'
    version = '0.1.0'

    def __init__(self, repository, revision, config):
        self.repository = repository
        self.revision = revision
        self.project = ""
        self.project_path = ""
        self.config = config

    def deliver(self, message):
        if self.config.debug:
            print message
        else:
            server = self.config.server
            # Deliver over XML-RPC
            xmlrpclib.ServerProxy(server).hub.deliver(message)

    def main(self):
        self.collectData()
        if self.files == 1:
            return 1
        self.deliver("<message>" +
                     self.makeGeneratorTag() +
                     self.makeSourceTag() +
                     self.makeBodyTag() +
                     "</message>")

    def makeAttrTags(self, *names):
        """Given zero or more attribute names, generate XML elements for
           those attributes only if they exist and are non-None.
           """
        s = ''
        for name in names:
            if hasattr(self, name):
                v = getattr(self, name)
                if v is not None:
                    s += "<%s>%s</%s>" % (name, escapeToXml(str(v)), name)
        return s

    def makeGeneratorTag(self):
        return "<generator>%s</generator>" % self.makeAttrTags(
            'name',
            'version',
            )

    def makeSourceTag(self):
        return "<source>%s</source>" % self.makeAttrTags(
            'project',
            'module',
            'branch',
            )

    def makeBodyTag(self):
        return "<body><commit>%s%s</commit></body>" % (
            self.makeAttrTags(
            'revision',
            'author',
            'log',
            'diffLines',
            ),
            self.makeFileTags(),
            )

    def makeFileTags(self):
        """Return XML tags for our file list"""
        return "<files>%s</files>" % ''.join([file.makeTag(self.config)
                                              for file in self.files])

    def svnlook(self, command):
        """Run the given svnlook command on our current repository and
        revision, returning all output"""
        return os.popen('/usr/local/svn-install/current/bin/svnlook %s -r "%s" "%s"' % \
                        (command, self.revision, self.repository)).read()

    def collectData(self):
        self.author = self.svnlook('author').strip()
        self.log = self.svnlook('log')
        self.diffLines = len(self.svnlook('diff').split('\n'))
        self.files = self.collectFiles()

    def findProject(self, file):
        for proj in self.config.projects:
            if string.find(file.fullPath, proj[1]) == 0:
                self.project = proj[0]
                self.project_path = proj[1]
                return 0
        return 1

    def collectFiles(self):
        # Extract all the files from the output of 'svnlook changed'
        files = []
        for line in self.svnlook('changed').split('\n'):
            line = line[2:].strip()
            if line:
                files.append(File(line))

        # assume that the first file indicates which project this commit is for.
        if self.findProject(files[0]) == 1:
            return 1
        for file in files:
            file.path = string.replace(file.fullPath, self.project_path, '', 1)

        return files


def escapeToXml(text, isAttrib=0):
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")
    if isAttrib == 1:
        text = text.replace("'", "&apos;")
        text = text.replace("\"", "&quot;")
    return text

if __name__ == "__main__":
    # Print a usage message when not enough parameters are provided.
    if len(sys.argv) < 3:
        sys.stderr.write("USAGE: %s REPOS-PATH REVISION\n" %
                         sys.argv[0])
        sys.exit(1)

    # Go do the real work.
    SvnClient(sys.argv[1], sys.argv[2], global_config).main()
