let s:save_cpo = &cpo
set cpo&vim

let s:uri = "http://paste.pocoo.org/xmlrpc/"

let pocoo#pastes = webapi#xmlrpc#wrap([
\ {'uri': s:uri, 'name': 'pastes.getPaste', 'argnames': ['id'], 'alias': 'getPaste'},
\ {'uri': s:uri, 'name': 'pastes.getLanguages', 'argnames': [], 'alias': 'getLanguages'},
\ {'uri': s:uri, 'name': 'pastes.getDiff', 'argnames': ['old_id','new_id'], 'alias': 'getDiff'},
\ {'uri': s:uri, 'name': 'pastes.getLast', 'argnames': [], 'alias': 'getLast'},
\ {'uri': s:uri, 'name': 'pastes.getRecent', 'argnames': ['...'], 'alias': 'getRecent'},
\ {'uri': s:uri, 'name': 'pastes.newPaste', 'argnames': ['language','code','...'], 'alias': 'newPost'},
\])

let pocoo#styles = webapi#xmlrpc#wrap([
\ {'uri': s:uri, 'name': 'styles.getStyles', 'argnames': [], 'alias': 'getStyles'},
\ {'uri': s:uri, 'name': 'styles.getStylesheet', 'argnames': ['name'], 'alias': 'getStylesheet'},
\])

"echo pacoo#pastes.getPaste(23)
"echo pacoo#pastes.getLanguages()
"echo pacoo#pastes.getDiff(23,24)
"echo pacoo#pastes.getLast()
"echo pacoo#pastes.getRecent(2)
"echo pacoo#styles.getStyles()
"echo pacoo#styles.getStylesheet("pastie")
"echo pacoo#pastes.newPaste("c", "int main(){printf(\"foo\\n\")}")

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
