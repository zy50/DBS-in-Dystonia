/****************************************************************************************
	Weighted Table Macro
	- by group and categorical variables have to be numerically formatted.
		- columns and rows will be in the order of the formatting.
		- may throw an error if categorical variable is not numerically formatted. (line 256)
	- Number of missing for both categorical and continuous variables is weighted.
	- P-values are not generated for categorical variables that have a level with
		all 0's.
	- P-value for categorical variables is Rao-Scott Likelihood Ratio Test based on the following criteria:
		- If you do not use a STRATA, CLUSTER, or REPWEIGHTS statement, then the default is CHISQ(NOADJUST).
		- If you use a STRATA, CLUSTER, or REPWEIGHTS statement, and you need to estimate only one parameter excluding the intercepts in the model, then the default is CHISQ(FIRSTORDER).
		- If you use a STRATA, CLUSTER, or REPWEIGHTS statement, and you need to estimate more than one parameter excluding the intercepts in the model, then the default is CHISQ(SECONDORDER).
	- P-value for continuous variables is Wald's F test.
	- Remember to always check your log to see if any errors or warnings occurred.
	- If you have any questions, comments, or feedback please email tr133@duke.edu.


	Dec 2022: Lexie Yang added an option of reporting row percentages for discrete variables.
	- PCTTYPE: type of percentage for discrete variables

	Jan 2023: Lexie Yang added an option of specifying decimal places for reporting

	- NDECNUM: number of decimal places for continuous variables, can be 1 or 2 
	- CDECNUM: number of decimal places for categorical variables, can be 1 or 2 

	--- variable definitions ---
	dsn:		input dataset
	patwt:		list of weight variables
	cluster:	list of cluster variables
	strata:		list of strata variables
	domain:		domain variable
	noby:		if you have a by variable, noby=0, if not, noby=1
	nopvalue:	if you want p-values, nopvalue=0, if not, nopvalue=1
	by:			variable whose levels are the columns of the table
	vars:		list of variables for the table (can be a series of macro variables containing stored lists of variable names)
	vartypes:	list of the variable type for each variable in the variable list
					1 = Continuous
					2 = Categorical
	out:		file path for output table NOT including the file name
	fname:		file name INCLUDING extension
	pcttype:	type of percentage for discrete variables
					col = column percentage 
					row = row percentage

	--- defining variables example ---
	%let dsn = analysis.LOS_sample;
	%let patwt = DISCWT;
	%let cluster = HOSP_NIS;
	%let strata = NIS_STRATUM YEAR;
	%let domain = incohort1;
	%let pcttype = row;
	%let noby = 0;
	%let nopvalue = 0;
	%let by = Disease_group;
	%let vars=AGE RACE FEMALE LOS;
	%let vartypes=1 2 2 1;
	%let out=\\duhs-vclin-nc1\dusom_biostats_fs\data\biostatscore\CRU\Surgery\Seth Cohen\201802_frailty\macro test\;
	%let fname=Test_Weighted Table Macro_&todaysDate..doc;

	
****************************************************************************************/

/* macro variable for todays date */
%let todaysDate = %sysfunc(today(), yymmddn8.);


%macro weighted_table();
%put &=vars;
%put &=vartypes;

/* Check if percent type is specified, if not, set default to report column percentages */
%if %symexist(pcttype) %then %do;
	%if &pcttype = col %then %let pct_type = row;
	%if &pcttype = row %then %let pct_type = col;
%end;
%else %do;
	%let pct_type = row;
%end;

/* Specify decimal places for reporting, default is 1 decimal place for both categorical and continuous variables */
* For categorical variables, only modify decimal places of percentages;
%if %symexist(CDECNUM) %then %do;
	%if &CDECNUM = 2 %then %do;
		%let CDNUM = 0.01;
		%let CFMT = COMMA25.2;
	%end;
%end;
%else %do;
	%let CDNUM = 0.1;
	%let CFMT = COMMA25.1;
