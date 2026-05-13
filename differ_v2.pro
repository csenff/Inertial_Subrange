FUNCTION differ_v2, y, x, method, npoint, edge=edge
;
;PURPOSE
;   Numerically differentiates y with respect to x using different methods,
;   ratio of differences between data points spaced npoint apart (QUOTIENT),
;   derivative of linear fit over npoint data points (LINFIT), or derivative
;   of quadratic fit over npoint data points (QUADFIT). Window of length npoint
;   is moved in a gliding fashion over the data. The value of the derivative is
;   assigned to the middle of the window. If edge is set to 0 (default) no
;   derivatives are calculated within npoint/2 of the ends of y. If edge is set
;   to 1 derivatives are determine within npoint/2 of the ends of y using a
;   progressively smaller window, i.e. npoint-1, npoint-2 etc. For the very first
;   and last data point only 2 data points are used for the derivative calculation
;   (first and second point, last and last-but-one point).
;   Version 2 calculates derivatives when data contain GARBAGE values. If the npoint window
;   over which derivative is calculated contains at least 2 non-GARBAGE data values derivative
;   is calculated using the valid data points and assigning the result to the middle gate. Otherwise
;   derivative result will be set to GARBAGE.
;INPUTS
;   y = data vector to be differentiated
;   x = variable with respect to which y is to be differentiated
;OPTIONAL INPUTS
;   method = differentiation method, 'Quotient', 'Linfit', 'Quadfit'
;            (default = 'Quotient')
;   npoint = number of points to be used for differentiation, if even then
;       npoint is set to next larger odd number (default = 3)
;   edge = flag determining whether or not to calculate derivatives at the ends
;          of the data (0 = no (default), 1 = yes)
;OUTPUTS
;   Derivative of y with respect to x
;MODIFICATION HISTORY
;   Authors: Christoph Senff
;   Last modified: 03/15/04
;===============================================================
; Check arguments
;===============================================================
    if n_elements(y) eq 0 then begin
       print, 'Provide data'
       progexit
    endif
    if n_elements(x) eq 0 then begin
       print, 'Provide variable'
       progexit
    endif
    if n_elements(x) ne n_elements(y) then begin
       print, 'Data and variable have different ' + $
               'number of elements'
       progexit
    endif
    if n_elements(method) eq 0 then method = 'QUOTIENT'
    method = strupcase(method)
    if method ne 'QUOTIENT' and $
       method ne 'LINFIT' and $
       method ne 'QUADFIT' then begin
         print, 'Differentiation method not valid'
           print, 'Enter either QUOTIENT or LINFIT or QUADFIT'
           print, '(spelling is NOT case sensitive)'
         progexit
    endif
    if n_elements(npoint) eq 0 then npoint = 3
    if npoint/2*2 eq npoint then npoint = npoint + 1  ; always use odd number of points
    if npoint lt 3 then begin
       print, 'Number of points needs to be at least 3 ' + $
              'to perform derivative calculation'
       progexit
    endif
    n = n_elements(x)
    if n lt npoint then begin
       print, 'Less than npoint elements - cannot calculate derivatives'
       progexit
    endif
    if n_elements(edge) eq 0 then edge = 0
;==============================================================
; Prepare for derivative calculation
;==============================================================
    GARBAGE = -999.d
    dy_dx = replicate(GARBAGE,n)
    down = replicate(npoint/2,n)
    down(0:npoint/2-1) = indgen(npoint/2)
    down(n-npoint/2:n-1) = reverse(indgen(npoint/2))
    up = down
    down(n-1) = 1
    up(0) = 1
    if edge then begin
       min = 0
       max = n-1
       if method eq 'QUADFIT' then begin
         min = 1
         max = n-2
       endif
    endif else begin
       min = npoint/2
       max = n - npoint/2 - 1
    endelse
;==============================================================
; k-point quotient of differences, k >= 3, k odd
;==============================================================
    if method eq 'QUOTIENT' then begin
       for i=min, max do begin
            if y(i+up(i)) eq GARBAGE or y(i-down(i)) eq GARBAGE then $
             dy_dx(i) = GARBAGE $
            else $
                dy_dx(i) = (y(i+up(i))-y(i-down(i)))/(x(i+up(i))-x(i-down(i)))
       endfor
    endif
;==============================================================
; k-point linear fit, k >= 3, k odd
;==============================================================
    if method eq 'LINFIT' then begin
       for i=min, max do begin
            xx = x((i-down(i)):(i+up(i)))
            yy = y((i-down(i)):(i+up(i)))
            index = where(yy ne GARBAGE)
            if n_elements(index) le 1 then $
               dy_dx(i) = GARBAGE $
            else $
              dy_dx(i) = (poly_fit(xx(index),yy(index),1))(1)
       endfor
    endif
;==============================================================
; k-point quadratic fit, k >= 3, k odd
;==============================================================
    if method eq 'QUADFIT' then begin
       for i=min, max do begin
            xx = x((i-down(i)):(i+up(i)))
            yy = y((i-down(i)):(i+up(i)))
            index = where(yy ne GARBAGE)
            if n_elements(index) le 2 then begin
               dy_dx(i) = GARBAGE
            endif else begin
              fit = poly_fit(xx(index),yy(index),2)
              dy_dx(i) = 2*fit(2)*x(i) + fit(1)
            endelse
       endfor
    endif
;=============================================================
    return, dy_dx
    END
