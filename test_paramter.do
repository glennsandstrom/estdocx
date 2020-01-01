
// * Implement use of dagger character as significanse marker
// Character	ANSI 	Number 	Unicode Number	ANSI Hex
// †			134		8224	0x86	U+2020	&dagger;
// 
// * Routine paramtype() is not used any longer as the base and omitted indicators
//	 in the level is removed from the list of the unique paramters.
/******************************************************************************/
/** Script start                                                             **/
/******************************************************************************/
/* Clear datasets from memory if any are loaded */
	clear all
	set more off, permanently
	set varabbrev off, permanently
	discard
	/**************************************************************************/
	/*** Change working directory depending on OS so that all automatic   *****/
	/*** saves are located in this path                                   *****/
	/**************************************************************************/
	if c(username)== "glsa0001" {
		cd "C:\Users\Glenn\OneDrive - Umeå universitet\Stata programs\estimates_table_docx"
		global  wordpath "C:\Program Files (x86)\Microsoft Office\Office15\WinWord.exe" 
		global  excelpath "C:\Program Files (x86)\Microsoft Office\Office15\EXCEL.exe" 
	}
	else if c(username) == "Glenn" {
		cd "C:\Users\Glenn\OneDrive - Umeå universitet\Stata programs\estimates_table_docx"	
		global  wordpath "C:\Program Files (x86)\Microsoft Office\root\Office16\WinWord.exe"
		sysdir set PERSONAL  "C:\Users\Glenn\Box Sync\Stata programs\ado\personal"
	}


sysuse nlsw88, clear
notes
label variable race "Etnicity"

logit never_married c.age i.race b1.collgrad i.union c.wage c.grade c.tenure collgrad#race b1.collgrad#c.tenure
	mat M= r(table)
	//transpose to get variables as rows
	mat M= M'
			
	//remove the equation-name
	matrix roweq M = ""
	mat li M
	local varlist: rowvarlist M

/******************************************************************************/
/** LOAD PROGRAM                                                            **/
/******************************************************************************/
do parameter.mata

mata:

void test(){
	class parameter scalar P

	P.setup("bn1.race")
	P.print()
	
	assert(P.level== "bn1")
	assert(P.leveli== "1")
	assert(P.base)
	assert(P.varname== "race")
	assert(P.label=="Etnicity")
	assert(P.vlab=="white")
	assert(!P.interaction)
	
	P.setup("age")
	//P.print()
	
	assert(P.level== "")
	assert(P.leveli== "")
	assert(!P.base)
	assert(!P.omitted)
	assert(P.varname== "age")
	assert(P.label=="age in current year")
	assert(!P.interaction)
	assert(P.vlab=="")
	
	
	P.setup("c.age")
	//P.print()
	
	assert(P.level== "c")
	assert(P.varname== "age")
	assert(P.label=="age in current year")
	assert(!P.base)
	assert(!P.omitted)
	assert(!P.interaction)
	assert(P.vlab=="")
	
	P.setup("co.wage")
	P.print()
	
	assert(P.level== "co")
	assert(!P.base)
	assert(P.omitted)
	assert(P.varname== "wage")
	assert(P.label=="hourly wage")
	assert(!P.interaction)
	assert(P.vlab=="")
	
	//produce error
	P.setup("xyzn11.wage")
	P.print()
}

test()


end
	di "`varlist'"
