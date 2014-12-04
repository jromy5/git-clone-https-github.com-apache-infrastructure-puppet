/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*****************************************************************************/
/* Documentation:                                                            */
/*                                                                           */
/*   This module is a bit of pragmatic hackery to be used in conjunction     */
/*   with mod_rewrite to enable redirects to be served out the original      */
/*   podling locations (instead of 404s or 500s) whenever a podling has      */
/*   graduated and its svn tree moved.  In practice you set a single config  */
/*   option SVNCheckPathPrefix (which could ideally be pulled out of the     */
/*   existing config but whatever) + a few rewrite blocks to gain utility    */
/*   out of this module.                                                     */
/*                                                                           */
/*   More generally this can be used to support arbitrary "project-level"    */
/*   in-repo svn move operations, given two fixed base uri prefixes to move  */
/*   between.                                                                */
/*                                                                           */
/* Examples:                                                                 */
/*                                                                           */
/*   LoadModule svn_check_path_module modules/mod_svn_check_path.so          */
/*                                                                           */
/*   RewriteEngine on                                                        */
/*                                                                           */
/*   # web requests- svn clients don't make use of this block                */
/*   RewriteCond %{SUBREQ} =false                                            */
/*   RewriteCond %{REQUEST_METHOD} =GET [OR]                                 */
/*   RewriteCond %{REQUEST_METHOD} =HEAD                                     */
/*   RewriteCond %{REQUEST_URI} /repos/asf/incubator(/.+)                    */
/*   RewriteCond /repos/asf%1?ckpath  -U                                     */
/*   RewriteRule .* /repos/asf%1 [L,R=301]                                   */
/*                                                                           */
/*   # this handles initial checkouts                                        */
/*   RewriteCond %{SUBREQ} =false                                            */
/*   RewriteCond %{REQUEST_METHOD} =PROPFIND                                 */
/*   RewriteCond %{REQUEST_URI} /repos/asf/!svn/(bc|rvr)/\d+/incubator(/.+)  */
/*   RewriteCond /repos/asf%2?ckpath  -U                                     */
/*   RewriteRule .* /repos/asf%2 [L,R=301]                                   */
/*                                                                           */
/*   # requires -DFILTERING to be set                                        */
/*   # handles updates (and checkouts)                                       */
/*   RewriteCond %{SUBREQ} =false                                            */
/*   RewriteCond %{REQUEST_METHOD} =REPORT                                   */
/*   RewriteCond %{REQUEST_URI} /repos/asf/!svn/(vcc/default|me)             */
/*   # ...                                                                   */
/*   # we have to parse the request body to get the real source url, so      */
/*   # we specify both the target prefix (/repos/asf) and the source prefix  */
/*   # (/repos/asf/incubator) of the moved trees on the -U line, neither of  */
/*   # which (or both) should include a trailing slash (/).  Use the hostname*/
/*   # as source prefix if you're trying to work with "/" as a source prefix.*/
/*   # ...                                                                   */
/*   RewriteCond /repos/asf?ckpath=/repos/asf/incubator -U                   */
/*   # resulting target path is passed back to the main request as PATH_INFO */
/*   RewriteRule .* %{PATH_INFO} [L,R=301]                                   */
/*                                                                           */
/*   <Location /repos/asf>                                                   */
/*     DAV svn                                                               */
/*     SVNPath /x1/svn/asf                                                   */
/*                                                                           */
/*     #this needs to match the Location url of the repo                     */
/*     SVNCheckPathPrefix /repos/asf                                         */
/*                                                                           */
/*     ...                                                                   */
/*   </Location>                                                             */
/*                                                                           */
/* Notes:                                                                    */
/*                                                                           */
/*   The query string on the -U RewriteCond line is absolutely required but  */
/*   basically arbitrary- it just needs to signal that this request is coming*/
/*   from the -U line and not an arbitrary subrequest from mod_dav_svn- the  */
/*   simplest way to distinguish them is by setting the query string to a    */
/*   magic prefix of "ckpath". On REPORT requests we overload the query      */
/*   string to also include the source prefix since we cannot determine that */
/*   from the %{REQUEST_URI} on the main request.                            */
/*****************************************************************************/

#include "httpd.h"
#include "http_config.h"
#include "http_log.h"
#include "http_request.h"

#include "apr_strings.h"

#include "svn_repos.h"
#include "svn_fs.h"
#include "svn_dirent_uri.h"

#include "mod_dav_svn.h"

