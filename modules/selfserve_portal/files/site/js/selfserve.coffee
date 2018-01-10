Number.prototype.pretty = (fix) ->
    if (fix)
        return String(this.toFixed(fix)).replace(/(\d)(?=(\d{3})+\.)/g, '$1,');
    return String(this.toFixed(0)).replace(/(\d)(?=(\d{3})+$)/g, '$1,');


fetch = (url, xstate, callback, snap, nocreds) ->
    xmlHttp = null;
    # Set up request object
    if window.XMLHttpRequest
        xmlHttp = new XMLHttpRequest();
    else
        xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    if not nocreds
        xmlHttp.withCredentials = true
    # GET URL
    xmlHttp.open("GET", url, true);
    xmlHttp.send(null);
    
    xmlHttp.onreadystatechange = (state) ->
            if xmlHttp.readyState == 4 and xmlHttp.status >= 200
                if callback
                    # Try to parse as JSON and deal with cache objects, fall back to old style parse-and-pass
                    try
                        response = JSON.parse(xmlHttp.responseText)
                        callback(response, xstate);
                    catch e
                        callback(null, xstate)

post = (url, args, xstate, callback, snap) ->
    xmlHttp = null;
    # Set up request object
    if window.XMLHttpRequest
        xmlHttp = new XMLHttpRequest();
    else
        xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    xmlHttp.withCredentials = true
    # Construct form data
    ar = []
    for k,v of args
        if isArray(v)
            for x in v
                ar.push(k + "=" + encodeURIComponent(x))
        else if v and v != ""
            ar.push(k + "=" + encodeURIComponent(v))
    fdata = ar.join("&")
    
    # POST URL
    xmlHttp.open("POST", url, true);
    xmlHttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    xmlHttp.send(fdata);
    
    xmlHttp.onreadystatechange = (state) ->
            if xmlHttp.readyState == 4 and xmlHttp.status == 500
                if snap
                    snap(xstate)
            if xmlHttp.readyState == 4 and xmlHttp.status >= 200
                if callback
                    # Try to parse as JSON and deal with cache objects, fall back to old style parse-and-pass
                    try
                        response = JSON.parse(xmlHttp.responseText)
                        callback(response, xstate, xmlHttp.status);
                    catch e
                        callback(xmlHttp.responseText, xstate, xmlHttp.status)


postJSON = (url, json, xstate, callback, snap) ->
    xmlHttp = null;
    # Set up request object
    if window.XMLHttpRequest
        xmlHttp = new XMLHttpRequest();
    else
        xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
    xmlHttp.withCredentials = true
    # Construct form data
    for key, val of json
        if val.match
            if val.match(/^\d+$/)
                json[key] = parseInt(val)
            if val == 'true'
                json[key] = true
            if val == 'false'
                json[key] = false
    fdata = JSON.stringify(json)
    
    # POST URL
    xmlHttp.open("POST", url, true);
    xmlHttp.setRequestHeader("Content-type", "application/json");
    xmlHttp.send(fdata);
    
    xmlHttp.onreadystatechange = (state) ->
            if xmlHttp.readyState == 4 and xmlHttp.status == 500
                if snap
                    snap(xstate)
            if xmlHttp.readyState == 4 and xmlHttp.status >= 200
                if callback
                    # Try to parse as JSON and deal with cache objects, fall back to old style parse-and-pass
                    try
                        response = JSON.parse(xmlHttp.responseText)
                        
                        callback(response, xstate, xmlHttp.status);
                    catch e
                        callback(xmlHttp.responseText, xstate, xmlHttp.status)

mk = (t, s, tt) ->
    r = document.createElement(t)
    if s
        for k, v of s
            if v
                r.setAttribute(k, v)
    if tt
        if typeof tt == "string"
            app(r, txt(tt))
        else
            if isArray tt
                for k in tt
                    if typeof k == "string"
                        app(r, txt(k))
                    else
                        app(r, k)
            else
                app(r, tt)
    return r

app = (a,b) ->
    if isArray b
        for item in b
            if typeof item == "string"
                item = txt(item)
            a.appendChild(item)
    else
        return a.appendChild(b)


set = (a, b, c) ->
    return a.setAttribute(b,c)

txt = (a) ->
    return document.createTextNode(a)

get = (a) ->
    return document.getElementById(a)


isArray = ( value ) ->
    value and
        typeof value is 'object' and
        value instanceof Array and
        typeof value.length is 'number' and
        typeof value.splice is 'function' and
        not ( value.propertyIsEnumerable 'length' )
        

