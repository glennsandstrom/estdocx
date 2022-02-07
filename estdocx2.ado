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
		[Nop] ///
		[eform]

		
		// You need to captalize all options that start with no; otherwise Stata treats at as a optionally off eg. p is off
		


	// set local holding the names of estimates to be reported in table
	local models= "`namelist'" //space separated list of estimates
	//loop over models to and check that they are valid estimation result names avalaible in memory

	qui estimates dir
	local estimates= r(names)
	foreach model in `models' {
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

		mata: create_frame_table("`models'",     /// 
		                         "`keep'",       ///
								 "`bfmt'",       ///
								 "`ci'",         /// 
								 "`star'",       ///
								 "`baselevels'", ///
								 " `Nop'",       ///
								 "`eform'"       ///
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
	if("`star'"!="none" & "`nop'"=="") write_legend, star(`star') row(`r(nrows)') col(`r(ncols)')
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
struct model {
	real matrix rtable
	string colvector params, stats


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
/*#######################################################################################*/
// CLASS estdocxtable
//# Bookmark #1
/*#######################################################################################*/
class estdocxtable {
	public:
		//public vars
		class     AssociativeArray scalar rtables // array to save numerical stats with striong keys for all paramters in models
		class     rowvarlist scalar rowvarlist    // computes the uniq ordered list of pramaters that for row of table
		string    scalar parameters              // uniq ordered list of pramaters
		string    scalar varnames                // uniq ordered list of varnames
		string    scalar fname                   
		string    scalar bfmt
		string    scalar ci
		`boolean' scalar eform
		
		//public functions
		void        setup()                          // setup takes a namlist of stored estimates
		`RS'        get_stat()
		void        create_display_frame()
		void        print()
		
	private:
		//private vars
		string vector models              // vector of the name of estimates
		
		//private functions
		struct model get_rtable()         // function returing structure (rtable, params, stats) for model
		void create_display()
}
/*#######################################################################################*/
//# Bookmark #2
// CLASS estdocxtable FUNCTIONS
/*#######################################################################################*/
	void estdocxtable::setup(`SS' models) {
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
	Function writes paramters for all models to dataframe
	****************************************************************************/
	void estdocxtable::create_display_frame() {
		string matrix table
		string colvector frames
		string scalar dispname, colwidh
		real scalar i, ii, mpl, c
		

		//dispname= st_tempname()
		dispname= "estdocx"
		frames= st_framedir()
		
		for (i=1; i<=length(frames); i++) {
			if(frames[i]==dispname) st_framedrop(dispname)
		}
		
		st_framecreate(dispname)
		st_framecurrent(dispname)
		
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
void estdocxtable::print() {
	printf("{txt}--- Object estdocxtable: --------------------------------------\n")
	"models" 
	this.models
	"varnames"
	this.varnames
	
	printf("{txt}bfmt is:{result} %s\n", this.bfmt)
	printf("{txt}ci is:{result} %s\n", this.ci)
	printf("{txt}eform is:{result} %f\n", this.eform)
	printf("{txt}___________________________________________________________\n")
	
}

/*###############################################################################################
// FUNCTIONS
###############################################################################################*/

void create_frame_table(`SS' models,
                      | `SS' keep,
		                `SS' bfmt,
		                `SS' ci,
		                `SS' star,
		                `SS' baselevels,
		                `SS' Nop,
		                `SS' eform
		                ) {
	//declare function objects, structures and variables						
	class estdocxtable scalar table
	
	print_opts(models, keep, bfmt, ci, star, baselevels, Nop, eform)
	
	// set up table objects
	table.setup(models)
	
	// set options in table object
	table.bfmt= bfmt // default is %04.2f set in main of ado
	table.ci= ci
	if(eform=="eform") table.eform= `TRUE'
	else table.eform= `FALSE'
	
	
	
	
	table.create_display_frame()
	table.print()
	
	
}

/*###############################################################################################*/
void print_opts(`SS' models,
              | `SS' keep,
		        `SS' bfmt,
		        `SS' ci,
		        `SS' star,
		        `SS' baselevels,
		        `SS' Nop,
		        `SS' eform
		        ) {
	printf("{txt}--- INPUT: --------------------------------------\n")
	
	printf("{txt}keep is:{result} %s\n", models)
	printf("{txt}keep is:{result} %s\n", keep)
	printf("{txt}bfmt is:{result} %s\n", bfmt)
	printf("{txt}ci is:{result} %s\n", ci)
	printf("{txt}star is:{result} %s\n", star)
	printf("{txt}Nop is:{result} %s\n", Nop)
	printf("{txt}eform is:{result} %s\n", eform)
	printf("{txt}__________________________________________________\n")
}






end











