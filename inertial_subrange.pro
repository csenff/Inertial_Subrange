PRO inertial_subrange, sf_nam, sp_nam, del_time, max_lag, data_descriptor, rel_tol=rel_tol, drv_rel_tol=drv_rel_tol
;====================================================
;   Procedure INERTIAL_SUBRANGE
;   Determines min and max structure function lag numbers that bracket the inertial subrange plus mean/median compensated structure function/TKE dissipation values over the inertial subrange
;   Author: Christoph Senff
;   Last modified: 05/13/2026 by CS
;====================================================
; Check arguments
;====================================================
    if n_elements(sf_nam) eq 0 then begin
       print, 'Provide structure function file name'
       retall
    endif
    if n_elements(sp_nam) eq 0 then begin
      print, 'Provide wind speed file name'
      retall
    endif
    if n_elements(del_time) eq 0 then begin
      print, 'Provide time resolution of data in seconds'
      retall
    endif
    if n_elements(max_lag) eq 0 then begin
      print, 'Provide maximum time lag'
      retall
    endif
    max_lag = long(max_lag)
    if n_elements(data_descriptor) eq 0 then begin
      print, 'Provide data descriptor'
      retall
    endif
    if n_elements(rel_tol) eq 0 then rel_tol = 0.25  ; default: REL_TOL = 25%
    if n_elements(drv_rel_tol) eq 0 then drv_rel_tol = 0.05  ; default: DRV_REL_TOL = 5%
;====================================================
; Set parameters
;====================================================
    bs = 0.003        ; CSF histogram bin size
    tau_offset = 1
    nl = max_lag - tau_offset + 1
    min_length = 20
    head = ['Alt,mAGL', 'min,s', 'max,s', 'gw,m2s-8/3', 'eps,m2s-3']
    head_format = '(a8,4a19)'
    data_format = '(f8.1,4f19.5)'
    tol_ext = '_TOL' + strcompress(string(rel_tol*100.,form='(i2)'),/rem) + '%_' +'DTOL' + strcompress(string(drv_rel_tol*100.,form='(i1)'),/rem) + '%'
    ;=== specific to our file naming convention and directory structure - other users will have to modify ======
    dir = (reverse(split_string(sf_nam,'/')))[1]
    date = strmid(dir,18,8)
    time = strmid(dir,37,14)
;====================================================
; Read structure function and wind data
;====================================================
    read_bscan3, sf_nam, hd, dt
    nlag = (size(dt))(2)
    nsamp = (size(dt))(1)
    alt = hd(20,0) + findgen(nsamp)*hd(21,0)
    read_bscan3, sp_nam, hd_sp, dt_sp
    mi = fltarr(nsamp)
    ma = mi
    gw_mn = mi
    gw_md = mi
    eps_mn = mi
    eps_md = mi
;==========================================================================
; Compute inertial subrange
;==========================================================================
    for i=nsamp-1,0,-1 do begin
      tau = (findgen(nl) + tau_offset) * del_time
      sf = reform(dt(i,nlag/2+tau_offset:nlag/2+tau_offset+nl-1))  ; structure function w/offset
      csf = sf/tau^0.6667                                          ; compensated structure function w/offset   
;==== Interpolate CSF on log grid =========================================
      tau_log = 10^(alog10(tau[0])+findgen(100)*.05)
      tau_log = tau_log(where(tau_log lt tau[nl-1]))
      nlg = n_elements(tau_log)
      del_time_log = (shift(tau_log,-1)-tau_log)[0:nlg-2]
      del_time_log = [del_time_log,del_time_log[nlg-2]]
      csf_log=interpol(csf,alog10(tau),alog10(tau_log)) 
      csf_derivative = differ_v2(csf_log,findgen(nlg),'linfit',5,/edge)
      tau = tau_log
      csf = csf_log
      delt = del_time_log
;=== Determine CSF reference value objectively =============================
      csf_indx = where(tau lt 500.)
      hist = histogram(csf[csf_indx],binsize=bs,min=0,max=ceil(max(csf[csf_indx])/bs)*bs,loc=loc)
      csf_hist_max = mean(loc(where(hist eq max(hist)))) + bs/2.   ; add half bin size to get middle of bin
      ii = where(csf ge 0.95*csf_hist_max and csf le 1.05*csf_hist_max)
      csf_fixed_ref = median(csf[ii])
      indx = intarr(nlg)
;=========================================================
      sum = 0
      for k=0,nlg-2 do begin
        diff = total(abs(csf[0:k] - csf_fixed_ref)*delt[0:k])               ; integrated absolute difference with respect to CSF_FIXED_REF
        csf_fixed_ref_area = total(replicate(csf_fixed_ref,k+1)*delt[0:k])  ; area under CSF_FIXED_REF
        rel_diff = diff / csf_fixed_ref_area
        eval_int = rel_diff le rel_tol
        rel_drv = abs(csf_derivative[k] / csf_log[k])
        eval_drv = rel_drv le drv_rel_tol
        eval = eval_int and eval_drv
        if eval then begin
            indx(k) = sum + 1
            sum = sum + 1
        endif else begin
            if sum ge min_length then begin
              goto, end_loop2
            endif
            sum = 0
        endelse
      endfor
      end_loop2:
      if max(indx) gt 0. then begin
        xi = (where(indx eq max(indx)))(0)
        isr_indx = [xi - max(indx) + 1, xi]
;=== min/max eddy size in sec within inertial subrange =====
        mi[i] = tau[isr_indx[0]]  
        ma[i] = tau[isr_indx[1]]  
        xx = isr_indx[0]+indgen(max(indx))
;=== mean/median of compensated structure function within inertial subrange =====
        gw = [mean(csf[xx]),median(csf[xx])]
        gw_mn[i] = gw[0]
        gw_md[i] = gw[1]
;=== mean/median of TKE dissipation within inertial subrange =====
        eps = (gw/2.)^1.5/dt_sp[i]
        eps_mn[i] = eps[0]
        eps_md[i] = eps[1]
;=== Results are written to TXT file in current working directory =====
        if i eq 0 then begin
          openw, 10, 'PROF_' + data_descriptor + '_' + date + time + tol_ext + '.txt'
          printf, 10, head, form=head_format
          for k=0,nsamp-1 do printf, 10, [alt[k],mi[k],ma[k],gw_md[k],eps_md[k]],form=data_format
          close, 10
        endif
      endif
    endfor
;==========================================================================
    END