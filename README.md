# Inertial_Subrange
This README file briefly describes the use of INERTIAL_SUBRANGE, an IDL (Interactive Data Language) routine.

From structure function and wind speed data, INERTIAL_SUBRANGE calculates the minimum and maximum time scales (eddy sizes) of the inertial subrange (ISR) as well as the mean and median compensated structure function/TKE dissipation values over the ISR. 

INPUTS:
sf_nam: File name of the structure function data. Can be 2-dimensional, i.e. time series for multiple altitudes. Time resolution: del_time.
sp_nam: File name of horizontal wind speed data. Can be 2-dimensional, i.e. time series for multiple altitudes. Average wind speed over the entire analysis time period, i.e. one value per altitude.
*** Structure function and wind speed data are assumed to be in BSCAN format, a binary format consisting of a 30-word header followed by n_gate (number of range gates) data values per record.
del_time: Time resolution of the structure function data in seconds.
max_lag: Maximum lag in seconds up to which calculations will be performed.
data_descriptor: String describing the data type.
*** The last two input parameters are relative threshold values that are used to find the "flat" portion of the compensated structure function (CSF), which, according to atmospheric turbulence theory, should be constant within the ISR.
rel_tol: Integrated absolute difference of the CSF with respect to a reference value, which is automatically computed. Default is 0.25 (25%). 
drv_rel_tol: Relative slope of the CSF. Default is 0.05 (5%).

OUTPUT:
TXT file listing minimum ISR eddy size, maximum ISR eddy size, ISR median compensated structure function values, and ISR median TKE dissipation value as a function of altitude AGL.
