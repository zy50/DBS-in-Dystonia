proc format;
	value yn 1='Yes' 0='No' 999='Unknown';

	value nmtrt 1='Neuromodulation Use' 0='No Neuromodulation Use';

	value sexf 1='Male' 2='Female' 999='Unknown';

	value groupf 1="1: Parkinson’s Disease"
			2="2: Essential Tremor"
			3="3: Dystonia"
			4="4: Epilepsy"
			999="Other";

	value groupnonum 1="Parkinson’s Disease"
			2="Essential Tremor"
			3="Dystonia"
			4="Epilepsy"
			999="Other";

	value panelf 1='Race'
			2='Sex'
			3='Insurance'
			4='Hospital Region'
			5='Household Income Quartile';

	value racefnew
		1='White'
		2='Black'
		3='Hispanic'
		4='Asian/Pacific Islander'
		999='Other/Unknown'
		;

	value teachfnew
		1='Urban teaching'
		0='Urban nonteaching/Rural'
		;

	value insurancef
				       1 = "Medicare"
                       2 = "Medicaid"
                       3 = "Private insurance/HMO"
                       999 = "Other"
;

	Value  FZIQnew                       /* ZIPINC_QRTL - Median household income for patient's ZIP Code (based on current year)  */
                       1 = "First quartile"
                       2 = "Second quartile"
                       3 = "Third quartile"
                       4 = "Fourth quartile"
					   999= "Unknown"
;

	Value  F1PAYnew                      /* PAY1 - Primary payer - uniform (1988-1997)  */
                       1 = "Medicare"
                       2 = "Medicaid"
                       3 = "Private insurance/HMO"
					   4 = "Self-pay"
                       999 = "Other/Unknown/No charge"
;

     Value  ST_REGNnew                    /* st_reg mapping  */
                       1 = "Northeast"
                       2 = "Midwest"
                       3 = "South"
                       4 = "West"
;

	Value  LOCTCHNnew                    /* locteach (location/teaching)  */
                       1 = "Rural"
                       2 = "Urban nonteaching"
                       3 = "Urban teaching"
;

	Value  FBEDSZNnew                    /* st_bedsz mapping  */
                       1 = "Small"
                       2 = "Medium"
                       3 = "Large"
;

	Value  F_CNTRLnew                    /* st-owner mapping  */
                       0 = "Government or private (collapsed category)"
                       1 = "Government, non-federal (public)"
                       2 = "Private, not-for-profit (voluntary)"
                       3 = "Private, investor-owned (proprietary)"
                       4 = "Private (collapsed category)"
;

run;



/* jenner-check addition: apply the project's formats to a small sample of
   discharge-level records, shaped like the NIS/HCUP fields these formats
   were built for (sex, race, insurance, dystonia/DBS flags, hospital region). */
data work.sample;
	input admid sex race pay1 dystonia dbs HOSP_REGION;
	format sex sexf. race racefnew. pay1 F1PAYnew. dystonia dbs yn. HOSP_REGION ST_REGNnew.;
	datalines;
1 1 1 1 1 1 1
2 2 2 2 0 0 2
3 1 3 3 1 0 3
4 2 4 999 0 0 4
5 999 999 999 1 1 999
;
run;

proc print data=work.sample label;
	title "Sample discharges with project formats applied";
run;
