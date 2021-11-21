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
set linesize 100
putdocx clear
// Create worddoc in memory for output
putdocx begin, pagesize(A4)
putdocx paragraph, style(Title)
putdocx text (`"Tutorial on how to use Stata estdocx to produce publication quality regression tables in MS Word"')

putdocx paragraph, style(Heading1)
putdocx text (`"Introduction"')

putdocx textblock begin, font (Garamond, 12)
<<dd_docx_display bold font(Consolas, 10): "estdocx" >> takes a <<dd_docx_display italic font(Consolas, 10): "namelist" >> of stored <<dd_docx_display italic font(Consolas, 10): "estimates" >> and exports this to a publication quality table in MS Word. Although it is possible to export estimates to a table using the command <<dd_docx_display italic font(Consolas, 10): "putdocx" >> in Stata 15 (i.e. <<dd_docx_display italic font(Consolas, 10): "putdocx table results =etable" >>) and since Stata v.17 through the <<dd_docx_display italic font(Consolas, 10): "collect" >> suite of commands both of these options has some drawbacks. The simple built-in method of <<dd_docx_display italic font(Consolas, 10): "putdocx" >> causes unwanted formatting issues in the resulting table such as e.g. hidden characters in cells making it difficult to choose alignment in the cells and the need to erase these characters. <<dd_docx_display bold font(Consolas, 10): "estdocx" >> avoid such issues and allows some additional benefits by providing options for the formatting of the resulting table and inclusion of legend etc. <<dd_docx_display italic font(Consolas, 10): "collect" >> is a very powerful command but is quite complex and making the desired table requires quite a lot of coding. If the desired table is a multicolumn regression table <<dd_docx_display bold font(Consolas, 10): "estdocx" >> is a much simpler way to produce the desired table with just one command.
putdocx textblock end

putdocx paragraph, style(Heading1)
putdocx text (`"A simple first example"')

putdocx textblock begin, font (Garamond, 12)
We will use the data set <<dd_docx_display italic font(Consolas, 10): "nlsw88" >> shipped with Stata. The data contains information from <<dd_docx_display italic: "the National Longitudinal Survey of Young Women who were ages 14-24 in 1968 (NLSW)." >> We will run a couple of simple logistic regressions on the dichotomous outcome never married regressed against a set of continuous, ordinal and nominal variables: <<dd_docx_display italic font(Consolas, 10): "age, race, wage, grade and college grad." >>
putdocx textblock end

qui log using "temp\1.txt" , replace text name(_1) nomsg

// load sample data and run example regressions
use Testdata/nlsw88, clear

qui logistic never_married c.age i.race i.collgrad c.wage
estimates store _1_

qui logistic never_married c.age i.race i.collgrad c.wage c.grade
estimates store _2_

qui logistic never_married c.age i.race b1.collgrad c.wage c.grade collgrad#race 
estimates store _3_

qui log close _1


stata_output_docx using "temp\1.txt"

putdocx textblock begin, font (Garamond, 12)
We can display these stored estimates as a text table in the console using the command <<dd_docx_display italic font(Consolas, 10): "estimates table." >>
putdocx textblock end

qui log using "temp\2.txt" , replace text name(_2) nomsg
estimates table _1_ _2_ _3_, star(.05 .01 .001) b(%7.2f) stfmt(%7.1f) ///
stats(N aic bic) varwidth(30) eform
qui log close _2

stata_output_docx using "temp\2.txt"
/******************************************************************************/
/** Simple 3 model logistic table                                             **/
/******************************************************************************/
putdocx textblock begin, font (Garamond, 12)
We can easily produce the same kind of regression table in MS-Word format using <<dd_docx_display italic font(Consolas, 10): "estdocx." >> with the following syntax.
putdocx textblock end

stata_output_docx using "temp\command1.txt"

putdocx textblock begin, font (Garamond, 12)
Which produces the following output in a new docx-document saved in the current path. The 
file is named estdocx.docx as the default name if a path/filename is not provided in 
the option <<dd_docx_display italic font(Consolas, 10): "saving(path/name)" >> in the 
call to <<dd_docx_display italic font(Consolas, 10): "estdocx.">>
putdocx textblock end

estdocx _1_ _2_ _3_, ///
title("Table 1: Simple table of logistic regressions") ///
star(.05 .01 .001) ///
stats(N aic bic) ///
inline

putdocx textblock begin, font (Garamond, 12)
The option <<dd_docx_display italic font(Consolas, 10): "star(1# 2# 3#)" >> works as in <<dd_docx_display italic font(Consolas, 10): "estimates table">> and tells the routine that we want star-notation for the specified significance levels. If we rather want significance printed in verbose mode which is the default we just omit the star-option. The resulting table is one with sig. p printed in parenthesis after the coefficient as seen below in Table 2.
putdocx textblock end

stata_output_docx using "temp\command2.txt"

estdocx _1_ _2_ _3_, ///
title("Table 2: Vervose significance levels") ///
stats(N aic bic) ///
inline

estdocx _1_ _2_ _3_, ///
title("Table 2: Report confidence intervals") ///
stats(N aic bic) ///
star(.05 .01 .001) ///
ci(%9.2f) ///
inline

putdocx save "temp/inline.docx", replace

winexec $wordpath "temp/inline.docx"