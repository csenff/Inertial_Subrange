PRO read_bscan3, fname, header, data
;
;PURPOSE
;
;INPUTS
;	fname = BSCAN file name
;COMMENT
;
;MODIFICATION HISTORY
;	Authors: Christoph Senff
;	Last modified: 10/26/17
;====================================================
  t_start = systime(/sec)
;====================================================
; Read first header
;====================================================
	openr, lun, fname, /get_lun
	stats = fstat(lun)
	record = assoc(lun,fltarr(30))
	first_header = record(0)
	free_lun, lun
	byteswap=0b
	if ((first_header(11) ne -999.) and (first_header(11) lt 1)) then begin
		byteswap = 1b
		byteorder,first_header,/Lswap
	endif
	head_len = first_header(23)
	rec_len = first_header(28) + head_len
	num_recs = stats.size/(rec_len*4)
;=================================================
; Read data and header
;=================================================
	openr, lun, fname, /get_lun
	z = fltarr(rec_len,num_recs,/nozero)
	readu, lun, z
	if byteswap then byteorder, z, /Lswap
	header = z(0:head_len-1,*)
  data = z(head_len:rec_len-1,*)
	free_lun, lun
;===========================================================
  ;print, 'Seconds elapsed = ', systime(/sec) - t_start
	end