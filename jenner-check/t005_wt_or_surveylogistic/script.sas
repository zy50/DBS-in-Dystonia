/* jenner-check bundle: the project's %wt_or macro from Analysis.sas
   ("Univariate OR" section), copied verbatim apart from redirecting the
   hardcoded &sour.&sub.\Results\ ODS RTF path to a relative one. Calls
   PROC SURVEYLOGISTIC with the project's own WEIGHT/CLUSTER/STRATA/domain
   survey-design statements and CLASS ref= coding, against a small mock
   cohort shaped like the "COMBINED" dataset (weighted NIS discharges with
   a treatment outcome, demographic and hospital covariates) the macro is
   called against in Analysis.sas's regression section.

   Note: the macro's outcome variable is named trt_&dx., and the project
   calls it as %wt_or(COMBINED, sex) etc. (dataset literally named
   COMBINED) -- so the macro looks for a column named trt_COMBINED, not
   trt_dystonia. That mismatch is in the source repo's own code, not
   something jenner-check introduced; this bundle names the mock outcome
   column trt_COMBINED to match what the macro actually binds to, so it
   exercises the same PROC SURVEYLOGISTIC / survey-design logic the
   project runs. */

proc format;
	value yn 1='Yes' 0='No' 999='Unknown';
run;

* Unadjusted model;
%macro wt_or(dx, var);

	ods rtf file="./Univariate_OR_&dx._&var..rtf";
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


* jenner-check addition: mock weighted NIS-shaped cohort for the sex covariate,
  matching the project's COMBINED dataset shape used at %wt_or(COMBINED, sex); ;
data work.COMBINED;
	length race $10;
	format trt_COMBINED yn.;
	input HOSP_NIS NIS_STRATUM NEW_YEAR DISCWT insubset sex race $ pay1 HOSP_REGION ZIPINC_QRTL teach trt_COMBINED;
	datalines;
1 1 2018 2.5 1 1 White 1 1 1 1 1
1 1 2018 2.5 1 2 Black 2 2 2 0 0
2 1 2019 3.0 1 1 White 3 3 3 1 1
2 2 2019 3.0 1 2 White 1 1 1 0 0
3 2 2018 2.0 1 1 Black 2 4 4 1 0
3 2 2019 2.0 1 2 White 1 2 2 0 1
4 1 2018 2.5 1 1 White 3 3 1 1 0
4 2 2019 3.5 1 2 Black 1 1 2 0 1
;
run;

%wt_or(COMBINED, sex);

proc print data=pvalCOMBINEDsex label;
	title "Parameter estimates for sex, from the project's weighted logistic macro";
run;
