/* ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| */
/*========================================================================
Author: Lexie Yang
Created: 7/23/2024
Description:

This program includes analysis code for data manipulation, figure/table creation,
and regression models for the DBS in dystonia project.

The source dataset "out.core" contains core data for all patients who met the
study inclusion criteria.

The source dataset "out.hospital" contains hospital data for all years 2012-2019.

/* ---------------------------- TOP MATTER ----------------------------------*/

********************************************************************************************************************;
%let rdate = %sysfunc(today(), yymmddn8.);%put &rdate;

/*PATHS*/

* Project folder path;
%let path=X:\XXXXXXXXXXX;

/* LIBRARIES and MACROS*/

* Library for analysis data;
libname out "&path.\Data\";

* Formats, macros, macro variable definitions;
%include "&path.\format.sas";
%include "&path.\codelist.sas";
%include "&path.\weightedtable.sas";

/*||||||||||||||||||||||||||||||||||||||||||||||||||||*/
/* GLOBAL OPTIONS */
options orientation=portrait pagesize=120 ls=160 symbolgen mprint mlogic center nodate threads = yes CPUCOUNT=actual spool; ods html;

********************************************************************************************************************;


/**********************************
***		Define variables		***
**********************************/

* Merge core and hospital data;
proc sql;
	create table cohort as
	select distinct A.admid, A.year, A.key_nis, A.hosp_nis, A.age, A.female, A.race, A.pay1, A.ZIPINC_QRTL,
				A.dbs, A.rns, A.dystonia, A.DISCWT, A.HOSP_NIS, A.NIS_STRATUM,
				B.HOSP_REGION, B.HOSP_LOCTEACH, B.HOSP_BEDSIZE, B.H_CONTRL
	from out.core as A left join out.hospital as B
	on A.HOSP_NIS=B.HOSP_NIS and A.year=B.year;
quit;


* Regroup race and insurance;
data cohort;
	set cohort;

	if race in (5 6 .A .C .) then race=999;
	
	if female=1 then sex=2;
	else if female=0 then sex=1;
	else sex=999;

	if pay1 in (5 6 .A .C .) then pay1=999;

	if ZIPINC_QRTL in (.A .C .) then ZIPINC_QRTL=999;

	format sex sexf. dystonia dbs rns yn. race racefnew. pay1 F1PAYnew. ZIPINC_QRTL FZIQnew. 
			HOSP_REGION ST_REGNnew. HOSP_LOCTEACH LOCTCHNnew. HOSP_BEDSIZE FBEDSZNnew. H_CONTRL F_CNTRLnew.;

	label sex='Sex' 
		RACE='Race'
		PAY1='Primary expected payer'
		ZIPINC_QRTL='Median household income for patient’s ZIP code national quartile'
		HOSP_LOCTEACH='Location/teaching status of hospital'
		HOSP_BEDSIZE='Bed size of hospital'
		H_CONTRL='Control/ownership of hospital'
		;
	drop female;
run;


/* Elixhauser comorbidities */

