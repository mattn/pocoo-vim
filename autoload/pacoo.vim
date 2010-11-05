let s:save_cpo = &cpo
set cpo&vim

let s:url = "http://paste.pocoo.org/xmlrpc/"

let pacoo#pastes = {}
let pacoo#styles = {}

function! s:from_value(value)
  let value = a:value
  if value.name == 'methodResponse'
    let param = value.childNode('params').childNodes('param')
    if len(param) == 1
      return s:from_value(param[0].childNode('value').childNode())
    else
      let ret = []
      for v in param
        call add(ret, s:from_value(v.childNode('value').childNode()))
      endfor
      return ret
    endif
  elseif value.name == 'string'
    return value.value()
  elseif value.name == 'int'
    return 0+substitute(value.value(), "[ \n\r]", '', 'g')
  elseif value.name == 'double'
    return str2float(substitute(value.value(), "[ \n\r]", '', 'g'))
  elseif value.name == 'struct'
    let ret = {}
    for member in value.childNodes('member')
      let ret[member.childNode('name').value()] = s:from_value(member.childNode('value').childNode())
    endfor
    return ret
  elseif value.name == 'array'
    let ret = []
    for v in value.childNode('data').childNodes('value')
      call add(ret, s:from_value(v.childNode()))
    endfor
    return ret
  elseif value.name == 'nil'
    return 0
  else
    throw "unknown type: ".value.name
  endif
endfunction

function! s:to_value(content)
  if type(a:content) == 4
    let struct = xml#createElement("struct")
    for key in keys(a:content)
      let member = xml#createElement("member")
      let name = xml#createElement("name")
      call name.value(key)
      call add(member.child, name)
      let value = xml#createElement("value")
      call add(value.child, s:to_value(a:content[key]))
      call add(member.child, value)
      call add(struct.child, member)
    endfor
    return struct
  elseif type(a:content) == 3
    let array = xml#createElement("array")
    let data = xml#createElement("data")
    for item in a:content
      let value = xml#createElement("value")
      call add(value.child, s:to_value(item))
      call add(data.child, value)
    endfor
    call add(array.child, data)
    return array
  elseif type(a:content) <= 1 || type(a:content) == 5
    if type(a:content) == 0
      let int = xml#createElement("int")
      call int.value(a:content)
      return int
    elseif type(a:content) == 1
      let str = xml#createElement("string")
      call str.value(a:content)
      return str
    elseif type(a:content) == 5
      let double = xml#createElement("double")
      call double.value(a:content)
      return double
    endif
  endif
  return {}
endfunction

function! s:to_fault(dom)
  let struct = a:dom.find('struct')
  let faultCode = ""
  let faultString = ""
  for member in struct.childNodes('member')
    if member.childNode('name').value() == "faultCode"
      let faultCode = member.childNode('value').value()
    elseif member.childNode('name').value() == "faultString"
      let faultString = member.childNode('value').value()
    endif
  endfor
  return faultCode.":".faultString
endfunction

function! pacoo#pastes.getPaste(id) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("pastes.getPaste")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("id", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#pastes.getPaste(23)

function! pacoo#pastes.getLanguages() dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("pastes.getLanguages")
  call add(methodCall.child, methodName)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#pastes.getLanguages()

function! pacoo#pastes.getDiff(old_id, new_id) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("pastes.getDiff")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("old_id,new_id", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#pastes.getDiff(23,24)

function! pacoo#pastes.getLast() dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("pastes.getLast")
  call add(methodCall.child, methodName)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#pastes.getLast()

function! pacoo#pastes.getRecent(...) dict
  let amount = a:0 > 0 ? a:1 : 5
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("pastes.getRecent")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  let param = xml#createElement("param")
  let value = xml#createElement("value")
  call value.value(s:to_value(amount))
  call add(param.child, value)
  call add(params.child, param)
  call add(methodCall.child, params)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#pastes.getRecent(2)

function! pacoo#styles.getStyles() dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("styles.getStyles")
  call add(methodCall.child, methodName)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#styles.getStyles()

function! pacoo#styles.getStylesheet(name) dict
  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("styles.getStylesheet")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("name", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval('a:'.arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#styles.getStylesheet("pastie")

function! pacoo#pastes.newPaste(language, code, ...) dict
  let language = a:language
  let code = a:code
  let parent_id = a:0 > 0 ? a:1 : 0
  let filename = a:0 > 1 ? a:2 : ''
  let private = a:0 > 2 ? a:3 : "false"

  let methodCall = xml#createElement("methodCall")
  let methodName = xml#createElement("methodName")
  call methodName.value("pastes.newPaste")
  call add(methodCall.child, methodName)
  let params = xml#createElement("params")
  for arg in split("language,code,parent_id,filename,private", ",")
    let param = xml#createElement("param")
    let value = xml#createElement("value")
    call value.value(s:to_value(eval(arg)))
    call add(param.child, value)
    call add(params.child, param)
  endfor
  call add(methodCall.child, params)
  let xml = iconv(methodCall.toString(), &encoding, "utf-8")
  let res = http#post(s:url, xml, {"Content-Type": "text/xml"})
  let dom = xml#parse(res.content)
  if len(dom.find('fault'))
    throw s:to_fault(dom)
  else
    return s:from_value(dom)
  endif
endfunction
"echo pacoo#pastes.newPaste("c", "int main(){printf(\"foo\\n\")}")

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
