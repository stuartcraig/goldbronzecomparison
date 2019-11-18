cd ~/Desktop
adopath + ~/Dropbox/ado_shared

clear
set obs 30000
gen claims = _n

// Plan characteristics
	gen dBronze = 5750
	gen dGold = 0
	
	gen cBronze = 0.5
	gen cGold	= 0.35 // rough estimate
	
	gen pBronze = 406
	gen pGold	= 683
	
	gen mBronze = 8150
	gen mGold	= 7000
	// Annualize premiums
	foreach v of varlist p* {
		qui replace `v' = `v'*12
	}

// Calculate OOP for each
* loc t = "Bronze"
	foreach t in Bronze Gold {
	cap drop temp_remainder
	qui gen temp_remainder = claims
	
	cap drop temp_underdeductible
	qui gen temp_underdeductible = min(claims,d`t')
	qui replace temp_remainder = temp_remainder - temp_underdeductible
	
	cap drop temp_cum
	qui gen temp_cum = min(temp_remainder*c`t' + temp_underdeductible,m`t')
	rename temp_cum oop`t'
	drop temp*
	}
	
// At which points does Gold dominate
	qui gen net = (oopGold + pGold) - (oopBronze + pBronze)
	qui gen domGold = net<0
	qui summ claims if domGold
	loc min = r(min)
	loc max = r(max)

	loc nl "0 10000 20000 30000 `min' `max'"
	foreach n in  0 10000 20000 30000 `min' `max' {
		loc fn: di %10.0fc `n'
		label define claims `n' "`fn'", modify
	}
	
// Show the figure	
	tw line oopGold claims, lw(medthick) ///
		|| line oopBronze claims, lw(medthick) ///
		xline(`min' `max', lc(black) lw(medthick)) ///
		xtitle("Incurred Claims ($)") ytitle("OOP Payments ($)") ///
		ylab(,format(%10.0fc)) xlab(`nl',val format(%10.0fc)) ///
		legend(order(1 "Gold" 2 "Bronze") ring(0) pos(5))
	graph export goldbronze_comparison.png, width(2000) replace



