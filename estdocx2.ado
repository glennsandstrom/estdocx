/**************************************************************************/
/**TODO  **/
/**************************************************************************/
// * DONE:Implement a keep(coeflist) option and report coefficients in order specified
// 
// * DONE: Implement possibility to report 95%CI rather than p-values or both....
// 
// * DONE: Implement an inline-mode that inserts table in document in memory rather than saves to a file
//
// * Format stats N with tousand number separator i.e. 1,000,000
//
// * PARTIALLY: Implement eform option to transform non exponatisated coefficients...
//   fixed but does not handle multiple equation models such as'
//   xtlogit with ancilliary paramters that should not be transformed. Program needs to honor the 
//   equation name where free paramters have a different equation name, In r(table) all params 
//   after / in the equation name are free paramters "Free parameters are scalar parameters, 
//   variances, covariances, and the like that are part of the model being fit"
//   
//   These should be handled differntly removed from the matrix of parameters and placed 
//   in the stats matrix and handled separatly printed under each model. Asi the program work now
//   it print also the free paramters in eform wich is an error.
//
//
// * BUG:if a variable has no valuelables program ends in Error st_vlmap():  3300  argument out of range
// * BUG: if factor has more than single digit level program throws error
//   for some reason I have introduced a catch that throws arguemnt out of range in mata-function param-type
//   Temporarly I comment this out but need to figure out why i did this in the first place
//
//
// * Implement additonal signs for significanse with dagger mark as e.g. style
//   in Demography.
//
// * Implement higher order interactions than 2-way.... Simplify the functions paramtype
//   Only needs to return factor, factor-interaction (includes factor#continious), 
//   continious (includes constants, continious-interactions)
//	 Goal is to simplifiy the forming of rowlabels for differnt types of interacations
//   and to handle situations when there are either no label or no value-labels
//   assossiated to one or more variables/levels in the paramteter that forms the row of the table
//
// * Handle stratified variables in cox-regressions
// 
// * Implement option to set the titles of models
//
// * Implement a possibility to include a note below the regression table e.g. source comment etc.
//
// 
/*###############################################################################################*/
/**SUB-ROUTINES  **/
/*###############################################################################################*/
	/*########################################################################*/
	program check_stats
		version 15.1
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
/*###############################################################################################*/
// MAIN PROGRAM
/*###############################################################################################*/
program estdocx
	version 15.1
  
	syntax namelist(min=1),	///
		[saving(string)] ///
		[inline] ///
		[title(string)] ///
		[bfmt(string)] ///
		[ci(string)] ///
		[star(string)] ///
		[stats(string)] ///
		[baselevels] ///
		[keep(string)] ///
		[pagesize(string)] ///
		[landscape] ///
		[Nopval] ///
		[eform] ///
		[fname(string)] 
		
		// You need to captalize all options that start with no; otherwise Stata treats at as a optionally off eg. p is off
		


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
	

	/**************************************************************************/
	/** Call MATA to set up frame with the desired regression table **/
	/**************************************************************************/
	


		
**# Bookmark #1

		mata: create_frame_table("`estnames'",     ///
								 "`baselevels'", ///
								 "`bfmt'",       ///
								 "`ci'",         /// 
								 "`star'",       ///
								 "`nopval'",       ///
								 "`eform'",       ///
								 "`fname'",       ///
								  "`keep'"      ///
								 )
	
