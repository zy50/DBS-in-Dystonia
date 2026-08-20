/* jenner-check bundle: the project's %get_cmscore macro from Analysis.sas,
   copied verbatim, called against 3 mock patients' Elixhauser comorbidity
   flags using the same %let nv_=29 / DATA step / %get_cmscore call pattern
   Analysis.sas uses right after its "elx" data step. */

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


* jenner-check addition: 3 mock patients with a handful of Elixhauser
  comorbidity flags set, matching the caller pattern used right after
  Analysis.sas's "elx" data step;
data work.elx;
	input admid CM_AIDS CM_ALCOHOL CM_ANEMDEF CM_ARTH CM_BLDLOSS CM_CHF CM_CHRNLUNG CM_COAG CM_DEPRESS CM_DM
		  CM_DMCX CM_DRUG CM_HTN_C CM_HYPOTHY CM_LIVER CM_LYMPH CM_LYTES CM_METS CM_NEURO CM_OBESE
		  CM_PARA CM_PERIVASC CM_PSYCH CM_PULMCIRC CM_RENLFAIL CM_TUMOR CM_ULCER CM_VALVE CM_WGHTLOSS;
	datalines;
1 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
3 0 1 1 0 0 0 1 0 1 0 0 0 0 0 0 0 1 0 1 0 0 0 1 1 1 0 0 0 1
;
run;

%Let    nv_  = 29;

DATA work.scored;
    SET  work.elx ;
    %get_cmscore;
    ***two output score names are readmit_score and mortal_score;
	label mortal_score='Elixhauser comorbidity index';
RUN;

proc print data=work.scored label;
	title "Readmission and mortality scores from the project's weighted comorbidity-scoring macro";
run;