* Define Elixhauser comorbidities using diagnosis codes from the codelist;
data elx;
	set out.core(keep=admid dx1-dx30 I10_DX1-I10_DX40);

	array dx DX1-DX30;
	do over dx;
		if DX in: (&CM_arrhythmias9.) then CM_arrhythmias = 1; 
		if DX in: (&CM_VALVE9.) then CM_VALVE = 1; 
		if DX in: (&CM_PERIVASC9.) then CM_PERIVASC = 1; 
		if DX in: (&CM_HYPOTHY9.) then CM_HYPOTHY = 1; 
		if DX in: (&CM_RENLFAIL9.) then CM_RENLFAIL = 1; 
		if DX in: (&CM_LIVER9.) then CM_LIVER = 1; 
		if DX in: (&CM_OBESE9.) then CM_OBESE = 1; 
		if DX in: (&CM_LYTES9.) then CM_LYTES = 1;
		if DX in: (&CM_CHF9.) then CM_CHF = 1;
		if DX in: (&CM_PULMCIRC9. ) then CM_PULMCIRC = 1;
		if DX in: (&CM_HTN9. ) then CM_HTN = 1;
		if DX in: (&CM_HTNCX9. ) then CM_HTNCX = 1;
		if DX in: (&CM_HTNPREG9. ) then CM_HTNPREG = 1;
		if DX in: (&CM_HTNWOCHF9.) then CM_HTNWOCHF = 1;
		if DX in: (&CM_HTNWCHF9. ) then CM_HTNWCHF = 1;
		if DX in: (&CM_HRENWORF9. ) then CM_HRENWORF = 1;
		if DX in: (&CM_HRENWRF9. ) then CM_HRENWRF = 1;
		if DX in: (&CM_HHRWOHRF9. ) then CM_HHRWOHRF = 1;
		if DX in: (&CM_HHRWCHF9. ) then CM_HHRWCHF = 1;
		if DX in: (&CM_HHRWRF9. ) then CM_HHRWRF = 1;
		if DX in: (&CM_HHRWHRF9. ) then CM_HHRWHRF = 1;
		if DX in: (&CM_OHTNPREG9.) then CM_OHTNPREG = 1;
		if DX in: (&CM_PARA9. ) then CM_PARA = 1;
		if DX in: (&CM_NEURO9. ) then CM_NEURO = 1;
		if DX in: (&CM_CHRNLUNG9. ) then CM_CHRNLUNG = 1;
		if DX in: (&CM_DM9. ) then CM_DM = 1;
		if DX in: (&CM_DMCX9. ) then CM_DMCX = 1;
		if DX in: (&CM_ULCER9. ) then CM_ULCER = 1;
		if DX in: (&CM_AIDS9. ) then CM_AIDS = 1;
		if DX in: (&CM_LYMPH9. ) then CM_LYMPH = 1;
		if DX in: (&CM_METS9. ) then CM_METS = 1;
		if DX in: (&CM_TUMOR9. ) then CM_TUMOR = 1;
		if DX in: (&CM_ARTH9. ) then CM_ARTH = 1;
		if DX in: (&CM_COAG9. ) then CM_COAG = 1;
		if DX in: (&CM_WGHTLOSS9. ) then CM_WGHTLOSS = 1;
		if DX in: (&CM_BLDLOSS9.) then CM_BLDLOSS = 1;
		if DX in: (&CM_ANEMDEF9. ) then CM_ANEMDEF = 1;
		if DX in: (&CM_ALCOHOL9.) then CM_ALCOHOL = 1;
		if DX in: (&CM_DRUG9. ) then CM_DRUG = 1;
		if DX in: (&CM_PSYCH9. ) then CM_PSYCH = 1;
		if DX in: (&CM_DEPRESS9. ) then CM_DEPRESS = 1;
	end;

	array dx_I10 I10_DX1--I10_DX30;
	do over dx_I10;
		if dx_I10 in: (&CM_arrhythmias10.) then CM_arrhythmias = 1; 
		if dx_I10 in: (&CM_VALVE10.) then CM_VALVE = 1; 
		if dx_I10 in: (&CM_PERIVASC10.) then CM_PERIVASC = 1; 
		if dx_I10 in: (&CM_HYPOTHY10.) then CM_HYPOTHY = 1; 
		if dx_I10 in: (&CM_RENLFAIL10.) then CM_RENLFAIL = 1; 
		if dx_I10 in: (&CM_LIVER10.) then CM_LIVER = 1; 
		if dx_I10 in: (&CM_OBESE10.) then CM_OBESE = 1; 
		if dx_I10 in: (&CM_LYTES10.) then CM_LYTES = 1; 
		if dx_I10 in: (&CM_CHF10.) then CM_CHF = 1;
		if dx_I10 in: (&CM_PULMCIRC10.) then CM_PULMCIRC = 1;
		if dx_I10 in: (&CM_HTN10.) then CM_HTN = 1;
		if dx_I10 in: (&CM_HTNCX10.) then CM_HTNCX = 1;
		if dx_I10 in: (&CM_HTNPREG10.) then CM_HTNPREG = 1;
		if dx_I10 in: (&CM_HTNWOCHF10.) then CM_HTNWOCHF = 1;
		if dx_I10 in: (&CM_HTNWCHF10.) then CM_HTNWCHF = 1;
		if dx_I10 in: (&CM_HRENWORF10.) then CM_HRENWORF = 1;
		if dx_I10 in: (&CM_HRENWRF10.) then CM_HRENWRF = 1;
		if dx_I10 in: (&CM_HHRWOHRF10.) then CM_HHRWOHRF = 1;
		if dx_I10 in: (&CM_HHRWCHF10.) then CM_HHRWCHF = 1;
		if dx_I10 in: (&CM_HHRWRF10.) then CM_HHRWRF = 1;
		if dx_I10 in: (&CM_HHRWHRF10.) then CM_HHRWHRF = 1;
		if dx_I10 in: (&CM_OHTNPREG10.) then CM_OHTNPREG = 1;
		if dx_I10 in: (&CM_PARA10.) then CM_PARA = 1;
		if dx_I10 in: (&CM_NEURO10.) then CM_NEURO = 1;
		if dx_I10 in: (&CM_CHRNLUNG10.) then CM_CHRNLUNG = 1;
		if dx_I10 in: (&CM_DM10.) then CM_DM = 1;
		if dx_I10 in: (&CM_DMCX10.) then CM_DMCX = 1;
		if dx_I10 in: (&CM_ULCER10.) then CM_ULCER = 1;
		if dx_I10 in: (&CM_AIDS10.) then CM_AIDS = 1;
		if dx_I10 in: (&CM_LYMPH10.) then CM_LYMPH = 1;
		if dx_I10 in: (&CM_METS10.) then CM_METS = 1;
		if dx_I10 in: (&CM_TUMOR10.) then CM_TUMOR = 1;
		if dx_I10 in: (&CM_ARTH10.) then CM_ARTH = 1;
		if dx_I10 in: (&CM_COAG10.) then CM_COAG = 1;
		if dx_I10 in: (&CM_WGHTLOSS10.) then CM_WGHTLOSS = 1;
		if dx_I10 in: (&CM_BLDLOSS10.) then CM_BLDLOSS = 1;
		if dx_I10 in: (&CM_ANEMDEF10.) then CM_ANEMDEF = 1;
		if dx_I10 in: (&CM_ALCOHOL10.) then CM_ALCOHOL = 1;
		if dx_I10 in: (&CM_DRUG10.) then CM_DRUG = 1;
		if dx_I10 in: (&CM_PSYCH10.) then CM_PSYCH = 1;
		if dx_I10 in: (&CM_DEPRESS10.) then CM_DEPRESS = 1;	
	end;

	if CM_HTN=1 OR CM_HTNCX=1 then CM_HTN_C=1;
    	else CM_HTN_C=0;

	keep admid CM_arrhythmias--CM_DEPRESS CM_HTN_C;
