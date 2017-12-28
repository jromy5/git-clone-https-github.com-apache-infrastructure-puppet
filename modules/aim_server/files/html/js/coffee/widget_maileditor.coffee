ps_domain = ''
ps_project = ''
ps_listname = ''
ps_new = false

saveMailingList = () ->
    if ps_new
        ps_listname = get('mailinglist_listname').value + "@" + ps_domain
    ps_moderators = get('mailinglist_moderators').value.split(/\r?\n/)
    ps_por = get('mailinglist_por').value
    ps_private = get('poption').checked
    ps_modunsubbed = get('moption').checked
    ps_trailer = get('toption').checked
    
    ps_changes = {
        'listname': ps_listname,
        'project': ps_project,
        'moderators': ps_moderators,
        'private': ps_private,
        'modunsubed': ps_modunsubbed,
        'trailer': ps_trailer,
        'action': 'modify'
    }
    payload = {
        'project': ps_project,
        'por': ps_por,
        'type': 'mailinglist',
        'payload': ps_changes
    }
    
    put('queue/list/add', payload, null, sentMailingList)

chMods = (add, remove) ->
    if add == '' and not remove
        return
    mods = get('mailinglist_moderators').value.split(/\r?\n/)
    if add
        mods.push(add)
    if remove
        xmods = []
        for mod in mods
            if mod != remove and mod != ''
                xmods.push(mod)
        mods = xmods
    get('mailinglist_moderators').value = mods.join("\n")
    makeMods()
        
makeMods = () ->
    if get('mailinglist_moderators')
        moderators = get('mailinglist_moderators').value.split(/\r?\n/)
        mdiv = get('mod_div')
        mdiv.innerHTML = ''
        for mod in moderators
            if mod != ''
                w = new HTML('div', { style: { float: 'left'}})
                m = new HTML('span', { class: 'tagvalue'}, mod)
                x = new HTML('span', { class: 'tagcross', onclick: "chMods(null, '#{mod}');"}, 'X')
                w.inject(m)
                w.inject(x)
                mdiv.inject(w)
        t = new HTML('input', { type: 'text', class: 'tagtext', placeholder: 'Type to add', onblur: 'chMods(this.value);'})
        mdiv.inject(t)
        t.focus()
    
        
saveUnsub = () ->
    ps_target = get('mailinglist_target').value
    ps_method = get('mailinglist_method').value
    ps_por = get('mailinglist_unsub_por').value
    
    ps_changes = {
        'listname': ps_listname,
        'project': ps_project,
        'action': ps_method,
        'target': ps_target
    }
    payload = {
        'project': ps_project,
        'por': ps_por,
        'type': 'mail-unsub',
        'payload': ps_changes
    }
    put('queue/list/add', payload, null, sentUnsub)

sentMailingList = (json, state) ->
    get('mailinglist_form').innerHTML = "<h2>Your request (#{json.id}) has been filed!</h2>"

sentUnsub = (json, state) ->
    get('mailinglist_unsub_form').innerHTML = "<h2>Your request (#{json.id}) has been filed!</h2>"

