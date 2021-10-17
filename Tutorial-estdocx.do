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
	if c(hostname)== "1630-sandstrom" {
		cd "C:\Users\Glenn\OneDrive - Umeå universitet\Stata programs\estdocx"
		global  wordpath "C:\Program Files\Microsoft Office\root\Office16\WinWord.exe" 
		global  excelpath "C:\Program Files (x86)\Microsoft Office\Office15\EXCEL.exe" 
	}
	else if c(hostname) == "i5" {
		cd "F:\OneDrive - Umeå universitet\Stata programs\estdocx" /* Windows path */
		global  wordpath "C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE"
		sysdir set PERSONAL  "F:\OneDrive - Umeå universitet\Stata programs\ado\personal"
	}


clear all
discard

/******************************************************************************/
// Run subroutine
/******************************************************************************/
do sub1-tutorial.do
/*** LOAD PROGRAM **********************/
do estdocx.ado
/******************************************************************************/
// 
/******************************************************************************/
putdocx clear
// Create worddoc in memory for output
putdocx begin, pagesize(A4)

qui log using "temp\1.txt" , replace text name(_1) nomsg

// load sample data and example regressions
use Testdata/nlsw88, clear
notes

qui logistic never_married c.age i.race i.collgrad c.wage
estimates store _1_

qui logistic never_married c.age i.race i.collgrad c.wage c.grade
estimates store _2_

qui logistic never_married c.age i.race b1.collgrad c.wage c.grade c.tenure collgrad#race b1.collgrad#c.tenure#i.south
estimates store _3_

// use estiamtes table to produce a regression table
estimates table _1_ _2_ _3_, star(.05 .01 .001) b(%7.2f) stfmt(%7.1f) ///
stats(N aic bic) varwidth(30) allbaselevels eform

qui log close _1
stata_output_docx using "temp\1.txt"
/******************************************************************************/
/** Test inline mode                                              **/
/******************************************************************************/

//test creating table in an active document with the inline option
estdocx _1_ _2_ _3_, star(.05 .01 .001) ///
title("Table 1: Simple table of logistic regressions") ///
stats(N aic bic) b(%9.2f) inline

putdocx save "temp/inline.docx", replace

winexec $wordpath "temp/inline.docx"