run;


* Code comorbidities to 0 if no matches were found;
data elx;
	set elx;
	array vars CM_arrhythmias--CM_DEPRESS;
	do over vars;
		if vars=. then vars=0;
	end;
run;

* Merge to study cohort;
proc sql;
	create table cohort as
	select A.*, B.*
	from cohort as A, elx as B
	where A.admid=B.admid;
quit;

* Comorbidity index;
%macro get_cmscore(
aids_    =CM_AIDS, 
alcohol_ =CM_ALCOHOL,       
anemdef_ =CM_ANEMDEF,       
arth_    =CM_ARTH,          
bldloss_ =CM_BLDLOSS,       
chf_     =CM_CHF,           
chrnlung_=CM_CHRNLUNG,      
coag_    =CM_COAG,          
depress_ =CM_DEPRESS,       
dm_      =CM_DM,            
dmcx_    =CM_DMCX,          
drug_    =CM_DRUG,          
htn_c_   =CM_HTN_C,         
hypothy_ =CM_HYPOTHY,       
liver_   =CM_LIVER,         
lymth_   =CM_LYMPH,         
lytes_   =CM_LYTES,         
mets_    =CM_METS,         
neuro_   =CM_NEURO,         
obese_   =CM_OBESE,         
para_    =CM_PARA,          
perivasc_=CM_PERIVASC,      
psych_   =CM_PSYCH,         
pulmcirc_=CM_PULMCIRC,      
renlfail_=CM_RENLFAIL,      
tumor_   =CM_TUMOR,         
ulcer_   =CM_ULCER,         
valve_   =CM_VALVE,         
wghtloss_=CM_WGHTLOSS,      
rscore_=readmit_score, 
mscore_=mortal_score
       );

/***********************************************************/
/*  Readmission Weights for calculating scores             */
/***********************************************************/