%end;

* For continuous variables, modify all stats;
%if %symexist(NDECNUM) %then %do;
	%if &NDECNUM = 2 %then %do;
		%let NDNUM = 0.01;
		%let NFMT = COMMA25.2;
	%end;
%end;
%else %do;
	%let NDNUM = 0.1;
	%let NFMT = COMMA25.1;
%end;

%if &noby=1 %then %do;
	/* creating weighted scale for missing */
	proc surveyfreq data = &dsn.;
		strata &strata.;
		cluster &cluster.;
		weight &patwt.;
		table &domain.;
		ods output OneWay = oneway;
	run;
	proc print data=oneway;
	run;
	data oneway2;
		set oneway;
		if &domain. = 1 then do;
			scale=WgtFreq/Frequency;
			call symput("scale",scale);
		end;
	run;
	data table1;
		length Variable Level Weighted $100;
	run;
	%let nwords=%sysfunc(countw(&vars));
	%do i=1 %to &nwords;
		%let vartype=%scan(&vartypes, &i);
		%if &vartype=2 %then %do;
			%let var=%scan(&vars, &i);
			proc surveyfreq data = &dsn. VARHEADER=LABEL order = FORMATTED;
				strata &strata.;
				cluster &cluster.;
				weight &patwt.;
				table &domain.*&var. /row;
				ods output CrossTabs = cross;
			run;
			data cross;
				length &var. 8;
				set cross;
			run;
			/* getting missing number counts */
			proc freq data=&dsn.;
				table &domain.*&var. /missing;
				ods output CrossTabFreqs = crossb;
			run;
			/* setting up data set with missing counts */
			data crossb2;
				set crossb;
				if &domain. = 1;
				if &var. = . and _TYPE_ in("11");
			run;
			data cross2;
				set cross crossb2;
				if missing (F_&var.) then do;
					WgtFreq=&scale.*Frequency;
					F_&var. = "WgtMissing";
				end;
			run;
			data cross3(drop=Table &domain. WgtFreq RowPercent WgtFreq2 RowPercent2);
				retain Table2 F_&var. Weighted;
				length Table2 $50;
				set cross2(keep=Table &domain. F_&var. WgtFreq RowPercent);
				by Table;
				if &domain. = 1;
				if F_&var. = "Total" then delete;
				Table2=scan(strip(Table),2,"*");
				WgtFreq2=put(round(WgtFreq,1),comma25.);
				RowPercent2=put(round(RowPercent,&CDNUM.),f8.1);
				Weighted=strip(WgtFreq2)||" ("||strip(RowPercent2)||"%)";
				if F_&var. = "WgtMissing" then Weighted = strip(WgtFreq2);
				rename F_&var.=Level Table2=Variable;
			run;
			data cross4;
				set cross3;
				by Variable;
				if level = "WgtMissing" then Order=1;
			run;
			proc sort data=cross4 out=cross5;
				by descending Order;
			run;
			data cross6;
				set cross5(drop=Order);
			run;
			data cross7;
				set cross6;
				by Variable;
				if first.Variable ne 1 then do;
					Variable = "";
				end;
				output;
				if last.Variable = 1 then do;
					Variable="";
					Level="";
					Weighted="";
					output;
				end;
			run;
			data table1;
				set table1 cross7;
			run;
		%end;

		%if &vartype=1 %then %do;
			%let var=%scan(&vars, &i);
			proc surveymeans data = &dsn. plots = none NOBS NMISS nomcar sum mean stderr median Q1 Q3 RANGE min max;
				strata &strata.;
				cluster &cluster.;
				weight &patwt.;
				domain &domain.;
				var &var.;
				ods output Domain=stats;
				ods output DomainQuantiles=quant;
			run;
			data stats2(drop=Mean StdErr Min Max NMiss);
				set stats(drop=DomainLabel VarLabel N Median Q1 Q3 Range StdDev Sum);
				MeanSte=strip(put(round(strip(Mean),&NDNUM.),&NFMT.))||" ("||strip(put(round(strip(StdErr),.01),COMMA25.2))||")";
				MinMax="("||strip(put(round(strip(Min),&NDNUM.),&NFMT.))||", "||strip(put(round(strip(Max),&NDNUM.),&NFMT.))||")";
				WgtNMiss=&scale.*NMiss;
			run; 
			proc sort data=stats2;
				by VarName &domain.;
			run;
			proc transpose data=stats2 out=stats3;
				by VarName &domain.;
				var WgtNMiss MeanSte MinMax;
			run;
			data stats4;
				set stats3;
				if &domain. = 1;
				if _NAME_ in("WgtNMiss") then Order=1;
				else if _NAME_ in("MeanSte") then Order=2;
				else if _NAME_ in("MinMax") then Order=5;
				rename _NAME_=Stat COL1=Value;
			run;
			data quant2;
				set quant(drop=DomainLabel VarLabel Percentile Quantile StdErr LowerCL UpperCL ControlVar);
				if PercentileLabel in ("Median","Q1","Q3");
			run;
			proc transpose data=quant2 out=quant3;
				by VarName &domain.;
				id PercentileLabel;
			run;
			data quant4(drop=Q1 Q3);
				set quant3(drop=_NAME_);
				Median2=strip(put(round(strip(Median),&NDNUM.),&NFMT.));
				Q1Q3=strip(put(round(strip(Q1),&NDNUM.),&NFMT.))||", "||strip(put(round(strip(Q3),&NDNUM.),&NFMT.));
				drop Median;
				rename Median2=Median;
			run;
			proc transpose data=quant4 out=quant5;
				by VarName &domain.;
				var Median Q1Q3;
			run;
			data quant6;
				set quant5;
				if &domain. = 1;
				if _NAME_ in("Median") then Order=3;
				else if _NAME_ in("Q1Q3") then Order=4;
				rename _NAME_=Stat COL1=Value;
			run;
			data finalstats(drop=&domain.);
				set stats4 quant6;
				rename VarName=Variable Stat=Level Value=Weighted;
			run;
			proc sort data=finalstats;
				by Variable Order;
			run;
			data finalstats2(drop=Order);
				set finalstats;
				by Variable;
				if first.Variable ne 1 then do;
					Variable = "";
				end;
				output;
				if last.Variable = 1 then do;
					Variable="";
					Level="";
					Weighted="";
					output;
				end;
			run;
			data table1;
				set table1 finalstats2;
			run;
		%end;
	%end;
