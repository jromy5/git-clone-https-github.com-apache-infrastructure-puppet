ps_domain = ''
ps_project = ''
ps_podling = false
ps_new = false

saveRepository = () ->
    ps_repo = get('repo_name').value
    ps_type = get('repo_type').value
    ps_por = get('repo_por').value
    ps_commitlist = get('repo_commitlist').value
    ps_issuelist = get('repo_issuelist').value
    ps_jira = get('repo_jira').value
    
    ps_changes = {
        'repo': ps_repo,
        'project': ps_project,
        'type': ps_type,
        'commitlist': ps_commitlist,
        'issuelist': ps_issuelist,
        'jira': ps_jira
    }
    payload = {
        'project': ps_project,
        'por': ps_por,
        'type': 'repository',
        'payload': ps_changes
    }
    
    put('queue/list/add', payload, null, sentRepository)

sentRepository = (json, state) ->
    get('repo_form').innerHTML = "<h2>Your request (#{json.id}) has been filed!</h2>"


switchRepoType = (t) ->
    if t == 'gitbox'
        get('repo_host').innerText = 'https://gitbox.apache.org/repos/asf/'
        get('repo_ext').innerText = '.git'
    if t == 'git-wip'
        get('repo_host').innerText = 'https://git-wip-us.apache.org/repos/asf/'
        get('repo_ext').innerText = '.git'
    if t == 'svn'
        get('repo_host').innerText = 'https://svn.apache.org/repos/asf/'
        get('repo_name').value = ps_project
        if ps_podling
            get('repo_host').innerText += "incubator/"
        get('repo_ext').innerText = ''
    if t == 'svnpmc'
        get('repo_host').innerText = 'https://svn.apache.org/repos/private/pmc/'
        if ps_podling
            get('repo_host').innerText += "incubator/"
        get('repo_name').value = ps_project
        get('repo_ext').innerText = ''
repoEditor = (json, state) ->
    ps_new = false
    ps_project = json.project
    tbl = new HTML('table', {id: 'repo_form', class: 'table table-striped'})
    
    d = new HTML('div')
    d.inject(new HTML('p', {},
                        "This page allows you to create or modify repositories for your project."
                        ))
    d.inject(new HTML('p', {},
                        "Once your request has been filed, and approved by Infrastructure, it will take approximately 30 minutes to be processed and applied."
                        ))
    state.widget.inject(d, true)
    
    if not json.type
        d.inject(new HTML('b', {}, "There doesn't seem to be any configuration for this repository yet, but you can request a setup using the form below:"))
        ps_new = true
        json = {
            'type': 'gitbox',
            'project': json.project,
            'domain': json.domain,
            'repository': 'foo',
            'podling': json.podling
        }
    if json.project and json.type
        ps_podling = json.podling
        json.por = 'Put some reason or a vote link here'
        tr = new HTML('tr')
        tr.inject(
            new HTML('th', {}, "Configuration")
        )
        tr.inject(
            new HTML('th', {}, "Value")
        )
        
        tbl.inject(tr)
        
        # Project
        key = "Project"
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, json.project))
        tbl.inject(tr)
        
        # Repo type
        key = "Repository type"
        xvalue = new HTML('select', { onchange: 'switchRepoType(this.value);', id: 'repo_type'})
        xvalue.inject(
            new HTML('option', { value: 'gitbox', selected: if (json.type||'gitbox') == 'gitbox' then 'selected' else null}, 'GitBox/GitHub repository')
        )
        xvalue.inject(
            new HTML('option', { value: 'git-wip', selected: if (json.type||'gitbox') == 'git-wip' then 'selected' else null}, 'Legacy Git repository (git-wip-us)')
        )
        xvalue.inject(
            new HTML('option', { value: 'svn', selected: if (json.type||'gitbox') == 'svn' then 'selected' else null}, 'Subversion repository')
        )
        xvalue.inject(
            new HTML('option', { value: 'svnpmc', selected: if (json.type||'gitbox') == 'svnpmc' then 'selected' else null}, 'Subversion repository, PMC private')
        )
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, [xvalue, ' New podlings and projects migrating from svn should pick GitBox over the legacy git-wip host.']))
        tbl.inject(tr)
        
        # repo name
        fooName = ""
        if not ps_new
            fooName = json.repository
        else
            fooName = json.project + "-foo"
            if json.podling
                fooName = "incubator-" + fooName
        key = "Repository name"
        xvalue = [
            new HTML('span', {id: 'repo_host'}),
            new HTML('input', { id: 'repo_name', readonly: (if not ps_new then 'readonly' else null), type: 'text', value: (if not ps_new then json.repository.replace('.git', '') else fooName), size: 16, placeholder: 'foo.git'}),
            new HTML('span', {id: 'repo_ext'}, if json.type != 'svn' then '.git' else '')
            ]
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # Commits list
        key = "Commit list"
        fooName = "commits@#{json.domain}.apache.org"
        xvalue = [            
            new HTML('input', { id: 'repo_commitlist', type: 'text', value: (if not ps_new and (json.commitlist and json.commitlist.length > 0) then json.commitlist else fooName), size: 32, placeholder: 'commits@foo.apache.org'}),
            ' For subversion repositories, commit lists are hardcoded and cannot be set here.'
            ]
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # issue/PR list
        key = "GitHub PR/issue notification list"
        fooName = "dev@#{json.domain}.apache.org"
        xvalue = [            
            new HTML('input', { id: 'repo_issuelist', type: 'text', value: (if not ps_new and (json.issuelist and json.issuelist.length > 0) then json.issuelist else fooName), size: 32, placeholder: 'commits@foo.apache.org'}),
            ' This only applies to git repositories.'
            ]
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # GitHub -> JIRA settings
        key = "GitHub to JIRA settings"
        xvalue = new HTML('select', { id: 'repo_jira'})
        xvalue.inject(
            new HTML('option', { value: 'default', selected: if (json.jira||'default') == 'default' then 'selected' else null}, 'Default (mirror all tickets/comments)')
        )
        xvalue.inject(
            new HTML('option', { value: 'worklog', selected: if (json.jira||'default') == 'worklog' then 'selected' else null}, 'Mirror to work log')
        )
        xvalue.inject(
            new HTML('option', { value: 'nocomment', selected: if (json.jira||'default') == 'nocomment' then 'selected' else null}, 'Only mirror open/close of tickets')
        )
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        
        # PoR
        key = 'Proof-of-Request'
        xvalue = new HTML('textarea', { id: 'repo_por', style: { width: '400px', height: '120px'}, placeholder: "Put a reason for the request, e.g. a link to a vote email thread or explain it's a new podling etc. This will be used to assess the validity of the request."})
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
            
            
        tr = new HTML('tr')
        td = new HTML('td', {colspan: 2})
        btn = new HTML('input', { type: 'button', class: 'btn btn-success', onclick: 'saveRepository();', value: 'Save and request changes'})
        td.inject(btn)
        tr.inject(td)
        tbl.inject(tr)
    
    else
        
        badModal("We can't find this mailing list. Please contact infra!")
    
    state.widget.inject(tbl)
    switchRepoType(json.type||'gitbox')
    

