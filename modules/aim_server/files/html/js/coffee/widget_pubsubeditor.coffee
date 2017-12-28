ps_domain = ''
ps_project = ''
savePubSub = () ->
    ps_type = get('pubsub_type').value
    ps_por = get('pubsub_por').value
    ps_source = get('pubsub_source').value
    
    ps_changes = {
        'domain': ps_domain,
        'project': ps_project,
        'type': ps_type,
        'source': ps_source,
    }
    payload = {
        'project': ps_project,
        'por': ps_por,
        'type': 'pubsub',
        'payload': ps_changes
    }
    
    put('queue/list/add', payload, null, sentPubSub)

sentPubSub = () ->
    get('pubsub_form').innerHTML = "<h2>Your request has been filed!</h2>"

pubsubEditor = (json, state) ->
    tbl = new HTML('table', {id: 'pubsub_form', class: 'table table-striped'})
    
    d = new HTML('div')
    d.inject(new HTML('p', {},
                        "This page allows you to create or modify the publisher/subscriber settings for your project's web site."
                        ))
    d.inject(new HTML('p', {},
                        "Once your request has been filed, and approved by Infrastructure, it will take approximately 30 minutes to be processed and applied."
                        ))
    d.inject(new HTML('p', {},
                        "Note that we only accept official ASF repos on svn.apache.org, git-wip.apache.org and gitbox.apache.org"
                        ))
    state.widget.inject(d, true)
    
    if not json.type
        d.inject(new HTML('b', {}, "There doesn't seem to be any pubsub configuration for this domain yet, but you can request a setup using the form below:"))
        json = {
            'type': 'git',
            'source': '',
            'domain': json.domain,
            'project': json.project
        }
    if json.type and json.project
        ps_domain = json.domain
        ps_project = json.project
        json.por = 'Put some reason or a vote link here'
        tr = new HTML('tr')
        tr.inject(
            new HTML('th', {}, "Configuration")
        )
        tr.inject(
            new HTML('th', {}, "Value")
        )
        
        tbl.inject(tr)
        
        for key, value of json
            
            
            xvalue = value
            if key == 'type'
                xvalue = [new HTML('select', {'id': 'pubsub_type'})]
                xvalue[0].inject(new HTML('option', { value: 'git', selected: if value == 'git' then 'selected' else null}, 'GitPubSub'))
                xvalue[0].inject(new HTML('option', { value: 'svn', selected: if value == 'svn' then 'selected' else null}, 'SVNPubSub'))
                xvalue.push(new HTML('br'))
                xvalue.push("For git repositories, remember that all sites are published using the asf-site branch. This branch MUST be present before you request pubsub setup. The setup procedure will verify this once the request has been approved.")
            if key == 'source'
                xvalue = new HTML('input', { id: 'pubsub_source', type: 'text', value: value, size: 64, placeholder: 'e.g. https://gitbox.apache.org/repos/asf/foo-site.git'})
            
            if key == 'por'
                key = 'Proof-of-Request'
                xvalue = new HTML('textarea', { id: 'pubsub_por', style: { width: '400px', height: '120px'}, placeholder: "Put a reason for the request, e.g. a link to a vote email thread or explain it's a new podling etc. This will be used to assess the validity of the request."})
            
            tr = new HTML('tr')
                
            tr.inject(
                new HTML('td', {}, key)
            )
            
            tr.inject(
                new HTML('td', {}, xvalue)
            )
            tbl.inject(tr)
        tr = new HTML('tr')
        td = new HTML('td', {colspan: 2})
        btn = new HTML('input', { type: 'button', class: 'btn btn-success', onclick: 'savePubSub();', value: 'Save and request changes'})
        td.inject(btn)
        tr.inject(td)
        tbl.inject(tr)
    
    else
        badModal("We can't find this sub-domain in LDAP. Please contact infra!")
    
    state.widget.inject(tbl)
