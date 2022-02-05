

/*###############################################################################################*/
// MAIN PROGRAM
/*###############################################################################################*/

//capture program drop estdocx

program estdocx
	version 15.1
  
	syntax namelist(min=1),	///
		[saving(string)] ///
		[inline] ///
		[title(string)] ///
		[b(string)] ///
		[ci(string)] ///
		[star(string)] ///
		[stats(string)] ///
		[baselevels] ///
		[keep(string)] ///
		[pagesize(string)] ///
		[landscape] ///
		[Nop] ///
		[eform]
		
		
		// You need to captalize all options that start with no; otherwise Stata treats at as a optionally off eg. p is off
		

// di "main: nop: `nop'"
// di "main: eform: `eform'"
	// set local holding the names of estimates to be reported in table
	local models= "`namelist'" //space separated list of estimates
	
	// set local holding list of allowed statistics
	local allowed "none N aic bic"
	
	// default values for options if none are provided
	if ("`star'"=="") local star "none" // default is to report numerical p-value in pertenthesis
	if ("`b'"=="") local b "%04.2f"
	if ("`saving'"=="") local saving "estimates_table.docx"
	if ("`pagesize'"=="") local pagesize "A4"
	
	// if stats is provided check that all stats are allowed/implemented
	if ("`stats'"!="") check_stats `stats', allowed(`allowed')
	if ("`stats'"=="") local stats "N" // set default stat N if stats is not provided
	if ("`stats'"=="none") local stats "" // set stat null string if stat(none)
	
	/**************************************************************************/
	/** CREATE TABLE                     **/
	/**************************************************************************/
	// if !inline first create docx in memory to hold the table
	if("`inline'"=="") create_docx , pagesize(`pagesize') `landscape'
	// then create the table in the document currenlty in memory
	create_table `models', pagesize(`pagesize') title(`title') `landscape' 
	//putdocx describe esttable
	/**************************************************************************/
	/** Get unique varlist from estimates for each of the specified models **/
	/**************************************************************************/
	if("`keep'"=="") get_models `models'
	else get_models `models', keep(`keep')
	// returns 
	// 1. r(params)= MACRO STRING nicley formated list of unique paramters making 
	//    up rows in the returned matrix 
	// 2. r(numparams)= SCALAR Number of paramters
	// 3. r(model_betas) MATRIX beta of all models
	// 4. r(model_p) MATRIX pvalues of all models
	// 5. r(model_ll) MATRIX lower CI of all models
	// 6. r(model_ul) MATRIX upper CI of all models
	// 7. r(model_eform) MATRIX of bolean values indicating if parameter is in eform or not
	/**************************************************************************/
	/** PRINT ALL THE UNIQUE VARIABLES OCCURING IN THE MODELS AND THEIR LEVELS*/
	/**************************************************************************/
	local row= 1
	local betarow= 1
	local rows: rowsof r(model_betas) // rows of full table
	// Here I fetch the full rowvarlist for the complete table ex.
	// 1bn.race 2.race 3.race age 0bn.collgrad 1.collgrad that I loop over
	// and print each paramter/row of the full table
	local varlist: rowvarlist r(model_betas)
	
	foreach var in `varlist' {
			
		/**************************************************************************/	
		// Check the type of the parameter 1. CONTINIOUS/CONS 2. FACTOR 3.INTERACTION 
		/**************************************************************************/
		// get the type of paramter and the full label and value label to print
		// in the row, differntiate between base levels and parmaters that are not 1|0
		mata: paramtype("`var'") //returns locals: paramtype, label, vlab
