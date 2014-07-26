" ---------------------------------------------------------------------------------
" Spotify Client for Vim
" ---------------------------------------------------------------------------------

if exists('g:vim_spotify_loaded') || &cp
  finish
endif

let g:vim_spotify_loaded       = 1
let g:vim_spotify_current_song = ''
" Commands
" ---------------------------------------------------------------------------------
command!          Spotify       call s:VimSpotifyCreateBuffer()
command! -nargs=1 SpotifySearch call s:VimSpotifySearch(<f-args>)
command!          SpotifyPlay   call s:VimSpotifyPlayTrack()

" Show buffer
" ---------------------------------------------------------------------------------
function! s:VimSpotifyCreateBuffer()
  let existing_spotify_buffer = bufnr('Spotify')
  
  setlocal filetype=vim-spotify
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal nonumber
  setlocal nowrap

  map <buffer> S <esc>:SpotifySearch 
  map <buffer> s <esc>:SpotifySearch 
  map <buffer> P <esc>:SpotifyPlay<cr>
  map <buffer> p <esc>:SpotifyPlay<cr>
endfunction

" Search Spotify
" ---------------------------------------------------------------------------------
function! s:VimSpotifySearch(search_string)
  let search_string = a:search_string
  call s:VimSpotifyGetURI(search_string)
endfunction

" Play Song
" ---------------------------------------------------------------------------------
function! s:VimSpotifyPlayTrack()
    setlocal cursorline
  ruby VimSpotify::play_track(VIM::evaluate("getline('.')"))
endfunction

" Vim -> Ruby interface
" ---------------------------------------------------------------------------------
function! s:VimSpotifyGetURI(search_string)
  setlocal modifiable

  ruby VimSpotify::get_search_uri(VIM::evaluate('a:search_string'))
  setlocal nomodifiable
endfunction

" Ruby extension
" ---------------------------------------------------------------------------------
ruby << EOF

require 'json'
require 'uri'
require 'httparty'

module VimSpotify
  class << self
    def get_search_uri(string)
      json = JSON.parse HTTParty.get("http://ws.spotify.com/search/1/track.json", query: {"q" => string}).body
      
      json['tracks'].each.with_index do |track,i|
        length = Time.at(track['length']).gmtime.strftime('%M:%S')
        artist = track['artists'][0]['name'].byteslice(0..17).rjust(18).force_encoding('ASCII-8BIT')
        song   = track['name'].byteslice(0..35).ljust(36).force_encoding('ASCII-8BIT')
        album  = track['album']['name'].byteslice(0..39).ljust(40).force_encoding('ASCII-8BIT')
        href   = track['href']

        entry  = "| #{song} | #{artist} | #{href} |"

        $curbuf.append i, entry
      end

    end

    def play_track(line)
      x,*meta   = *line.split('|').map {|c| c.strip}
      song   = meta.first
      artist = meta[1]
      href   = meta.last

      `osascript -e 'tell application "Spotify" to play track "#{href}"'`

    end
  end
end

EOF