### isHash: function to detect if an object is a hash ###
isHash = (value) ->
    value and
        typeof value is 'object' and
        not isArray(value)
        

class HTML
    constructor: (type, params, children) ->
        ### create the raw element, or clone if passed an existing element ###
        if typeof type is 'object'
            @element = type.cloneNode()
        else
            @element = document.createElement(type)
        
        ### If params have been passed, set them ###
        if isHash(params)
            for key, val of params
                ### Standard string value? ###
                if typeof val is "string" or typeof val is 'number'
                    @element.setAttribute(key, val)
                else if isArray(val)
                    ### Are we passing a list of data to set? concatenate then ###
                    @element.setAttribute(key, val.join(" "))
                else if isHash(val)
                    ### Are we trying to set multiple sub elements, like a style? ###
                    for subkey,subval of val
                        if not @element[key]
                            throw "No such attribute, #{key}!"
                        @element[key][subkey] = subval
        
        ### If any children have been passed, add them to the element  ###
        if children
            ### If string, convert to textNode using txt() ###
            if typeof children is "string"
                @element.inject(txt(children))
            else
                ### If children is an array of elems, iterate and add ###
                if isArray children
                    for child in children
                        ### String? Convert via txt() then ###
                        if typeof child is "string"
                            @element.inject(txt(child))
                        else
                            ### Plain element, add normally ###
                            @element.inject(child)
                else
                    ### Just a single element, add it ###
                    @element.inject(children)
        return @element
###*
# prototype injector for HTML elements:
# Example: mydiv.inject(otherdiv)
###
HTMLElement.prototype.inject = (child) ->
    if isArray(child)
        for item in child
            # Convert to textNode if string
            if typeof item is 'string'
                item = txt(item)
            this.appendChild(item)
    else
        # Convert to textNode if string
        if typeof child is 'string'
            child = txt(child)
        this.appendChild(child)
    return child

formData = {}
lastGoodFormData = {}
regex = {}
verifiers = {}
preloaded = {}
urls = {}
forms = {}


verifyJIRA = (name) ->
            if preloaded["js/keys.json"]
                        if name in preloaded["js/keys.json"]
                                    return "#{name} is already in use!"
verifyCONF = (name) ->
            if preloaded["js/spacekeys.json"]
                        if name in preloaded["js/spacekeys.json"]
                                    return "#{name} is already in use!"


userExists = (name) ->
            request = new XMLHttpRequest()
            request.open('GET', 'cgi-bin/jirauser.cgi?username=' + name, false)
            request.send(null)
            
            if (request.status != 200)
                        return request.responseText
          

cuserExists = (name) ->
            request = new XMLHttpRequest()
            request.open('GET', 'cgi-bin/confluenceuser.cgi?username=' + name, false)
            request.send(null)
            
            if (request.status != 200)
                        return request.responseText

checkPrivacy = (name) ->
    if name == 'true' and formData['list'] and not (formData['list'] in ['private', 'security'])
        return "Only private@ and security@ may be privately archived!"
    
verifyListname = (name) ->
    if name == "" and get('form_preset').value == ""
        return "You must pick a list name or a preset!"
          
verifyField = (e) ->
            key = e.target.getAttribute('id').split('_')[1...].join('_')
            if regex[key] and colorField(e)
                return
            f = verifiers[key]
            if not lastGoodFormData[key] or lastGoodFormData[key] != e.target.value
                        cval = e.target.value
                        if (e.target.getAttribute("type") == 'checkbox' and e.target.checked == false)
                            cval = null
                        rv = f(cval)
                        obj = get('warning_' + key)
                        if obj
                                    obj.parentNode.removeChild(obj)
                        if rv
                                    e.target.parentNode.setAttribute("class", "bad")
                                    e.target.parentNode.parentNode.appendChild(new HTML("div", { id: "warning_#{key}", class: "warning"}, rv))
                                    return rv
                        else if e.target.value.length > 0
                                    e.target.parentNode.setAttribute("class", "good")
                                    lastGoodFormData[key] = e.target.value
                                    if typeof e.target.checked == 'boolean'
                                        lastGoodFormData[key] = if e.target.checked then 'true' else null
                                    return false
                        else if e.target.parentNode.getAttribute("class") == 'bad'
                                    e.target.parentNode.setAttribute("class", "")
                                    return false
                        
