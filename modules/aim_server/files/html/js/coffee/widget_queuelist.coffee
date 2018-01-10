queue_items = {}

showHideQueue = (id) ->
    obj = get('request_'+id)
    if obj
        if obj.style.display == 'none'
            obj.style.display = 'table-row'
            queueDetails(obj, id)
        else
            obj.style.display = 'none'

denyQueue = (id) ->
    patch('queue/list/foo',
          {
            id: id,
            status: 'denied'
          }, null, () -> location.reload()
         )


approveQueue = (id) ->
    patch('queue/list/foo',
          {
            id: id,
            status: 'approved'
          }, null, () -> location.reload()
         )



unapproveQueue = (id) ->
    patch('queue/list/foo',
          {
            id: id,
            status: 'unapproved'
          }, null, () -> location.reload()
         )
    
resetQueue = (id) ->
    patch('queue/list/foo',
          {
            id: id,
            status: 'rescheduled'
          }, null, () -> location.reload()
         )
    
queueDetails = (obj, id) ->
    item = queue_items[id]
    html = new HTML('td', {colspan: 7})
    html.inject(new HTML('h3', {}, "Request #{id}:"))
    
    # DNS change
    if item.type == 'dns'
        html.inject(["This is a request to create ", new HTML('kbd', {}, item.project + ".apache.org"), " via normaltlps.txt"])
    
    # GitPubSub setup
    if item.type == 'pubsub'
        html.inject([
            "This is a request to set up #{item.payload.type}PubSub for  ",
            new HTML('kbd', {}, item.payload.domain),
            ", pointing at ",
            new HTML('kbd', {}, item.payload.source),
            ])
        
    # Mailing list creation/editing
    if item.type == 'mailinglist'
        if item.payload.action == 'create'
            ml = item.payload.listname
            html.inject(["This is a request to create ", new HTML('kbd', {}, ml), "."])
        if item.payload.action == 'modify'
            ml = item.payload.listname
            html.inject(["This is a request to modify ", new HTML('kbd', {}, ml), "."])
    
    # ML unsub requests
    if item.type == 'mail-unsub'
        ml = item.payload.listname
        html.inject("This is a request to unsubscribe #{item.payload.target} from #{ml}")
    
    html.inject(new HTML('br'))
    
    # Diff and PoR
    if item.diff and item.diff.length > 0
        html.inject(new HTML('pre', {}, "Changeset:\n\n" + item.diff))
        html.inject(new HTML('hr'))
    if item.por
        pre = new HTML('pre', {}, "Proof of Request:\n")
        por = item.por.replace(/</g, "&lt;").replace(/(https?:\/\/\S+)/g, (a) => "<a href='#{a}' target='_blank'>#{a}</a>")
        pre.innerHTML += por
        html.inject(pre)
    else
        html.inject("No Proof-of-Request provided")
    
    html.inject(new HTML('hr'))
    if userAccount.isRoot
        if item.approved == false
            btn = new HTML('input', {onclick: "approveQueue('#{item.id}');",type: 'button', class: 'btn btn-success', value: 'Approve request'})
            html.inject(btn)
            
            btn = new HTML('input', {onclick: "denyQueue('#{item.id}');", type: 'button', class: 'btn btn-danger', value: 'Deny request'})
            html.inject(btn)
        
        if item.approved == true and item.completed == false
            btn = new HTML('input', {onclick: "unapproveQueue('#{item.id}');", type: 'button', class: 'btn btn-danger', value: 'Remove approval'})
            html.inject(btn)
            
    # Errors encounted?
    if item.error
        if userAccount.isRoot
            btn = new HTML('input', {onclick: "resetQueue('#{item.id}');", type: 'button', class: 'btn btn-warning', value: 'Reschedule request'})
            html.inject(btn)
        
        html.inject(new HTML('pre', {}, "This request was processed on #{item.handler} but failed:\n" + item.error))
        
    
    obj.innerHTML = ""
    obj.inject(html)

queueList = (json, state) ->
    tbl = new HTML('table', {class: 'table table-striped'})
    if json.queue and json.queue.length > 0
        json.queue.sort((a,b) => b.createdTime - a.createdTime)
        tr = new HTML('tr')
        tr.inject(
            new HTML('th', {}, "Request ID")
        )
        tr.inject(
            new HTML('th', {}, "Request Type")
        )
        tr.inject(
            new HTML('th', {}, "Project")
        )
        tr.inject(
            new HTML('th', {}, "Requester")
        )
        tr.inject(
            new HTML('th', {}, "Time in queue")
        )
        tr.inject(
            new HTML('th', {}, "Approved")
        )
        tr.inject(
            new HTML('th', {}, "Status")
        )
        tbl.inject(tr)
        
        for item in json.queue
            queue_items[item.id] = item
            tr = new HTML('tr', { class: 'hovertr', onclick: "showHideQueue('#{item.id}')"})
            if item.error
                tr.style.background = '#F0D0C0'
                tr.style.color = '#803000'
                
            tr.inject(
                new HTML('td', {}, item.id)
            )
            tr.inject(
                new HTML('td', {}, item.type)
            )
            tr.inject(
                new HTML('td', {}, item.project)
            )
            tr.inject(
                new HTML('td', {}, item.creator)
            )
            age = (new Date().getTime() / 1000) - item.createdTime
            if age > 7200
                age = Math.round(age/3600) + " hours"
            else
                age = Math.round(age / 60) + " minutes"
            tr.inject(
                new HTML('td', {}, age)
            )
            app = new HTML('span', { style: {color: if item.approved == true then 'green' else 'grey'}}, if item.approved == true then 'Approved by ' + item.approver else 'Not yet')
            tr.inject(
                new HTML('td', {}, app)
            )
            status = "Pending approval"
            if item.approved == true
                status = "Pending processing"
            if item.completed == true
                status = "Processed"
            if item.error
                status = "Error in processing!"
            tr.inject(
                new HTML('td', {}, status)
            )
            tbl.inject(tr)
            
            # Item details
            tr = new HTML('tr', {id: "request_#{item.id}", style: { display: 'none'}})
            td = new HTML('td', {colspan: 7}, "foooo")
            tr.inject(td)
            tbl.inject(tr)
            
    else
        tbl.inject(txt("No pending requests"))
    state.widget.inject(tbl, true)
