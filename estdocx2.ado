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
		                         "`keep'",       ///
								 "`baselevels'", ///
								 "`bfmt'",       ///
								 "`ci'",         /// 
								 "`star'",       ///
								 " `Nop'",       ///
								 "`eform'",       ///
								 "`fname'"       ///
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
/*************************************************************************
STRUCTURE model                     
**************************************************************************/
struct model {
	real matrix rtable
	string colvector params, stats


}
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
				_error(3300, "Parameter contains an non implemented value(s)")
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
// CLASS rowvarlist
/*#######################################################################################*/
class rowvarlist {
	public:
		//public vars
		string colvector unique
		string colvector constants
		
		//public functions
		void setup() // setup takes a namlist of stored estimates
		void print()
		
}
	/*#######################################################################################
	// CLASS rowvarlist FUNCTIONS
	#######################################################################################*/
	/***************************************************************************
	Function takes a vector of model structures models and returns the unique
	list of pramameters with all duplicates removed => function as the rows
	of the regression table
	****************************************************************************/
	void rowvarlist::setup(struct model colvector models) {

	real scalar i, ii, found
	string scalar param, varname, prefix, find

		//declare colvector allvars
		this.constants= J(0, 1, "")
		
	
		for (i=1; i<=length(models); i++) {
			for (ii=1; ii<=length(models[i].params); ii++) {
				// if it is constant or free and adding it to this.constants
				if(regexm(models[i].params[ii], "^[_/]")) {
					if(!anyof(this.constants, models[i].params[ii])) this.constants=this.constants\models[i].params[ii]
				}
				else { // if it is not free/const add it to unique if it is not already a member of unique
					if(!anyof(this.unique, models[i].params[ii])) this.unique= this.unique\models[i].params[ii]
				}
				
			}
		
			
		}
		
		// add the unique set of constants/ancilliary parameters to the end of the rowvarlist
		this.unique= this.unique\this.constants

		
	}
	
/*#######################################################################################*/
// CLASS estdocxtable
/*#######################################################################################*/
class estdocxtable {
	public:
		//public vars
		class     AssociativeArray scalar rtables // array to save rtable-data using string keys: model, stat, parameter 
		class     rowvarlist scalar rowvarlist    // computes the uniq ordered list of pramateters that form the rows of table
		string    colvector parameters            // uniq ordered list of pramameters
		string    scalar varnames                 // uniq ordered list of varnames
		string    scalar fname                    // framename used to store the table
		string    scalar bfmt                     // %fmt for beta
		string    scalar ci                       // %fmt for confidence interval
		`boolean' scalar eform
		`boolean' scalar baselevels
		real      colvector star                  // numeric vector of sig < P cuttofs for * significnase markers
		
		//public functions
		void      setup()                          // setup takes a namlist of stored estimates
		void      create_display_frame()
		void      print()
		void      set_star()
		
	private:
		//private vars
		string vector estnames              // vector of the name of estimates
		
		//private functions
		struct model get_rtable()         // function returing structure (rtable, params, stats) for model
		void   remove_baselevels()
		void   create_display()
		`SS'   get_beta()
		`SS'   get_pvalue()
		`SS'   get_ci()
		
}
/*#######################################################################################
// CLASS estdocxtable FUNCTIONS
#######################################################################################*/
	void estdocxtable::setup(`SS' estnames) {
		struct model scalar mod // structure holding 
		struct model colvector models
		real scalar i, ii, iii
		string colvector allparams


		
		// convert string scalar to string vector of estnames
		this.estnames= tokens(estnames)
			
		// reinitate the assositative array as array with 3 dimention string keys
		this.rtables.reinit("string", 3) 
		this.rtables.notfound(.)
		
		//declare structure colvector models
		models= J(0, 1, "")

		// fill AssociativeArray T with data from struct mod
		for (iii=1; iii<=length(this.estnames); iii++) {
						
			// create and return struct holding mat rtable and string vectors params stats
			mod= get_rtable(this.estnames[iii])
			// add mod to vector models
			if(!length(models)) models= mod
			else models= models\mod
			
			for (ii=1; ii<=length(mod.stats); ii++) {
				for (i=1; i<=length(mod.params); i++) {
					this.rtables.put((this.estnames[iii], mod.stats[ii], mod.params[i]), mod.rtable[i,ii])
				}
			}
			
		}
	
		