colorField = (e) ->
            key = e.target.getAttribute('id').split('_')[1...].join('_')
            f = regex[key]
            if e.target.value.length > 0 and not e.target.value.match(f)
                        e.target.parentNode.setAttribute("class", "bad")
                        return true
            else
                        e.target.parentNode.setAttribute("class", "")
                        if e.target.value.length > 0
                                    e.target.parentNode.setAttribute("class", "good")
                        return false

            

xpage = 1
xobj = null
renderForm = (state, page) ->
    doc = xobj
    doc.innerHTML = ""
    
    pages = forms[state.file].pages
    
    if not pages[page-1]
        page = 1
    xpage = page
    wpct = parseInt(100/pages.length) + "%"
    bpct = "calc(#{wpct} - 24px)"
    mpct = parseInt(100/pages.length)/2 + "%"
    
    if pages.length > 1
            bc = new HTML("div", {class: 'breadcrumb', style: { marginLeft: "-#{mpct}"}})
            bctext = new HTML("div", {class: 'breadcrumb', style: { marginLeft: "-#{mpct}"}})
            
            bc.inject(new HTML('div', { style: { float: 'left', height: '24px', width: "calc(#{mpct} - 12px)"}}, ""))
            for entry, i in pages
                    xbc = new HTML('div', { class: 'bc', type: (if (i+1) == page then 'selected' else null), onclick: "changePage(\"#{state.file}\", #{i+1});"}, String(i+1))
                    bctext.inject(new HTML('div', {class: 'bctext', style: { width: wpct}, onclick: "changePage(\"#{state.file}\", #{i+1});"}, entry.title))
                    bc.inject(xbc)
                    if i != (pages.length-1)
                                bc.inject(new HTML('div', {class: 'bcsplitter', style: {width: bpct}}))
            doc.inject([bc, bctext])
        
    entry = pages[page-1]
    form = new HTML('form')
    form.inject(new HTML('h2', {}, entry.title))
    hasMandatory = false
    
    for key, field of entry.fields
            if field.preload and not preloaded[field.preload]
                        fetch(field.preload, {url: field.preload}, (json, state) -> preloaded[state.url] = json)
            fdiv = new HTML('div', {style: { width: '100%', float: 'left', marginBottom: '16px'}})
            tdiv = new HTML('div', { style: { width: '50%', float: 'left'}}, field.desc+":")
            if field.mandatory == true
                        tdiv.style.fontWeight = 'bold'
                        hasMandatory = true
            box = new HTML('input', { type: 'text', placeholder: field.placeholder, id: "form_#{key}", value: formData[key]})
            if field.type == 'textarea'
                        box = new HTML('textarea', {placeholder: field.placeholder, id: "form_#{key}"}, formData[key])
            if field.type == 'checkbox'
                        box = new HTML('input', {type: 'checkbox', value: 'true', id: "form_#{key}", checked: (if formData[key] and formData[key] == 'true' then 'checked' else null)})
            if field.type == 'list'
                        list = []
                        options = field.options
                        if typeof options == "string" and urls[options]
                                    options = urls[options]
                        if isArray(options)
                            for el in options
                                        sel = if (formData[key] and formData[key] == el) or (not formData[key] and el == field.default) then 'true' else null
                                        x = new HTML('option', { value: el, selected: sel}, el)
                                        list.push(x)
                        else if isHash(options)
                            for el, val of options
                                        sel = if (formData[key] and el == formData[key]) or (not formData[key] and el == field.default) then 'true' else null
                                        x = new HTML('option', { value: el, selected: sel}, val)
                                        list.push(x)
                                                
                        box = new HTML('select', {id: "form_#{key}"}, list)
            if field.type == 'multilist'
                        list = []
                        options = field.options
                        if typeof options == "string" and urls[options]
                                    options = urls[options]
                        if isArray(options)
                            for el in options
                                        sel = if (formData[key] and el in formData[key]) or (not formData[key] and el == field.default) then 'true' else null
                                        x = new HTML('option', { value: el, selected: sel}, el)
                                        list.push(x)
                        else if isHash(options)
                            for el, val of options
                                        sel = if (formData[key] and el in formData[key]) or (not formData[key] and el == field.default) then 'true' else null
                                        x = new HTML('option', { value: el, selected: sel}, val)
                                        list.push(x)
                                                
                        box = new HTML('select', {multiple: "multiple", id: "form_#{key}"}, list)
                        
            idiv = new HTML('div', { style: { width: '50%', float: 'left'}}, box)
            if field.type == 'checkbox' and field.placeholder
                idiv.inject(new HTML('span', { style: { display: 'inline-block'}}, field.placeholder))
            fdiv.inject([tdiv, idiv])
            form.inject(fdiv)
            if not field.filter
                        field.filter = /.*/
            if field.verifier
                        try
                            verifiers[key] = eval(field.verifier)
                        catch e
                            
                        if verifiers[key]
                            if field.type == "checkbox"
                                box.addEventListener('change', verifyField)
                            else
                                box.addEventListener('blur', verifyField)
                            if formData[key]
                                        verifyField({target:  box})
            if field.filter
                        regex[key] = field.filter
                        box.addEventListener('keyup', colorField)
                        if formData[key]
                                    colorField({target:  box})
            
    if hasMandatory
            form.inject(new HTML('div', {style: {fontStyle: 'italic', fontSize: '12px'}}, "Fields in bold are mandatory"))
    
    if page > 1
            form.inject(new HTML('input', {style: {float: 'left'}, type: 'button', value: 'Previous page', onclick: 'changePage("'+state.file+'", '+(page-1)+');'}))
            
    if page < pages.length
            form.inject(new HTML('input', {style: {float: 'right'}, type: 'button', value: 'Next page', onclick: 'changePage("'+state.file+'", '+(page+1)+');'}))
    else
            form.inject(new HTML('input', {style: {float: 'right', background: '#125caa'}, type: 'button', value: 'Submit request', onclick: 'submitForm("'+state.file+'");'}))
    
    # Entry footer html?
    if entry.footer
        form.innerHTML += entry.footer
        
    doc.inject(form)

    
