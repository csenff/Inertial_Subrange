FUNCTION split_string, str, separator
;
;PURPOSE
;	Splits string into substrings that are separated by blanks
;INPUTS
;	str_in = string
;	separator = separtion string
;OUTPUT
;	str_out = sub-strings
;COMMENT
;
;MODIFICATION HISTORY
;	Authors: Christoph Senff
;	Last modified: 06/19/99
;=============================================================
str_in = str
pos = strpos(str_in,separator)
while pos ne -1 do begin
	if n_elements(str_out) eq 0 then str_out = strmid(str_in,0,pos) $
	else str_out = [str_out,strmid(str_in,0,pos)]
	str_in = strmid(str_in,pos+1,strlen(str_in))
	pos = strpos(str_in,separator)
endwhile
if n_elements(str_out) eq 0 then str_out = strmid(str_in,0,strlen(str_in)) $
else str_out = [str_out,strmid(str_in,0,strlen(str_in))]
;==============================================================
return, str_out
end