#define MAGIC_STRING "ckpath"

/* request uri magic string */
#define PROPFIND_PREFIX  "/!svn/bc/"

#define CKSVNERR(name) do {                                             \
        if (svnerr) {                                                   \
            ap_log_rerror(APLOG_MARK, APLOG_ERR, svnerr->apr_err, r,    \
                          MAGIC_STRING ": " #name                       \
                          "() failed: %s", svnerr->message);            \
            svn_error_clear(svnerr);                                    \
            return HTTP_INTERNAL_SERVER_ERROR;                          \
        }                                                               \
    } while (0)

module AP_MODULE_DECLARE_DATA svn_check_path_module;

#ifdef HEADER_LOGGING

#include "apr_tables.h"

static int dump_table(void *data, const char *key, const char *value)
{
    request_rec *r = data;
    if (strcasecmp(key, "Authorization") != 0
        && strcasecmp(key, "Cookie") != 0)
        ap_log_rerror(APLOG_MARK, APLOG_ERR, APR_SUCCESS, r, MAGIC_STRING
                      ": Header: %s=%s", key, value);
    return 1;
}

#endif

#ifdef FILTERING

#include "http_protocol.h"
#include "util_filter.h"
#include "apr_buckets.h"

/* Needs apreq_util.h for a few INLINE brigade utils: headers available at
 * http://svn.apache.org/repos/asf/httpd/apreq/trunk/include/
 */
#include "apreq2/apreq_util.h"

/* request body magic strings */
#define UPDATE_REPORT   "update-report"
#define SRC_PATH        "src-path>"
#define TARGET_REVISION "target-revision>"
#define DST_PATH        "dst-path>"

static APR_INLINE void relocate(ap_filter_t *f)
{
    request_rec *r = f->r;

    if (f != r->input_filters) {
        ap_filter_t *top = r->input_filters;
        ap_remove_input_filter(f);
        r->input_filters = f;
        f->next = top;
    }
    r->proto_input_filters = f; /* be subreq friendly */
}

static apr_status_t fetch_body(request_rec *r, char **body, apr_size_t *blen)
{
    ap_filter_t *f;
    apr_bucket_brigade *bb;
    apr_status_t s;

    bb = apr_brigade_create(r->pool, r->connection->bucket_alloc);
    f = ap_add_input_filter(MAGIC_STRING, NULL, r->main, r->connection);
    relocate(f); /* sigh- this should really get fixed in httpd-land */

    s = ap_get_brigade(f, bb, AP_MODE_EXHAUSTIVE, APR_BLOCK_READ, 1024);
    if (s != APR_EOF && s != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, s, r, MAGIC_STRING
                      ": ap_get_brigade() failed: %d", s);
        return HTTP_INTERNAL_SERVER_ERROR;
    }
    s = apr_brigade_pflatten(bb, body, blen, r->pool);
    apr_brigade_cleanup(bb);
    if (s != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, s, r, MAGIC_STRING
                      ": apr_brigade_pflatten() failed: %d", s);
        return HTTP_INTERNAL_SERVER_ERROR;
    }
    ap_log_rerror(APLOG_MARK, APLOG_DEBUG, s, r, MAGIC_STRING
                  ": (%s) BODY(%d): %.*s", r->uri,
                  (int)*blen, (int)*blen, *body);
    return s;
}

#endif /* FILTERING */

