
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
label variable race "Etnicity"
label variable tenure ""
label values married .

mata:

void test(){
	class parameter scalar P
	/******************************************************************************/
	// test some common single variable paramter types
	/******************************************************************************/
	P.setup("bn1.race")
	//P.print()
	
	assert(P.vars[1].vartype=="factor")
	assert(P.vars[1].prefix== "bn1")
	assert(P.vars[1].level== "1")
	assert(P.vars[1].base)
	assert(P.vars[1].varname== "race")
	assert(P.vars[1].label=="Etnicity")
	assert(P.vars[1].vlab=="white")
	
	assert(P.paramtxt=="bn1.race")
	assert(P.paramtype=="factor")
	assert(P.comblabel=="Etnicity")
	assert(P.combvlab=="white")
 	assert(!P.interaction)
	
	P.setup("2b.race")
	//P.print()
	
	assert(P.vars[1].vartype=="factor")
	assert(P.vars[1].prefix== "2b")
	assert(P.vars[1].level== "2")
	assert(P.vars[1].base)
	assert(P.vars[1].varname== "race")
	assert(P.vars[1].label=="Etnicity")
	assert(P.vars[1].vlab=="black")
	
	assert(P.paramtxt=="2b.race")
	assert(P.paramtype=="factor")
	assert(P.comblabel=="Etnicity")
	assert(P.combvlab=="black")
 	assert(!P.interaction)
	
	P.setup("age")
	//P.print()
	
	assert(P.paramtype=="continious")
	assert(P.vars[1].prefix== "")
	assert(P.vars[1].level== "")
 	assert(!P.vars[1].base)
 	assert(!P.vars[1].omitted)
 	assert(P.vars[1].varname== "age")
 	assert(P.vars[1].label=="age in current year")
	assert(P.vars[1].vlab=="")
	
	assert(P.paramtxt=="age")
	assert(P.paramtype=="continious")
	assert(P.comblabel=="age in current year")
	assert(P.combvlab=="")
 	assert(!P.interaction)
	
	P.setup("c.age")
	//P.print()
	
	assert(P.paramtype=="continious")
	assert(P.vars[1].prefix== "c")
	assert(P.vars[1].level== "")
 	assert(!P.vars[1].base)
 	assert(!P.vars[1].omitted)
 	assert(P.vars[1].varname== "age")
 	assert(P.vars[1].label=="age in current year")
	assert(P.vars[1].vlab=="")
	
	assert(P.paramtxt=="c.age")
	assert(P.paramtype=="continious")
	assert(P.comblabel=="age in current year")
	assert(P.combvlab=="")
 	assert(!P.interaction)
	
	P.setup("co.wage")
	//P.print()
	
	assert(P.paramtype=="continious")
	assert(P.vars[1].prefix== "co")
	assert(P.vars[1].level== "")
 	assert(!P.vars[1].base)
 	assert(P.vars[1].omitted)
 	assert(P.vars[1].varname== "wage")
 	assert(P.vars[1].label=="hourly wage")
	assert(P.vars[1].vlab=="")
	
	assert(P.paramtxt=="co.wage")
	assert(P.paramtype=="continious")
	assert(P.comblabel=="hourly wage")
	assert(P.combvlab=="")
 	assert(!P.interaction)
 	
	/******************************************************************************/
	// test single paramters that has no label or value-labels set or both
	/******************************************************************************/
	// continuious omitted variable with no label
	P.setup("co.tenure")
	//P.print()
	
	assert(P.paramtype=="continious")
	assert(P.vars[1].prefix== "co")
	assert(P.vars[1].level== "")
 	assert(!P.vars[1].base)
 	assert(P.vars[1].omitted)
 	assert(P.vars[1].varname== "tenure")
 	assert(P.vars[1].label=="tenure")
	assert(P.vars[1].vlab=="")
	
	assert(P.paramtxt=="co.tenure")
	assert(P.paramtype=="continious")
	assert(P.comblabel=="tenure")
	assert(P.combvlab=="")
 	assert(!P.interaction)
	
	// factor with no value-label
	P.setup("11b.married")
	P.print()
	
	assert(P.paramtype=="factor")
	assert(P.vars[1].prefix== "11b")
	assert(P.vars[1].level== "11")
 	assert(P.vars[1].base)
 	assert(!P.vars[1].omitted)
 	assert(P.vars[1].varname== "married")
 	assert(P.vars[1].label=="married")
	assert(P.vars[1].vlab=="11")
	
	assert(P.paramtxt=="11b.married")
	assert(P.paramtype=="factor")
	assert(P.comblabel=="married")
	assert(P.combvlab=="11")
 	assert(!P.interaction)
	
	/******************************************************************************/
	// Interactions
	/******************************************************************************/
	/*
		// factor with no value-label
	P.setup("0.collgrad#3.race")
	P.print()
	*/
	
	
	
}

test()


end
	di "`varlist'"