%end;

%if &noby=0 %then %do;
	/*********************************************************
		Part 1: By variable
	    Create header showing N in each by group 
	*********************************************************/
	/* generating N's for each by group */
	proc surveyfreq data = &dsn.;
		strata &strata.;
		cluster &cluster.;
		weight &patwt.;
		table &domain.*&by./col;
		ods output CrossTabs = cross;
	run;
	/* sorting by levels of by variable, with 'Total' as the last row */
	data cross2;
		set cross;
		if &domain. = 1 and missing(&by.) and strip(F_&by.) = "Total" then do;
			&by.=99;
			scale=WgtFreq/Frequency;
			call symput("scale",scale);
		end;
	run;
	proc sort data=cross2;
		by &by.;
	run;
	/* cleaning raw output */
	data cross3(keep=F_&by. WgtFreq2 col);
		set cross2 (where = (&domain. = 1));
		WgtFreq2=put(WgtFreq, comma15.);
		ord=_N_;
		if strip(F_&by.) = "Total" then ord=99;
		col=strip(compress("COL"||ord));
	run;
	/* sorting so that the 'Total' column is last */
	proc sort data=cross3;
		by col;
	run;
	/* saving column headers to macro variable */
	proc transpose data=cross3 out=cross3a;
		id WgtFreq2;
		var col;
	run;
	data _null_;
		set cross3a(drop=_NAME_);
		call symput("colvars",catx(" ", OF _:));
	run;
	/* transposing output to represent table column headers */
	proc transpose data=cross3 out=cross4;
		id col;
		var F_&by. WgtFreq2;
	run;
	/* cleaning final output */
	data by(drop=_LABEL_);
		length Variable &colvars $200;
		set cross4(drop=_NAME_);
		Variable=_LABEL_;
		if missing(_LABEL_) then Variable="Weighted N";
	run;
	/*proc print data=by;*/
	/*run;*/
	%if &nopvalue = 0 %then %do;
		data table1;
			retain Variable Level &colvars Pvalue;
			length Variable Level &colvars $200;
			set by;
		run;
	%end;
	%if &nopvalue = 1 %then %do;
		data table1;
			retain Variable Level &colvars;
			length Variable Level &colvars $200;
			set by;
		run;
	%end;


	/**********************************************************
		Part 2: categorical variables
	**********************************************************/
	%let nwords=%sysfunc(countw(&vars));
	%do i=1 %to &nwords;
		%let vartype=%scan(&vartypes, &i);
		%if &vartype=2 %then %do;
			%let var=%scan(&vars, &i);
			/* creating 'zero' flag */
			%let zero_flag = 1;
			/* storing variable label */
			proc transpose data = &dsn. (obs = 1 keep = &var) out = varlabl;
			run;
			data _null_;
				set varlabl;
				call symput('varlabl', trim(_LABEL_));
			run;
			/* suppressing output */
			ods select NONE;
			/* generating counts and frequencies for variable */
			proc surveyfreq data = &dsn. VARHEADER=LABEL order = FORMATTED;
				strata &strata.;
				cluster &cluster.;
				weight &patwt.;
				table &domain.*&by.*&var. /&pct_type.;
				ods output CrossTabs = cross;
			run;

			%if &pct_type. = col %then %do;
			data cross;
				length &var. 8;
				set cross;
				rename ColPercent=RowPercent;
			run;
			%end;
			%else %do;
			data cross;
				length &var. 8;
				set cross;
			run;
			%end;
			/* getting missing number counts */
			proc freq data=&dsn.;
				table &domain.*&by.*&var. /missing;
				ods output CrossTabFreqs = crossb;
			run;
			/* setting up data set with missing counts */
			data crossb2;
				set crossb;
				if &domain. = 1;
				if &var. = . and _TYPE_ in("111","101");
				if &by. = . then &by. = 99;
			run;
			data cross2;
				set cross crossb2;
				if &domain. = 1 and missing(&by.) and F_&by. = "Total" and F_&var. = "Total" then &by.=99;
				if missing(&by.) and F_&by. = "Total" then &by.=99;
				if missing (F_&var.) then WgtFreq=&scale.*Frequency;
			run;
			data cross2b;
				set cross2;
				length F_&var.2 $200;
				F_&var.2=F_&var.;
				if missing(F_&by.) and missing(F_&var.) then F_&var.2 = "WgtMissing";
				char_&by.=vvalue(&by.);
				F_&by. = char_&by.;
				if &by. = 99 then F_&by. = "Total";
				drop F_&var.;
				rename F_&var.2=F_&var.;
			run;
			/* sorting by levels of by variable, with 'Total' as the last row */
			proc sort data=cross2b;
				by &by.;
			run;
			/* cleaning raw output */
			data cross3(keep=F_&by. F_&var. value col);
				set cross2b (where = (&domain. = 1));
				by &by.;
				if strip(compress(F_&var.)) = "Total" then delete;
				if strip(compress(F_&by.)) = "Total" then do;
					RowPercent = Percent;
				end;
				if Frequency = 0 then do;
					RowPercent = 0;
					WgtFreq = 0;
				end;
				if Frequency = 0 and strip(F_&by.) = "Total" then do;
					call symput("zero_flag",strip(Frequency));
				end;
				if _n_=1 then ord=0;
				if first.&by. then ord+1;
				if F_&by. = "Total" then ord=99;
				col=strip(compress("COL"||ord));
				WgtFreq2=strip(put(round((WgtFreq),1),comma25.));
				RowPercent2=strip(put(round((RowPercent),&CDNUM.),&CFMT.));
				value = cat(strip(WgtFreq2)," (",strip(RowPercent2),"%)");
				if F_&var. = "WgtMissing" then value = strip(WgtFreq2);
			run;
			/* sorting for transpose of variable levels */
			proc sort data = cross3;
				by F_&var.;
			run;
			proc transpose data = cross3 out = cross4;
				by F_&var.;
				var value;
				id col;
			run;
			data cross5;
				set cross4;
				ord=_N_;
				if strip(F_&var.) = "WgtMissing" then ord=0;
			run;
			proc sort data=cross5;
				by ord;
			run;
			/* cleaining final output */
			data cross5&var.(drop=F_&var. _NAME_ ord);
				set cross5;
				Level=F_&var.;
				Variable = "";
			run;
			/* generating p-value */
			%if &nopvalue = 0 %then %do;
				%if &zero_flag ne 0 %then %do;
					proc surveylogistic data = &dsn.;
						class &by. &domain. &var.;
					    model &var. = &by.;
					    strata &strata.;
						cluster &cluster.;
						weight &patwt.;
						domain &domain.;
						ods output GlobalTests = pvalue;
					run;
					data pvalue_&var.;
						set pvalue;
						Variable = "&varlabl.";
						where &domain. = 1 and test = "Likelihood Ratio";
					run;
				%end;
				%if &zero_flag eq 0 %then %do;
					data pvalue_&var.;
						Variable = "&varlabl.";
						ProbChiSq = .;
					run;
				%end;
				/* cleaning raw output */
				data pvalue_&var.2;
					set pvalue_&var.(keep=Variable ProbChiSq);
					ProbChiSq2=put(round(ProbChiSq,.001),f8.3);
					if strip(ProbChiSq2) = "0.000" then ProbChiSq2 = "<0.001";
					drop ProbChiSq;
					rename ProbChiSq2=Pvalue;
				run;
				data cat_&var.;
					length Variable Level &colvars $200;
					set pvalue_&var.2 cross5&var.;
				run;
				/* restore suppressed output */
				ods select ALL;
				/*proc print data=cat_&var.;*/
				/*run;*/
				/*** combining results ***/
				data table1;
					retain Variable Level &colvars Pvalue;
					length Variable Level &colvars $200;
					set table1 cat_&var.;
				run;
			%end;
			%if &nopvalue = 1 %then %do;
				data nopvalue_&var.;
					length Variable $200;
					Variable = "&varlabl.";
				run;
				data cat_&var.;
					length Variable Level &colvars $200;
					set nopvalue_&var. cross5&var.;
				run;
				ods select ALL;
				data table1;
					retain Variable Level &colvars;
					length Variable Level &colvars $200;
					set table1 cat_&var.;
				run;
			%end;
		%end;


	/*********************************************************
		Part 3: continuous variables
	*********************************************************/
		%if &vartype=1 %then %do;
			%let var=%scan(&vars, &i);
			/* storing variable label */
			proc transpose data = &dsn. (obs = 1 keep = &var) out = varlabl;
			run;
			data _null_;
				set varlabl;
				call symput('varlabl', trim(_LABEL_));
			run;
			/* suppressing output */
			ods select NONE;
			/* generating summary stats for variable */
			proc surveymeans data = &dsn. plots = none NOBS NMISS nomcar sum mean stderr median Q1 Q3 RANGE min max;
				strata &strata.;
				cluster &cluster.;
				weight &patwt.;
				domain &domain.*&by.;
				var &var.;
				ods output Domain = stats
						 DomainQuantiles = quant;	
			run;
			/* cleaning raw output */
			data stats2(keep=&by. VarLabel NMISS WgtNMISS Mean stderr min max);
				set stats;
				if &domain. = 1;
				WgtNMISS=round((&scale.*NMISS),1);
			run;
			/* raw data for median, Q1, Q3 */
			data quant2(keep=&by. VarLabel PercentileLabel estimate);
				set quant;
				if &domain = 1 and (PercentileLabel = "Median" or PercentileLabel = "Q1" or PercentileLabel = "Q3");
			run;
			/* generating 'Total' stats */
			proc surveymeans data = &dsn. plots = none NOBS NMISS nomcar sum mean stderr median Q1 Q3 RANGE min max;
				strata &strata.;
				cluster &cluster.;
				weight &patwt.;
				domain &domain.;
				var &var.;
				ods output Domain = statstotal
						 DomainQuantiles = quanttotal;	
			run;
			/* cleaning raw output */
			data statstotal2(keep=VarLabel NMISS WgtNMISS min max mean stderr &by.);
				retain &by. VarLabel NMISS WgtNMISS min max mean stderr; 
				set statstotal;
				&by. = 99;
				if &domain. = 1;
				WgtNMISS=round((&scale.*NMISS),1);
			run;
			data quanttotal2(keep=VarLabel PercentileLabel estimate &by.);
				retain &by. VarLabel percentilelabel estimate;
				set quanttotal;
				&by. = 99;
				if &domain. = 1 and (PercentileLabel = "Median" or PercentileLabel = "Q1" or PercentileLabel = "Q3");
			run;
			/* stacking group and total stats - MeanSE and MinMax */
			data stats3(drop=Mean StdErr Mean2 StdErr2 Min Max Min2 Max2);
				set stats2 statstotal2;
				Mean2=put(round((Mean),&NDNUM.),&NFMT.);
				StdErr2=put(round((StdErr),.01),COMMA25.2);
				MeanSE=cat(strip(Mean2)," (",strip(StdErr2),")");
				Min2=put(round((Min),&NDNUM.),&NFMT.);
				Max2=put(round((Max),&NDNUM.),&NFMT.);
				MinMax=cat("(",strip(Min2),",",strip(Max2),")");
				ord=_N_;
				if &by. = 99 then ord=99;
				col=strip(compress("COL"||ord));
			run;
			/* sorting by groups before transpose - 'Total' is the last column */
			proc sort data=stats3;
				by ord;
			run;
			proc transpose data = stats3 out = stats4;
				var WgtNMISS MeanSE MinMax;
				id col;
			run;
			data stats5;
				set stats4;
				if strip(_NAME_) = "WgtNMISS" then do;
					if COL99 = 0 then delete;
				end;
			run;
			/* cleaning final output */
			data stats6(drop=_NAME_);
				length Level &colvars Variable $200;
				set stats5;
				Level=_NAME_;
				Variable = "";
			run;
			/* stacking group and total stats - MedianIQR */
			data quant3;
				set quant2 quanttotal2;
			run;
			/* sorting by groups before transpose - 'Total' is the last column */
			proc sort data = quant3;
				by &by.;
			run;
			proc transpose data = quant3 out = quant4;
				by &by.;
				id PercentileLabel;
				var Estimate;
			run;
			data quant5(drop=_NAME_ Median Q1 Q3 Median2 Q1_2 Q3_2);
				set quant4;
				Median2=put(round((Median),&NDNUM.),&NFMT.);
				Q1_2=put(round((Q1),&NDNUM.),&NFMT.);
				Q3_2=put(round((Q3),&NDNUM.),&NFMT.);
				MedianIQR=cat(strip(Median2)," (",strip(Q1_2),",",strip(Q3_2),")");
				ord=_N_;
				if &by. = 99 then ord=99;
				col=strip(compress("COL"||ord));
			run;
			/* transposing so the row is each stat */
			proc transpose data = quant5 out = quant6;
				var MedianIQR;
				id col;
			run;
			/* cleaning final output */
			data quant7(drop=_NAME_);
				length Level &colvars Variable $200;
				set quant6;
				Level=_NAME_;
				Variable = "";
			run;
			/* generating p-value */
			%if &nopvalue = 0 %then %do;
				proc surveyreg data = &dsn.;
					class &by. &domain.;
				    model &var. = &by.;
				    strata &strata.;
					cluster &cluster.;
					weight &patwt.;
					domain &domain.;
					ods output Effects = pvalue;
				run;
				data pvalue_&var.;
					set pvalue;
					Variable = "&varlabl.";
					where &domain. = 1 and Effect = "Model";
				run;
				data pvalue_&var.2;
					set pvalue_&var.(keep=Variable ProbF);
					ProbF2=put(round(ProbF,.001),f8.3);
					if strip(ProbF2) = "0.000" then ProbF2 = "<0.001";
					drop ProbF;
					rename ProbF2=Pvalue;
				run;
				/* final data set for summary stats of continuous variable */
				data all_stats;
					set stats6 quant7;
					if Level = "MeanSE" then ord=1;
					else if Level = "MedianIQR" then ord=2;
					else if Level = "MinMax" then ord=3;
					else if Level = "WgtNMISS" then ord=0;
				run;
				proc sort data=all_stats;
					by ord;
				run;
				data cont_&var.(drop=ord);
					length Variable Level &colvars $200;
					set pvalue_&var.2 all_stats;
				run;
				/* restore suppressed output */
				ods select ALL;
				/*proc print data=cont_&var.;*/
				/*run;*/
				/*** combining results ***/
				data table1;
					retain Variable Level &colvars Pvalue;
					length Variable Level &colvars $200;
					set table1 cont_&var.;
				run;
			%end;
			%if &nopvalue = 1 %then %do;
				data all_stats;
					set stats6 quant7;
					if Level = "MeanSE" then ord=1;
					else if Level = "MedianIQR" then ord=2;
					else if Level = "MinMax" then ord=3;
					else if Level = "WgtNMISS" then ord=0;
				run;
				proc sort data=all_stats;
					by ord;
				run;
				data nopvalue_&var.;
					length Variable $200;
					Variable = "&varlabl.";
				run;
				data cont_&var.(drop=ord);
					length Variable Level &colvars $200;
					set nopvalue_&var. all_stats;
				run;
				ods select ALL;
				data table1;
					retain Variable Level &colvars;
					length Variable Level &colvars $200;
					set table1 cont_&var.;
				run;
			%end;
		%end;
	%end;
