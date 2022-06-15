{smcl}
{* *! version 0.96 20220617 }{...}
{right:version 0.963}
{title:Title}
{phang}
{bf:estdocx} {hline 2} a command giving same functionality as estimates table 
but exports results directly to a MSWord-document in memory (created with putdocx) 
or to a standalone docx-file.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:estdocx}
namelist
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt saving(filename)}}Path/filename of the generated docx file.{p_end}
{synopt:{opt inline}}Add table to a docx in memory rather than saving to standalone file.{p_end}
{synopt:{opt title(string)}}Optional title for table.{p_end}
{synopt:{opt colabels(string)}}Optional labels for columns.{p_end}
{synopt:{opt bfmt(%fmt)}}Stata format used for coefficients. Default is %9.2f{p_end}
{synopt:{opt star(numlist)}}Numlist of significance levels. If option is omitted significance is reported numerically.{p_end}
{synopt:{opt nop}}Do not report significance levels.{p_end}
{synopt:{opt ci(%fmt)}}Stata format used for 95% confidence intervals. If option is omitted no CIs are not reported. {p_end}
{synopt:{opt stats(scalarlist)}}Report scalarlist in table. Allowed is N aic bic {p_end}
{synopt:{opt baselevels}}Include all baselevels.{p_end}
{synopt:{opt keep(coflist)}}List of coefficient to include in table.{p_end}
{synopt:{opt pagesize(psize)}}Set pagesize of Word document.{p_end}
{synopt:{opt landscape}}Use landscape layout for word document.{p_end}
{synopt:{opt eform}}Report parameters as exp(B).{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
{cmd:estdocx} takes a namelist of stored {cmd:estimates} and exports this 
to a publication quality table in MS Word. Although it is possible to export estimates 
to a table using the command {cmd:putdocx} avaliable since Stata v.15 i.e. putdocx table results =etable and since Stata v.17 through the collect suite of commands both of these options has some drawbacks. The simple built-in method of putdocx causes unwanted formatting issues in the resulting table such as e.g. hidden characters in cells making it difficult to choose alignment in the cells and the need to erase these characters. estdocx avoid such issues and allows some additional benefits by providing options for the formatting of the resulting table and inclusion of legend etc. collect is a very powerful command but is quite complex and making the desired table requires quite a lot of coding. If the desired table is a multicolumn regression table estdocx is a much simpler way to produce the desired table with just one command.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt saving(string)} Path/filename of the generated docx file. This option is not allowed in inline-mode where you rather set these options when you create the document in memory trough the putdocx-command.

{phang}
{opt inline} Used when you want to add the resulting table to a docx in memory created by calling {cmd: putdocx begin [, options]}-command rather than saving to a standalone file. 

{phang}
{opt title(string)} Optional title for table.

{phang}
{opt colabels(string)} Optional labels for columns. Supply list of column number # "label"... Default is to label models/columns using the names of the stored estimates used to form the table. 

{phang}
{opt bfmt(%fmt)} Specifies how the coefficients are to be displayed. Default is %9.2f

{phang}
{opt star(numlist .05 .01 .001)} significance levels. If option is not set p-values are printed within parentheses with three decimal places. Significance levels can be fully excluded if options {opt nop} is passed.

{phang}
{opt nopval} Do not report significance levels, used if you e.g. only want to show CIs.

{phang}
{opt ci(%fmt)} Stata format used for 95% confidence intervals. If option is omitted no CIs are not reported.

{phang}
{opt stats(scalarlist)} List of statistics from e() to be displayed at bottom of table. Currently aic, bic and N can be specified.
Default behavior is to display N. If you do not want anything to be displayed at bottom of table specify stats(none).

{phang}
{opt baselevels} Include all baselevels in the resulting table.

{phang}
{opt keep(coflist)} List of coefficient to include in table. Will present parameters in the specified order.
Specify the the variables to be included as in estimation command but exclude level indicators.
For Model 3 in examples you would specify age race collgrad wage grade tenure collgrad#race collgrad#tenure _cons

{phang}
{opt pagesize(psize)} Set pagesize of Word document. psize may be letter, legal, A3, A4, or B4JIS. Default is pagesize(A4). This option is not allowed in inline-mode where you rather set these
options when you create the document in memory trough the putdocx-command.

{phang}
{opt landscape} Use landscape layout for Word document. This option is not allowed in inline-mode where you rather set these options when you create the document in memory trough the putdocx-command.

{phang}
{opt eform} Report parameters as exp(B).



{marker examples}{...}
{title:Examples}

{hline}
Setup
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}

{pstd}Run estimation command{p_end}
{phang2}{cmd:. logistic never_married c.age i.race i.collgrad c.wage}

{pstd}Store model using estimates{p_end}
{phang2}{cmd:. estimates store _1_}

{pstd}Run second model{p_end}
{phang2}{cmd:. logistic never_married c.age i.race i.collgrad c.wage c.grade}

{pstd}Store second model using estimates{p_end}
{phang2}{cmd:. estimates store _2_}

{pstd}Run third model{p_end}
{phang2}{cmd:. logistic never_married c.age i.race b1.collgrad c.wage c.grade c.tenure collgrad#race b1.collgrad#c.tenure}

{pstd}Store third model using estimates{p_end}
{phang2}{cmd:. estimates store _3_}

{pstd}Run command to produce table in a standalone Word document with default name estdocx.docx{p_end}
{phang2}{cmd:. estdocx base grade tenure}

{hline}


{title:Author}
{p}

Dr Glenn Sandström, Umeå Univerity, Sweden.
Email: {browse "mailto:glenn.sandstrom@umu.se":glenn.sandstrom@umu.se}
Web:{browse "http://www.idesam.umu.se/english/about/staff/?uid=glsa0001"}


{title:See Also}
Related commands: estimates table, putdocx


