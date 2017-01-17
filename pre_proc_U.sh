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


for year in $(seq 1976 1977)

do

	echo "Recorta PS para o tamanho de U do ano $year" # My PS_file has a different size from my UV_file, so I need to cut it 
    cdo selgrid,1 223835.PS.${year}.20thC.PS.nc tt.nc  # select grid
    cdo selindexbox,39,97,21,99 tt.nc tt1.nc           # select area by indices and cnhages from lon=(0-360) for lon=(-180+180)
    rm tt.nc

	echo "Juntando PS com U do ano $year" 			    
	ncks -A -v PS tt1.nc 224331.U.${year}.20thC.U.nc   # append variable PS in the UV_file
	echo "Juntando P0 e demais com U do ano $year"
	ncks -A -v P0,hyam,hybm,hyai,hybi /home/leilane/RESULTADOS/CMIP5/CCSM4/historical/atm/raw/va/1975_20thC_V_ORIGINAL.nc 224331.U.${year}.20thC.U.nc  # append variables in the UV_file

	# CDO interpolation command was made for ECHAM model convention (P = A + B*PS), but for CAM model the convention is (P = A*P0 + B*PS).
	# So, for to interpolate CCSM4 (CAM4) results I have to multiply A (i.e., hyai and hyam) by 100000 (P0) before using ml2hl.
	echo "Multiplicando hy por 100000 do ano $year" 		
	ncap2 -A -s "hyai=hyai*100000;hyam=hyam*100000;" 224331.U.${year}.20thC.U.nc U_${year}_historical.nc

	echo "Interpolando U do ano $year de Hibrido-Sigma para 10m"

	height="10" 

	cdo -delname,sp \
	    -ml2hlx,"$height" \							   # this command ml2hlx(x) is a EXTRAPOLATE option, otherwise the height(10m) will have fill_values in some grid points
	    -selname,sp,U \
	    -chname,PS,sp \
	    U_${year}_historical.nc \
	    U10m_${year}_historical.nc

	rm U_${year}_historical.nc tt1.nc 224331.U.${year}.20thC.U.nc

	echo "Mudando nome da variavel V do ano $year"     # this is a preparation to create a ROMS forcing file
	cdo chname,U,Vwind U10m_${year}_historical.nc CCSM4-U-${year}.nc
	rm U10m_${year}_historical.nc

done

echo "Juntanto os arquivos da variavel U"              # this is a preparation to create a ROMS forcing file
cdo copy CCSM4-U-* U.nc
rm CCSM4-U-*


#5) Mudar o time - DEIXAR PARA O FIM POR CAUSA DO PROBLEMA DAS DATAS!
echo "Mudando a data de referência da variavel V"      # this is a preparation to create a ROMS forcing file
cdo setreftime,0001-01-01,00:00:00,days U.nc Uwind.nc
rm U.nc

# After run this shell script, must run prepara_CFSR_atm_netcdf.m for finish the preparation to create a ROMS forcing files