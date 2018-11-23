# estimates_table_docx v. 1.1
Program to produce publication ready regression tables in MS Word from stored estimates

See file test_estimates_docx for examples of how to use the program.

Installation
============
Either use net command in Stata:
```stata
net install estimates_table_docx , from(https://github.com/glennsandstrom/estimates_table_docx/raw/master/)
```
Or first intall haghish github command for Stata:
```stata
net install github, from("https://haghish.github.io/github/")
```
....and the run 
```stata
github install glennsandstrom/estimates_table_docx
```
in Stata.

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
bdec(real)        |  Number of decimal places used for parameters. Default is .01
star(numlist)     |  Numlist of significance levels. Default is .05 .01 .001.
baselevels        |  Include all baselevels.
landscape         |  Use landscape layout for Word document.


Description
------------

    estimates_table_docx Takes a namelist of stored estiamtes and exports this to a publication quality table in MS Word.
    Although it is possible to export estimates to a table using the command putdocx Stata 15 (i.e. putdocx table results =
    etable) This method causes unwanted formatting issues in the resulting table such as e.g. hidden characters in cells making
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
estimates store base
```
Run second model
```stata
logistic never_married c.age i.race i.collgrad c.wage c.grade(reg)
```
Store second model using estimates
```stata
estimates store grade
```
Run command to produce table in Word document estimates_table.docx
```stata
estimates_table_docx base grade tenure, star(.05 .01 .001) bdec(.001) title("Table 1: Test title") baselevels
```

Author
-------

Dr Glenn Sandström, Umeå Univerity, Sweden.
Email: glenn.sandstrom@umu.se
Web:http://www.idesam.umu.se/english/about/staff/?uid=glsa0001