mailEditor = (json, state) ->
    ps_new = false
    ps_listname = "#{json.listname}@#{json.domain}"
    ps_domain = json.domain
    ps_project = json.project
    tbl = new HTML('table', {id: 'mailinglist_form', class: 'table table-striped'})
    
    d = new HTML('div')
    d.inject(new HTML('p', {},
                        "This page allows you to create or modify mailing list settings for your project."
                        ))
    d.inject(new HTML('p', {},
                        "Once your request has been filed, and approved by Infrastructure, it will take approximately 30 minutes to be processed and applied."
                        ))
    state.widget.inject(d, true)
    
    if not json.type
        d.inject(new HTML('b', {}, "There doesn't seem to be any configuration for this list yet, but you can request a setup using the form below:"))
        ps_new = true
        json = {
            'type': 'mailinglist',
            'source': '',
            'domain': json.domain,
            'project': json.project,
            'modunsubbed': true,
            'listname': 'NEW',
            'moderators': [],
        }
    if json.domain and json.listname
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
        
        # list name
        key = "List name"
        xvalue = [
            new HTML('input', { id: 'mailinglist_listname', readonly: (if json.listname != 'NEW' then 'readonly' else null), type: 'text', value: (if json.listname != 'NEW' then json.listname else 'foo'), size: 16, placeholder: 'foo@foo.apache.org'}),
            '@'+json.domain
            ]
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # Moderators
        key = "Moderators"
        xvalue = [new HTML('textarea', { id: 'mailinglist_moderators', style: { display: 'none', width: '400px', height: '120px'}, placeholder: "Email addresses, one per line."}, json.moderators.join("\n"))]
        xvalue.push(new HTML('div', {id: 'mod_div', style: { lineHeight: '30px', maxWidth: '640px'}}))
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # Options
        key = "Mailing list options"
        xvalue = []
        
        poption = new HTML('div')
        poption.inject(
            new HTML('input', { id: 'poption', type: 'checkbox', value: 'yes', checked: (if json.listname in ['private', 'security'] or json.private then 'checked' else null)})
        )
        poption.inject(
            new HTML('label', { for: 'poption', style: { marginLeft: '8px'}}, "Private list (private archive, subscribers moderated). ")
        )
        poption.inject(
            new HTML('span', {}, " NOTE: private@ as well as security@ will always be private. All other lists SHOULD be public.")
        )
        xvalue.push(poption)
        
        moption = new HTML('div')
        moption.inject(
            new HTML('input', { id: 'moption', type: 'checkbox', value: 'yes', checked: if json.modunsubbed then 'checked' else null})
        )
        moption.inject(
            new HTML('label', { for: 'moption', style: { marginLeft: '8px'}}, "Moderate emails from unsubscribed senders")
        )
        xvalue.push(moption)
        
        poption = new HTML('div')
        poption.inject(
            new HTML('input', { id: 'toption', type: 'checkbox', value: 'yes', checked: if json.trailer then 'checked' else null})
        )
        poption.inject(
            new HTML('label', { for: 'toption', style: { marginLeft: '8px'}}, "Add unsubscribe trailer to emails")
        )
        xvalue.push(poption)
        
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # PoR
        key = 'Proof-of-Request'
        xvalue = new HTML('textarea', { id: 'mailinglist_por', style: { width: '400px', height: '120px'}, placeholder: "Put a reason for the request, e.g. a link to a vote email thread or explain it's a new podling etc. This will be used to assess the validity of the request."})
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
            
            
        tr = new HTML('tr')
        td = new HTML('td', {colspan: 2})
        btn = new HTML('input', { type: 'button', class: 'btn btn-success', onclick: 'saveMailingList();', value: 'Save and request changes'})
        td.inject(btn)
        tr.inject(td)
        tbl.inject(tr)
    
    else
        badModal("We can't find this mailing list. Please contact infra!")
    
    state.widget.inject(tbl)
    makeMods()


mailUnsubber = (json, state) ->
    
    ps_listname = "#{json.listname}@#{json.domain}"
    ps_project = json.project
    tbl = new HTML('table', {id: 'mailinglist_unsub_form', class: 'table table-striped'})
    
    d = new HTML('div')
    state.widget.inject(d, true)
    
    if json.domain and json.listname
        json.por = 'Put some reason or a vote link here'
        
        # Target
        key = "Target email address"
        xvalue = new HTML('input', { id: 'mailinglist_target', type: 'text', value: "", size: 64, placeholder: 'foo@example.org'})
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # Method
        key = "Method"
        xvalue = new HTML('select', {id: 'mailinglist_method'})
        xvalue.inject(new HTML('option', { value: 'unsub'}, "Just unsubscribe the user, don't ban"))
        xvalue.inject(new HTML('option', { value: 'ban'}, "Unsubscribe and ban (prevent from re-subscribing)"))
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
        # PoR
        key = 'Proof-of-Request'
        xvalue = new HTML('textarea', { id: 'mailinglist_unsub_por', style: { width: '400px', height: '120px'}, placeholder: "Put a reason for the request, e.g. a link to a vote email thread or explain it's a new podling etc. This will be used to assess the validity of the request."})
        tr = new HTML('tr')
        tr.inject(new HTML('td', {}, key))
        tr.inject(new HTML('td', {}, xvalue))
        tbl.inject(tr)
        
            
        tr = new HTML('tr')
        td = new HTML('td', {colspan: 2})
        btn = new HTML('input', { type: 'button', class: 'btn btn-success', onclick: 'saveUnsub();', value: 'Request unsubscription'})
        td.inject(btn)
        tr.inject(td)
        tbl.inject(tr)
    state.widget.inject(tbl, true)