rwAIDS      =   19 ;
rwALCOHOL   =    6 ;
rwANEMDEF   =    9 ;
rwARTH      =    4 ;
rwBLDLOSS   =    3 ;
rwCHF       =   13 ;
rwCHRNLUNG  =    8 ;
rwCOAG      =    7 ;
rwDEPRESS   =    4 ;
rwDM        =    6 ;
rwDMCX      =    9 ;
rwDRUG      =   14 ;
rwHTN_C     =   -1 ;
rwHYPOTHY   =    0 ;
rwLIVER     =   10 ;
rwLYMPH     =   16 ;
rwLYTES     =    8 ;
rwMETS      =   21 ;
rwNEURO     =    7 ;
rwOBESE     =   -3 ;
rwPARA      =    6 ;
rwPERIVASC  =    4 ;
rwPSYCH     =   10 ;
rwPULMCIRC  =    5 ;
rwRENLFAIL  =   15 ;
rwTUMOR     =   15 ;
rwULCER     =    0 ;
rwVALVE     =    0 ;
rwWGHTLOSS  =   10 ;

/***********************************************************/
/*  Mortality Weights for calculating scores               */
/***********************************************************/

mwAIDS      =    0 ;
mwALCOHOL   =   -1 ;
mwANEMDEF   =   -2 ;
mwARTH      =    0 ;
mwBLDLOSS   =   -3 ;
mwCHF       =    9 ;
mwCHRNLUNG  =    3 ;
mwCOAG      =   11 ;
mwDEPRESS   =   -5 ;
mwDM        =    0 ;
mwDMCX      =   -3 ;
mwDRUG      =   -7 ;
mwHTN_C     =   -1 ;
mwHYPOTHY   =    0 ;
mwLIVER     =    4 ;
mwLYMPH     =    6 ;
mwLYTES     =   11 ;
mwMETS      =   14 ;
mwNEURO     =    5 ;
mwOBESE     =   -5 ;
mwPARA      =    5 ;
mwPERIVASC  =    3 ;
mwPSYCH     =   -5 ;
mwPULMCIRC  =    6 ;
mwRENLFAIL  =    6 ;
mwTUMOR     =    7 ;
mwULCER     =    0 ;
mwVALVE     =    0 ;
mwWGHTLOSS  =    9 ;

array cmvars(&nv_) 	&aids_    &alcohol_  &anemdef_ &arth_     &bldloss_  &chf_     &chrnlung_ &coag_    &depress_ &dm_      
					&dmcx_    &drug_     &htn_c_   &hypothy_  &liver_    &lymth_   &lytes_    &mets_    &neuro_   &obese_   
					&para_    &perivasc_ &psych_   &pulmcirc_ &renlfail_ &tumor_   &ulcer_    &valve_   &wghtloss_
					;

array rwcms(&nv_) 	rwAIDS    rwALCOHOL  rwANEMDEF rwARTH     rwBLDLOSS   rwCHF    rwCHRNLUNG  rwCOAG    rwDEPRESS rwDM            
					rwDMCX    rwDRUG     rwHTN_C   rwHYPOTHY  rwLIVER     rwLYMPH  rwLYTES     rwMETS    rwNEURO   rwOBESE         
					rwPARA    rwPERIVASC rwPSYCH   rwPULMCIRC rwRENLFAIL  rwTUMOR  rwULCER     rwVALVE   rwWGHTLOSS      
					;

array mwcms(&nv_) 	mwAIDS    mwALCOHOL  mwANEMDEF mwARTH     mwBLDLOSS   mwCHF    mwCHRNLUNG  mwCOAG    mwDEPRESS  mwDM            
					mwDMCX    mwDRUG     mwHTN_C   mwHYPOTHY  mwLIVER     mwLYMPH  mwLYTES     mwMETS    mwNEURO    mwOBESE         
					mwPARA    mwPERIVASC mwPSYCH   mwPULMCIRC mwRENLFAIL  mwTUMOR  mwULCER     mwVALVE   mwWGHTLOSS      
					;

array ocms(&nv_)  	oAIDS     oALCOHOL   oANEMDEF  oARTH      oBLDLOSS    oCHF     oCHRNLUNG   oCOAG     oDEPRESS   oDM            
					oDMCX     oDRUG      oHTN_C    oHYPOTHY   oLIVER      oLYMPH   oLYTES      oMETS     oNEURO     oOBESE         
					oPARA     oPERIVASC  oPSYCH    oPULMCIRC  oRENLFAIL   oTUMOR   oULCER      oVALVE    oWGHTLOSS      
					;  

*****Calculate readmit score;
do i = 1 to &nv_;
  ocms[i]=cmvars[i]*rwcms[i];
end;

&rscore_ = sum(of ocms[*]);

*****Calculate mortality score;
do i = 1 to &nv_;
  ocms[i]=cmvars[i]*mwcms[i];
end;

