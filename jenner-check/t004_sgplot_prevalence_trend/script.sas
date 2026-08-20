/* jenner-check bundle: the PROC SGPLOT trend-line block from Analysis.sas
   (the "Figures" section that plots dystonia prevalence and DBS treatment
   rate across NIS years), copied unmodified apart from redirecting the
   graphics output path and swapping the hardcoded &Sour./&sub. path
   variables for a relative one. Mock data below is shaped exactly like
   the "plot" dataset Analysis.sas builds from its "dystoniatrend" table
   (year, type, per) right before this block. */

data work.dystrend;
	length type $40;
	input year per;
	type='Dystonia DX among all discharges';
	datalines;
2012 0.0021
2013 0.0022
2014 0.0024
2015 0.0026
2016 0.0027
2017 0.0028
2018 0.0030
2019 0.0031
;
run;

data work.dbstrend;
	length type $40;
	input year per;
	type='DBS rate among dystonia discharges';
	datalines;
2012 0.0010
2013 0.0013
2014 0.0015
2015 0.0018
2016 0.0021
2017 0.0024
2018 0.0027
2019 0.0030
;
run;

data work.plot;
	set work.dystrend work.dbstrend;
	if year=. then delete;
run;

* Create a figure of prevalence of dystonia among all NIS discharges and
	prevalence of DBS among all dystonia patients across years;
ods graphics on / RESET IMAGEFMT=jpeg IMAGENAME='Prevalence of dystonia and DBS';
ods listing image_dpi=300 gpath="./";
title "Prevalence of Dystonia DX and DBS Treatment";
proc sgplot data=work.plot;
series x = year y = per / group=type MARKERS LINEATTRS = (THICKNESS = 2) markerattrs=(symbol=trianglefilled);
yaxis label="Prevalence(%)" values=(0 to 0.01 by 0.002);
xaxis type=discrete label='Year';
keylegend / title="";
run;
ods graphics off;