%end;
/* template to make the font smaller in the output */
proc template;
   define style styles.smaller;
   parent = styles.printer;
      class fonts from fonts /  /* Reduce all sizes by 2pt */
            'TitleFont2' = ("Times",9pt,Bold Italic)
            'TitleFont' = ("Times",11pt,Bold Italic)
            'StrongFont' = ("Times",8pt,Bold)
            'EmphasisFont' = ("Times",9pt,Italic)
            'FixedEmphasisFont' = ("Courier New, Courier",7pt,Italic)
            'FixedStrongFont' = ("Courier New, Courier",7pt,Bold)
            'FixedHeadingFont' = ("Courier New, Courier",7pt,Bold)
            'BatchFixedFont' = ("SAS Monospace, Courier New, Courier",5pt)
            'FixedFont' = ("Courier New, Courier",7pt)
            'headingEmphasisFont' = ("Times",9pt,Bold Italic)
            'headingFont' = ("Times",9pt,Bold)
            'docFont' = ("Times",8pt);
      class Table from Output /
            rules = ALL
            cellpadding = 2pt     /* Reduced from 4pt to 2pt */
            cellspacing = 0.25pt
            borderwidth = 0.75pt;
   end;
run;

/* saving output to file */
options orientation=landscape;
ods rtf file="&out.&fname." style=styles.smaller;
proc print data=table1;
run;
title;
ods rtf close;

%mend weighted_table;