		this.rowvarlist.setup(models)
		this.parameters = this.rowvarlist.unique
				
				
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
	Function writes paramters for all models to display frame
	****************************************************************************/
	void estdocxtable::create_display_frame(| string scalar fname) {
		string matrix table
		string colvector frames
		string scalar colwidh, pvalue, ci, paramtext
		real scalar i, ii, mpl, c
		

		if(fname=="" ) this.fname= st_tempname()
		else this.fname= fname
	
		frames= st_framedir()
		
		for (i=1; i<=length(frames); i++) {
			if(frames[i]==this.fname) st_framedrop(this.fname)
		}
		
		st_framecreate(this.fname)
		st_framecurrent(this.fname)
		
		//remove base and omitted from interaction paramteters if baselevels is FALSE
		if(!this.baselevels) remove_baselevels()

		
		//find maximum number of characthers of in parameters
		mpl=max(strlen(this.parameters))
		colwidh= "str" + strofreal(mpl) // stringfomrat mpl number of characthers
		// add column for paramters with a widh/characthers of the longest parameter
		varindex= st_addvar(colwidh, "params")
		
		// add columns for for each model
		for (i=1; i<=length(this.estnames); i++) {
			varindex= st_addvar("str15", this.estnames[i])
		}
				
		
		// add rows euqal
		st_addobs(length(this.parameters))

		
		st_sview(table, ., .)  // load dataset from stata
		
		for (i=1; i<=length(this.parameters); i++) {
			// write full parameter text to row header
			table[i,1]= this.parameters[i]
			
			
			// get stats for each model and form the celltext
			for (ii=1; ii<=length(this.estnames); ii++) {
				c= ii+1
				
				
				//always get beta
				paramtext= this.get_beta(this.estnames[ii], this.parameters[i])
				
				
				// if ci is TRUE add/get CI, that it is valied fmt is confirmed in main ado
				if(this.ci!="") paramtext= paramtext + this.get_ci(this.estnames[ii], this.parameters[i])
				
				
				//add/get p-value
				pvalue= this.get_pvalue(this.estnames[ii], this.parameters[i])
				paramtext= paramtext + pvalue
				
				// write full parameter text to cell in display frame
				table[i,c]= paramtext
			}
		}
		
		

	}
	/***************************************************************************
	Function returns 
	****************************************************************************/
	void estdocxtable::remove_baselevels() {
		real scalar i, ii, interaction, bases
		string scalar prefix
		string colvector reduced, intervars
		
		//declare colvector reduced
		reduced= J(0, 1, "")
		
		for (i=1; i<=length(this.parameters); i++) {
			
			//check if parameter is an interaction
			interaction= strrpos(this.parameters[i],"#")  > 0
			
			if (interaction) {
				//check if all incuded factors in interaction are base or omitted
				intervars=tokens(subinstr(this.parameters[i], "#", " ") ) //matrix with varnames forming the interaction
				bases= 0
				for (ii=1; ii<=length(intervars); ii++) {
					// assign part of string before . to P.prefix
					prefix= substr(intervars[ii] , 1 , strrpos(intervars[ii],".")-1 )
					
					if(strrpos(prefix,"b")  > 0 | strrpos(prefix,"o")  > 0) bases++
				}
				
				if(length(intervars)!=bases) {
					if(!length(reduced)) reduced= this.parameters[i]
					else reduced= reduced\this.parameters[i]
				}

			}
			else {
				if(!length(reduced)) reduced= this.parameters[i]
				else reduced= reduced\this.parameters[i]
				
			}	
		
		}	
			
		this.parameters= reduced
				
	}
	/***************************************************************************
	Function returns formated beta-value string for model, param 
	****************************************************************************/
	`SS' estdocxtable::get_beta(`SS' model, `SS' param) {
		
		string scalar beta
		real scalar B
		
		
		beta= sprintf(this.bfmt, this.rtables.get((model, "b", param)))
		
		return(beta)
		
	}
	/***************************************************************************
	Function returns formated p-value string for model, param 
	****************************************************************************/
	`SS' estdocxtable::get_pvalue(`SS' model, `SS' param) {
		string scalar pvalue
		real scalar p, i
		
		p= this.rtables.get((model, "pvalue", param))
		
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
	Function returns formated CI string for model, param 
	****************************************************************************/
	`SS' estdocxtable::get_ci(`SS' model, `SS' param) {
		string scalar ci, lowb, highb
		real scalar ll, ul
		
		ll= this.rtables.get((model, "ll", param))
		ul= this.rtables.get((model, "ul", param))
		
		// 95% CIs
		lowb= strofreal(ll, this.ci)
		highb= strofreal(ul, this.ci)
		if(lowb!=".") ci= " (" + lowb + "-" + highb + ")"
				
		return(ci)
		
	}
	/***************************************************************************
	Function set the star-option 
	****************************************************************************/
	void estdocxtable::set_star(`SS' star) {
		this.star= strtoreal(tokens(star))
   	}
	/***************************************************************************
	Function displays table of object propreties
	****************************************************************************/
	void estdocxtable::print() {
		printf("{txt}--- Object estdocxtable: --------------------------------------\n")
		"estnames" 
		this.estnames
		"varnames"
		this.varnames
		
		"paramters"
		this.parameters
		printf("{txt}baselevels is:{result} %f\n", this.baselevels)
		printf("{txt}bfmt is:{result} %s\n", this.bfmt)
		printf("{txt}ci is:{result} %s\n", this.ci)
		printf("{txt}eform is:{result} %f\n", this.eform)
		printf("{txt}fname is:{result} %s\n", this.fname)
		printf("{txt}___________________________________________________________\n")
		
	}

/*###############################################################################################
// FUNCTIONS
###############################################################################################*/
//# Bookmark #2

void create_frame_table(`SS' estnames,
                      | `SS' keep,
					    `SS' baselevels,
		                `SS' bfmt,
		                `SS' ci,
		                `SS' star,
		                `SS' Nop,
		                `SS' eform,
						`SS' fname
		                ) {
	//declare function objects, structures and variables						
	class estdocxtable scalar table
	
	print_opts(estnames, keep, bfmt, ci, star, baselevels, Nop, eform, fname)
	
	// set up table objects
	table.setup(estnames)
	
	// set options in table object
	if(star!="") table.set_star(star)
	
	// set options in table object
	if(baselevels=="baselevels") table.baselevels= `TRUE'
	else table.baselevels= `FALSE'
	

	table.bfmt= bfmt // default is %04.2f set in main of ado
	
	if(ci!="") table.ci= ci
	
	if(eform=="eform") table.eform= `TRUE'
	else table.eform= `FALSE'
	
	
	
	
	
	
	
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
		        `SS' Nop,
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
	printf("{txt}Nop is:{result} %s\n", Nop)
	printf("{txt}eform is:{result} %s\n", eform)
	printf("{txt}fname is:{result} %s\n", fname)
	printf("{txt}__________________________________________________\n")
}






end











