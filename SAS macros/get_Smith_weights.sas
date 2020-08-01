/***************************************************************************************/
/* This macro computes weights from the diagonal elements of the variance-covariance   */
/* matrix for adjusted means of several trials                                         */
/* Prior to use of this macro the means must be computed using MIXED, GLIMMIX or       */
/* HPMIXED using up to four by variables                                               */
/* The COV option to the LSMEANS statement must be used to get the R matrix of each    */
/* individual trial within the ods table of lsmeans                                    */
/* data=        Name of SAS dataset containing the adjusted means and their R matrix,  */
/*              to avoid problems no data sets with names starting with xa should be   */
/*              used, as these data sets were used within the macro                    */
/* by=          First variable of the by statement                                     */
/* by2=         Optional second variable of the by statement                           */
/* by3=         Optional third variable of the by statement                            */
/* by4=         Optional fourth variable of the by statement                           */
/* entry=       Name of variable identifying entries in the lsmeans dataset. You can   */
/*              use more than one variable using the statement %str(). If you use more */
/*              than one entry variable, the order of them in the class statement with */
/*              PROC MIXED and in %str() should be identical        				   */
/* outL=        Name of SAS dataset into which the updated dataset with weights        */
/*              is to be stored. The name can be identical with the original data set  */
/*                                                                                     */
/* The following statements must be used in the subsequent MIXED or GLIMMIX call for   */
/* analysis of the adjusted means in the lsmeans dataset                               */
/*                                                                                     */
/*  weight weight_Smith;                                                               */
/*  parms (1)^n        (1) /hold="n+1";                                                */
/*                                                                                     */
/*  where "n+1" is the number of variance components of the corresponding model. If    */
/*  there are four variance components of random effects (effects except of the error  */
/*	the statements will be:                         								   */
/*                                                                                     */
/*  weight weight_Smith;                                                               */
/*  parms (1)(1)(1)(1)(1) /hold=5;                                                     */
/*                                                                                     */
/*  It is not allowed to have the variables weight_Smith, xtrial and xg within the     */
/*  datasets, again, as these variables are created during creating weights.           */
/***************************************************************************************/
%macro get_Smith_weights(data=, by=, by2=, by3=, by4=, entry=, outL=);
data xa1;
set &data;
xtrial=1;
run;
Proc sort data=xa1;by xtrial &by &by2 &by3 &by4;run;
Proc means noprint data=xa1;by xtrial &by &by2 &by3 &by4;output out=xa2;run;
data xa1;set xa1;xg=1;drop xtrial;run;
data xa2;set xa2;where _stat_='MEAN';xtrial=_n_;xg=1;keep xg xtrial &by &by2 &by3 &by4;run;
Data xa3;merge xa1 xa2;by xg &by &by2 &by3 &by4;drop xg;run;
proc sort data=xa3 ;     
by &entry;                     
run;

proc means data=xa3 noprint;
var estimate;
by &entry;
output out=xa4 mean=;
run;

proc means data=xa4 noprint;
var estimate;
output out=xa41 n=n_cov;
run;

data xa41;
set xa41;
call symput('n_cov',trim(left(n_cov)));
run;
data xa4;set xa4;
xg=_n_;
keep xg &entry;
run;
data xa3;merge xa3 xa4;by &entry;run;

proc sort data=xa3 ;     
by xtrial;                     
run;

data xa3;
set xa3;
by xtrial;
first=first.xtrial;
run;

data xa5;
parm=1;
array col col1-col&n_cov;
array cov cov1-cov&n_cov;
row=0;
done=0;
i=1;
set xa3 point=i nobs=n_cases;
do i=1 to n_cases;
  set xa3 point=i;
  do j=1 to &n_cov;
    col[j]=cov[j];
  end;
  if first=1 then row=0;
  row=row+1;
  output;
end;
stop;
run;

data xa6;
xtrial=0;
parm=1;row=0;set xa5;
keep &entry xg estimate xtrial parm row col1-col&n_cov cov1-cov&n_cov;
run;

Proc rank data=xa6 out=xa6;
by xtrial;
var xg;ranks rows;
run;
data xa6;set xa6;row=rows;drop rows;run;
data xa7;
do row=1 to &n_cov;
xtrial=1;parm=1;xg=0;estimate=1;
output;end;
run;
data xa5;merge xa7 xa6;by xtrial row;run;
%do i=1 %to &n_cov;
data xa5;set xa5;
if col&i=. then col&i=0;
run;
%end;

ods output InvR=xaInvR;
proc mixed data=xa5;
by xtrial;
class xg row;
model estimate=xg;
repeated row/subject=intercept type=lin(1) ldata=xa5 ri;
parms (1)/hold=1 noiter;
run;

data xa8;set xa5;keep xtrial row xg;run;
data xa8;xg=0;merge xa8 xaInvR;by xtrial row;if xg=0 then delete; keep xtrial xg row col1-col&n_cov;run;
Proc sort data=xa8;by xg;run;
Proc sort data=xa4;by xg;run;
Data xa8;merge xa8 xa4;by xg;run;

data xaweights;
array col col1-col&n_cov;
set xainvR;
weight_Smith=col[row];
keep xtrial row weight_Smith;
run;

data xa9;
merge xa5 xaweights;
if xg=0 then delete;
by xtrial row;
drop xg row parm;
run;
data xa9;merge xa2 xa9;by xtrial;drop xtrial ;run;
Proc sort data=xa9;by &by &by2 &by3 &by4 &entry;run;
Proc sort data=&data;by &by &by2 &by3 &by4 &entry;run;
data &outL;merge &data xa9;by &by &by2 &by3 &by4 &entry;drop col1-col&n_cov;run;
Proc datasets library=work;
delete xa1-xa9 xa41 xaweights xainvR;
run;quit;
%mend get_Smith_weights;
;

