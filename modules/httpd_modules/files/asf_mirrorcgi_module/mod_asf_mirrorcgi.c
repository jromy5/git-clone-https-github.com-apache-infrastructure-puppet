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

#include "httpd.h"
#include "http_core.h"
#include "http_config.h"
#include "http_protocol.h"
#include "http_request.h"
#include "http_log.h"
#include "apr_strings.h"

/**
 * This module is a replacement for the classic 'download.cgi' scripts
 * used by ASF Projects.
 * 
 * The download.cgi scripts really just invoked another mirrors.cgi script,
 * with their path.  The mirrors.cgi did all the magic, like the template
 * rendering and mirror list generation.
 *
 * This module detects the download.cgi module by search for the path to the
 * mirrors.cgi script in the first 8kb, if it finds it, it automatically rewrites
 * the URL -- meaning we can turn off ExecCGI for the download.cgi path --
 * and saving us an extra fork/exec on every view of download.cgi. 
 *
 */


typedef struct mcgi_conf_t {
    int enabled;
    const char *path;
    const char *force_handler;
} mcgi_conf_t;

module AP_MODULE_DECLARE_DATA asf_mirrorcgi_module;

static apr_status_t should_remap(request_rec *r, mcgi_conf_t *conf) 
{
    apr_file_t *fp;
    char buf[AP_IOBUFSIZE];
    apr_status_t rv = APR_EGENERAL;
    apr_size_t bytes_read = 0;

    rv = apr_file_open(&fp,  r->filename, APR_READ|APR_BINARY, APR_OS_DEFAULT, 
                       r->pool);
    if (rv) {
        return rv;
    }

    rv = apr_file_read_full(fp,
                            &buf[0],
                            sizeof(buf)-1, &bytes_read);

    if (rv && bytes_read <= 0) {
        return rv;
    }

    buf[bytes_read] = '\0';
    
    if (strstr(buf, conf->path) != NULL) {
        apr_file_close(fp);
        return APR_SUCCESS;
    }

    apr_file_close(fp);
    return APR_EGENERAL;
}

static int mcgi_handler(request_rec *r)
{
    int status;
    mcgi_conf_t *conf;
    
    conf = (mcgi_conf_t *) ap_get_module_config(r->per_dir_config,
                                                &asf_mirrorcgi_module);

    if (!conf || conf->enabled == 0 || conf->path == NULL) {
        return DECLINED;
    }

    /* only operate on CGI scripts -- just like mod_cgi.c */
    if (strcmp(r->handler, CGI_MAGIC_TYPE) && strcmp(r->handler, "cgi-script")) {
        return DECLINED;
    }
    
    if (should_remap(r, conf) == APR_SUCCESS) {
        if (strcmp(r->filename, conf->path) == 0) {
            ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
                          "ASFMirrorCgi: Can't hack mirror url to itself: '%s'", conf->path);
            return HTTP_INTERNAL_SERVER_ERROR;
        }

        /* store the original path so that the mirrors.cgi can pull it out again. */
        apr_table_set(r->subprocess_env, "ASF_MIRROR_FILENAME", r->filename);
        r->filename = apr_pstrdup(r->pool, conf->path);
        if (conf->force_handler) {
          r->handler =  conf->force_handler;
        }
    }
    else {
        return DECLINED;
    }

    status = ap_directory_walk(r);
    if (status) {
        return status;
    }
    
    status = ap_file_walk(r);
    if (status) {
        return status;
    }

    return DECLINED;
}

static void mcgi_register_hooks(apr_pool_t * p)
{
  ap_hook_handler(mcgi_handler, NULL, NULL, APR_HOOK_REALLY_FIRST);
}

static void *mcgi_create_conf(apr_pool_t * p, char *dummy)
{
    mcgi_conf_t *conf = apr_pcalloc(p, sizeof(mcgi_conf_t));
    
    conf->enabled = 0;
    conf->path = NULL;
    conf->force_handler = NULL;
    return conf;
}

static void* mcgi_merge_conf(apr_pool_t* pool, void* a, void* b) {
    mcgi_conf_t* base = (mcgi_conf_t*) a;
    mcgi_conf_t* add = (mcgi_conf_t*) b;
    mcgi_conf_t* conf = apr_palloc(pool, sizeof(mcgi_conf_t));

    conf->enabled = add->enabled ? add->enabled : base->enabled;
    conf->path = add->path ? add->path : base->path;
    conf->force_handler = add->force_handler ? add->force_handler : base->force_handler;

    return conf;
}

static const command_rec mcgi_cmds[] = {
    AP_INIT_FLAG("ASFMirrorCgi", ap_set_flag_slot,
                 (void *) APR_OFFSETOF(mcgi_conf_t, enabled),
                 ACCESS_CONF,
                 "Enable MirrorCgi"),
    AP_INIT_TAKE1("ASFMirrorCgiPath", ap_set_file_slot,
              (void *) APR_OFFSETOF(mcgi_conf_t, path),
              ACCESS_CONF,
              "Set the path to hack"),
  AP_INIT_TAKE1("ASFMirrorForceHandler", ap_set_string_slot,
                (void *) APR_OFFSETOF(mcgi_conf_t, force_handler),
                ACCESS_CONF,
                "Set the path to hack"),
  {NULL}
};


module AP_MODULE_DECLARE_DATA asf_mirrorcgi_module = {
    STANDARD20_MODULE_STUFF,
    mcgi_create_conf,
    mcgi_merge_conf,
    NULL,
    NULL,
    mcgi_cmds,
    mcgi_register_hooks,
};