&mscore_ = sum(of ocms[*]);

***drop all intermediate variables;
drop rw: mw: o: i;

%mend;

%Let    DS_  = cohort;
    ***if 29 variables are from HCUP standard severity file;
%Let    nv_  = 29;

DATA out.cohort;
    SET  &DS_. ;
    %get_cmscore;
    ***two output score names are readmit_score and mortal_score;

	format trt_dystonia yn.;
	label 
	trt_dystonia='DBS for dystonia'
	mortal_score='Elixhauser comorbidity index';
RUN;

/* 1/20/2023: remove those with missing sex */
data out.cohort;
	set out.cohort;
	where sex in (1 2);
run;

/* 1/31/2023: remove those with missing income quartile 
combine self-pay and other/unknown
combine urban nonteaching and rural
*/
data out.cohort;
	set out.cohort;
	where ZIPINC_QRTL in (1 2 3 4);

	if HOSP_LOCTEACH=3 then teach=1;else teach=0;
	if pay1=4 then pay1=999;

	format pay1 insurancef. teach teachfnew.;
	label teach='Location/teaching status of hospital';
run;



/******************************
***		Create Table 1 		***
******************************/

* Weighted table 1;
* Create dummy variables for hospitals not in the subset;
data COMBINED ; 
	length NIS_STRATUM 8.;
	set out.cohort out.hospital(in=INHOSP KEEP=year HOSP_NIS NIS_STRATUM) ; 
	INSUBSET = 1 ; 
	if INHOSP then do ; 
		INSUBSET = 0 ;   * ASSIGN A VALUE OUTSIDE THE SUBSET ; 
		DISCWT = 1 ;     * ASSIGN A VALID WEIGHT ; 
		age = 0 ;    * SET ANALYSIS VARIABLES TO ZERO ;    
		sex = 1;
		race = 1;
		mortal_score = 0;
		pay1 = 1;
		ZIPINC_QRTL = 1;
		teach = 1;
		HOSP_BEDSIZE = 1;
		HOSP_REGION = 1;
		H_CONTRL = 1;
		trt_dystonia=0;
		dystonia=0;
	end ; 

	new_year=year;
run; 

* Specify parameters for the weighted table macro;
%let patwt = DISCWT;
%let cluster = HOSP_NIS;
%let strata = NIS_STRATUM YEAR;
%let domain = INSUBSET;
%let noby = 0;
%let nopvalue = 1;
%let pcttype=row;
%let CDECNUM=2;
%let vars=age sex race pay1 ZIPINC_QRTL HOSP_REGION mortal_score teach;
%let vartypes=1 2 2 2 2 2 1 2;
%let out=&Sour.\&sub.\Results\;

%let dsn = COMBINED;
%let fname=Table7_dystonia_&rdate..doc;
%let by = trt_dystonia;
%weighted_table;




/********************************
***		 NIS Sample Size	  ***
********************************/

* Total N's in each year of NIS (weighted), data downloaded from https://datatools.ahrq.gov/hcupnet;
data out.NIS_totalN;
	input year totN;
	datalines;
2012	36484846
2013	35597792
2014	35358818
2015	35769942
2016	35675421
2017	35798453
2018	35527481
2019	35419023
2020	32355827
run;

* Create a macro variable for the total number of discharges over years (weighted) in NIS;
proc sql;select sum(totN) into :N12_19 from out.NIS_totalN ;quit;



/**********************************
***			Trend Table			***
**********************************/


