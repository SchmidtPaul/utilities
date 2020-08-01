;/***************************************************************************************/
/* This macro computes a block-diagonal variance-covariance matrix for adjusted means  */
/* computed for several trials                                                         */
/* Prior to use of this macro the means must be computed using MIXED, GLIMMIX or       */
/* HPMIXED using the trial ID in by statements                                         */
/* The COV option to the LSMEANS statement must be used to get the R matrix of each    */
/* individual trial                                                                    */
/* data=        Name of SAS dataset containing the adjusted means and their R matrix,  */
/*              to avoid problems no data sets with names starting with xa should be   */
/*              used, as these data sets were used within the macro                    */
/* by=          First variable of the by statement                                     */
/* by2=         Optional second variable of the by statement                           */
/* by3=         Optional third variable of the by statement                            */
/* by4=         Optional fourth variable of the by statement                           */
/* entry=       Name of variable identifying entries in the lsmeans dataset. You can   */
/*              use more than one variable using the statement %str(). If you use more */
/*              than one entry variable, the order of them in the class statement 	   */
/*              within PROC MIXED and in %str() should be identical    				   */
/* outL=        Name of SAS dataset into which the big R matrix is to be stored for    */
/*              later use as both dataset and with the LDATA option for a LIN(1)       */
/*               structure in aREPEATED statement                                      */
/*                                                                                     */
/* The following statements must be used in the subsequent MIXED or GLIMMIX call for   */
/* analysis of the adjusted means in the lsmeans dataset                               */
/*                                                                                     */
/*  class row xtrial                                                                   */
/*  repeated row/subject=xtrial type=lin(1) ldata=<outL>;                              */
/*  parms (1)^n        (1) /hold="n+1";                                                */
/*                                                                                     */
/*                                                                                     */
/*  where "n+1" is the number of variance components of the corresponding model. If    */
/*  there are four variance components of random effects (effects except of the error  */
/*	the statements will be:                         								   */
/*                                                                                     */
/*  It is not allowed to have the variables parm, row, xtrial and xg within the        */
/*  datasets, again, as these variables are created during creating weights.           */
/***************************************************************************************/
;/***************************************************************************************/
%macro get_one_big_omega(data=, by=, by2=, by3=, by4=, entry=, outL=);
data xa1;set &data;xtrial=1;run;
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

proc means data=xa3 noprint;       
var estimate;
output out=xa42 n=n_means;
run;
data xa42;
set xa42;
call symput('n_means',trim(left(n_means))); 
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

proc means data=xa3 noprint;       
by xtrial ;                        
output out=xa43 n=n;
run;
data xa5;
parm=1;
array col col1-col&n_means;
array cov cov1-cov&n_cov;
row0=0;
done=0;
i=1;


do i=1 to n_cases;
set xa43 point=i nobs=n_cases;
cases=i;
  do j=1 to n;
  num=n;
    do ii=1 to &n_means;
      col[ii]=0;
    end;
	row0=row0+1;
    set xa3 point=row0;               
	row=row0;
    do k=done+1 to done+n;
	  col[k]=cov[k-done];
	end;
	output;
  end;
  done=done+n;
end;
stop;
run;
data &outl;set xa5;
keep parm &by &by2 &by3 &by4 xtrial row &entry estimate col1-col&n_means effect stderr;
run;
Proc datasets library=work;
delete xa1-xa5 xa41-xa43 ;
run;quit;
%mend get_one_big_omega;
;