changePage = (form, page, norender) ->
            # Validate
            pages = forms[form].pages
            entry = pages[xpage-1]
            
            
            for key, field of entry.fields
                        el = get("form_#{key}")
                        if el.getAttribute("type") == 'checkbox'
                            if el.checked == true
                                el = { value: 'true'}
                            else
                                el = { value: ''}
                        if page >= xpage and field.mandatory == true and el.value == ""
                                    alert("Please fill in the mandatory field '#{field.desc}'!'")
                                    return true
                        if page >= xpage and field.filter and not el.value.match(field.filter)
                                    alert("The field '#{field.desc}' must match #{field.filter}!")
                                    return true
                        if page >= xpage and eval(field.verifier)
                                    rv = verifyField({target: get("form_#{key}")})
                                    if rv
                                                alert(rv)
                                                return true
                        formData[key] = el.value
                        if field.type == 'multilist'
                            d = []
                            for eo in el.options
                                if eo.selected
                                    d.push(eo.value)
                            formData[key] = d
                            
            if not norender
                        renderForm({file: form}, page)


saveFile = (json, state) ->
            if state and state.file
                        urls[state.file] = json
                        forms[state.form.file].pending--
                        if forms[state.form.file].pending == 0
                                    renderForm(state.form, 1)
                                    

preloadFiles = (json, state) ->
            if json and state
                        forms[state.file] = json
                        if isArray(json.preload) and json.preload.length > 0
                                    forms[state.file].pending = json.preload.length
                                    urls[state.file] = json.preload
                                    for url in json.preload
                                                fetch(url, {form: state, file: url}, saveFile)
                        else
                                    renderForm(state, 1)
                        

loadForm = (file, divid) ->
            obj = get(divid)
            xobj = obj
            if obj
                        obj.innerHTML = ""
                        obj.appendChild(makeWave())
            fetch(file, {file: file, div: divid}, preloadFiles)
            
makeWave = (text) ->
            parent = new HTML('div', {class: 'wave-parent'})
            div = new HTML('div', {class: 'wavetext'}, if text then text else "Loading, please wait...")
            parent.appendChild(div)
            for i in [1..16]
                        div = new HTML('div', {class: 'wave'})
                        parent.appendChild(div)
            return parent
         
formSubmitted = (response, state, rc) ->
    xobj.innerHTML = ""
    form = new HTML('form')
    xobj.inject(form)
    if rc in [200,201]
        form.innerHTML = response
    else
        form.innerHTML = response
        form.inject(new HTML('input', {style: {float: 'left'}, type: 'button', value: 'Back to form', onclick: 'renderForm({file:"'+state.file+'"}, 1);'}))
        

submitForm = (file) ->
            if not changePage(file, xpage+1, true)
                        xobj.innerHTML = ""
                        xobj.appendChild(makeWave("Submitting request, please wait..."))
                        form = forms[file]
                        if form.format and form.format.toLowerCase() == 'json'
                            postJSON(form.posturl, formData, {file: file}, formSubmitted)
                        else
                            post(form.posturl, formData, {file: file}, formSubmitted)
                                    

