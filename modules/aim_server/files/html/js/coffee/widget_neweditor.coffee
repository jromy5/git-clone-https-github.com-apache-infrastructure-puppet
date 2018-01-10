

newEditor = (json, state) ->
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
