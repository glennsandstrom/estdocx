
// Character	ANSI 	Number 	Unicode Number	ANSI Hex
// †			134		8224	0x86	U+2020	&dagger;		
/******************************************************************************/
/** Script start                                                             **/
/******************************************************************************/
/* Clear datasets from memory if any are loaded */
	clear all
	set more off, permanently
	set varabbrev off, permanently
	/**************************************************************************/
	/*** Change working directory depending on OS so that all automatic   *****/
	/*** saves are located in this path                                   *****/
	/**************************************************************************/
	if c(os)== "MacOSX" {
		cd "/Users/Glenn/Box Sync/Stata programs/" /* Mac path */
		sysdir set PERSONAL "/Users/Glenn/Box Sync/Stata programs/ado/personal"
	}
	else if c(username)== "glsa0001" {
		cd "C:\Users\glsa0001\Box Sync\Stata programs"
		global  wordpath "C:\Program Files (x86)\Microsoft Office\Office15\WinWord.exe" 
		global  excelpath "C:\Program Files (x86)\Microsoft Office\Office15\EXCEL.exe" 
	}
	else if c(username) == "Glenn" {
		cd "F:\Box Sync\Stata programs"	
		global  wordpath "C:\Program Files (x86)\Microsoft Office\root\Office16\WinWord.exe"
		sysdir set PERSONAL  "C:\Users\Glenn\Box Sync\Stata programs\ado\personal\estimates_table_docx"
	}
	else if c(username)== "LENA" { //you need to change this to the username on your computer. Execute creturn list to find out
	// and add the path to your folder on your work computer here...se my syntax above
	}

capture rm test.docx

sysuse nlsw88, clear
notes

unique idcode

tab never_married

logistic never_married c.age i.race i.collgrad c.wage
estimates store base

logistic never_married c.age i.race i.collgrad c.wage c.grade
estimates store grade

logistic never_married c.age i.race i.collgrad c.wage c.grade c.tenure collgrad#race c.grade#c.tenure
estimates store tenure




mat drop _all



/******************************************************************************/
/** LOAD PROGRAM                                                            **/
/******************************************************************************/
do estimates_table_docx.ado
label variable race "Ethnicity"
label variable age "Age"
//mata: sig_param(.93807586, .00736294, ".05 .01 .001", "%9.2g")
mata: paramtype("1.race") // return locals: label paramtype
assert "`paramtype'"=="factor"
assert "`label'"=="Ethnicity"
assert "`vlab'"=="white"

mata: paramtype("_cons") 
assert "`paramtype'"=="constant"

mata: paramtype("age")
assert "`paramtype'"=="continious"

mata: paramtype("1b.race")
assert "`paramtype'"=="factor"
assert `base'
assert !`omit'

mata: paramtype("1o.race")
assert "`paramtype'"=="factor"
assert !`base'
assert `omit'


// interactions

mata: paramtype("0b.collgrad#1b.race") 
assert "`paramtype'"=="f#f"
assert `base'
assert !`omit'

mata: paramtype("1.collgrad#3.race") 
assert "`paramtype'"=="f#f"
assert !`base'
assert !`omit'

mata: paramtype("c.grade#c.tenure")
assert "`paramtype'"=="c#c"

mata: paramtype("1.collgrad#c.grade")
assert "`paramtype'"=="c#f"

mata: paramtype("0b.collgrad#co.grade")
assert "`paramtype'"=="c#f"
assert `base'
assert `omit'

mata: paramtype("co.grade#0b.collgrad")
assert "`paramtype'"=="c#f"
assert `base'
assert `omit'



// 0b.collgrad#co.grade
//1o.collgrad#1b.race
//1.collgrad#3.race
// c.grade#c.tenure





//mata: paramtype("1.race") // return locals: varname, level, base

//untit test of function get_models
get_models base grade tenure
return list
//assert r(numparams)==10
//assert r(params)=="age 1b.race 2.race 3.race 0b.collgrad 1.collgrad wage grade tenure _cons"

mat li r(model_betas)
//mat li r(model_p)

mat A= r(model_betas)
assert round(A[rownumb(A,"age") ,colnumb(A,"base")],.0000001)== .9380759
assert round(A[rownumb(A,"3.race") ,colnumb(A,"base")],.000001)== 1.463495
assert round(A[rownumb(A,"_cons") ,colnumb(A,"base")],.0000001)== .7183583

//assert round(A[rownumb(A,"2.race") ,colnumb(A,"tenure")],.00001)== 2.66407
//assert round(A[rownumb(A,"_cons") ,colnumb(A,"tenure")],.00001)== .69244

//run entire program for models base and grade
estimates_table_docx base grade tenure, saving("test.docx") star(0.1 .05 .01 .001) ///
title("Table 1: This is the title of the table") bdec(.001)

winexec $wordpath "test.docx"

estimates table base grade tenure, star(.05 .01 .001) b(%7.2f) stfmt(%7.1f) ///
stats(N) varwidth(30) eform 

makehlp, file(estimates_table_docx) replace