/*
	/**************************************************************************/
	/** CREATE TABLE                     **/
	/**************************************************************************/
	// if !inline first create docx in memory to hold the table
	if("`inline'"=="") create_docx , pagesize(`pagesize') `landscape'
	
	
	/**************************************************************************/
	/** PRINT THE TABLE FROM FRAME */
	/**************************************************************************/
	
//create worddoc 
	putdocx clear
	putdocx begin, pagesize(A4) 
	putdocx paragraph, halign(left)
	putdocx text ("Table 1: "), bold font(Garamond, 13)
	putdocx text ("Models" ), font(Garamond, 13) 

	// create the header rows of the table 
	putdocx table tab1 = (1, 4), ///
	border(start, nil) ///
	border(top, nil) ///
	border(insideH, nil) ///
	border(insideV, nil) ///
	border(end, nil) ///
	halign(left) layout(autofitcontents)
	putdocx table tab1(1,1) = ("Variable"), bold font(Garamond, 11) halign(left)
	putdocx table tab1(1,2) = ("Model 1"), bold font(Garamond, 11) halign(center)
	putdocx table tab1(1,3) = ("Model 2"), bold font(Garamond, 11) halign(center)
	putdocx table tab1(1,4) = ("Model 3"), bold font(Garamond, 11) halign(center)
	
local rows= _N
local rt= 1
forvalues rd= 1(1)`rows' {
	
	putdocx table tab1(`rd',.), addrows(1, after) // add a row to the table
	local ++rt
	putdocx table tab1(`rt',1) = (params[`rd']), font(Garamond, 10) halign(center)

}

putdocx save temp/estocx.docx, replace

	
	/**************************************************************************/	
	// ADD STATS TO BOTTOM OF TABLE IF stats!=null
	/**************************************************************************/
	if ("`stats'"!="") write_stats `models', stats(`stats') row(`row')
	/**************************************************************************/	
	// print a legend with significance values
	/**************************************************************************/
	qui putdocx describe esttable
	if("`star'"!="none" & "`nopval'"=="") write_legend, star(`star') row(`r(nrows)') col(`r(ncols)')
	/**************************************************************************/
	/** Save worddocument if program is not in inline mode           **/
	/**************************************************************************/
	//putdocx describe esttable
	if("`inline'"=="") putdocx save "`saving'", replace
	
	/**************************************************************************/
	/** Garbage collection             **/
	/**************************************************************************/
	//matrix drop _all
*/
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

				//get only the numeric value in prefix if it contains letters to get valuelabel with st_varvaluelabel()
				// match the numbers with regexm and tehn return them with regexs
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
				
				//contionios variables haver no base-level
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
//# Bookmark #5
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
		`boolean' scalar get_intr()         // returns boolean==TRUE if level is a base
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
		
		set_levels()        //set the string vector levels contining pramters with base/omitted stripped
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
					// increment bases if it is a base or omitted factor
					if(strrpos(prefix,"b")  > 0 | strrpos(prefix,"o")  > 0) baseom++
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
		"parameters, levels, interactions, base, omitted, constfree"

		printf("{txt}___________________________________________________________\n")
		
	}	
/*#######################################################################################*/
// CLASS estdocxtable
//# Bookmark #3
/*#######################################################################################*/
class estdocxtable {
	public:
		//public vars
		class     model colvector models
		string    colvector levels                // uniq ordered list of pramameters
		string    scalar    varnames              // uniq ordered list of varnames
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
		void   set_ulevels()                // computes the uniq ordered list of levels that form the rows of table
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
		string colvector allparams

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
	Function writes paramters for all estnames to display frame
	****************************************************************************/
	void estdocxtable::create_display_frame(| string scalar fname) {
		string matrix table
		string colvector frames
		string scalar colwidh, paramtext
		real scalar i, ii, mpl, c, varindex
		

		if(fname=="" ) this.fname= st_tempname()
		else this.fname= fname
	
		frames= st_framedir()
		
		for (i=1; i<=length(frames); i++) {
			if(frames[i]==this.fname) {
				st_framecurrent("default")
				st_framedrop(this.fname)
			}
		}
		
		st_framecreate(this.fname)
		st_framecurrent(this.fname)
		
		//remove base and omitted from interaction paramteters if baselevels is FALSE
		//if(!this.baselevels) remove_baselevels()

		
		//find maximum number of characthers of in parameters
		mpl=max(strlen(this.levels))
		colwidh= "str" + strofreal(mpl) // stringfomrat mpl number of characthers
		// add column for paramters with a widh/characthers of the longest parameter
		varindex= st_addvar(colwidh, "params")
		
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
			
			
			// get stats for each model and form the celltext
			for (ii=1; ii<=length(this.models); ii++) {
				c= ii+1
				
				
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
	
		printf("{txt}{hline 80}\n")
		printf("{txt}------------------ END OBJECT ESTDOCXTABLE: -------------------------------\n")
		printf("{txt}{hline 80}\n")
		
	}

/*###############################################################################################
// FUNCTIONS CALLED DIRECTLY FROM ADO
###############################################################################################*/
//# Bookmark #2

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
	
	print_opts(estnames, keep, bfmt, ci, star, baselevels, nopval, eform, fname)
	
	// set set all table propreties to default values values

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

	table.print()
	
	
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











