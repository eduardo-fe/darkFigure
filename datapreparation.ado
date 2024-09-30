
forvalues i= 12/19 {

	local j = `i' +1
	use "/Users/user/Documents/datasets/csew/stata/stata13_se/csew_apr`i'mar`j'_vf.dta", clear
	keep rowlabel copsknow crimtype

	merge m:1 rowlabel using "/Users/user/Documents/datasets/csew/stata/stata13_se/csew_apr`i'mar`j'_nvf.dta"
	gen cknow = copsknow == 1
	gen crimevic = crimtype!=.
	
	display "Wave is `i'"
	local commonVars asbneigh noisneg1 asbprob asbexp teenhang rubbish vandals druguse ///
	drunk abancar pfilter pfoot  ratpol2 ///
	wburgl wmugged wcarstol wfromcar wraped   ///
	 polatt1 polatt2 polatt3 polatt5  polatt6  ///
	polatt7 rowlabel copsknow crimtype age sex livharm1a gor ethgrp2a whopresc nchil
	
	local specific12 emdidec3 wmdidec4 rural2 educat2 ecridec3 wcridec4
	local specific13 emdidec3 wmdidec4 educat2 rural3 ecridec3 wcridec4
	local specific14 emdidec3 wmdidec4 educat2 rural3 ecridec3 wcridc14
	local specific15 emdidec3 wmdidc14 educat2 rural3 ecridc15 wcridc14
	local specific16 emdidc15 wmdidc14 educat2 rural3 ecridc15 wcridc14
	
	if(`i' == 12) {
	
		keep  `commonVars' `specific12'
		rename (emdidec3 wmdidec4 educat2 rural2  ecridec3 wcridec4)(imdE imdW  educat rural imdCe imdCw)
	}
	else if (`i' ==13) {
		keep  `commonVars' `specific13'
		rename (emdidec3 wmdidec4 educat2 rural3 ecridec3 wcridec4)(imdE imdW  educat rural imdCe imdCw)
	}
	else if (`i'  ==14) {
		keep  `commonVars' `specific14'
		rename (emdidec3 wmdidec4 educat2 rural3 ecridec3 wcridc14)(imdE imdW  educat rural imdCe imdCw)
	}
	else if (`i' ==15) {
		keep  `commonVars' `specific15'
		rename (emdidec3 wmdidc14 educat2 rural3 ecridc15 wcridc14) (imdE imdW  educat rural imdCe imdCw)
	}
	else if (`i' >15 ) {
		keep  `commonVars' `specific16'
		rename (emdidc15 wmdidc14 educat2 rural3 ecridc15 wcridc14) (imdE imdW  educat rural imdCe imdCw)
	}

	gen wave = `i'
	save "/Users/user/Documents/datasets/csew/data_for_analysis/data`i'_`j'.dta", replace

}

local datadir "/Users/user/Documents/datasets/csew/data_for_analysis/"

use `datadir'data12_13.dta, clear
append using "`datadir'data13_14.dta" 
append using "`datadir'data14_15.dta" 
append using "`datadir'data15_16.dta" 
append using "`datadir'data16_17.dta" 
append using "`datadir'data17_18.dta" 
append using "`datadir'data18_19.dta" 
append using "`datadir'data19_20.dta" 

egen imdT = rowmax(imdE imdW)
egen imdC = rowmax(imdCe imdCw)


gen female = sex==2
rename rural urban
gen rural = urban == 2
forvalues j = 1/3 {

	gen aux`j' = polatt`j' == 5
	
}
forvalues j = 5/7 {

	gen aux`j' = polatt`j' == 5
	
}
egen mistrusts = rowtotal(aux1 aux2 aux3 aux5 aux6 aux7) // Drop if mistrust >=3
replace copsknow =. if copsknow >2
recode copsknow (2=0)
gen crimevic = crimtype!=.

gen dislikesPolice = mistrusts >=3
gen crimeDeprived = imdC <=5
gen incomDeprived = imdT <=5
gen withPartner = whopresc ==1




*termporary catergories 
gen higherEd = educat == 1|educat == 2|educat == 3
gen drop16Ed = educat ==5|educat ==6|educat ==7|educat ==8
replace higherEd =. if educat >10
replace drop16Ed =. if educat >10
qui tab gor, gen(gor_r)
qui tab livharm1a, gen(marital)
qui tab ethgrp2a, gen(ethn)
qui tab crimtype, gen(tipo)
egen clusters = group(ethgr urban imdT)

* AGe is capped in some waves, and uncapped in other years

replace age = 80 if age >80 & age<200
replace age =. if age >120
gen age80plus = age ==80
gen age80less = age <80
gen trueAge = age80less*age
tab ethgrp2a, gen(ethi)


gen crime_car = crimtype >=1 & crimtype <=4
gen crime_home = crimtype >=5 & crimtype <=17
gen crime_personal = crimtype >=18 & crimtype <=21
gen crime_violent = crimtype >=22 & crimtype <=25


gen def1 = withPartner ==0
gen def3 = withPartner ==0 & crimeDeprived==0
gen def2 = withPartner ==0 & crime_car==1
gen def4 = withPartner ==0 & crime_car==1 & crimeDeprived==0

gen alt_def1 = withPartner ==0
gen alt_def2 = crimeDeprived==0
gen alt_def3 = crime_car==1
gen alt_def4 = withPartner ==0 & crimeDeprived==0
gen alt_def5 = withPartner ==0 & crime_car==1
gen alt_def6 = withPartner ==0 & crime_car==1 & crimeDeprived==0
