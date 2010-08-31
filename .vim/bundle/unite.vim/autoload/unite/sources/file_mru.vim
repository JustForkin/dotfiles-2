"=============================================================================
" FILE: file_mru.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 Aug 2010
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

" Variables  "{{{
" The version of MRU file format.
let s:VERSION = '0.2.0'

" [ { 'path' : full_path, 'time' : localtime()}, ... ]
let s:mru_files = []

let s:mru_file_mtime = 0  " the last modified time of the mru file.

call unite#set_default('g:unite_source_file_mru_time_format', '(%x %H:%M:%S)')
call unite#set_default('g:unite_source_file_mru_file',  g:unite_temporary_directory . '/.file_mru')
call unite#set_default('g:unite_source_file_mru_limit', 100)
call unite#set_default('g:unite_source_file_mru_ignore_pattern', '')
"}}}

let s:source = {
      \ 'name' : 'file_mru',
      \ 'key_table': {
      \      'default' : 'open',
      \    },
      \ 'action_table': {},
      \}

function! s:source.gather_candidates(args)"{{{
  call s:load()
  return sort(map(copy(s:mru_files), '{
        \ "abbr" : strftime(g:unite_source_file_mru_time_format, v:val[1]) .
        \          fnamemodify(v:val[0], ":~:.") . (isdirectory(v:val[0]) ? "/" : ""),
        \ "word" : v:val[0],
        \ "source" : "file_mru",
        \ "unite_file_mru_time" : v:val[1],
        \ "is_directory" : isdirectory(v:val[0]),
        \   }'), 's:compare')
endfunction"}}}

function! s:source.action_table.open(candidate)"{{{
  return s:open('', a:candidate)
endfunction"}}}
function! s:source.action_table.open_x(candidate)"{{{
  return s:open('!', a:candidate)
endfunction"}}}

function! unite#sources#file_mru#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#file_mru#_append()"{{{
  " Append the current buffer to the mru list.
  let l:path = expand('%:p')
  if !s:is_exists_path(path) || &l:buftype != ''
  \   || (g:unite_source_file_mru_ignore_pattern != ''
  \      && substitute(l:path, '\\', '/', 'g') =~# g:unite_source_file_mru_ignore_pattern)
    return
  endif

  call s:load()
  call insert(filter(s:mru_files, 'v:val[0] !=# path'),
  \           [path, localtime()])
  if 0 < g:unite_source_file_mru_limit
    unlet s:mru_files[g:unite_source_file_mru_limit]
  endif
  call s:save()
endfunction"}}}
function! unite#sources#file_mru#_sweep()  "{{{
  call filter(s:mru_files, 's:is_exists_path(v:val[0])')
  call s:save()
endfunction"}}}

" Misc
function! s:open(bang, candidate)"{{{
  let v:errmsg = ''

  call unite#leave_buffer()
  edit `=a:candidate.word`

  return v:errmsg == '' ? 0 : v:errmsg
endfunction"}}}
function! s:compare(candidate_a, candidate_b)"{{{
  return a:candidate_b['unite_file_mru_time'] - a:candidate_a['unite_file_mru_time']
endfunction"}}}
function! s:save()  "{{{
  call writefile([s:VERSION] + map(copy(s:mru_files), 'join(v:val, "\t")'),
  \              g:unite_source_file_mru_file)
  let s:mru_file_mtime = getftime(g:unite_source_file_mru_file)
endfunction"}}}
function! s:load()  "{{{
  if filereadable(g:unite_source_file_mru_file)
  \  && s:mru_file_mtime != getftime(g:unite_source_file_mru_file)
    let [ver; s:mru_files] = readfile(g:unite_source_file_mru_file)
    if ver !=# s:VERSION
      echohl WarningMsg
      echomsg 'Sorry, the version of MRU file is old.  Clears the MRU list.'
      echohl None
      let s:mru_files = []
      return
    endif
    let s:mru_files =
    \   filter(map(s:mru_files[0 : g:unite_source_file_mru_limit - 1],
    \              'split(v:val, "\t")'), 's:is_exists_path(v:val[0])')
    let s:mru_file_mtime = getftime(g:unite_source_file_mru_file)
  endif
endfunction"}}}
function! s:is_exists_path(path)  "{{{
  return isdirectory(a:path) || filereadable(a:path)
endfunction"}}}


" vim: foldmethod=marker
