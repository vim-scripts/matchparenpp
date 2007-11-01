" Improved Vim plugin for showing matching parens
" Features:      Not limited to on-screen paren pairs; prints
"                line containing matching paren in status line
" Maintainer:    Erik Falor <efalor@spillman.com>
" Last Change:   2007 Nov 11
" Version:       0.1
"
" Changes {{{
" 0.1 2007-11-01
"   Initial Version.  Improves over standard matchparen.vim plugin by echoing
"   line containing matching bracket in the status line so you can quickly
"   see which block is terminated by this paren.  Also scans for braces/parens
"   which are off-screen.
"   If you write functions or blocks like this:
"   if (condition)
"   {
"       ...
"   }
"   the plugin will echo the line "if (condition)" and not the lone "{".
"   By default, the plugin scans the line containing the opening brace and the
"   two lines above that, looking for the statement that begins the block, be
"   it a loop or function definition.  If you want more or less, set it in the
"   variable g:stmt_thresh.
"}}}

" Exit quickly when: {{{
" - this plugin (or the original matchparen.vim) was already 
"   loaded (or disabled)
" - the "CursorMoved" autocmd event is not availble.
if exists("g:loaded_matchparen") || !exists("##CursorMoved")
    finish
endif
"}}}

" Variables {{{
"avoid loading the standard plugin
let g:loaded_matchparen = 1
let g:paren_hl_on = 0
"}}}

" Functions {{{
function! s:skip_string_or_comment(line, col) "{{{
    let attr = synIDattr(synIDtrans(synID(a:line, a:col, 0)), 'name')
    if attr ==? 'constant' || attr ==? 'comment'
        return 1
	endif
	return 0
endfunction "}}}

function! s:Highlight_Matching_Paren() "{{{
    if g:paren_hl_on
        3match none
        echo
        let g:paren_hl_on = 0
    endif
	let c_lnum = line('.')
	let c_col = col('.')
    if s:skip_string_or_comment(c_lnum, c_col) != 0
        return
    endif
    let c = getline(c_lnum)[c_col - 1]
    let plist = split(&matchpairs, ':\|,')
    let i = index(plist, c)
    if i < 0
        return
    endif
    if i % 2 == 0
        let s_flags = 'nW'
        let c2 = plist[i + 1]
    else
        let s_flags = 'nbW'
        let c2 = c
        let c = plist[i - 1]
    endif
    if c == '['
        let c = '\['
        let c2 = '\]'
    endif

    let [m_lnum, m_col] = searchpairpos(c, '', c2, s_flags, 's:skip_string_or_comment(' . c_lnum .','. c_col .')')
    if m_lnum > 0 && m_lnum >= line('w0') && m_lnum <= line('w$')
        exe '3match Todo /\(\%' . c_lnum . 'l\%' . c_col .
                    \ 'c\)\|\(\%' . m_lnum . 'l\%' . m_col . 'c\)/'
        let g:paren_hl_on = 1
    endif
	"number of lines to scan backward looking for a statement
	"beginning a block
	if exists('g:stmt_thresh')
		let s:stmt_thresh = g:stmt_thresh
	else
		let s:stmt_thresh = 3
	endif
	"print the line containing the matching paren in the statusline
    if m_lnum < c_lnum && 'i' != mode()
		let m_stmt = m_lnum
		let i = 0
		while getline(m_stmt) =~ '^\s*' . c . '\s*$\|^\s*$' 
					\&& i <= s:stmt_thresh
			let m_stmt = m_lnum - i
			let i += 1
		endwhile
		if i > s:stmt_thresh
			redraw | echomsg m_lnum . ": " . getline(m_lnum)
		else
			redraw | echomsg m_stmt . ": " . getline(m_stmt)
		endif
	elseif m_lnum > c_lnum && 'i' != mode()
		redraw | echomsg m_lnum . ": " . getline(m_lnum)
    endif
endfunction "}}}

"}}}

" Auto-Commands {{{
autocmd! CursorMoved,CursorMovedI * call s:Highlight_Matching_Paren()
autocmd! InsertEnter * 3match none
"}}}

" vim: set foldmethod=marker textwidth=78:
