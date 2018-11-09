{smcl}
{* *! version 1.0  9 Nov 2018}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "estimates_table_docx##syntax"}{...}
{viewerjumpto "Description" "estimates_table_docx##description"}{...}
{viewerjumpto "Options" "estimates_table_docx##options"}{...}
{viewerjumpto "Remarks" "estimates_table_docx##remarks"}{...}
{viewerjumpto "Examples" "estimates_table_docx##examples"}{...}
{title:Title}
{phang}
{bf:estimates_table_docx} {hline 2} a command giving same fucntionality as estimates table but exports results directly to a Wordtable

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:estimates_table_docx}
namelist(name=models)
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt title(string)}}  {p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:estimates_table_docx} Although it is possible o do this directly with the command 
 putdocx Stata 15 native implementation using putdocx table results = etable causes 
 unwanted formatting issues in the resulting table such as e.g. hidden characters in cells
 making formating of the table difficult. This implemtation avoid such issues and allowes some
 additonal benefits by providing options for the formating of the reuslting table and inclusion of
 legend etc.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt title(string)}    
{marker examples}{...}
{title:Examples}
{pstd}

{pstd}

{pstd}
 	{stata estimation command }
	{stata estimates store m1 }
	{stata estimation command }
	{stata estimates store tenure }
	{stata estimates_to_docx base grade tenure, saving("test.docx") star(.05 .01 .001) title("Table 1: Title") bdec(.001) }
	

{pstd}

{pstd}


{title:Author}
{p}

Dr Glenn Sandström, CEDAR Centre for Demographic and Ageing Research, University of Umeå.

Email {browse "mailto:glenn.sandstrom@umu.se":glenn.sandstrom@umu.se}



{title:See Also}
Related commands:


