#!/usr/bin/python
#
# UI for selfserve ss2.
#
# ====================================================================
#    Licensed to the Apache Software Foundation (ASF) under one
#    or more contributor license agreements.  See the NOTICE file
#    distributed with this work for additional information
#    regarding copyright ownership.  The ASF licenses this file
#    to you under the Apache License, Version 2.0 (the
#    "License"); you may not use this file except in compliance
#    with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing,
#    software distributed under the License is distributed on an
#    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#    KIND, either express or implied.  See the License for the
#    specific language governing permissions and limitations
#    under the License.
######################################################################

import cgi
import cgitb

import logging
import logging.handlers
import os
import sys
import time
import re
import StringIO

import ezt

from ss2config import *

import selfserve.email
import selfserve.exceptions
import selfserve.ldap
import selfserve.tokens

class AppendHandler(logging.Handler):
  def __init__(self, tdata, level=logging.DEBUG):
    logging.Handler.__init__(self, level)
    self._tdata = tdata

  def emit(self, record):
    self._tdata['_debug'] = self._tdata.pop('_debug', "") + self.format(record) + "\n"

def debug_dump():
    for key, val in os.environ.iteritems():
        print "%r: %r" % (key, val)

    print `sys.argv`

def render_exception(e, tdata, lookup):
    template = lookup.get_template('results.html')

    msgs = {
        selfserve.exceptions.BadUserOrPassword : "Wrong username '%s' or password" % str(e),
        selfserve.exceptions.CorruptToken : 'Internal error: corrupt token %s' % str(e),
        selfserve.exceptions.NoSuchToken  : 'No such token %s' % str(e),
        selfserve.exceptions.NonMatchingPasswords : "Passwords don't match, try again",
        selfserve.exceptions.EncryptionError : "Encryption failed",
        selfserve.exceptions.WeakPassword : "Password does not meet complexity policy",
        selfserve.exceptions.InvalidInput : "Invalid input: %s" % str(e),
    }
    codes = {
        selfserve.exceptions.BadUserOrPassword : 401,
        selfserve.exceptions.CorruptToken : 500,
        selfserve.exceptions.NoSuchToken  : 404,
        selfserve.exceptions.NonMatchingPasswords : 409,
        selfserve.exceptions.EncryptionError : 500,
        selfserve.exceptions.WeakPassword : 403,
        selfserve.exceptions.InvalidInput : 405,
    }
    tdata['status'] = get_by_subclass(codes, e, 500)
    tdata['message'] = get_by_subclass(msgs, e, "Unspecified exception; logged.")
    if tdata['message'].endswith('; logged') or tdata['status'] >= 500:
        logger.error("Unspecified exception: %s", `e`)
    print template.render(**tdata)

def render_index(tdata, lookup, form, pathinfo):
    template = lookup.get_template('index.html')
    tdata['availid'] = form.getvalue('availid', '') # /details/$availid redirector
    tdata['changepw_is_checked'] = (form.getvalue('changepw') and 'checked' or '')
    print template.render(**tdata)

def render_reset(tdata, lookup, form, pathinfo):
    "The 'Request a password reset email' screen."
    if 'submit_sendmail' in form:
        availid = form.getvalue('availid')
        if availid is None:
            template = lookup.get_template('results.html')
            tdata['message'] = "No username given"
            tdata['status'] = 500
        else:
            template = lookup.get_template('results.html')
            remote24 = os.environ['REMOTE_ADDR']
            m = re.search("(?:\d+\.){3}", remote24)
            remote24 = m.group(0);
            msgid = selfserve.email.send_email(availid, lookup.PATH, remote24,
                                               tdata['base_url'])
            tdata['message'] = "Email sent, Message-ID=<%s>." % msgid
    else:
        template = lookup.get_template('sendemail.html')
    print template.render(**tdata)

def get_by_subclass(dict_, obj, default_value):
  for k, v in dict_.iteritems():
    if isinstance(obj, k):
      return v
  else:
    return default_value

def render_token(tdata, lookup, form, pathinfo):
    "The 'Here is the password reset token I got by email' screen."
    token = pathinfo.split('/', 3)[-1]
    # Validate the token
    # ### layering violation?
    remote24 = os.environ['REMOTE_ADDR']
    m = re.search("(?:\d+\.){3}", remote24)
    remote24 = m.group(0);

    hextoken, availid, expiry = selfserve.tokens.has_token(PW_RESET_MAGIC, token, remote24)

    tdata['availid'] = availid
    tdata['hextoken'] = hextoken

    if os.environ.get('REQUEST_METHOD') == 'POST':
        assert form['hextoken'].value == hextoken

        # SECURITY: The ONLY criterion for to accept this new pw is that
        # the POST was made to the correct token URI.
        logger.info('finishing password reset for valid token=%s', selfserve.tokens.censor_token(hextoken))
        remote24 = os.environ['REMOTE_ADDR']
        m = re.search("(?:\d+\.){3}", remote24)
        remote24 = m.group(0);
        selfserve.ldap.do_pw_reset(availid, form.getvalue('new_pw1'), form.getvalue('new_pw2'), hextoken, remote24)

        template = lookup.get_template('results.html')
        tdata['message'] = 'Password change successful'
        print template.render(**tdata)
    else:
        logger.info('starting password reset for valid token=%s', selfserve.tokens.censor_token(hextoken))
        template = lookup.get_template('resetpassword.html')
        print template.render(**tdata)

