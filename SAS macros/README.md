The SAS macros `%get_one_big_omega` and `%get_Smith_weights` are taken directly from the supplemental material of 
[Damesa, Tigist Mideksa, et al. "One step at a time: Stage‐wise analysis of a series of experiments." Agronomy Journal 109.3 (2017): 845-857.](https://acsess.onlinelibrary.wiley.com/doi/abs/10.2134/agronj2016.07.0395)

You may run the macro directly from SAS without donwloading it (given you have internet access) as:

*%get_Smith_weights*
`
FILENAME file_get_Smith_weights URL 
   'https://raw.githubusercontent.com/SchmidtPaul/utilities/master/SAS%20macros/get_Smith_weights.sas';
%INCLUDE file_get_Smith_weights;
`

*%get_one_big_omega*
`
FILENAME file_get_one_big_omega URL 
   'https://raw.githubusercontent.com/SchmidtPaul/utilities/master/SAS%20macros/get_one_big_omega.sas';
%INCLUDE file_get_one_big_omega;
`