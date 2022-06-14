/**************************************************************************/
/**TODO  **/
/**************************************************************************/
// * free-parameters:
//   Program does not handle multiple equation models such as'
//   xtlogit with ancilliary/free paramters that should not be transformed. Program needs to honor the 
//   equation name where free paramters have a different equation name, In r(table) all params 
//   after / in the equation name are free paramters "Free parameters are scalar parameters, 
//   variances, covariances, and the like that are part of the model being fit"
//   
//   These should be handled differntly removed from the matrix of parameters and placed 
//   in the stats matrix and handled separatly printed under each model. Currenlty free paramters
//   are reported in eform wich is an error.
//
//
// * BUG:if a variable has no valuelables program ends in Error st_vlmap():  3300  argument out of range

// * BUG: if factor has more than single digit level program throws error
//
// * BUG: Omitted variables are incorrectly displayed as (base)

//
// * Implement additonal signs for significanse with dagger mark as e.g. style
//   in Demography.
//
// * *Indicate stratified variables in cox-regressions
//
// * Implement a possibility to include a note below the regression table e.g. source comment etc.
/*###############################################################################################*/
/**SUB-ROUTINES  **/
/*###############################################################################################*/
	/*########################################################################*/
	program check_stats
		version 17
		syntax anything(name=statlist id="Statistics"), allowed(string)
		
		foreach stat in `statlist' {
			// get postion of stat in list of allowed statistics
			local i : list posof "`stat'" in allowed
			if(!`i') {
				di _newline(3)  
				di as error "ERROR: `stat' is not an allowed statistic in option stats()"
				di _newline  
				error 197
			
			}
		}
	end
	/*########################################################################*/
	program create_docx
		version 17
		syntax , pagesize(string) [landscape]
	
		/**************************************************************************/
		/** CREATE THE WORDDOCUMENT THAT WILL HOLD THE TABLE                     **/
		/**************************************************************************/
			// clear any unsaved documents from memory
			putdocx clear
			if "`landscape'"!="" putdocx begin, pagesize(`pagesize') landscape
			else putdocx begin, pagesize(`pagesize')
			
	end
	/*########################################################################*/
**# Bookmark #2
	program create_table
		version 17
		syntax namelist(name=models), pagesize(string) [title(string)] [landscape]
		
		/**************************************************************************/
		/** SET WIDTH OF THE TABLE                     **/
		/**************************************************************************/
		local nummodels :list sizeof models
		// set the width of the table= nummodels + one rowheader column to display variable
		// names and factor levels in case var is a factor
		local COLUMNS= `nummodels' +1
		
		// try to insert a pragraph
		capture putdocx paragraph, halign(left) spacing(after, 0) 
		if _rc!=0 {
				display as error "No active document in memory. "
				display as error "If you are using the option inline "
				display as error "you first have to run the command putdocx begin "
				display as error "before calling estdocx"
				exit _rc
		}
			
		//print title of table it there is one
		if ("`title'"!="") putdocx text ("`title'"), bold

		/**************************************************************************/
		/** CREATE THE HEADER ROW TABLE USING `ROWS',`COLUMNS' DIMENSIONS        **/
		/**************************************************************************/

			putdocx table esttable = (1,`COLUMNS'), ///
			border(start, nil) ///
			border(insideH, nil) ///
			border(insideV, nil) ///
			border(end, nil) ///
			halign(left) layout(autofitcontents)
			
		
			//set column lable for x-variables
			putdocx table esttable(1,1) = ("Variables"), bold font(Garamond, 11) halign(left) 
			
			
			forvalues col=2/`COLUMNS' {
				local mod= `col'-1
				local model: word `mod' of `models'
				putdocx table esttable(1,`col') = ("`model'"),	bold font(Garamond, 11) halign(left)
				
			}
			
			
	end
	/*########################################################################*/
	program set_headers
		version 17
		syntax , headers(string asis) nummod(integer)
		
	
	// get first col to be able to start the loop
	gettoken col headers : headers, parse(`"" "')

	while(`"`col'"' != "") {
	
		confirm integer number `col' 
		di `"col: `col'"'
		
		// confirm that specified col is in te range ofnumod
		if (`col' < 1 | `col' > `nummod') {
			di as error "The value: `col' set in option headers() is invalid; column out of range"
			error 125
			exit _rc
			
		}
		
		local col= `col'+1
		
		gettoken heading headers : headers, parse(`"" "')
		di `"heading: `heading'"'
		
		// write heading to table
		putdocx table esttable(1,`col') = ("`heading'"),	bold font(Garamond, 11) halign(left)
		
		// get next col
		gettoken col headers : headers, parse(`"" "')
		
		}
			
			
	end
	/*########################################################################*/
	program write_legend
		version 15.1
		syntax, star(string) row(integer) col(integer)
		
		local sigs: word count `star'
		local text "legend: "
		
		forvalues sig=1/`sigs' {
			local p: word `sig' of `star' //.05
			local s= "`s'*"
			local text=  "`text' `s' p<" + "`p'; "  
		
		}
		putdocx table esttable(`row',.), addrows(1)
		local row= `row'+1
		putdocx table esttable(`row',1) = ("`text'"), ///
		font(Garamond, 11) halign(left) colspan(`col') ///
		border(bottom, nil) ///
		border(top)
	end
/*########################################################################*/	
	program write_stats
		version 15.1
		syntax namelist(min=1), stats(string) row(integer)
		//di "MODELS: `namelist'"
		//di "STATS: `stats'"
		//di "ROW: `row'"
		
		local models= "`namelist'" //space sparated list of estimates
			
		foreach stat in `stats' {
			//add row for stat
			putdocx table esttable(`row',.), addrows(1)
			local ++row
			putdocx table esttable(`row',1) = ("`stat'"), font(Garamond, 11) halign(left) bold
			
			// get matrix of stat for each model
			get_`stat' `models'
			matrix S= r(S)
			local col= 2
			
			foreach mod in `models' {
				if ("`stat'"!="N") {
					local text: display %-12.1f S[rownumb(S,"`stat'"),colnumb(S,"`mod'")]
					local text= subinstr("`text'"," ","", .)
				}
				else {
					local text: display %-12.0gc  S[rownumb(S,"`stat'"),colnumb(S,"`mod'")]
				}
				putdocx table esttable(`row',`col') = ("`text'"), font(Garamond, 11) halign(left)			
				local ++col
			}
		}		
		
	
	end
	/*########################################################################*/
	program get_N, rclass
		version 15.1
		syntax namelist(min=1)
		
		local models= "`namelist'" //space sparated list of estimates
		
		//create a matrix for storing statistics
		local nummods: list sizeof models
		matrix Y= J(1,`nummods', .)
		matrix colnames Y = `models'
		matrix rownames Y = N
		
		//loop over models and get each statistic in stats and store in S
		foreach model in `models' {
			//restore model to acces e()
			qui estimates restore `model'  
			// store value of statistics specified in arg: stats in matrix S
			mat Y[rownumb(Y,"N"),colnumb(Y,"`model'")]= e(N)			
		}

		return matrix S= Y
	end
	/*########################################################################*/
	program get_aic, rclass
		version 15.1
		syntax namelist(min=1)
		
		local models= "`namelist'" //space sparated list of estimates
		
		//create a matrix for storing statistics
		local nummods: list sizeof models
		matrix Y= J(1,`nummods', .)
		matrix colnames Y = `models'
		matrix rownames Y = aic
		
		//loop over models and get each statistic in stats and store in S
		foreach model in `models' {
			//restore model to acces e()
			qui estimates restore `model'  
			qui estat ic
			mat Z= r(S)
			local val= Z[1 ,colnumb(Z,"AIC")]
			mat Y[rownumb(Y,"aic"),colnumb(Y,"`model'")]= `val'			
		}

		return matrix S= Y
	end
	/*########################################################################*/
	program get_bic, rclass
		version 15.1
		syntax namelist(min=1)
		
		local models= "`namelist'" //space sparated list of estimates
		
		//create a matrix for storing statistics
		local nummods: list sizeof models
		matrix Y= J(1,`nummods', .)
		matrix colnames Y = `models'
		matrix rownames Y = bic
		
		//loop over models and get each statistic in stats and store in S
		foreach model in `models' {
			//restore model to acces e()
			qui estimates restore `model'  
			qui estat ic
			mat Z= r(S)
			local val= Z[1 ,colnumb(Z,"BIC")]
			mat Y[rownumb(Y,"bic"),colnumb(Y,"`model'")]= `val'			
		}

		return matrix S= Y
	end
	/*########################################################################*/
/*###############################################################################################*/
// MAIN PROGRAM
/*###############################################################################################*/
program estdocx, rclass
	version 17
  
	syntax namelist(min=1),	///
		[saving(string)] ///
		[inline] ///
		[title(string)] ///
		[Headers(string asis)] ///
		[bfmt(string)] ///
		[ci(string)] ///
		[star(string)] ///
		[stats(string)] ///
		[baselevels] ///
		[keep(string)] ///
		[pagesize(string)] ///
		[landscape] ///
		[NOPval] ///
		[eform] ///
		[fname(string)] 
		
		// You need to captalize all options that start with no; otherwise Stata treats at as a optionally off eg. p is of

	// set local holding the names of estimates to be reported in table
	local estnames= "`namelist'" //space separated list of estimates
	//loop over estnames to and check that they are valid estimation result names avalaible in memory

	qui estimates dir
	local estimates= r(names)
	foreach model in `estnames' {
		if(!strmatch("`estimates'", "*`model'*")) {
		di _newline(3)  
		di as error "ERROR: `model' is not in the list of stored estimates in memory; check the supplied model names"
		di _newline  
		di as result "The estimates currently stored in memory are:" 
		estimates dir
		exit _rc
		}
			
	}
	
	// set local holding list of allowed statistics
	local allowed "none N aic bic"
	
	// default values for options if none are provided
	if ("`bfmt'"=="") {
		local bfmt "%04.2f"
	} 
	else {
		capture confirm numeric format `bfmt'
		if(_rc!=0) {
			di as error "The value provided in option bfmt(`bfmt') is not a valid Stata format"
			exit _rc
			}
	}
	

	if ("`ci'"!="") {
		capture confirm numeric format `ci'
		if(_rc!=0) {
			di as error "The value provided in option ci(`ci') is not a valid Stata format"
			exit _rc
			}
	}
	
	
	if ("`saving'"=="") local saving "estdocx.docx"
	if ("`pagesize'"=="") local pagesize "A4"
	
	// if stats is provided check that all stats are allowed/implemented
	if ("`stats'"!="") check_stats `stats', allowed(`allowed')
	if ("`stats'"=="") local stats "N" // set default stat N if stats is not provided
	if ("`stats'"=="none") local stats "" // set stat null string if stat(none)
	
	//find out the name of the current frame used to search for labels and vlables

	qui frame pwf
	local datafr= r(currentframe)
	

	/**************************************************************************/
	/** Call MATA to set up frame with the desired regression table **/
	/**************************************************************************/
	mata: create_frame_table("`estnames'",   ///
							 "`baselevels'", ///
							 "`bfmt'",       ///
							 "`ci'",         /// 
							 "`star'",       ///
							 "`nopval'",     ///
							 "`eform'",      ///
							 "`fname'",      ///
							  "`keep'")
	
	
	//find out the name of the frame holding the regression table
	//after the mata routines the active frame will be the one holding the regression table
	qui frame pwf
	local tabfr= r(currentframe)
	
	/**************************************************************************/
	/** CREATE WORDTABLE                     **/
	/**************************************************************************/
	// if !inline first create docx in memory to hold the table
	if("`inline'"=="") create_docx , pagesize(`pagesize') `landscape'
	
		/**************************************************************************/
		/** SET WIDTH OF THE TABLE                     **/
		/**************************************************************************/
		local nummodels :list sizeof estnames
		// set the width of the table= nummodels + one rowheader column to display variable
		// names and factor levels in case var is a factor
		local totcols= `nummodels' +1
	
**# Bookmark #1
	create_table `estnames', pagesize(`pagesize') title(`title') `landscape'
	
	if ("`headers'"!="") set_headers , headers(`headers') nummod(`nummodels')
	
	// set border on bottom of header row of table
	putdocx table esttable(1,.), border(bottom)
	
	
	/**************************************************************************/
	/** PRINT THE TABLE FROM FRAME */
	/**************************************************************************/
	
	
	//read table data from frame 
	local rows= _N // get the total number of rows in the frame that should be exported to word
	local rowMSWord= 1 // rowindicator for MSWord table
	local printed ""

	// loop over rows in frame
	forvalues rowframe= 1(1)`rows' {
		
		// 1. check the type of parameter 
		local type= type[`rowframe']
		local label= label[`rowframe']
		local vlab=vlab[`rowframe']
		
		// 2. if factor 
		if "`type'"=="factor" | "`type'"=="factor-interaction"{
			//di "factor: `label': `vlabel'"
			//add a variable header row and print varname if it has not been printed
			//check if varname is in the list of printed varnames
			
			local lab= subinstr("`label'", " ", "", .) //remove all whitespace
			local print : list posof "`lab'" in printed
			//di "`printed'"
			// if the header is not orinted add row for varheader
			if !`print' {
				// add header row with varname of factor variable
				putdocx table esttable(`rowMSWord',.), addrows(1)
				local ++rowMSWord
				putdocx table esttable(`rowMSWord',1) = ("`label'"), bold font(Garamond, 11) halign(left)
				local printed "`printed' `lab'" //add varname to list of printed headers
			}
			// print row with params for factor-level
				putdocx table esttable(`rowMSWord',.), addrows(1)
				local ++rowMSWord
				putdocx table esttable(`rowMSWord',1) = ("`vlab'"), italic font(Garamond, 10) halign(center)
				
				//loop over columns of frame and set cell values of table for continious
				forvalues col=2/`totcols' {
					local estnum= `col'-1
					local estname: word `estnum' of `estnames'
					putdocx table esttable(`rowMSWord',`col') = (`estname'[`rowframe']), font(Garamond, 10) halign(left)		
					}
				
			
		}
		else if "`type'"=="continious" | "`type'"=="continious-interaction" | "`type'"=="const" {
			//di "continious: `label'"
			putdocx table esttable(`rowMSWord',.), addrows(1)
			local ++rowMSWord
			putdocx table esttable(`rowMSWord',1) = ("`label'"), bold font(Garamond, 11) halign(left)
			//loop over columns of frame and set cell values of table for continious
			forvalues col=2/`totcols' {
				local estnum= `col'-1
				local estname: word `estnum' of `estnames'
				putdocx table esttable(`rowMSWord',`col') = (`estname'[`rowframe']), ///
				font(Garamond, 10) halign(left)
				}
		}
	}

		// set border at bottom beta table
	putdocx table esttable(`rowMSWord',.), border(bottom)


	/**************************************************************************/	
	// ADD STATS TO BOTTOM OF TABLE IF stats!=null
	/**************************************************************************/
	if ("`stats'"!="") write_stats `estnames', stats(`stats') row(`rowMSWord')
	/**************************************************************************/	
	// print a legend with significance values
	/**************************************************************************/
	qui putdocx describe esttable
	if("`star'"!="" & "`nopval'"=="") write_legend, star(`star') row(`r(nrows)') col(`r(ncols)')

	/**************************************************************************/
	/** Save worddocument if program is not in inline mode           **/
	/**************************************************************************/
	//putdocx describe esttable
	if("`inline'"=="") putdocx save "`saving'", replace
	
	/**************************************************************************/
	/** Garbage collection             **/
	/**************************************************************************/
	//matrix drop _all
end

version 17
mata: mata set matastrict on
mata: mata set matalnum on

// macroed types
local boolean real
local TRUE    1
local FALSE   0
local SS      string scalar
local SCV     string colvector
local RS      real scalar

mata:
/*#######################################################################################*/
// STRUCTURES
/*#######################################################################################*/

/**************************************************************************
STRUCTURE paramvar
**************************************************************************/
struct paramvar {
		string scalar vartype
		string scalar varname
		string scalar label 
		string scalar vlab
		string scalar prefix		//entire string before . in paramtxt
		string scalar level			
		real scalar base
		real scalar omitted


}

/*#######################################################################################*/
// CLASS parameter
/*#######################################################################################*/
class parameter {
	public:
		string scalar paramtype		// type of paramter.. continious, factor, interaction
		string scalar comblabel 	// combined label of all variables forming the paramter
		string scalar combvlab		// combined label of all included variabels/levels
		string scalar paramtxt		//complete string forming the paramter
		
		real scalar interaction 	//boolean indicating if it is an interaction
		
		string vector intervars
		
		struct paramvar vector vars //vector of different variables forming the parameter
				
		void setup()
		void print()
		struct paramvar parsevar()
	
	
		
}
	/*#######################################################################################
	// CLASS parameter FUNCTIONS
	#######################################################################################*/
	void parameter::setup(string scalar user_txt) {
		real scalar i
		struct paramvar scalar P
		
		//make sure all propreties are null when setup is run
		this.comblabel= this.combvlab = this.paramtype = this.paramtxt = ""
		this.interaction= .
		
		
		this.paramtxt= user_txt // text defining the complete paramteter
		
		//check if parameter is an interaction
		this.interaction= strrpos(this.paramtxt,"#")  > 0
		
		if (this.interaction) {
			//"do complicated things for interaction paramters"
			this.intervars=tokens(subinstr(this.paramtxt, "#", " ") ) //matrix with varnames forming the interaction
			
			// fill colvector this.vars with strcutures for each varaible in interaction stored in intervars
			// set this vars to a new vector of struct paramvars of length= this.intervars
			this.vars = paramvar(length(this.intervars)) 
					
			for (i=1; i<=length(this.intervars); i++) {
				P= this.parsevar(this.intervars[i]) //create struct paramvar using string in this.intervars
				this.vars[i]= P // add struct to vector this.vars
			
			}
			
			// form the combined label and value-label for the interaction
			// intercations containing at least one factor should have vlab
			
			for (i=1; i<=length(this.vars); i++) {
							
				if (i > 1) this.comblabel= this.comblabel + " * " + this.vars[i].label
				else this.comblabel= this.vars[i].label
				
				// if vlab is null do nothing
				// if vlab !null and comb !null add "*" + vlab to comb
				// if vlab !null and comb null add vlab to comb
				if (this.combvlab=="" & this.vars[i].vlab!="") {
					this.combvlab= this.vars[i].vlab
				}
				else if(this.combvlab!="" & this.vars[i].vlab!="") {
					this.combvlab= this.combvlab + " * " + this.vars[i].vlab
				}
				else {
					// do nothing
				}
				
			
			}
			//check if any of the incuded variables are factors this.combvlab will not be null
			if(this.combvlab=="") this.paramtype= "continious-interaction"
			else this.paramtype= "factor-interaction"
		
		}
		else {
			//"do easy things for factors and continious variables"
			//create a single element vector with one paramvar struct
			this.vars = paramvar(1) 
			this.vars= this.parsevar(this.paramtxt)
			this.comblabel= this.vars[1].label
			this.combvlab= this.vars[1].vlab
			this.paramtype= this.vars[1].vartype
		}
	}
	/***************************************************************************
	Function 
	****************************************************************************/
	struct paramvar parameter::parsevar(string scalar vartext){
			struct paramvar scalar P
			real scalar rcode
			string scalar cmd
			
			
			// assign the part of the string efter . to P.varname 
			P.varname= substr(vartext , strrpos(vartext,".")+1 ,  strlen(vartext))
			
			// assign part of string before . to P.prefix
			P.prefix= substr(vartext , 1 , strrpos(vartext,".")-1 )
			
			//check that P.varname is a varaible in the dataset
			cmd= "confirm variable " + P.varname
			//function will return non-zero (error=111) if varname does not exist
			// set type and name and then exit
			if (_stata(cmd, 1)) {
				P.vartype= "const"
				P.label= P.varname
				return(P)
			
			}
			
			//check if prefix contains numeric character then it is a factor
			if (regexm(P.prefix, "[0-9]")) {
				
				P.vartype= "factor"
				
				// check if prefix is base
				P.base= strrpos(P.prefix,"b")  > 0
				
				// check if prefix is ommitted
				P.omitted= strrpos(P.prefix,"o")  > 0
				
				// check if it is bn than it is not base or omitted
				if(regexm(P.prefix, "bn")) {
					P.base= `FALSE'
					P.omitted= `FALSE'
				}

				//get only the numeric value in prefix if it contains letters to get valuelabel with st_varvaluelabel()
				// match the numbers with regexm and then return them with regexs
				if (regexm(P.prefix, "[0-9]+"))	P.level= regexs(0)
			
				
				// check that value labels are set and set vlab to correct value label in P.vlab 
				if (st_varvaluelabel(P.varname)!="") P.vlab = st_vlmap(st_varvaluelabel(P.varname), strtoreal(P.level))
				else P.vlab = P.level
				
				// sometimes the value lable is set but is null string => set to level of factor
				if (P.vlab=="") P.vlab = P.level
			} 
			
			else if (P.prefix=="" | P.prefix=="c" | P.prefix=="co") {
				P.vlab= "" // paramter is not factor vlab should be null
				P.vartype= "continious"
				
				//contionios variables have no base-level
				P.base= 0
				
				// check if paramter is omitted 
				P.omitted= strrpos(P.prefix,"o") > 0
			
			}
			else {
				_error(3300, "Parameter contains a value not implemented in estdocx")
			}
			
			// check that a varlabel is set else return varname in P.label
			if (st_varlabel(P.varname)!="") P.label= st_varlabel(P.varname)
			else P.label= P.varname
			
			return(P)
	}
	/***************************************************************************
	Function 
	****************************************************************************/
	void parameter::print() {
		real scalar i
			printf("{txt}___________________________________________________________\n")
		for(i=1; i<=length(this.vars); i++) {
			
			
			printf("{txt}---Structure: %f ---------------------------------\n", i)
			printf("{txt}vartype is:{result} %s\n", this.vars[i].vartype)
			printf("{txt}varname is:{result} %s\n", this.vars[i].varname)
			printf("{txt}label is:{result} %s\n", this.vars[i].label)
			printf("{txt}vlab is:{result} %s\n", this.vars[i].vlab)
			printf("{txt}prefix is:{result} %s\n", this.vars[i].prefix)
			printf("{txt}level is:{result} %s\n", this.vars[i].level)
			printf("{txt}base is:{result} %f\n", this.vars[i].base)
			printf("{txt}omitted is:{result} %f\n", this.vars[i].omitted)
		}

			printf("{txt}--- Object: --------------------------------------\n")
			printf("{txt}paramtxt is:{result} %s\n", this.paramtxt)
			printf("{txt}paramtype is:{result} %s\n", this.paramtype)
			printf("{txt}comblabel is:{result} %s\n", this.comblabel)
			printf("{txt}combvlab is:{result} %s\n", this.combvlab)
			printf("{txt}interaction is:{result} %f\n", this.interaction)
			printf("{txt}___________________________________________________________\n")
	}
/*#######################################################################################*/
// CLASS model
/*#######################################################################################*/
class model {
	public:
		//public vars
		string scalar    estname       // name of a stored estimate in memory
		real   matrix    modscalars    // matrix with all data for model
		string colvector statistics    // list of statistics returned by matrixcolstripe(r(table))
		string colvector parameters    // full list of parameters from matrixrowstripe(r(table))
		string colvector levels        // colvector with base and omitted removed used to match params across models
		real   colvector interactions  // vector of boolean values indicating if parameter[row] is interaction
		real   colvector base          // vector of boolean values indicating if parameter[row] is base
		real   colvector omitted       // vector of boolean values indicating if parameter[row] is omitted
		real   colvector constfree     // vector of boolean values indicating if parameter[row] is _const or free
		
		//public functions
		void             setup()            // setup takes a name of a stored estimate in memory
		void             print()            // prints object properties to screen
		`RS'             get_beta()         // returns beta as real for a given level
		`RS'             get_pvalue()       // returns pvalue as real for a given level
		`RS'             get_ll()           // returns lower bound of ci as real for a given level
		`RS'             get_ul()           // returns upper bound of ci as real for a given level
		`boolean' scalar get_base()         // returns boolean==TRUE if level is a base
		`boolean' scalar get_intr()         // returns boolean==TRUE if level is a interaction
		`boolean' scalar get_eform()        // returns boolean==TRUE if level is in eform
		
	private:
	    // private vars
		class AssociativeArray scalar rtable // array to save rtable-data using string keys: parameter, statistic
	
		
	    // private functions
		void set_levels()
		void set_interactions()
		void set_base()
		void set_omitted()
		void set_constfree()
		
}
	/*#######################################################################################
	// CLASS model FUNCTIONS
	#######################################################################################*/
	void model::setup(string scalar estname) {
		string scalar com
		real scalar i, ii
				
		//get matrix rtable created by running estimates replay estname
		com= "estimates replay " + estname
		stata(com, 1)
		stata("mat M= r(table)")
		//stata("mat li M")
		stata("mat M= M'")
		
		modscalars= st_matrix("M")

		parameters= st_matrixrowstripe("M") //get varlist of model
		statistics= st_matrixcolstripe("M") //get stats of model
		statistics= statistics[.,2] 		//remove first col that is all missing
		parameters= parameters[.,2] 		//remove first col that is all missing
		
		set_levels()        //set the string vector levels contining paramters with base/omitted stripped
		set_interactions()  //set the boolean vector indicating if parameter/level is an interaction
		set_base()          //set the boolean vector indicating if parameter/level is base/omitted
		set_constfree()     //set the boolean vector indicating if parameter/level is _const or free
		
		// fill array rtable with data from modscalars for each statistics
		// reinitate the assositative array as array with 3 dimention string keys
		this.rtable.reinit("string", 2) 
		this.rtable.notfound(.)
		
			for (ii=1; ii<=length(this.statistics); ii++) {
				for (i=1; i<=length(this.levels); i++) {
					this.rtable.put((this.statistics[ii], this.levels[i]), this.modscalars[i,ii])
				}
			}
		
	}
	/***************************************************************************
	Function returns boolean TRUE if supplied level is a baselevel
	****************************************************************************/
	`boolean' scalar model::get_base(`SS' level) {
		`RS' i
		
		i= selectindex(regexm(this.levels, "^" + level + "$"))
		//In cases where level is not in the list of model levels selectindex()
		// will return J(0,0,.) an empty real vector and not a scalar

		if(orgtype(i) == "scalar") return(this.base[i])
		else return(`FALSE')
	}
	/***************************************************************************
	Function returns boolean TRUE if supplied level is an interaction
	****************************************************************************/
	`boolean' scalar model::get_intr(`SS' level) {
		`RS' i
		
		i= selectindex(regexm(this.levels, "^" + level + "$"))
		//In cases where level is not in the list of model levels selectindex()
		// will return J(0,0,.) an empty real vector and not a scalar

		if(orgtype(i) == "scalar") return(this.interactions[i])
		else return(`FALSE')
	}
	/***************************************************************************
	Function returns boolean TRUE if supplied level is in eform
	****************************************************************************/
	`boolean' scalar model::get_eform(`SS' level) {
		return(this.rtable.get(("eform", level)))
	}
	/***************************************************************************
	Function returns beta-value for supplied level
	****************************************************************************/
	`RS' model::get_beta(`SS' level) {
		return(this.rtable.get(("b", level)))
	}
	/***************************************************************************
	Function returns p-value string param 
	****************************************************************************/
	`RS' model::get_pvalue(`SS' level) {
		return(this.rtable.get(("pvalue", level)))
	}
	/***************************************************************************
	Function returns upper bound of ci as real
	****************************************************************************/
	`RS' model::get_ul(`SS' level) {
		return(this.rtable.get(("ul", level)))
	}
	/***************************************************************************
	Function returns lower bound of ci as real
	****************************************************************************/
	`RS' model::get_ll(`SS' level) {
		return(this.rtable.get(("ll", level)))
	}
	/***************************************************************************
	Function sets the boolean vector indicating if parameter/level is _const or free
	****************************************************************************/
	void model::set_constfree() {
		real scalar r
		
		this.constfree= J(length(this.parameters), 1, .)
		
		for (r=1; r<=length(this.parameters); r++) {
			// match paramaters that has _/ at beginning of string
			this.constfree[r]= regexm(this.parameters[r], "^[_/]")
		}
			
		
	}
	/***************************************************************************
	Function sets the string vector levels contining pramters with base/omitted stripped
	****************************************************************************/
	void model::set_levels() {
		real scalar r
		string scalar param
		
		this.levels= J(length(this.parameters), 1, "")
		
		for (r=1; r<=length(this.parameters); r++) {
			param= this.parameters[r]
			// remove base and omitted charathers
			while(regexm(param, "[bo]+\.")) param= regexr(param, "[bo]+\.", ".")
			// remove contionious chanter in intercations
			while(regexm(param, "[c]+\.")) param= regexr(param, "[c]+\.", "")
			
			
			this.levels[r]=param
		}
			
		
	}
	/***************************************************************************
	Function sets the boolean vector indicating if parameter/level is an interaction
	****************************************************************************/
	void model::set_interactions() {
		`RS' r
		
		this.interactions= J(length(this.parameters), 1, .)
		
		for (r=1; r<=length(this.parameters); r++) {
			this.interactions[r]= (strrpos(this.parameters[r],"#") > 0)
		}
	}
	/***************************************************************************
	Function sets the boolean vector indicating if parameter/level is base/omitted
	****************************************************************************/
	void model::set_base() {
		`RS' r, i, baseom
		`SS' prefix
		`SCV' intervars
		
		this.base= J(length(this.parameters), 1, .)
			
		for (r=1; r<=length(this.parameters); r++) {
		
			if (this.interactions[r]) {
				//check if all incuded factors in interaction are base or omitted
				intervars=tokens(subinstr(this.parameters[r], "#", " ") ) //matrix with varnames forming the interaction
				
				baseom= 0
				
				for (i=1; i<=length(intervars); i++) {
					// assign part of string before . to P.prefix
					prefix= substr(intervars[i] , 1 , strrpos(intervars[i],".")-1 )
					// increment bases if it is a base or omitted factor but not nobase
					if((strrpos(prefix,"b")  > 0 | strrpos(prefix,"o") > 0) & !strrpos(prefix,"n")) baseom++
				}
				
				// check if all factors are base or omitted
				this.base[r]= (length(intervars)==baseom)
			
			}
			else {	// if it is not an interaction
				prefix= substr(this.parameters[r] , 1 , strrpos(this.parameters[r],".")-1)
				this.base[r]=(strrpos(prefix,"b")  > 0 | strrpos(prefix,"o") > 0) 
			}	
		}		
	}
	/***************************************************************************
	Function prints object properties to screen
	****************************************************************************/
	void model::print() {	
		
		`SS' tabrowtxt, colwith
		`RS' i
		
		colwith=strofreal(max(strlen(this.parameters))+10)
		colwith
		
		//this.parameters, this.levels, strofreal(this.interactions), strofreal(this.base)) 
		
		printf("{txt}--- Object model: --------------------------------------\n")
		printf("{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}")
		printf("{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}")
		printf("{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}\n\n")
		//hline 1
		printf("{hline 4 }{c +}") //5
		printf("{hline 34}{c +}") //40
		printf("{hline 3 }{c +}") //44
		printf("{hline 3 }{c +}") //48
		printf("{hline 3 }{c +}") //52
		printf("{hline 26}{c +}\n") //79
		//hline 2
		printf("{txt}{space 2}R{space 1}{c |}")
		printf("{space 1}parameters{col 40}{c |}")
		printf("{space 1}#{space 1}{c |}")
		printf("{space 1}B{space 1}{c |}")
		printf("{space 1}C{space 1}{c |}")
		printf("{space 1}levels{col 79}{c |}\n")
		//hline 2
		printf("{hline 4 }{c +}") //5
		printf("{hline 34}{c +}") //40
		printf("{hline 3 }{c +}") //44
		printf("{hline 3 }{c +}") //48
		printf("{hline 3 }{c +}") //52
		printf("{hline 26}{c +}\n") //79
		// lines table
		for (i=1; i<=length(this.parameters); i++) {
			
			            tabrowtxt= "{result}{space 1}%2.0f{space 1}{txt}{c |}"
			tabrowtxt= tabrowtxt + "{result}{space 1}%s{col 40}{txt}{c |}"
			tabrowtxt= tabrowtxt + "{result}{space 1}%1.0f{space 1}{txt}{c |}"
			tabrowtxt= tabrowtxt + "{result}{space 1}%1.0f{space 1}{txt}{c |}"
			tabrowtxt= tabrowtxt + "{result}{space 1}%1.0f{space 1}{txt}{c |}"
			tabrowtxt= tabrowtxt + "{result}{space 1}%s{col 79}{txt}{c |}\n"
			
			printf(tabrowtxt, i, this.parameters[i], this.interactions[i], this.base[i], this.constfree[i], this.levels[i])
		}
		printf("{txt}{hline 4}{c BT}")
		printf("{hline 34}{c BT}")
		printf("{hline 3 }{c BT}")
		printf("{hline 3 }{c BT}")
		printf("{hline 3 }{c BT}")
		printf("{hline 26}{c BT}\n")
		
		
		
		printf("{txt}estname is:{result} %s\n", this.estname)
		printf("{txt}___________________________________________________________\n")
		
	}	
/*#######################################################################################*/
// CLASS estdocxtable
/*#######################################################################################*/
class estdocxtable {
	public:
		//public vars
		class     model colvector models
		class     parameter scalar par

		string    colvector levels                // uniq ordered list of levels
		string    colvector terms                 // colvector with unique set of terms in all models
		string    colvector keep                  // terms to keep in the table and their ordering
		string    colvector types
		string    colvector labels
		string    colvector vlabs
		string    scalar    fname                 // framename used to store the table
		string    scalar    bfmt                  // %fmt for beta
		string    scalar    ci                    // %fmt for confidence interval
		`boolean' scalar    eform
		`boolean' scalar    baselevels
		`boolean' scalar    nopval
		real      colvector star                  // numeric vector of sig < P cuttofs for * significanse markers
		
		//public functions
		void      setup()                          // setup takes a namlist of stored estimates
		void      create_display_frame()
		void      print()
		void      set_star()
		
		
	private:
		//private vars
		string vector estnames              // vector of the name of estimates
		
		//private functions
		void   set_ulevels()             // computes the uniq ordered list of levels that form the rows of table
		void   set_terms()               // computes the uniq ordered list of terms
		void   set_keep()                // computes the uniq ordered list of levels that form the rows of table
		
		void   create_display()
		`SS'   get_beta()
		`SS'   get_pvalue()
		`SS'   get_ci()
		
}
/*#######################################################################################
// CLASS estdocxtable FUNCTIONS
#######################################################################################*/
	void estdocxtable::setup(`SS' estnames_txt,
					       | `SS' baselevels_txt,
		                     `SS' bfmt_txt,
		                     `SS' ci_txt,
		                     `SS' star_txt,
		                     `SS' nopval_txt,
		                     `SS' eform_txt,
						     `SS' fname_txt,
					         `SS' keep_txt
						   ) {
		real scalar i

		// convert string scalar to string vector of estnames
		estnames= tokens(estnames_txt)
		
		//return colvector model objects
		models= model(length(estnames))
		
		// run setup of model objects for estnames
		for (i=1; i<=length(estnames); i++) {
			models[i].setup(estnames[i])
			//models[i].print()
		}
		
	// set options in table object
	if(star_txt!="") this.star= strtoreal(tokens(star_txt))
	
	// set option nopval
	if(nopval_txt=="nopval") this.nopval= `TRUE'
	else this.nopval= `FALSE'
	
	// set options in table object
	if(baselevels_txt=="baselevels") this.baselevels= `TRUE'
	else this.baselevels= `FALSE'
	
	//set option eform
	if(eform_txt=="eform") this.eform= `TRUE'
	else this.eform= `FALSE'
	
	this.bfmt= bfmt_txt // default is %04.2f set in main of ado
	
	if(ci_txt!="") this.ci= ci_txt
	
	this.set_ulevels()
	this.set_terms()
		
	// convert string scalar to string vector of estnames
	if(keep_txt!="") {
		this.keep= tokens(keep_txt)				
		this.set_keep()
		}
		

	
		
	// run setup of parameter objects 
	for (i=1; i<=length(this.levels); i++) {
			par.setup(this.levels[i])
			this.types= this.types\par.paramtype
			this.labels= this.labels\par.comblabel
			this.vlabs= this.vlabs\par.combvlab
			
		}
	}
	/***************************************************************************
	Function takes a vector of model objects models and returns the unique
	list of levels with all duplicates removed => function as the rows
	of the regression table
	****************************************************************************/
	void estdocxtable::set_ulevels() {
	string colvector constants
	real scalar i, ii
	string scalar level
		
		//declare colvector constants
		constants= J(0, 1, "")
		
		for (i=1; i<=length(this.models); i++) {
		
			for (ii=1; ii<=length(this.models[i].levels); ii++) {
				level= this.models[i].levels[ii]
					
				// if it is constant or free and not in this.constants add it to constants
				if(this.models[i].constfree[ii]) {
					if(!anyof(constants, level)) constants= constants\level
				}
				
				// if it is not an interaction add it regardless and jump to next level
				else if(!this.models[i].get_intr(level)) { 
					if(!anyof(this.levels, level)) this.levels= this.levels\level
				}
				
				// if it is an interaction and not a baselevel add it and jump to next level
				else if(!this.models[i].get_base(level)) { 
					if(!anyof(this.levels, level)) this.levels= this.levels\level
				}
				// if baselevels add it anyway and jump to next level
				else if(this.baselevels==`TRUE') { 
					if(!anyof(this.levels, level)) this.levels= this.levels\level
				}
			}
		}
		
		// add the unique set of constants/ancilliary parameters to the end of the rowvarlist
		this.levels= this.levels\constants
		

		
	
		
		
	}
	/***************************************************************************
	Function takes a vector of model objects models and returns the unique
	list of levels with all duplicates removed => function as the rows
	of the regression table
	****************************************************************************/
	/***************************************************************************
	Function sets the string vector levels contining pramters with base/omitted stripped
	****************************************************************************/
	void estdocxtable::set_terms() {
		real scalar r
		string scalar term
		
		
		
		for (r=1; r<=length(this.levels); r++) {
			term= this.levels[r]
			// remove factor, base, omitted, nobase and continious charathers
			while(regexm(term, "[0-9bocn]+\.")) term= regexr(term, "[0-9bocn]+\.", ".")
			term= subinstr(term, ".", "")
			
			if(!anyof(this.terms, term)) this.terms= this.terms\term
		}
			
		
	}
	/***************************************************************************
	Function limits the set of levels displayed in the table
	****************************************************************************/
	void estdocxtable::set_keep() {
		`RS' i, ii
		`SCV' keeplevels
		real colvector add
		`SS' term
		
			//check that all all terms in keep exists in models
			for (i=1; i<=length(this.keep); i++) {
				
				if(!anyof(this.terms, this.keep[i])) {
					printf("{error}ERROR: The term {txt}%s{error} is incorrectly specified or does not exist in any of the models{txt}\n", this.keep[i])
					exit(error(193))
				}
			}
		
		
		//declare colvector this_unique => limited and ordered version of coiffcents returned
		keeplevels= J(0, 1, "")
	
		//loop over terms to be keept
		for (i=1; i<=length(this.keep); i++) {
		
			add= J(0, 1, .)
			for (ii=1; ii<=length(this.terms); ii++) {
				if(this.terms[ii]==this.keep[i]) add= add\ii
				
			}
			
		keeplevels	= keeplevels\this.levels[(add)]
		}

		this.levels= keeplevels
		
	}
	/***************************************************************************
	Function writes paramters for all estnames to display frame
	****************************************************************************/
	void estdocxtable::create_display_frame(| string scalar fname) {
		string matrix table
		string colvector frames
		string scalar colwidh, paramtext
		real   scalar i, ii, mpl, c, varindex

		if(fname=="" ) this.fname= st_tempname()
		else this.fname= fname
	
		frames= st_framedir()
		
		//check if there is a frame in memory with the same name as this.fname
		//and drop it from memory if there is
		for (i=1; i<=length(frames); i++) {
			if(frames[i]==this.fname) {
				st_framecurrent("default")
				st_framedrop(this.fname)
			}
		}
		
		//create the frame for the table and switch to frame
		st_framecreate(this.fname)
		st_framecurrent(this.fname)
				
		// add column for paramters with a widh/characthers of the longest parameter
		varindex= st_addvar(max(strlen(this.levels)), "params")
		varindex= st_addvar(max(strlen(this.types)), "type")
		varindex= st_addvar(max(strlen(this.labels)), "label")
		varindex= st_addvar(max(strlen(this.vlabs)), "vlab")
	
		
		// add columns for for each model
		for (i=1; i<=length(this.estnames); i++) {
			varindex= st_addvar("str25", this.estnames[i])
		}
				
		
		// add rows euqal
		st_addobs(length(this.levels))

		
		st_sview(table, ., .)  // load dataset from stata
		
		for (i=1; i<=length(this.levels); i++) {
			// write full parameter text to row header
			table[i,1]= this.levels[i]
			// måste skapa vector med param-object innan jag är i view-frame
			table[i,2]= this.types[i]
			table[i,3]= this.labels[i]
			table[i,4]= this.vlabs[i]
			
			// get stats for each model and form the celltext
			for (ii=1; ii<=length(this.models); ii++) {
				c= ii+4
				
				
				//always get beta
				paramtext= this.get_beta(this.models[ii], this.levels[i])
				
				
				// if ci is TRUE add/get CI, that it is valied fmt is confirmed in main ado
				if(this.ci!="") paramtext= paramtext + this.get_ci(this.models[ii], this.levels[i])
			
				
				//add/get p-value
				if(!this.nopval) paramtext= paramtext + this.get_pvalue(this.models[ii], this.levels[i])
			
				// write full parameter text to cell in display frame
				table[i,c]= paramtext
				
			}
		}
		
		

	}
	/***************************************************************************
	Function returns formated beta-value string for model, param 
	****************************************************************************/
	`SS' estdocxtable::get_beta(class model scalar mod, `SS' level) {
		string scalar beta

		
		if(mod.get_base(level))	{
			beta= "(base)"
		}
		else if(!this.eform){
			beta= sprintf(this.bfmt, mod.get_beta(level))
		}
		else {
			
			if(!mod.get_eform(level)) beta= sprintf(this.bfmt, exp(mod.get_beta(level)))
			else beta= sprintf(this.bfmt, mod.get_beta(level))
			
		}
		return(beta)
		
	}
	/***************************************************************************
	Function returns formated CI string for model, param 
	****************************************************************************/
	`SS' estdocxtable::get_ci(class model scalar mod, `SS' level) {
		string scalar ci, lowb, highb
		real scalar ll, ul
		
		ll= mod.get_ll(level)
		ul= mod.get_ul(level)
		
		// 95% CIs
		lowb= strofreal(ll, this.ci)
		highb= strofreal(ul, this.ci)
		if(lowb!=".") ci= " (" + lowb + " " + highb + ")"
				
		return(ci)
		
	}
	/***************************************************************************
	Function returns formated p-value string for model, param 
	****************************************************************************/
	`SS' estdocxtable::get_pvalue(class model scalar mod, `SS' level) {
		string scalar pvalue
		real scalar p, i
		
		p= mod.get_pvalue(level)
		
		if(length(this.star)) {
			//add stars according to cutoffs
			for(i=1; i<=cols(this.star); i++) {
				if  (p < this.star[i]) pvalue= pvalue + "*"
				}
		}
		else {
			// star is FALSE return numeric pvalue
			pvalue= substr(strofreal(p, "%5.3f"), 2, .)
			// if there is a pvalue add that to the pramter in pertenthesis
			if(pvalue!="")  pvalue= " (" + pvalue + ")"
		}
		
		

		return(pvalue)
		
	}
	/***************************************************************************
	Function displays table of object propreties
	****************************************************************************/
	void estdocxtable::print() {
		real scalar i
		printf("{txt}{hline 80}\n")
		printf("{txt}------------------ OBJECT ESTDOCXTABLE: -----------------------------------\n")
		printf("{txt}{hline 80}\n")
		printf("{txt}estnames is:")
		for (i=1; i<=length(this.estnames); i++) {
			printf("{result} %s, ", this.estnames[i])
		}
		printf("\n")
		printf("{txt}baselevels is:{result} %f\n", this.baselevels)
		printf("{txt}bfmt is:{result} %s\n", this.bfmt)
		printf("{txt}ci is:{result} %s\n", this.ci)
		printf("{txt}eform is:{result} %f\n", this.eform)
		printf("{txt}fname is:{result} %s\n", this.fname)
		printf("{txt}nopval is:{result} %f\n", this.nopval)
		printf("{txt}star is:")
		for (i=1; i<=length(this.star); i++) {
			printf("{result} %f, ", this.star[i])
		}
		printf("\n")
		
		printf("{txt}---------------------------------------------------------------------------\n")
		"estnames" 
		this.estnames
		"levels"
		this.levels
		"terms"
		this.terms
	
		printf("{txt}{hline 80}\n")
		printf("{txt}------------------ END OBJECT ESTDOCXTABLE: -------------------------------\n")
		printf("{txt}{hline 80}\n")
		
	}

/*###############################################################################################
// FUNCTIONS CALLED DIRECTLY FROM ADO
###############################################################################################*/

void create_frame_table(`SS' estnames,
					  | `SS' baselevels,
		                `SS' bfmt,
		                `SS' ci,
		                `SS' star,
		                `SS' nopval,
		                `SS' eform,
						`SS' fname,
					    `SS' keep
		                ) {
	//declare function objects, structures and variables						
	class estdocxtable scalar table
	string scalar orgframe
	//print_opts(estnames, keep, bfmt, ci, star, baselevels, nopval, eform, fname)
	
	// if program ha been run prior to running with the option fname current frame will
	// not be the dataframe used to run the estimates but viewframe and routine will not before
	// able to read varaible properties for the models r(orgframe) will not be null => Swith to  
	

	// I need to set up all the options in the setup function for teh class to work
	table.setup(estnames,
				baselevels,
		        bfmt,
		        ci,
		        star,
		        nopval,
		        eform,
				fname,
				keep)

	table.create_display_frame(fname)

	//table.print()
	
	
}

/*###############################################################################################*/
void print_opts(`SS' estnames,
              | `SS' keep,
		        `SS' bfmt,
		        `SS' ci,
		        `SS' star,
		        `SS' baselevels,
		        `SS' nopval,
		        `SS' eform,
				`SS' fname
		        ) {
	printf("{txt}--- INPUT: --------------------------------------\n")
	
	printf("{txt}estnames is:{result} %s\n", estnames)
	printf("{txt}keep is:{result} %s\n", keep)
	printf("{txt}bfmt is:{result} %s\n", bfmt)
	printf("{txt}ci is:{result} %s\n", ci)
	printf("{txt}star is:{result} %s\n", star)
	printf("{txt}baselevels is:{result} %s\n", baselevels)
	printf("{txt}nopval is:{result} %s\n", nopval)
	printf("{txt}eform is:{result} %s\n", eform)
	printf("{txt}fname is:{result} %s\n", fname)
	printf("{txt}__________________________________________________\n")
}






end