def render_login_redirector(tdata, lookup, form, pathinfo):
    template = lookup.get_template('results.html')
    availid = form.getvalue('availid')
    password = form.getvalue('password')
    selfserve.ldap.bind_as_user(availid, password)
    remote24 = os.environ['REMOTE_ADDR']
    m = re.search("(?:\d+\.){3}", remote24)
    remote24 = m.group(0);
    sesskey = selfserve.tokens.make_token(SESSION_MAGIC, availid, seconds=60, cookie=remote24)[0] # one minute
    tdata['session'] = sesskey
    if 'changepw' in form:
      tdata['location'] = '%s/details/%s/password?session=%s' % (tdata['base_url'], availid, sesskey)
    else:
      tdata['location'] = '%s/details/%s?session=%s' % (tdata['base_url'], availid, sesskey)
    tdata['message'] = "Login successful"
    print template.render(**tdata)

def make_attrs_dict(attributes):
    retval = {}
    for k, v in attributes:
       retval[k] = v
    return retval


class Attribute(object):
    def __init__(self, key, name, editable, multivalue, values):
        self.key = key
        self.name = name
        self.editable = editable
        self.multivalue = multivalue
        self.values = values


def render_edit_details(tdata, lookup, form, pathinfo):
    "The 'edit my details or password' screens."

    pathinfo_parts = pathinfo.split('/')
    assert len(pathinfo_parts) == 3 or len(pathinfo_parts) == 4 and pathinfo_parts[-1] in [ 'password' , '' ]
    # let's hope we don't have password@a.o
    editing_the_password = (pathinfo_parts[-1] == 'password')

    # validation
    if os.environ.get('REQUEST_METHOD') == 'POST':
        # submitting a filled form
        availid = form['availid'].value
        tdata['availid'] = availid
    else:
        if 'session' in form:
            # came here via the login screen and the 1-minute redirector 
            remote24 = os.environ['REMOTE_ADDR']
            m = re.search("(?:\d+\.){3}", remote24)
            remote24 = m.group(0);
            hextoken, availid, expiry = selfserve.tokens.has_token(SESSION_MAGIC, form.getvalue('session'), remote24)
            tdata['availid'] = availid 
            # for the "logout" function
            tdata['session'] = hextoken
        else:
            # redirect to login screen
            template = lookup.get_template('results.html')
            tdata['location'] = '%s?availid=%s&changepw=%s' % (
                                    tdata['base_url'], pathinfo_parts[2], ['', '1'][editing_the_password])
            tdata['message'] = "Redirecting..."
            if editing_the_password:
                # TODO
                pass
            print template.render(**tdata)
            return

    if editing_the_password:
        if os.environ.get('REQUEST_METHOD') == 'POST':
            template = lookup.get_template('results.html')
            selfserve.ldap.do_pw_change(availid, form.getvalue('old_pw'),
                                        form.getvalue('new_pw1'), form.getvalue('new_pw2'))
            tdata['message'] = 'Password change successful'
            print template.render(**tdata)
        else:
            template = lookup.get_template('changepassword.html')
            print template.render(**tdata)
    else:
        attributesdict = make_attrs_dict(ATTRIBUTES)
        if os.environ.get('REQUEST_METHOD') == 'POST':
            template = lookup.get_template('results.html')
            edits = {}
            for k in form:
                if k.endswith('_attr'):
                    attr = k[:-5]
                    if attributesdict[attr][1]:
                        edits[attr] = form.getlist(k)
            for attr in attributesdict:
              if attr not in edits and attributesdict[attr][1]:
                edits[attr] = None
            selfserve.ldap.do_details_change(availid, form.getvalue('old_pw'), edits)
            # TODO: maybe kill the session token here?
            tdata['message'] = "Details change successful"
            print template.render(**tdata)
        else:
            template = lookup.get_template('changedetails.html')

            values = selfserve.ldap.fetch_attributes(availid,
                                                     attributesdict.keys())

            attrs = []
            for key, (name, editable, multivalue) in ATTRIBUTES:
                if editable:
                    editword = ''
                else:
                    editword = 'readonly'
                if key not in values:
                    editword = 'disabled'
                attrs.append(Attribute(key, name, editword,
                                       ezt.boolean(multivalue),
                                       values.get(key, ['<not present>'])))
            tdata['attributes'] = attrs

            tdata['dn'] = USER_DN_T % availid
            print template.render(**tdata)

