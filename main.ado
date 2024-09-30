/*
	Code for "Partial Identification of the Dark Figure of Crime   
		with survey data under misreporting errors."
	
	This version: 11 July 2024.
	
	This code call two additional files	
		- functions.ado contains the main programs for estimation of the bounds.
		- datapreparation.ado compiles the waves of the CSEW.
	
	

*/

include "/Users/user/Desktop/kreiderPepper/functions.ado"
include "/Users/user/Desktop/kreiderPepper/datapreparation.ado"



local outcome copsknow 
local explanatoryVariables female trueAge age80plus marital2-marital7 nchil higherEd drop16Ed gor_r1-gor_r10 ///
	 ethi*  whopresc polatt7 ethn1-ethn5 rural imdT imdC  dislikesPolice
	
// 1. Descriptive Statistics. 
//===========================================================================
estpost sum `outcome' `explanatoryVariables'
est store des1
estpost sum `outcome' `explanatoryVariables' if crimtype !=.
est store des2

esttab des1 des2 
esttab des1 des2 using "/Users/user/Desktop/kreiderPepper/output/descriptives.tex", ///
mtitle("All" "Experienced crime") ///
	cells(mean(fmt(2)) sd(par fmt(2))) label booktabs nonum collabels(none) gaps f noobs ///
	replace se star(* 0.1 ** 0.05 *** 0.01) b(%9.3f) se(%9.3f) ///
	coeflabels("Female" "Age")