static apr_status_t ckpath(request_rec *r)
{
    svn_node_kind_t kind;
    svn_error_t *svnerr;
    svn_repos_t *svnrepos;
    svn_fs_t *svnfs;
    svn_fs_root_t *svnroot;
    svn_revnum_t svnrev;
#ifdef FILTERING
    char *body;
    apr_size_t blen = 0;
#endif
    char *p;
    const char *svnpath;
    dav_error *daverr;

    const char **conf = ap_get_module_config(r->per_dir_config,
                                             &svn_check_path_module);

    if (r->main == NULL || r->args == NULL || conf == NULL || *conf == NULL
        || strstr(r->uri, *conf) != r->uri
        || strstr(r->args, MAGIC_STRING) != r->args)
        return DECLINED;

#ifdef FILTERING

    if (strcmp(r->main->method, "REPORT") == 0) {
        char *src, *uri, *end, tmp, *src_prefix, *target_prefix;
        apr_status_t s;

        if ((src_prefix = strchr(r->args, '=')) == NULL) {
            ap_log_rerror(APLOG_MARK, APLOG_ERR, APR_EGENERAL, r, MAGIC_STRING
                          ": query string is missing source prefix!");
            return HTTP_INTERNAL_SERVER_ERROR;
        }        
        ++src_prefix;

        /* we need to fish the source uri out of <src-path/> in the body,
         * if this is an update-report, for the remainder of the code to work
         */

        if ((s = fetch_body(r, &body, &blen)) != APR_SUCCESS)
            return s;

        if (blen > 3 && (src = memmem(body, blen - 3, UPDATE_REPORT,
                                      strlen(UPDATE_REPORT)))
            != NULL
            && (src = memmem(src + strlen(UPDATE_REPORT),
                             body + blen - 2 - src - strlen(UPDATE_REPORT),
                             SRC_PATH, strlen(SRC_PATH)))
            != NULL
            && (uri = memmem(src + strlen(SRC_PATH),
                             body + blen - 1 - src - strlen(SRC_PATH),
                             src_prefix, strlen(src_prefix)))
            != NULL) {

            src += strlen(SRC_PATH);
            while (src < uri)
                /* double-check that we're still in the <src-path/> block */
                if (*src++ == '<')
                    return HTTP_BAD_REQUEST;

            if (memmem(body, blen, DST_PATH, strlen(DST_PATH)) != NULL)
                /* this is an svn switch op which we should ignore */
                return HTTP_BAD_REQUEST;

            /* effectively we now run s/.*?$src_prefix/$target_prefix/ (where
             * $target_prefix was provided as r->uri) on the now fished full
             * source uri- really should xml-decode the uri before parsing it
             */
            uri += strlen(src_prefix);
            end = uri;
            while (end < body + blen - 1 && *end != '<')
                ++end;
            tmp = *end;
            *end = 0;
            
            target_prefix = r->uri;
            ap_parse_uri(r, apr_pstrcat(r->pool, target_prefix, uri, NULL));
            *end = tmp;
            ap_getparents(r->uri);
            if (strstr(r->uri, target_prefix) != r->uri)
                return HTTP_BAD_REQUEST;
        }
        else
            return HTTP_BAD_REQUEST;
    }

#endif /* FILTERING */

#ifdef HEADER_LOGGING
    /* looking for revision data in the headers */
    apr_table_do(dump_table, r, r->headers_in, NULL);
#endif

    if ((daverr = dav_svn_get_repos_path(r, *conf, &svnpath)) != NULL) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, daverr->error_id, r, MAGIC_STRING
                      ": dav_svn_get_repos_path() failed: %s", daverr->desc);
        return daverr->status;
    }

    svnerr = svn_repos_open2(&svnrepos, svnpath, NULL, r->pool);
    CKSVNERR(svn_repos_open2);
    svnfs = svn_repos_fs(svnrepos);

    if (strcmp(r->main->method, "PROPFIND") == 0) {
        if (strstr(r->main->uri, PROPFIND_PREFIX) != NULL)
            svnrev = apr_atoi64(r->main->uri + strlen(*conf)
                                + strlen(PROPFIND_PREFIX));
        else /* propfind prefix is "/!svn/rvr/" which is 1 char longer */
            svnrev = apr_atoi64(r->main->uri + strlen(*conf)
                                + strlen(PROPFIND_PREFIX) + 1);
        ap_log_rerror(APLOG_MARK, APLOG_DEBUG, APR_SUCCESS, r, MAGIC_STRING
                      ": propfind-revision=%ld", svnrev);
    }
    else if (r->main->args != NULL
             && (p = strstr(r->main->args, "p=")) != NULL) {
        svnrev = apr_atoi64(p + 2);
        ap_log_rerror(APLOG_MARK, APLOG_DEBUG, APR_SUCCESS, r, MAGIC_STRING
                      ": p=%ld", svnrev);
    }
#ifdef FILTERING
    else if (blen > 1 && (p = memmem(body, blen - 1, TARGET_REVISION,
                                     strlen(TARGET_REVISION)))
             != NULL) {
        char *end, tmp;
        p += strlen(TARGET_REVISION);
        end = p;
        while (end < body + blen - 1 && *end != '<')
            ++end;
        tmp = *end;
        *end = 0;
        svnrev = apr_atoi64(p);   
        *end = tmp;
        ap_log_rerror(APLOG_MARK, APLOG_DEBUG, APR_SUCCESS, r, MAGIC_STRING
                      ": target-revision=%ld", svnrev);
    }