def render_logout(tdata, lookup, form, pathinfo):
    template = lookup.get_template('results.html')
    sesskey = pathinfo.split('/')[-1]
    try:
        # don't check remote24/cookie
        selfserve.tokens.kill_token(sesskey)
        tdata['status'] = 200
        tdata['message'] = "Bye, token '%s' removed" % sesskey
    except selfserve.exceptions.NoSuchToken:
        tdata['status'] = 200
        tdata['message'] = "Bye"
    except selfserve.exceptions.SS2Exception, ss2e:
        raise
    print template.render(**tdata)

def render_unknown_uri(tdata, lookup, form, pathinfo):
    template = lookup.get_template('results.html')
    tdata['status'] = 500
    tdata['message'] = "Unknown URI '%s'" % pathinfo
    print template.render(**tdata)


### this will go away, but it is handy for the conversion from Mako
class CompatTemplate(object):
    def __init__(self, template):
        self.template = template

    def render(self, **kw):
        buffer = StringIO.StringIO()
        self.template.generate(buffer, kw)
        return buffer.getvalue()


class CompatLookup(object):
    PATH = '../templates'
    def get_template(self, template_name):
        template = ezt.Template(os.path.join(self.PATH, template_name),
                                base_format=ezt.FORMAT_HTML)
        return CompatTemplate(template)


def start(tdata):
    pathinfo = os.environ.get("PATH_INFO")
    logger.debug("pathinfo = %r", pathinfo)

    lookup = CompatLookup()

    form = cgi.FieldStorage()

    # some default values
    tdata['location'] = None
    tdata['status'] = None
    tdata['toolbar'] = None
    tdata['menu'] = None
    tdata['messagebox'] = None
    tdata['message'] = None
    tdata['availid'] = None
    tdata['_debug'] = ''

    # to force a newline, in the presence of whitespace compression
    tdata['newline'] = '\n'

    try:
        if DEBUG_EVERYTHING:
            # this may include passwords!
            logger.debug(`form`)
        if pathinfo in [None, '/']:
            render_index(tdata, lookup, form, pathinfo)
        elif pathinfo == '/reset/enter':
            render_reset(tdata, lookup, form, pathinfo)
        elif pathinfo.startswith('/reset/token/'):
            render_token(tdata, lookup, form, pathinfo)
        elif pathinfo == '/details/login':
            render_login_redirector(tdata, lookup, form, pathinfo)
        elif pathinfo.startswith('/details/logout/'):
            render_logout(tdata, lookup, form, pathinfo)
        elif pathinfo.startswith('/details/'):
            render_edit_details(tdata, lookup, form, pathinfo)
        else:
            render_unknown_uri(tdata, lookup, form, pathinfo)
    except selfserve.exceptions.SS2Exception, ss2e:
        return render_exception(ss2e, tdata, lookup)
    except Exception, e:
        return render_exception(e, tdata, lookup)
    except BaseException, e:
        return render_exception(e, tdata, lookup)
    finally:
        pass

class CustomSubjectHandler(logging.handlers.SMTPHandler):
    def getSubject(self, logrecord):
        # logging.handlers.SMTPHandler.getSubject(self, logrecord)
        return logrecord.getMessage().split("\n")[0]

def main():
    #print "Content-type: text/plain\n\n"; debug_dump()

    if DEBUG_MODE:
      cgitb.enable()

    # TODO config file
    # TODO don't spam stderr (presumably due to the root logger?)
    logging.basicConfig(
      level=logging.__dict__[LOG_LEVEL],
      #self.setFormatter(logging.Formatter(
      format=((
        "[%(asctime)s]\t[%(processName)s:%(process)d]\t[%(levelname)s]\t[%(filename)s:%(lineno)d %(funcName)s()]\t%(message)s")))
    global logger
    logger = logging.getLogger("%s.app" % LOGGER_NAME)
    #logger.setLevel(logging.__dict__[LOG_LEVEL])
    SCRIPT_NAME = os.environ['SCRIPT_NAME']
    tdata = {
        'script_name' : SCRIPT_NAME,
        # ensure SCRIPT_DIRNAME has a trailing slash
        'script_dirname' : (os.path.dirname(SCRIPT_NAME)+'/').replace('//','/'),
        'base_url' : '%s://%s%s' % (HTTP_PROTOCOL, os.environ['HTTP_HOST'], os.environ['SCRIPT_NAME']),
    }
    # add a root logger
    if DEBUG_MODE:
        ah = AppendHandler(tdata)
        logging.getLogger().addHandler(ah)
    basename = os.path.basename(os.getenv('SCRIPT_FILENAME'))
    rootMailHandler = CustomSubjectHandler(
                          SMTP_HOST, '"Selfserve (%s)" <%s>' % (basename, FROM_ADDRESS), NOTIFY_TO,
                          "Selfserve <%s>" % basename # unused by the subclass
                      );
    rootMailHandler.setLevel(logging.__dict__[LOG_LEVEL_MAIL])
    logging.getLogger().addHandler(rootMailHandler)

    start(tdata)


#raise Exception("Hello world")
