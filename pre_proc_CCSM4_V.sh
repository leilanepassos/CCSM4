#!/bin/bash

###############################################################################################################
#
# CCSM4(CAM4) Wind output are in hybrid-sigma levels. This scrpit interpolates from hybrid-sigma levels for 
# 10 m height using CDO and NCO.
# Farther, join multi years files in one file with all years (1975-2005).
#
# author/date: Leilane/jan2017
# email: leilanepassos@gmail.com
###############################################################################################################


for year in $(seq 1975 1976)

do

	echo "Recorta PS para o tamanho de V do ano $year" # My PS_file has a different size from my UV_file, so I need to cut it 
    cdo selgrid,1 223835.PS.${year}.20thC.PS.nc tt.nc  # select grid
    cdo selindexbox,39,97,21,99 tt.nc tt1.nc           # select area by indices and cnhages from lon=(0-360) for lon=(-180+180)
    rm tt.nc

	echo "Juntando PS com V do ano $year"
	ncks -A -v PS tt1.nc 224331.V.${year}.20thC.V.nc   # append variable PS in the UV_file 
	echo "Juntando P0 e demais com V do ano $year"
	ncks -A -v P0,hyam,hybm,hyai,hybi /home/leilane/RESULTADOS/CMIP5/CCSM4/historical/atm/raw/va/1975_20thC_V_ORIGINAL.nc 224331.V.${year}.20thC.V.nc  # append variables in the UV_file

	# CDO interpolation command was made for ECHAM model convention (P = A + B*PS), but for CAM model the convention is (P = A*P0 + B*PS).
	# So, for to interpolate CCSM4 (CAM4) results I have to multiply A (i.e., hyai and hyam) by 100000 (P0) before using ml2hl.	
	echo "Multiplicando hy por 100000 do ano $year"
	ncap2 -A -s "hyai=hyai*100000;hyam=hyam*100000;" 224331.V.${year}.20thC.V.nc V_${year}_historical.nc

	echo "Interpolando V do ano $year de Hibrido-Sigma para 10m"

	height="10" 

	cdo -delname,sp \
	    -ml2hlx,"$height" \							   # this command ml2hlx(x) is a EXTRAPOLATE option, otherwise the height(10m) will have fill_values in some grid points
	    -selname,sp,V \
	    -chname,PS,sp \
	    V_${year}_historical.nc \
	    V10m_${year}_historical.nc

	rm V_${year}_historical.nc tt1.nc 224331.V.${year}.20thC.V.nc

	echo "Mudando nome da variavel V do ano $year"     # this is a preparation to create a ROMS forcing file
	cdo chname,V,Vwind V10m_${year}_historical.nc CCSM4-V-${year}.nc
	rm V10m_${year}_historical.nc

done

echo "Juntanto os arquivos da variavel V"              # this is a preparation to create a ROMS forcing file
cdo copy CCSM4-V-* V.nc
# rm CCSM4-V-*


echo "Mudando a data de referência da variavel V"      # this is a preparation to create a ROMS forcing file
cdo setreftime,0001-01-01,00:00:00,days V.nc Vwind.nc
rm V.nc

# After run this shell script, must run prepara_CFSR_atm_netcdf.m for finish the preparation to create a ROMS forcing files