* Create macro to calculate weighted frequency and percent of dystonia dx and DBS;
%macro wt_trend(dx);

	* Weighted freq of dystonia;
	PROC SURVEYFREQ data=&dx.;
		WEIGHT DISCWT;
		CLUSTER HOSP_NIS;
		STRATA NIS_STRATUM NEW_YEAR;
		TABLES insubset*YEAR*&dx./row;
		ods output CrossTabs = cross;
	run;

	data cross;
		set cross;
		where insubset=1 and &dx.=1;
		keep &dx. year Frequency WgtFreq;
	run;

	* Weighted freq and percent of neuromodulation;
	PROC SURVEYFREQ data=&dx. ;
		WEIGHT DISCWT;
		CLUSTER HOSP_NIS;
		STRATA NIS_STRATUM NEW_YEAR;
		TABLES insubset*&dx.*YEAR*trt_&dx./row;
		ods output CrossTabs = cross2;
	run;

	data cross2;
		set cross2;
		where insubset=1 and &dx.=1 and trt_&dx.=1;
		keep &dx. year Frequency WgtFreq RowPercent;
	run;

	* Combine N and % of DX and DBS;
	proc sql;
		create table &dx.trend as
		select A.&dx., A.year, A.Frequency as freq_dx, A.WgtFreq as WgtFreq_dx,
				B.Frequency as freq_trt, B.WgtFreq as WgtFreq_trt, B.RowPercent as trt_percent
		from cross as A, cross2 as B
		where A.year=B.year;
	quit;

	* Format the table;
	data &dx.trend;
		set &dx.trend;
		WgtFreq_dx=round(WgtFreq_dx,1);
		WgtFreq_trt=round(WgtFreq_trt,1);
		trt_percent=trt_percent/100;
		format trt_percent percent9.4 freq_dx WgtFreq_dx freq_trt WgtFreq_trt COMMA12.;
		label freq_dx="Unweighted Frequency of &dx."
			WgtFreq_dx="Weighted Frequency of &dx."
			freq_trt='Unweighted Frequency of Neuromodulation'
			WgtFreq_trt='Weighted Frequency of Neuromodulation'
			trt_percent="Percent of Neuromodulation Among &dx.";
	run;

	* Add N of discharges for each year to the table;
	proc sql;
		create table &dx.trend as
		select A.*, B.*
		from &dx.trend as A left join out.NIS_totalN as B
		on A.year=B.year;
	quit;

	data &dx.trend;
		set &dx.trend;
		dx_percent=WgtFreq_dx/totN;
		format dx_percent percent9.4 totN COMMA12.;
		label totN="Weighted Frequency of Discharges in NIS"
			dx_percent="Percent of &dx. Among All Discharges";
	run;

	* Add total N across years 2012-2019 to the last row of the table;
	data &dx.trend;
		set &dx.trend;
		if year=. then totN=&N12_19.;
		dx_percent=WgtFreq_dx/totN;
		if trt_percent=. then trt_percent=WgtFreq_trt/WgtFreq_dx;
	run;
	

	proc datasets library=work noprint;
		delete cross cross2;
	quit;

%mend wt_trend;


%wt_trend(COMBINED);

* Output;
ods rtf file="&Sour.\&sub.\Results\Weighted_trend_&rdate..rtf";
proc print data=dystoniatrend label;run;
ods rtf close;



/**********************************
***			Figures				***
**********************************/


data dystrend;
	set dystoniatrend;
	length type $40;
	type='Dystonia DX among all discharges';
	keep year dx_percent  type;
	rename dx_percent=per;
data dbstrend;
	set dystoniatrend;
	length type $40;
	type='DBS rate among dystonia discharges';
	keep year trt_PERCENT type;
	rename trt_PERCENT=per;
data plot;
	set dystrend dbstrend ;
	if year=. then delete;
run;

* Create a figure of prevalence of dystonia among all NIS discharges and 
	prevalence of DBS among all dystonia patients across years;
ods graphics on / RESET IMAGEFMT =jpeg IMAGENAME = 'Prevalence of dystonia and DBS';
ods listing image_dpi=300 gpath = "&Sour.\&sub.\Results\"; 
title "Prevalence of Dystonia DX and DBS Treatment"; 
proc sgplot data=plot;
series x = year y = per / group=type MARKERS LINEATTRS = (THICKNESS = 2) markerattrs=(symbol=trianglefilled);
yaxis label="Prevalence(%)" values=(0 to 0.01 by 0.002);
xaxis type=discrete label='Year';
keylegend / title="";
run;
ods graphics off;


/* Table of weighted prevalence of DBS/RNS by race, sex, insurance, region, and income */

%macro wtrend_by(dx, var);
	PROC SURVEYFREQ data=&dx. ;
		WEIGHT DISCWT;
		CLUSTER HOSP_NIS;
		STRATA NIS_STRATUM NEW_YEAR;
		TABLES insubset*&dx.*&var.*YEAR*trt_&dx./row;
		ods output CrossTabs = cross2;
	run;

	data cross2;
		set cross2;
		where insubset=1 and &dx.=1 and trt_&dx.=1 ; 
		keep &dx. year &var. Frequency WgtFreq RowPercent;
	run;

	data &dx.&var.;
		set cross2;
		WgtFreq=round(WgtFreq,1);
		percent=RowPercent/100;
		format percent percent9.4;
		label
			WgtFreq='Weighted Frequency of Neuromodulation'
			percent='Percent of Neuromodulation';
	run;

	proc datasets library=work noprint;
		delete cross2;
	quit;
