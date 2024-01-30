/*
	L = dependent variable (e.g. reported to policy; working)
	X = reported value of explanatory (e.g. victim; disable)
	W = actual value of explanatory 
	nu = lower bound on prob of accurate reports of X:
		P(Z=1) where Z=1 iff X=W
*/

//program drop mivKrepper
program mivKrepper, rclass
	syntax varname(numeric max=3) [if] [in] , nu(numlist) [verified(varlist max=1)]
	tempvar X L Y MIV
	qui{		
		marksample touse
		tokenize `varlist'
							
		gen `L'  = `1'
		gen `X' = `2'
		gen `MIV' = `3'

		levelsof `MIV', local(unique_values)

		matrix mLB = J(1,1,.)
		matrix mLB_no = J(1,1,.)
		matrix mUB = J(1,1,.)
		matrix mP = J(1,1,.)
		matrix mCoords = J(1,1,.)
		
		count if `touse'
		local N= r(N)
		foreach v of local unique_values {
		  
			count if `MIV' == `v' & `touse'
			local nv= r(N)
			local pi = `nv' / `N'
				
			if("`verified'" == ""){
				krepper `L' `X' if `MIV' == `v' & `touse' , nu(`nu') 
			}
			else{
				krepper `L' `X' if `MIV' == `v' & `touse', nu(`nu')  verified(`verified')
			}
			
			matrix mLB = mLB \ r(lb)
			matrix mUB = mUB \ r(ub)
			matrix mLB_no = mLB_no \ r(lb_no)
			matrix mP = mP \ `pi'	
			matrix mCoords = mCoords \ `v'
		}


		matrix mLB = mLB[2...,1...]
		matrix mUB = mUB[2...,1...]
		matrix mLB_no = mLB_no[2...,1...]
		matrix mP = mP[2...,1...]
		matrix mCoords = mCoords[2...,1...]
		
		matrix toPrint = mCoords, mLB, mLB_no, mUB
		capture drop toPrint*
		svmat toPrint
		replace toPrint1 = round(toPrint1, 0.001)
		replace toPrint2 = round(toPrint2, 0.001)
		replace toPrint3 = round(toPrint3, 0.001)
		replace toPrint4 = round(toPrint4, 0.001)

		mata: miv()

		return matrix mLB = mLB
		return matrix mUB = mUB
		return matrix mLB_no = mLB_no
		return matrix mP = mP
		return scalar mivL = mivL
		return scalar mivU = mivU
	}
	
	if("`verified'" == ""){
		krepper `L' `X' if  `touse' , nu(`nu') 
	}
	else{
		krepper `L' `X' if  `touse', nu(`nu')  verified(`verified')
	}
		
	local lb_standard = r(lb)
	local ub_standard = r(ub)
	local lb_standardNo = r(lb_no)
	local mivL = mivL
	local mivU = mivU
	twoway pcspike toPrint2 toPrint1 toPrint4 toPrint1, mlabcolor(gs10) lcolor(gs10) legend(off)|| ///
		scatter toPrint2 toPrint1, msym(o) mlabel(toPrint2) mcolor(gs10) mlabcolor(gs10) || ///
		scatter toPrint4 toPrint1, msym(o) mcolor(gs10) mlabcolor(gs10) mlabel(toPrint4, ) ///
		yline(`lb_standard',lcolor(black) lpattern(dash)) ///
		  yline(`ub_standard', lcolor(black) lpattern(dash)) /// 
		  yline(`mivL', lcolor(black)) yline(`mivU', lcolor(black)) ///
		  graphregion(color(white)) graphregion(margin(large)) ///
		  xtitle("")


	
	display "Kreider-Pepper Nonparametric bounds"
	display ""
	display "Monotone Instrumental Variables."
	display "-----------------------------------------------------"
	display ""
	display "ATE:  " _column(16) "[" %9.4f mivL "," %9.4f mivU "]"
	display "-----------------------------------------------------"

end

//clear mata
mata:
void miv()
{
		real scalar i, n, r 
		real matrix mL, mU, mAuxL, mAuxU, mivL, mivU

		mL = st_matrix("mLB")
		mU = st_matrix("mUB")
		mP = st_matrix("mP")
		R =rows(mL)
		
		mAuxL = J(1,1,.)
		mAuxU = J(1,1,.)
		
		for(r = 1; r<= R; r++){
	
			mAuxL = mAuxL \ colmax(mL[1..r,1])
			mAuxU = mAuxU \ colmin(mU[r..R,1])
		
		}
		mAuxL[2..R+1,1]
		mAuxU[2..R+1,1]
		
		mivL = colsum(mAuxL[2..R+1,1] :* mP)
		mivU = colsum(mAuxU[2..R+1,1] :* mP)
		
		st_numscalar("mivL", mivL)
		st_numscalar("mivU", mivU)
		
		
}
void imbensManski(scalar N, scalar ub, scalar lb, scalar sd_u, scalar sd_l)
{

	real scalar  c, fa, fb, fc, lower, upper, eps_abs, eps_step, a, b;
	printf("Initial values" )
	
	ub 
	
	lb
	
	eps_abs = 1e-5;
	eps_step = 1e-5;
	a = 0;
	b =40;
	
			  
	
	fa = obfn(a, N, ub, lb, sd_l, sd_u);
	fb = obfn(b,N, ub, lb, sd_l, sd_u);

	if( fa*fb>0){

		printf("Error: Initial function has same sign at both end points");
		fa;
		fb;
		a= 1.645
		b= 1.645
	}
	else{
		while (abs(b - a) >= eps_step |  ( abs(fa) >= eps_abs & abs(fb) >= eps_abs )) {
			c = (a + b)/2;
			fc =obfn(c,N, ub, lb, sd_l, sd_u);
			if ( fc == 0 ){
				break;
			}
			else if (fa*fc <0){
				b = c;
				fb =obfn(b,N, ub, lb, sd_l, sd_u);
			}
			else{
				a = c;
				fa =obfn(a,N, ub, lb, sd_l, sd_u);
			}

			
		}
	}
	printf("solution");
	fa;
	//fb;fc;
	printf("Critical value: ");a;

	lower = lb -(a*sd_l);
	upper = ub +(a*sd_u);

	printf("upper bound "); ub;
	printf("upper bound ci"); upper;
	printf("lower bound "); lb;
	printf("lower bound ci"); lower
	
	st_numscalar("imbensManski_l", lower)
	st_numscalar("imbensManski_u", upper)

}



real scalar obfn(scalar x, scalar N, scalar ub, scalar lb, scalar sd_l, scalar sd_u)
{
	real scalar s, fx
	s = sqrt(N)*(ub-lb)/colmax(sd_u\sd_l);
	fx = normal(x+s) - normal(-x) - 0.95;
	return (fx);

}

end

//program drop krepper
program krepper, rclass

syntax varname(numeric max=2) [if] [in]  , nu(numlist) [verified(varlist max=1)]
tempvar X L Y
 		
	marksample touse
	tokenize `varlist'
	qui{					
		gen `L'  = `1'
		gen `X' = `2'

		count if `touse'
		local N = r(N)
		display `N'

		if("`verified'" == ""){
			
			qui{
			count if `X' == 1 & `touse'
			local pX1 = r(N) / `N'

			count if `L' == 1 & `X' == 1 & `touse'
			local pL1X1 = r(N) / `N'

			count if `L' == 0 & `X' == 1 & `touse'
			local pL0X1 = r(N) / `N'

			count if `L' == 0 & `X' == 0 & `touse'
			local pL0X0 = r(N) / `N'

			count if `L' == 1 & `X' == 0 & `touse'
			local pL1X0 = r(N) / `N'
			}

			local condition1  = `pL1X1' - `pL0X1' - (1-`nu')
			local condition2  = `pL1X1' - `pL0X1' + (1-`nu')

			if(`condition1' <= 0) {

				local delta = min((1-`nu'), `pL1X1')
			}
			else {
				local delta = max(0, (1-`nu')-`pL0X0' )
			}

			if(`condition2' <= 0) {

				local gamma = min((1-`nu'), `pL1X0')
			}
			else {
				local gamma = max(0, (1-`nu')-`pL0X1' )
			}



			local lb = (`pL1X1' - `delta') / (`pX1' - 2*`delta' +(1-`nu'))
			local lb_noOr =  `pL1X1' / (`pX1'+(1-`nu'))
			local ub = (`pL1X1' + `gamma') / (`pX1' +2*`gamma' -(1-`nu'))

		}
		else{
			
			gen `Y' = `verified'
			qui{
			count if `L' == 1 & `X' == 1 &`Y'==1 & `touse'
			local pL1X1Y1= r(N) / `N'
			
			count if `X' == 1 & `Y' == 1 & `touse'
			local pX1Y1 = r(N) / `N'

			count if `L' == 0 &`Y'==0 & `touse'
			local pL0Y0= r(N) / `N'
			
			count if `Y'==1 & `touse'
			local pY1= r(N) / `N'
			
			count if `L' == 1 &`Y'==0 & `touse'
			local pL1Y0= r(N) / `N'
			
			count if `X' == 1 & `Y' == 1  & `touse'
			local pX1Y1= r(N) / `N'

			count if `L' == 0 & `X' == 0 &`Y'==1 & `touse'
			local pL0X0Y1= r(N) / `N'
			
			count if `L' == 1 & `X' == 1 & `touse'
			local pL1X1= r(N) / `N'
			
			count if `L' == 1 & `X' == 0 & `touse'
			local pL1X0= r(N) / `N'
			
			count if `L' == 0 & `X' == 1 &`Y'==1 & `touse'
			local pL0X1Y1= r(N) / `N'
			
			count if `L' == 0 & `Y' == 0 & `touse'
			local pL0Y0= r(N) / `N'
			
			count if `L' == 1 & `Y' == 0 & `touse'
			local pL1Y0= r(N) / `N'
			}
			local alpha1 = `pL1X1Y1' - `pL0X1Y1' - `pL0Y0' - (1-`nu')*`pY1'
			local alpha2 = `pL1X1Y1' - `pL0X1Y1' + `pL1Y0' + (1-`nu')*`pY1'

			if(`alpha1' <= 0) {

				local delta = min((1-`nu')*`pY1', `pL1X1')
			}
			else {
				local delta = max(0, (1-`nu')*`pY1'-`pL0X0Y1' )
			}

			if(`alpha2' <= 0) {

				local gamma = min((1-`nu')*`pY1', `pL1X0')
			}
			else {
				local gamma = max(0, (1-`nu')*`pY1'-`pL0X1Y1' )
			}
		
			local lb = (`pL1X1Y1' - `delta') / (`pX1Y1' +`pL0Y0'- 2*`delta' +(1-`nu')*`pY1')
			local lb_noOr = (`pL1X1Y1') / (`pX1Y1' +`pL0Y0'+(1-`nu')*`pY1')
			local ub = (`pL1X1Y1' +`pL1Y0'+ `gamma') / (`pX1Y1' +`pL1Y0'+2*`gamma' -(1-`nu')*`pY1')

			
			

		}
		return scalar lb = `lb'
		return scalar lb_no = `lb_noOr'
		return scalar ub = `ub'
	}
	display ""
	display "Kreider-Pepper Nonparametric bounds"
	display "-----------------------------------------------------"
	display ""
	display "ATE:  " _column(16) "[" %9.4f `lb' "," %9.4f `ub' "]"
	display ""
	display "No over-reporting"
	display "ATE:  " _column(16) "[" %9.4f `lb_noOr' "," %9.4f `ub' "]"
	display "-----------------------------------------------------"

end


