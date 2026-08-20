/* jenner-check bundle: exercises the project's ICD code lists from codelist.sas
   (excerpted verbatim below: DBS_ICD9/10, dystn_ICD9/10, CM_CHF9/10, CM_HTN9/10)
   against mock diagnosis records, using the same "in:" substring-matching
   pattern the project's Analysis.sas uses in its Elixhauser comorbidity data
   step (the "elx" data step that flags CM_CHF, CM_HTN, etc. from
   DX1-DX30 / I10_DX1-I10_DX40 against these same macro variables). */

/* ---- verbatim excerpt from codelist.sas ---- */
%let DBS_ICD9 = "0293", "0120", "8694", "8695", "8696", "8697", "8698"; *full;
%let DBS_ICD10 = "00H00MZ","00H03MZ","00H04MZ","00H60MZ","00H63MZ","00H64MZ","0JH60DZ","0JH63DZ","0JH70DZ","0JH73DZ","0JH80DZ","0JH83DZ",
				"0JH60EZ", "0JH60BZ", "0JH80MZ", "0JH83MZ"; *full;

%let dystn_ICD9 = "3336","3337","33371","33372","33379","3338","33381","33382","33383","33384","33385","33389"; *full;
%let dystn_ICD10 = "G24"; *sub;

%let CM_CHF9 = %STR("39891", "428");
%let CM_CHF10 = %STR("I0981", "I501", "I5020", "I5021", "I5022", "I5023", "I5030", "I5031", "I5032", "I5033",
					 "I5040", "I5041", "I5042", "I5043", "I50810", "I50811", "I50812", "I50813", "I50814",
					 "I5082", "I5083", "I5084", "I5089", "I509");

%let CM_HTN9 = %STR("4011", "4019", "64200", "64201", "64202", "64203", "64204");
%let CM_HTN10 = %STR("I10", "O10011", "O10012", "O10013", "O10019", "O1002", "O1003",
					 "O10911", "O10912", "O10913", "O10919", "O1092", "O1093");
/* ---- end excerpt ---- */

data work.dx_sample;
	length admid 8 dx1-dx3 $8 icd10_dx1-icd10_dx3 $8;
	input admid dx1 $ dx2 $ dx3 $ icd10_dx1 $ icd10_dx2 $ icd10_dx3 $;
	datalines;
1 3336 4011 39891 G240 I10 I501
2 8694 4019 . 00H00MZ O10019 .
3 0000 0000 0000 X999 X999 X999
4 33371 39891 4372 G24 I5020 I441
;
run;

* Flag DBS procedures, dystonia diagnosis, and two Elixhauser comorbidities
  (CHF, hypertension) using the project's own code lists;
data work.flagged;
	set work.dx_sample;

	array dx dx1-dx3;
	array dx10 icd10_dx1-icd10_dx3;

	if dx1 in: (&DBS_ICD9.) or dx2 in: (&DBS_ICD9.) or dx3 in: (&DBS_ICD9.) then dbs_flag = 1;
	if icd10_dx1 in: (&DBS_ICD10.) or icd10_dx2 in: (&DBS_ICD10.) or icd10_dx3 in: (&DBS_ICD10.) then dbs_flag = 1;

	if dx1 in: (&dystn_ICD9.) or dx2 in: (&dystn_ICD9.) or dx3 in: (&dystn_ICD9.) then dystonia_flag = 1;
	if icd10_dx1 in: (&dystn_ICD10.) or icd10_dx2 in: (&dystn_ICD10.) or icd10_dx3 in: (&dystn_ICD10.) then dystonia_flag = 1;

	do over dx;
		if dx in: (&CM_CHF9.) then CM_CHF = 1;
		if dx in: (&CM_HTN9.) then CM_HTN = 1;
	end;
	do over dx10;
		if dx10 in: (&CM_CHF10.) then CM_CHF = 1;
		if dx10 in: (&CM_HTN10.) then CM_HTN = 1;
	end;

	if dbs_flag = . then dbs_flag = 0;
	if dystonia_flag = . then dystonia_flag = 0;
	if CM_CHF = . then CM_CHF = 0;
	if CM_HTN = . then CM_HTN = 0;

	keep admid dbs_flag dystonia_flag CM_CHF CM_HTN;
run;

proc print data=work.flagged label;
	title "DBS/dystonia/comorbidity flags from the project's ICD code lists";
run;