%mend wtrend_by;


/* Figure of prevelance by race, sex, insurance, region, and income */
%macro prevplot(dat, group, ylim, yby);

	%if &group.=RACE %then %let grp=Race;
	%if &group.=sex %then %let grp=Sex;
	%if &group.=PAY1 %then %let grp=Insurance;
	%if &group.=ZIPINC_QRTL %then %let grp=Median Household Income for Patient’s ZIP Code National Quartile;
	%if &group.=HOSP_REGION %then %let grp=Hospital Region;

	%if &dat.=out.dystoniapanel %then %let dx=Dystonia;

	ods graphics on / RESET IMAGEFMT =jpeg IMAGENAME = "Prevalence_&dx._&group.";
	ods listing image_dpi=300 gpath = "&Sour.\&sub.\Results\"; 
	title "Prevalence of Neuromodulation Among Patients with &dx."; 
	proc sgplot data=&dat.;
		where &group. ne .;
		series x = year y = PERCENT/ group=&group. MARKERS LINEATTRS = (THICKNESS = 2) markerattrs=(symbol=trianglefilled);
		yaxis label="Prevalence(%)" values=(0 to &ylim. by &yby.);
		xaxis type=discrete label='Year';
		keylegend / title="&grp.";
	run;

%mend prevplot;


%wtrend_by(COMBINED, race);
%wtrend_by(COMBINED, sex);
%wtrend_by(COMBINED, pay1);
%wtrend_by(COMBINED, HOSP_REGION);
%wtrend_by(COMBINED, ZIPINC_QRTL);

data out.dystoniapanel;
	set dystoniarace dystoniasex dystoniapay1 dystoniaZIPINC_QRTL dystoniaHOSP_REGION;
	if race ne . then panel=1;
	if sex ne . then panel=2;
	if pay1 ne . then panel=3;
	if HOSP_REGION ne . then panel=4;
	if ZIPINC_QRTL ne . then panel=5;

	if year=. then delete;
	* not reporting unknown categories;
	if pay1=999 or ZIPINC_QRTL=999 or race=999 then delete;

	if Frequency=0 then percent=0;
	format panel panelf.;
run;

* 4/13/2024: edited the y-axis of figures to range from 0 to 0.05;
%prevplot(out.dystoniapanel, RACE, 0.05, 0.005);
%prevplot(out.dystoniapanel, sex, 0.05, 0.005);
%prevplot(out.dystoniapanel, PAY1, 0.05, 0.005);
%prevplot(out.dystoniapanel, ZIPINC_QRTL, 0.05, 0.005);
%prevplot(out.dystoniapanel, HOSP_REGION, 0.05, 0.005);



/**********************************
***		Regression Analysis		***
**********************************/


* Check collinearity;
* Dummy code categorical variables;
data COMBINED;
	set COMBINED;
	if sex=2 then female=1; else female=0;
	if race=1 then white=1;else white=0;
	if race=2 then black=1;else black=0;
	if race=3 then hispanic=1;else hispanic=0;
	if race=4 then asian_pacific=1;else asian_pacific=0;
	if pay1=1 then medicare=1;else medicare=0;
	if pay1=2 then medicaid=1;else medicaid=0;
	if pay1=3 then private=1;else private=0;
	if HOSP_REGION=1 then Northeast=1;else Northeast=0;
	if HOSP_REGION=2 then Midwest=1;else Midwest=0;
	if HOSP_REGION=3 then South=1;else South=0;
	if ZIPINC_QRTL=1 then q1=1;else q1=0;
	if ZIPINC_QRTL=2 then q2=1;else q2=0;
	if ZIPINC_QRTL=3 then q3=1;else q3=0;
	if HOSP_LOCTEACH=3 then teach=1;else teach=0;
run;


proc reg data=COMBINED;
	where insubset=1 ;
	model trt_dystonia=age female white black hispanic asian_pacific medicare medicaid private  Northeast Midwest South 
			q1 q2 q3 teach mortal_score/tol vif collin;
quit;


/**********************************
***		Univariate OR			***
**********************************/

