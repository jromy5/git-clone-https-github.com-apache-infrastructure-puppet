projects = {}
dnsid = ''

makeDNS = (project, domain) ->
    dnsid = project
    payload = {
        'project': project,
        'type': 'dns',
        'payload':  {
            'domain': domain
        }
    }
    
    put('queue/list/add', payload, null, sentDNS)
    
sentDNS = (json, state) ->
    get("dns_#{dnsid}").setAttribute('onclick', 'javascript:void(0);')
    get("dns_#{dnsid}").setAttribute("class", 'btn btn-warning')
    get("dns_#{dnsid}").innerText = 'Request filed!'

showHideProject = (id) ->
    obj = get('project_'+id)
    if obj
        if obj.style.display == 'none'
            obj.style.display = 'table-row'
            projectDetails(obj, id)
        else
            obj.style.display = 'none'

projectDetails = (obj, id) ->
    item = projects[id]
    idtxt = id
    if item.podling
        idtxt += " (podling)"
    html = new HTML('td', {colspan: 7})
    html.inject(new HTML('h2', {style: {textAlign: 'center'}}, "#{idtxt}:"))
    html.inject(new HTML('br'))
    
    
    # dns
    html.inject(new HTML('hr'))
    html.inject(new HTML('h4', {}, 'DNS record:'))
    if item.dns
        html.inject("The domain, #{item.domain}, exists in DNS")
    else
        html.inject("The domain, #{item.domain}, does not appear to exist in DNS yet. ")
        html.inject(new HTML('a', { id:"dns_#{id}", class: 'btn btn-success', onclick: "makeDNS('#{id}', '#{item.domain}');"}, "Set up DNS"))
    html.inject(new HTML('br'))  
    
    # pubsub
    html.inject(new HTML('hr'))
    html.inject(new HTML('h4', {}, 'Web site publishing:'))
    if item.pubsub
        if item.pubsub.type == 'git'
            html.inject("The web site at ")
            html.inject(new HTML('a', { href: "https://#{item.domain}"}, item.domain))
            html.inject(" is served via gitpubsub from ")
            html.inject(new HTML('a', { href: item.pubsub.source}, item.pubsub.source))
            
            # details/modify
            html.inject(" - ")
            html.inject(new HTML('a', { class: 'btn btn-slim btn-warning', href: "?page=pubsub-modify&domain=#{item.domain}"}, "Details/modify"))
        
        if item.pubsub.type == 'svn'
            html.inject("The web site at ")
            html.inject(new HTML('a', { href: item.domain}, item.domain))
            if item.pubsub.source.search('websites/production') != -1
                html.inject(" is served via the ASF CMS system from ")
            else
                html.inject(" is served via svnpubsub from ")
            html.inject(new HTML('a', { href: item.pubsub.source}, item.pubsub.source))
            
            # details/modify
            html.inject(" - ")
            html.inject(new HTML('a', { class: 'btn btn-slim btn-warning', href: "?page=pubsub-modify&domain=#{item.domain}"}, "Details/modify"))
            
        html.inject(new HTML('br'))
    
    else
        html.inject("There doesn't appear to be any pubsub configuration for #{item.domain} yet.")
        html.inject(" - ")
        html.inject(new HTML('a', { class: 'btn btn-success', href: "?page=pubsub-new&domain=#{item.domain}"}, "Set up pubsub"))
        html.inject(new HTML('br'))
    
    # Mailing lists
    html.inject(new HTML('hr'))
    html.inject(new HTML('h4', {}, 'Mailing lists:'))
    if item.mailinglists
        mlno = 0
        for k,v of item.mailinglists
            mlno++
        html.inject("This project has #{mlno} mailing lists:")
        ul = new HTML('ul')
        for l, details of item.mailinglists
            li = new HTML('li', {title: "Moderators: " + details.moderators.join(", ")}, "#{l}@#{item.domain} (#{details.moderators.length} moderators, #{details.subscribers} subscribers) - ")
            li.inject(new HTML('a', { class: 'btn btn-slim btn-warning', href: "?page=mail-modify&ml=#{l}@#{item.domain}"}, "Details/modify"))
            ul.inject(li)
        html.inject(ul)
    if item.dns
        html.inject(new HTML('a', { class: 'btn btn-success', href: "?page=mail-new&ml=NEW@#{item.domain}"}, "Create a new mailing list"))
    else
        html.inject("You'll need to create a DNS record before you can set up mailing lists.")
    
    
    # Repositories
    html.inject(new HTML('hr'))
    html.inject(new HTML('h4', {}, 'Source code repositories:'))
    if item.repositories
        repno = 0
        for k,v of item.repositories
            repno++
        html.inject("This project has #{repno} source code repositores:")
        ul = new HTML('ul')
        for l, details of item.repositories
            li = new HTML('li', {}, new HTML('a', {href: details.url, target: '_blank'}, details.url))
            li.inject(new HTML('a', { class: 'btn btn-slim btn-warning', href: "?page=repo-modify&project=#{id}&repo=#{details.repository}"}, "Modify"))
            ul.inject(li)
        html.inject(ul)
    if mlno > 0
        html.inject(new HTML('a', { class: 'btn btn-success', href: "?page=repo-new&project=#{id}"}, "Create a new repository"))
    else
        html.inject("You'll need to create mailing lists before you can set up repositories.")
    
    
    obj.innerHTML = ""
    obj.inject(html)
    
pMissingComponent = (item) ->
    if not item.dns
        return "This project has no DNS record set yet."
    if not item.mailinglists or item.mailinglists.length == 0
        return "This project has no mailing lists yet"
    return null

projectList = (json, state) ->
    tbl = new HTML('table', {class: 'table table-striped'})
    if json.pmcs and json.pmcs.length > 0
        tr = new HTML('tr')
        tr.inject(
            new HTML('th', {}, "Project ID")
        )
        tr.inject(
            new HTML('th', {}, "Project domain")
        )
        tr.inject(
            new HTML('th', {}, "Project Status")
        )
        
        tbl.inject(tr)
        sortByKey(json.pmcs, 'id')
        for item in json.pmcs
            projects[item.id] = item
            tr = new HTML('tr', { class: 'hovertr', onclick: "showHideProject('#{item.id}')"})
            w = pMissingComponent(item)
            if w
                tr.style.background = '#F0D0C0'
                tr.style.color = '#604000'
                tr.setAttribute("title",  w)
            if item.error 
                tr.style.background = '#F0D0C0'
                tr.style.color = '#803000'
            
            tr.inject(
                new HTML('td', {}, item.id)
            )
            tr.inject(
                new HTML('td', {}, item.domain)
            )
            tr.inject(
                new HTML('td', {}, if item.podling then 'Podling' else 'Top Level Project')
            )
            tbl.inject(tr)
            
            # Item details
            tr = new HTML('tr', {id: "project_#{item.id}", style: { display: 'none'}})
            td = new HTML('td', {colspan: 7}, "foooo")
            tr.inject(td)
            tbl.inject(tr)
            
    else
        tbl.inject(txt("You are not on any PMCs"))
    state.widget.inject(txt("Click on a project to view resources assigned to it and perform actions."), true)
    state.widget.inject(tbl)