// 		di "var= `var'"
// 		di "paramtype= `paramtype'"
// 		di "label= `label'"
// 		di "vlab= `vlab'"
		// print paratmters that are facors or intercations including factors that have 
		// more than one level
		if "`paramtype'"=="factor" | "`paramtype'"=="factor-interaction"{
			// Always print if base==FALSE and only print if baselevels== TRUE if base==TRUE
			if !baselevels[`betarow', 1] | "`baselevels'"!="" {
				//check if varname is in the list of printed varnames
				local lab= subinstr("`label'", " ", "", .) //remove all whitespace
				
				local print : list posof "`lab'" in printed
				//add a header row with variable label for factor variables that has been added to the table
				if !`print' {
					// add header row with varname of factor variable
					putdocx table esttable(`row',.), addrows(1)
					local ++row
					putdocx table esttable(`row',1) = ("`label'"), bold font(Garamond, 11) halign(left)
					local printed "`printed' `lab'" //add varname to list of printed headers
				}
				
				// print row with factor parameters 
				write_level `models', row(`row') var(`var') vlab(`vlab') bfmt(`b') star("`star'") ci("`ci'") `eform' `nop'
				local ++row
			}
		}
		// here paramtype should return continious
		else if "`paramtype'"=="continious" | "`paramtype'"=="continious-interaction" | "`paramtype'"=="const" {
		
			write_continious `models', row(`row') var(`var') varlabel(`label') bfmt(`b') star("`star'") ci("`ci'") `eform' `nop'
			local ++row
			local printed "`printed' `lab'"
				
		}
		else {
			di as error "{error} Program does not support this type of parameter"
		
		}
	local ++betarow
	}
	
	// set border on bottom of header row of table
	putdocx table esttable(1,.), border(bottom)
	// set border at bottom beta table
	putdocx table esttable(`row',.), border(bottom)
	
	/**************************************************************************/	
	// ADD STATS TO BOTTOM OF TABLE IF stats!=null
	/**************************************************************************/
	if ("`stats'"!="") write_stats `models', stats(`stats') row(`row')
	/**************************************************************************/	
	// print a legend with significance values
	/**************************************************************************/
	qui putdocx describe esttable
	if("`star'"!="none" & "`nop'"=="") write_legend, star(`star') row(`r(nrows)') col(`r(ncols)')
	/**************************************************************************/
	/** Save worddocument             **/
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

mata:
/*#######################################################################################*/
// STRUCTURES
/*#######################################################################################*/
struct model {
	real matrix rtable
	string vector params, stats


}
/*#######################################################################################*/
// CLASS rowvarlist
/*#######################################################################################*/

class rowvarlist {
	public:
		//public vars
		string colvector unique
		string colvector uvarnames
		string colvector constants
		
		//public functions
		void setup() // setup takes a namlist of stored estimates
		void print()
		
	
	private:
		//private vars
		
		
		//private functions
		string colvector get_uniqvarnames()
		
	
	
	
	
}

/*#######################################################################################*/
// CLASS estdocxtable
/*#######################################################################################*/
class estdocxtable {
	public:
		//public vars
		class AssociativeArray scalar rtables // array to save numerical stats with striong keys for all paramters in models
		class rowvarlist scalar rowvarlist    // computes the uniq ordered list of pramaters that for row of table
		string scalar parameters              // uniq ordered list of pramaters
		string scalar varnames                // uniq ordered list of varnames
		real scalar maxparamlength
		//public functions
		void setup()                          // setup takes a namlist of stored estimates
		real scalar get_stat()
		
	private:
		//private vars
		string vector models              // vector of the name of estimates
		
		//private functions
		struct model get_rtable()         // function returing structure (rtable, params, stats) for model
		void create_display()
}
/*#######################################################################################*/
// CLASS estdocxtable FUNCTIONS
/*#######################################################################################*/
	void estdocxtable::setup(string scalar models) {
		struct model scalar mod // structure holding 
		
		real scalar i, ii, iii, maxparamlength
		string colvector allparams
		string vector test

		
		// convert string scalar to string vector of models
		this.models= tokens(models)
			
		// reinitate the assositative array as array with 3 dimention string keys
		this.rtables.reinit("string", 3) 
		this.rtables.notfound(.)
		
		//declare colvector allparams
		allparams= J(0, 1, "")

		// fill AssociativeArray T with data from struct mod
		for (iii=1; iii<=length(this.models); iii++) {
			
			// create and return struct holding mat rtable and string vectors params stats
			mod= get_rtable(this.models[iii])
			
			// stack colvector allparams with the params of model
			if(!length(allparams)) allparams= mod.params
			else allparams= allparams\mod.params
					
			for (ii=1; ii<=length(mod.stats); ii++) {
				for (i=1; i<=length(mod.params); i++) {
					this.rtables.put((this.models[iii], mod.stats[ii], mod.params[i]), mod.rtable[i,ii])
					//printf("{txt}%s  {res}%f\n",mod.params[i], mod.rtable[i,1])
				}
			}
			
		}
		

		this.rowvarlist.setup(allparams)
		this.parameters = this.rowvarlist.unique
		this.varnames = this.rowvarlist.uvarnames
		
		//this.rtables.keys()
		//test= ("men1830", "b", "39.ageL1")
		//this.rtables.exists(test)
		//this.rtables.get(test)
		
		this.create_display()
		
		
		
		
	}
	
	/***************************************************************************
	Function takes a estimtate name and returns a model structure with rtable, params and stats
	****************************************************************************/
	struct model estdocxtable::get_rtable(string scalar estname) {
		string scalar com
		struct model scalar mod
		com= "estimates replay " + estname
		stata(com, 1)
		stata("mat M= r(table)")
		//stata("mat li M")
		stata("mat M= M'")
		//get matrix rtable created by running estimates replay `model' in get_models
			mod.rtable= st_matrix("M")
			mod.params= st_matrixrowstripe("M") //get varlist of model
			mod.stats= st_matrixcolstripe("M") //get stats of model
			mod.stats= mod.stats[.,2] 			//remove first col that is all missing
			mod.params= mod.params[.,2] 			//remove first col that is all missing
					
			return(mod)

	}
	
	/***************************************************************************
	F
	****************************************************************************/
	real scalar estdocxtable::get_stat(string scalar model, string scalar param, string scalar stat) {
		real scalar value
		
			value= this.rtables.get((model, stat, param))
			return(value)

	}
	
	/***************************************************************************
	Funktion writes paramters for all models to dataframe
	****************************************************************************/
	void estdocxtable::create_display() {
		string matrix table
		string scalar cframename, dispname, colwidh
		real scalar i, ii, mpl, c
		
		cframename= st_framecurrent()
		//cframename
		//dispname= st_tempname()
		//if(st_frameexists(dispname)) _error("Can´t create display frame as frame with the anme already exists")
		//st_framecreate(dispname)
		
		st_framedir()
		st_framecurrent("_test")
		
		//find maximum number of characthers of in parameters
		mpl=max(strlen(this.parameters))
		colwidh= "str" + strofreal(mpl) 
		// set rows to the length of rowvarlist
		st_addvar(colwidh, "params")
		
		// add columns for variables
		for (i=1; i<=length(this.models); i++) {
			st_addvar("str15", this.models[i])
		}
		
		// add rows euqal
		st_addobs(length(this.parameters))

		
		st_sview(table, ., .)  // load dataset from stata
		
		for (i=1; i<=length(this.parameters); i++) {
			table[i,1]= this.parameters[i]
			for (ii=1; ii<=length(this.models); ii++) {
				c= ii+1
				table[i,c]=strofreal(this.get_stat(this.models[ii], this.parameters[i], "b"))
			}
		}
		
		

	}
/*#######################################################################################*/
// CLASS rowvarlist FUNCTIONS
/*#######################################################################################*/
	/***************************************************************************
	Function takes a vector of all paramters in all models and returns the unique
	list of pramameters with all duplicates removed => function as the rows
	of the regression table
	****************************************************************************/
	void rowvarlist::setup(string colvector allparams) {

	real scalar i, ii, found
	string scalar param, varname, prefix, find
		
		//declare colvector allvars
		this.constants= J(0, 1, "")
		
		// get the unique set of varnames in models with prefix stripped
		this.uvarnames= get_uniqvarnames(allparams)
		
		for (i=1; i<=length(this.uvarnames); i++) {
			// check if varname is a constant or free and at it to constants if not already there
			if(regexm(this.uvarnames[i], "^[_/]") & !anyof(this.constants, this.uvarnames[i])) this.constants=this.constants\this.uvarnames[i]
					
			find= "[0-9]*[obc]*\." + this.uvarnames[i] 
			//loop over complete list of parameters
			for (ii=1; ii<=length(allparams); ii++) {
				// check if the varname match find and it it to unique if not already there
				if(regexm(allparams[ii], find) & !anyof(this.unique, allparams[ii])) {
					//printf("{txt}pattern: {res}%s {txt}mathed to: {res}%s\n", find, allparams[ii])
					this.unique= this.unique\allparams[ii]
				}
			}
			
		}

		
		// add the unique set of constants/ancilliary parameters to the end of the rowvarlist
		this.unique= this.unique\this.constants
		
	}
	/***************************************************************************
	Function takes of all paramters in all models and returns the unique varnames
	found in the list of complete stack of paramters
	****************************************************************************/
	string colvector rowvarlist::get_uniqvarnames(allparams) {

	string colvector allvarnames, uvarnames
	string scalar param, vars, var
	real scalar i, ii

		allvarnames= J(0, 1, "")
		
			// remove numbers and letters before up until and including .
			for (i=1; i<=length(allparams); i++) {
				param= allparams[i,1]
				// for each mach of prefix remove it until non are left
				while(regexm(param, "[0-9]*[obc]*\.")) param= regexr(param, "[0-9]*[obc]*\.", "")
				//split by # into vector of varnames in the parameter
				vars= tokens(param, "#")
				for (ii=1; ii<=length(vars); ii++) {
					// add the var to varnames with the prefix removed
					if(vars[ii]!="#") allvarnames= allvarnames\vars[ii]
				}
			}
			
			// remove all duplicate varnames
			uvarnames= J(0, 1, "")
			for (i=1; i<=length(allvarnames); i++) {
				var= allvarnames[i,1]
				// check if cof is already in uvarnames and add it if it is not
				if(!anyof(uvarnames, var)) uvarnames= uvarnames\var
			}
			
			return(uvarnames)
					
	}

/*###############################################################################################*/
// FUNCTIONS
/*###############################################################################################*/




