#endif
    else {
        svnerr = svn_fs_youngest_rev(&svnrev, svnfs, r->pool);
        CKSVNERR(svn_fs_youngest_rev);
    }
    svnerr = svn_fs_revision_root(&svnroot, svnfs, svnrev, r->pool);
    CKSVNERR(svn_fs_revision_root);

    svnerr = svn_fs_check_path(&kind, svnroot,
                               svn_relpath_canonicalize(r->uri
                                                        + strlen(*conf),
                                                        r->pool),
                               r->pool);
    CKSVNERR(svn_fs_check_path);

    if (kind == svn_node_none)
        return HTTP_NOT_FOUND;

#ifdef FILTERING
    if (strcmp(r->main->method, "REPORT") == 0)
        r->main->path_info = r->uri;
#endif

    return DECLINED;
}

static void *create_config(apr_pool_t *p, char *d)
{
    return apr_pcalloc(p, sizeof(char *));
}

static const char* prefix(cmd_parms *cmd, void *data,
                          const char *arg)
{
    const char **conf = data;
    const char *err = ap_check_cmd_context(cmd, NOT_IN_LIMIT);
    size_t len = strlen(arg);

    if (err != NULL)
        return err;

    if (len > 0 && arg[len-1] == '/') {
        char *tmp = apr_pstrdup(cmd->pool, arg);
        tmp[len-1] = 0;
        arg = tmp;
    }

    *conf = arg;
    return NULL;
}

static const command_rec ckpath_cmds[] =
{
    AP_INIT_TAKE1("SVNCheckPathPrefix", prefix, NULL, OR_ALL,
                  "URL Prefix of SVN repo path"),
    { NULL }
};

#ifdef FILTERING

struct filter_ctx {
    apr_bucket_brigade *bb;
};

/* Expects to run in AP_MODE_EXHAUSTIVE initially as invoked from fetch_body().
 * Then it will make an internal copy of the full request body to feed to a
 * subsequent ap_get_brigade() caller in the main response handler
 * (mod_dav_svn), or another invocation of fetch_body() from a different
 * ckpath-enabled subrequest.
 */

static apr_status_t filter(ap_filter_t *f, apr_bucket_brigade *bb,
                           ap_input_mode_t mode, apr_read_type_e block,
                           apr_off_t readbytes)
{
    request_rec *r = f->r;
    struct filter_ctx *ctx = f->ctx;

    if (ctx == NULL) {
        apr_bucket_alloc_t *ba = r->connection->bucket_alloc;
        ctx = apr_palloc(r->pool, sizeof *ctx);
        ctx->bb = apr_brigade_create(r->pool, ba);
        f->ctx = ctx;
     }
    if (mode == AP_MODE_EXHAUSTIVE && APR_BRIGADE_EMPTY(ctx->bb)) {
        apr_status_t s;

        while ((s = ap_get_brigade(f->next, ctx->bb, AP_MODE_READBYTES,
                                   block, readbytes))
               == APR_SUCCESS) {
            apreq_brigade_setaside(ctx->bb, r->pool);
            apreq_brigade_move(bb, ctx->bb, APR_BRIGADE_SENTINEL(ctx->bb));
            if (APR_BUCKET_IS_EOS(APR_BRIGADE_LAST(bb)))
                break;
        }
        apreq_brigade_copy(ctx->bb, bb);
        return s;
    }
    else if (mode != AP_MODE_GETLINE && mode != AP_MODE_SPECULATIVE
             && !APR_BRIGADE_EMPTY(ctx->bb)) {
        apreq_brigade_move(bb, ctx->bb, APR_BRIGADE_SENTINEL(ctx->bb));
        return APR_SUCCESS;
    }
    else {
        return ap_get_brigade(f->next, bb, mode, block, readbytes);
    }
}

#endif /* FILTERING */

static void register_hooks(apr_pool_t *p)
{
    ap_hook_fixups(ckpath, NULL, NULL, APR_HOOK_LAST);

#ifdef FILTERING
    ap_register_input_filter(MAGIC_STRING, filter, NULL, AP_FTYPE_PROTOCOL-1);
#endif

    svn_fs_initialize(p);
}

module AP_MODULE_DECLARE_DATA svn_check_path_module = {
	STANDARD20_MODULE_STUFF,
        create_config,
        NULL,
	NULL,
	NULL,
	ckpath_cmds,
	register_hooks,
};