// 2. Does partner presence affect crime rates?
//===========================================================================
local explanatoryVariables female trueAge age80plus nchil higherEd drop16Ed incomDep ethi* dislikesP rural i.gor
matrix mRES = J(25,2,.)
forvalues i=1/25{

	qui probit tipo`i' whopresc `explanatoryVariables' if crimtype!=., clus(clusters)
	margins, dydx(whopresc) post
	matrix v= r(table)
	matrix mRES[`i',1] = v[1,1]
	matrix mRES[`i',2] = v[4,1]


}
matrix list mRES
outtable using "/Users/user/Desktop/kreiderPepper/output/effect_partner.tex", replace mat(mRES) center f(%9.3f)

* Note: To simplify, Table 2 in paper based on "crime_personal" and the aggregate below for "property crime"
/*gen pc = crime_car == 1|crime_home ==1
probit  pc whopresc female trueAge age80plus nchil higherEd drop16Ed incomDep ethi* dislikesP rural i.gor if crimtype!=., clus(clusters)
margins, dydx(whopresc) post*/


// 3. Dark figure of crime. 
//===========================================================================
// 3.1. Determinants of "cops know" 

local explanatoryVariables female trueAge age80plus nchil higherEd drop16Ed incomDep ethi* dislikesP rural i.gor i.crimtype
probit copsknow `explanatoryVariables'  if crimtype!=. , clus(clusters)  
margins, dydx(*) post
outreg2 using "/Users/user/Desktop/kreiderPepper/output/copsknowProbit.tex", tex replace
 
// 3.2. Determinants by type of crime. 
   
 graph hbar (mean) cops copsknow if crimtype <=25, ///
 over(crimtype, relabel(1 "Vehicle stolen" ///
2 "Something stolen from vehicle"  ///
3 "Vehicle deliberately damaged" ///
4 "Bike theft" ///
5 "Someone got in to steal (p.h.)" ///
6 "Someone got in to damage property (p.h.)" ///
7 "Someone tried to get in to steal/damage (p.h.)" ///
8 "Something stolen (p.h.)" ///
9 "Something stolen outside the house (p.h.)" ///
10 "Deliberate deface/damage to house outside (p.h.)" ///
11 "Someone got in and stole/tried to steal (n.p.)" ///
12 "Someone got in to steal" ///
13 "Someone got in to damage property" ///
14 "Someone tried to get in to steal/damage" ///
15 "Something stolen" ///
16 "Something stolen outside the house" ///
17 "Deliberate deface/damage to house outside" ///
18 "Personal theft" ///
19 "Someone tried (personal theft)" ///
20 "Something stolen from cloakroom, an office, a car" ///
21 "Something owned deliberately damaged/tampered" ///
22 "Person was hit/used violence or force against" ///
23 "Threaten in a way that frightened respondent" ///
24 "Sexually attacked" ///
25 "Household violence") ///
 label(angle(horizontal) labsize(small)) ) ///
 blabel(bar, format(%9.3f))  yline( .38674) graphregion(color(white)) ///
 bar(1, fcolor(black) )  ytitle(Proportion known to police)
   
   
// Bounds.  
//===========================================================================
* All types

* No verified group.
local B= 19
matrix mBounds = J(10,3,.)
local i =1
local _proportion 0.5 0.75 0.9 0.95 0.99
foreach j of local _proportion {
	
	count if crimevic==1
	local _N= r(N)
	local nu = `j'
	
	bs lb =r(lb) lb_no=r(lb_no) ub=r(ub), rep(`B'):krepper copsknow crimevic, nu(`nu') 
	
	matrix v = r(table)
	local lb_temp = v[1,1]
	local lb_noTemp = v[1,2]
	local ub_temp = v[1,3]
	local lb_se = v[2,1]
	local lb_noSe = v[2,2]
	local ub_se = v[2,3]
	
	mata:imbensManski(`_N', `ub_temp', `lb_temp',`ub_se', `lb_se')
	
	display "[`lb_temp', `ub_temp']"
	display "[",imbensManski_l,"", imbensManski_u,"]"
	
	matrix mBounds[`i',1] = `lb_temp'
	matrix mBounds[`i',3] = `ub_temp'		
	matrix mBounds[`i'+1,1] = imbensManski_l
	matrix mBounds[`i'+1,3] = imbensManski_u
	
	mata:imbensManski(`_N', `ub_temp', `lb_noTemp',`ub_se', `lb_noSe')
	
	display "[`lb_noTemp', `ub_temp']"
	display "[",imbensManski_l,"", imbensManski_u,"]"
	
	matrix mBounds[`i',2] = `lb_noTemp'	
	matrix mBounds[`i'+1,2] = imbensManski_l
	
	local i = `i' + 2
	
}
matrix list mBounds

local B= 99
matrix mBoundsVer = J(24,3,.)
local i=1
forvalues k = 1/6{
	forvalues r = 0.95(0.05)1{
		qui count if crimevic==1
		local _N= r(N)
		
		
		bs lb =r(lb) lb_no=r(lb_no) ub=r(ub), rep(`B'):krepper copsknow crimevic, nu(`r') verified(alt_def`k')
		matrix v = r(table)
		local lb_temp = v[1,1]
		local lb_noTemp = v[1,2]
		local ub_temp = v[1,3]
		local lb_se = v[2,1]
		local lb_noSe = v[2,2]
		local ub_se = v[2,3]
		matrix mBoundsVer[`i',1] = `lb_temp'
		matrix mBoundsVer[`i',2] = `lb_noTemp'
		matrix mBoundsVer[`i',3] = `ub_temp'
		
		qui mata:imbensManski(`_N', `ub_temp', `lb_temp',`ub_se', `lb_se')		
		matrix mBoundsVer[`i'+1,1] = imbensManski_l
		matrix mBoundsVer[`i'+1,3] = imbensManski_u
		
		qui mata:imbensManski(`_N', `ub_temp', `lb_noTemp',`ub_se', `lb_noSe')		
		matrix mBoundsVer[`i'+1,2] = imbensManski_l
		
		
		local i= `i'+2
		
	}
}



matrix list mBoundsVer
matrix rownames mBoundsVer = 0.95 . 1 . 0.95 . 1 . 0.95 . 1 . 0.95 . 1 . 0.95 . 1 . 0.95 . 1 .
matrix colnames mBoundsVer = LB LB-No UB
outtable using "/Users/user/Desktop/kreiderPepper/output/boundsVerified_R1.tex" , mat(mBoundsVer) ///
	nobox center format(%9.3f) norowlab nodots replace
                     
 
** MIV

gen likesPolice = polatt7
replace likesPolice = . if likesPolice >5
replace likesPolice = 6-likesPolice

mivKrepper copsknow crimevic likesPolice,  nu(0.75) 
graph export  "Users/user/Desktop/kreiderPepper/output/miv_all75.jpg", replace
mivKrepper copsknow crimevic likesPolice,  nu(0.90) 
graph export "/Users/user/Desktop/kreiderPepper/output/miv_all90.jpg", replace


matrix gorBounds =J(10,2,.)

forvalues k=1/10 {
mivKrepper copsknow crimevic likesPolice if gor==`k',  nu(0.9)
matrix gorBounds[`k',1] = r(mivL)
matrix gorBounds[`k',2] = r(mivU)
}
svmat gorBounds
preserve

keep gorBounds* 
gen diff = gorBounds2-gorBounds1
 gen diff2 = round(diff, 0.001)
 replace gorBounds2 = round(gorBounds2, 0.001)
 replace gorBounds1 = round(gorBounds1, 0.001)
 
gen id = _n
keep if gorBounds1 !=.
save "/Users/user/Desktop/kreiderPepper/NUTS/bound_area_90.dta"

* Geo Analysis
use "/Users/user/Desktop/kreiderPepper/NUTS/nuts.dta", clear
use dbuk, clear
merge 1:1 id using "/Users/user/Desktop/kreiderPepper/NUTS/bound_area_90.dta"
spmap diff2 using ukcoord if id<11, id(id)  /// 
clnumber(9) legend(pos(11) ring(0))


spmap gorBounds1 using ukcoord if id<11, id(id)  /// 
clnumber(9) legend(pos(11) ring(0))
spmap gorBounds2 using ukcoord if id<11, id(id)  /// 
clnumber(9) legend(pos(11) ring(0))


// Bounds for categoreis in table 2
// Tipo 22, 24, 25 and crime_personal and pc = crime_car == 1|crime_home ==1



local B= 199
matrix mBounds = J(10,3,.)
local i =1
local _proportion 0.5 0.75 0.9 0.95 0.99
foreach j of local _proportion {
	
	count if crimevic==1
	local _N= r(N)
	local nu = `j'
	
	bs lb =r(lb) lb_no=r(lb_no) ub=r(ub), rep(`B'):krepper copsknow crimevic if tipo25 ==1 , nu(`nu') 
	
	matrix v = r(table)
	local lb_temp = v[1,1]
	local lb_noTemp = v[1,2]
	local ub_temp = v[1,3]
	local lb_se = v[2,1]
	local lb_noSe = v[2,2]
	local ub_se = v[2,3]
	
	mata:imbensManski(`_N', `ub_temp', `lb_temp',`ub_se', `lb_se')
	
	display "[`lb_temp', `ub_temp']"
	display "[",imbensManski_l,"", imbensManski_u,"]"
	
	matrix mBounds[`i',1] = `lb_temp'
	matrix mBounds[`i',3] = `ub_temp'		
	matrix mBounds[`i'+1,1] = imbensManski_l
	matrix mBounds[`i'+1,3] = imbensManski_u
	
	mata:imbensManski(`_N', `ub_temp', `lb_noTemp',`ub_se', `lb_noSe')
	
	display "[`lb_noTemp', `ub_temp']"
	display "[",imbensManski_l,"", imbensManski_u,"]"
	
	matrix mBounds[`i',2] = `lb_noTemp'	
	matrix mBounds[`i'+1,2] = imbensManski_l
	
	local i = `i' + 2
	
}
matrix list mBounds