* Unadjusted model;
%macro wt_or(dx, var);

	ods rtf file="&sour.&sub.\Results\Univariate_OR_&dx._&var._&rdate..rtf";
	proc surveylogistic data=&dx.;
		class race(ref='White') trt_&dx. sex(ref='Male') pay1(ref='Private insurance/HMO') HOSP_REGION(ref='West') ZIPINC_QRTL(ref='First quartile') 
			teach(ref='Urban teaching') trt_&dx./param=ref;
		WEIGHT DISCWT;
		CLUSTER HOSP_NIS;
		STRATA NIS_STRATUM NEW_YEAR;
		domain insubset;
		model trt_&dx.(event='Yes') = &var.;
		ods output OddsRatios=or&dx.&var. ParameterEstimates=pval&dx.&var.;
	run;
	ods rtf close;

%mend wt_or;

* Combine ORs and p-values, print out the table to an rtf file;
%macro est(or, pvals, type);

	data &or.;
		length Variable $70. Reference $50.;
		set &or.;
		where insubset=1;
		Variable=scan(effect,1,' ');
		if variable='sex' then variable='Sex';
		if variable='RACE' then variable='Race';
		if variable='PAY1' then variable='Insurance';
		if variable='HOSP_REGION' then variable='Hospital Region';
		if variable='ZIPINC_QRTL' then variable='Median Household Income for Patient’s ZIP Code National Quartile';
		if variable='teach' then variable='Hospital Location/Teaching Status';
		if variable='mortal_score' then variable='Elixhauser Comorbidity Index';

		array refs {5} $20. ref1-ref5;
		do i=1 to 5;
			refs[i]=scan(effect,i+1,' ');
		end;

		* Combine;
		Reference=catx(' ', of ref1-ref5);

		obs=_N_;

		drop i effect ref1-ref5 INSUBSET Domain;
	run;

	data &pvals.;
		set &pvals.;
		where insubset=1 and Variable ne 'Intercept';
		obs=_N_;
		keep obs ProbT;
	run;

	proc sql;
		create table &or. as
		select A.*, B.*
		from &or. as A left join &pvals. as B
		on A.obs=B.obs;
	quit;

	data &or.;
		set &or.;
		drop obs;
	run;

	ods rtf file="&sour.&sub.\Results\&or._&type._&rdate..rtf";
	proc print label;run;
	ods rtf close;

%mend est;



%wt_or(COMBINED, race);
%wt_or(COMBINED, sex);
%wt_or(COMBINED, pay1);
%wt_or(COMBINED, HOSP_REGION);
%wt_or(COMBINED, ZIPINC_QRTL);
* 4/13/2024: added univariate analysis for age, teaching status, and elixhauser index;
%wt_or(COMBINED, age);
%wt_or(COMBINED, teach);
%wt_or(COMBINED, mortal_score);


data Dystonia_OR;
	length effect $60.;
	set orDystoniasex orDystoniarace orDystoniapay1 orDystoniahosp_region orDystoniaZIPINC_QRTL 
	orDystoniaage orDystoniateach orDystoniamortal_score;
run;

data pval;
	length Variable $50 ClassVal0 $30;
	set pvalDystoniasex pvalDystoniarace pvalDystoniapay1 pvalDystoniahosp_region pvalDystoniaZIPINC_QRTL
	pvalDystoniaage pvalDystoniateach pvalDystoniamortal_score;
run;

* Output;
%est(Dystonia_OR, pval, Univariate);





/* Multivariable regression */

* Other than the variables of interest for disparity study, add age, and

1) Teaching hospital status
 
2) Elixhauser index - this could influence surgery as higher index patients might be less likely to be operated upon.
;

* Adjusted;
%macro adj_or(dx);

	ods rtf file="&sour.&sub.\Results\Multivariable_OR_&dx._&rdate..rtf";
	proc surveylogistic data=&dx.;
		class race(ref='White') trt_&dx. sex(ref='Male') pay1(ref='Private insurance/HMO') HOSP_REGION(ref='West') ZIPINC_QRTL(ref='First quartile')
				teach(ref='Urban teaching')/param=ref;
		WEIGHT DISCWT;
		CLUSTER HOSP_NIS;
		STRATA NIS_STRATUM NEW_YEAR;
		domain insubset;
		model trt_&dx.(event='Yes') = age sex race pay1 HOSP_REGION ZIPINC_QRTL TEACH mortal_score;
		ods output OddsRatios=or&dx. ParameterEstimates=pval&dx.;
	run;
	ods rtf close;

%mend adj_or;


%adj_or(COMBINED);
* Output;
%est(ORDystonia, pvalDystonia, Multivariable);
