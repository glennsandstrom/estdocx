# estimates_table_docx v. 1.2.6
Program to produce publication ready regression tables in MS Word from stored estimates in the same fashion as the command:
```stata
estimates table
```
in Stata.
See help file for examples of how tho use the program.

Example of output in MS Word format
===================================
This is the result of running the example found in the helpfile
![exampletable](https://raw.githubusercontent.com/glennsandstrom/estimates_table_docx/master/example.PNG)

Installation
============
Either use net command in Stata:
```stata
net install estimates_table_docx , from(https://github.com/glennsandstrom/estimates_table_docx/raw/master/)
```

Or use the excellent github command by E. F. Haghish by first running
```stata
net install github, from("https://haghish.github.io/github/")
```
...and then installing estimates_table_docx by running
```stata
github install glennsandstrom/estimates_table_docx
```

Updating
============
Use the same command as above but add the option replace
```stata
net install estimates_table_docx , from(https://github.com/glennsandstrom/estimates_table_docx/raw/master/) replace
```

If you have used the github command by haghish rather run
```stata
github update estimates_table_docx
```
Usage
=====


Title
-----

estimates_table_docx 

A command giving same functionality as estimates table but exports results directly to a Word table

Syntax
------
estimates_table_docx namelist [, options]

Options           | Description
----------------- | -------------
saving(filename)  |  Path/filename of the generated docx file.
title(string)     |  Optional title for table.
b(%fmt)           |  Stata format used for coifficents. Default is %9.2f
star(numlist)     |  Numlist of significance levels. Default is .05 .01 .001.
stats(scalarlist) |  List of statistics from e() to be displayed at bottom of table. Currently aic, bic and N can be specified.
baselevels        |  Include all baselevels.
keep(coflist)     |  List of coifficent to indlude in table.
landscape         |  Use landscape layout for Word document.
pagesize(psize)   |  Set pagesize of Word document. psize may be letter, legal, A3, A4, or B4JIS. Deafault is pagesize(A4)


Description
------------
estimates_table_docx takes a namelist of stored estiamtes and exports this to a publication quality table in MS Word.
Although it is possible to export estimates to a table using the command putdocx in Stata 15 (i.e. putdocx table results =
etable). The builtin method causes unwanted formatting issues in the resulting table such as e.g. hidden characters in cells making
it difficult to choose alignment in the cells and the need to erase these characters.  estimates_table_docx avoid such
issues and allows some additional benefits by providing options for the formating of the resulting table and inclusion of
legend etc.

Examples
--------

Setup
```stata
sysuse nlsw88, clear
```
Run estimation command
```stata
logistic never_married c.age i.race i.collgrad c.wage
```
Store model using estimates
```stata
estimates store _1_
```
Run second model
```stata
logistic never_married c.age i.race i.collgrad c.wage c.grade
```
Store second model using estimates
```stata
estimates store _2_
```
Run third model
```stata
logistic never_married c.age i.race b1.collgrad c.wage c.grade c.tenure collgrad#race b1.collgrad#c.tenure
```
Store second model using estimates
```stata
estimates store _3_
```
Run command to produce table in Word document estimates_table.docx
```stata
estimates_table_docx _1_ _2_ _3_ , star(.05 .01 .001) b(%9.2f) title("Table 1: Test title") baselevels
```

Author
-------

Dr Glenn Sandström, Umeå Univerity, Sweden.
Email: glenn.sandstrom@umu.se
Web:http://www.idesam.umu.se/english/about/staff/?uid=glsa0001

