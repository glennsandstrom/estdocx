/**************************************************************************/
/**TODO  **/
/**************************************************************************/
// * DONE:Implement a keep(coeflist) option and report coefficients in order specified
//
// * PARTIALLY: Implement eform option...fixed but does not ahdle multiple equation models such as'
//   xtlogit with ancilliary paramters that should not be transformed. Program needs to honor the 
//   equation name where free paramters have a different equation name, In r(table) all params 
//   after / in the equation name are free paramters "Free parameters are scalar parameters, 
//   variances, covariances, and the like that are part of them odel being fit"
//   
//   These should be handled differntly removed from the matrix of parameters and placed 
//   in the stats matrix and handled separatly printed under each model. Asi the program work now
//   it print also the free paramters in eform wich is an error.
//
//
// * BUG:if a variable has no valuelables program ends in Error st_vlmap():  3300  argument out of range
// * BUG: if factor has more than single digit level program trows error
//   for smoe reason I have introduced a catch that throws arguemnt out of range in mata-function param-type
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
/**************************************************************************/
/**SUB-ROUTINES  **/
/**************************************************************************/
	/*########################################################################*/
	//capture program drop create_docx
	program create_docx
		version 15.1
		syntax namelist(name=models), pagesize(string) [title(string)] [landscape]
		/**************************************************************************/
		/** SET WIDTH OF THE TABLE                     **/
		/**************************************************************************/
		local nummodels :list sizeof models
		// set the with of the table= nummodels + one rowheader column to display variable
		// names and factor levels in case var is a factor
		local COLUMNS= `nummodels' +1
		/**************************************************************************/
		/** CREATE THE WORDDOCUMENT THAT WILL HOLD THE TABLE                     **/
		/**************************************************************************/
			// clear any usaved documents from memory
			putdocx clear
			if "`landscape'"!="" putdocx begin, pagesize(`pagesize') landscape
			else putdocx begin, pagesize(`pagesize')
			
			putdocx paragraph, halign(left) spacing(after, 0) 
			
			//print title of table it there is one
			if ("`title'"!="") putdocx text ("`title'"), bold

		/**************************************************************************/
		/** CREATE THE HEADER ROW TABLE USING `ROWS',`COLUMNS' DIMENSIONS              **/
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
	//capture program drop get_models
	program get_models, rclass
	version 15.1
	  
		syntax namelist(min=1),	///
		[keep(string)]
		
		local models= "`namelist'" //space sparated list of estimates
			
		
		//loop over models to create table model_betas & model_p
		foreach model in `models' {
		// create a matrix named model for each stored estimate that can then be combined
		// by mata to th the matrices model_betas, model_p model_eform
				
			if _rc==111 {
				di _newline(3)  
				di as error "ERROR: `model' is not in the list of stored estimates in memory; check the supplied model names"
				di _newline  
				di as result "The estimates currently stored in memory are:" 
				estimates dir
				exit _rc
			}
			
			//get stored estimates for model Y Y Z
			capture qui estimates replay `model'
			mat `model'= r(table)
			
			//transpose to get variables as rows
			mat `model'= `model''
			
			//remove the equation-name
			matrix roweq `model' = ""
			
		}
		
		// call mata to form the matrix with model parameters
		if("`keep'"=="") mata: models_varlist("`models'")
		else mata: models_varlist("`models'", "`keep'")
		
		mata: model_beta_table("`models'", "`modelvars'", "b pvalue eform")
		
		return local params "`modelvars'"
		return scalar numparams= `numparams'
		return matrix model_betas= model_betas
		return matrix model_p= model_p
		return matrix model_eform= eform
		
	end
	/*########################################################################*/
	//capture program drop write_continious
	program write_continious
		version 15.1
		syntax namelist(min=1), ///
		row(integer) ///
		var(string) ///
		varlabel(string) ///
		fmt(string) ///
		star(string) ///
		[eform]
			
		local models= "`namelist'" //space sparated list of estimates
		
		mat B= r(model_betas)
		mat P= r(model_p)
		mat E= r(model_eform)
		
		// add row for _cons to table
		putdocx table esttable(`row',.), addrows(1)
		local row= `row'+1
		putdocx table esttable(`row',1) = ("`varlabel'"), bold font(Garamond, 11) halign(left)
		
		
		//loop over models and write parameter for all models
		local col=2
		foreach model of local models {
			//check if parameters should be transformed to eform and if they are untranformed print exp(B)
			if ("`eform'"´!="") & !(E[rownumb(E,"`var'") ,colnumb(E,"`model'")]) local b= exp(B[rownumb(B,"`var'") ,colnumb(B,"`model'")])
			else local b= B[rownumb(B,"`var'") ,colnumb(B,"`model'")]
			
			local p= P[rownumb(P,"`var'") ,colnumb(P,"`model'")]
			mata: sig_param(`b', `p', "`star'", "`fmt'") // returns local param 
			putdocx table esttable(`row',`col') = ("`param'"), font(Garamond, 11) halign(left) 
			local ++col
		}
			
	end
	/*########################################################################*/	
	//capture program drop write_level
	program write_level
		version 15.1
		syntax namelist(min=1), ///
		row(integer) ///
		var(string) ///
		vlab(string) ///
		fmt(string) ///
		star(string) ///
		[eform]
			
		local models= "`namelist'" //space sparated list of estimates
		
		mat B= r(model_betas)
		mat P= r(model_p)
		mat E= r(model_eform)
		
		// add row for factor level to table
		putdocx table esttable(`row',.), addrows(1)
		local row= `row'+1
		
		// print level header in first column
		putdocx table esttable(`row',1) = ("`vlab'"), ///
		italic font(Garamond, 10) halign(center)
		
		//loop over models and write paramters
		local col=2
		foreach model of local models {
				//check if parameters should be transformed to eform and if they are untranformed print exp(B)
				if ("`eform'"´!="") & !(E[rownumb(E,"`var'") ,colnumb(E,"`model'")]) local b= exp(B[rownumb(B,"`var'") ,colnumb(B,"`model'")])
				else local b= B[rownumb(B,"`var'") ,colnumb(B,"`model'")]
				
				local p= P[rownumb(P,"`var'") ,colnumb(P,"`model'")]
				
				// returns local param => string with sig marker
				mata: sig_param(`b', `p', "`star'", "`fmt'") 
				
				putdocx table esttable(`row',`col') = ("`param'"), font(Garamond, 11) halign(left)
				local ++col
		}	
	end
	/*########################################################################*/	
	//capture program drop write_legend
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
					local text: display %-9.1f S[rownumb(S,"`stat'"),colnumb(S,"`mod'")]
					local text= subinstr("`text'"," ","", .)
				}
				else {
					local text= S[rownumb(S,"`stat'"),colnumb(S,"`mod'")]
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

//capture program drop estimates_table_docx

program estimates_table_docx
	version 15.1
  
	syntax namelist(min=1),	///
		[saving(string)] ///
		[title(string)] ///
		[b(string)] ///
		[star(string)] ///
		[stats(string)] ///
		[baselevels] ///
		[keep(string)] ///
		[pagesize(string)] ///
		[landscape] ///
		[eform]


	// set local holding the names of estimates to be reported in table
	local models= "`namelist'" //space separated list of estimates
	
	// set local holding list of allowed statistics
	local allowed "none N aic bic"
	
	// default values for options if none are provided
	if ("`star'"=="") local star ".05 .01 .001"
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
	create_docx `models', pagesize(`pagesize') title(`title') `landscape' 
	//putdocx describe esttable
	/**************************************************************************/
	/** Get unique varlist from estimates for each of the specified models **/
	/**************************************************************************/
	if("`keep'"=="") get_models `models'
	else get_models `models', keep(`keep')
	// returns 
	// 1. r(params)= MACRO STRING nicley formated list of unique paramters making 
	//    up rows in matrix r(model_betas) & r(model_p)
	// 2. r(numparams)= SCALAR Number of paramters
	// 3. r(model_betas) MATRIX beta of all models
	// 4. r(model_p) MATRIX pvalues of all models
	// 5. r(model_eform) MATRIX of bolean values indicating if paramter is in eform or not
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
				//add a header row with variable label for factor variables that has been added tothe table
				if !`print' {
					// add header row with varname of factor variable
					putdocx table esttable(`row',.), addrows(1)
					local ++row
					putdocx table esttable(`row',1) = ("`label'"), bold font(Garamond, 10) halign(left)
					local printed "`printed' `lab'" //add varname to list of printed headers
				}
				
				// print row with factor parameters 
				write_level `models', row(`row') var(`var') vlab(`vlab') fmt(`b') star("`star'") `eform' 
				local ++row
			}
		}
		// here paramtype should return continious
		else if "`paramtype'"=="continious" | "`paramtype'"=="continious-interaction" | "`paramtype'"=="const" {
		
			write_continious `models', row(`row') var(`var') varlabel(`label') fmt(`b') star("`star'") `eform'
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
	write_legend, star(`star') row(`r(nrows)') col(`r(ncols)')
	/**************************************************************************/
	/** Save worddocument             **/
	/**************************************************************************/
	//putdocx describe esttable
	putdocx save "`saving'", replace
	
	/**************************************************************************/
	/** Garbage collection             **/
	/**************************************************************************/
	//matrix drop _all

end
version 15.1
mata: mata set matastrict on
mata: mata set matalnum on

mata:
/*###############################################################################################*/
// STRUCTURES
/*###############################################################################################*/
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
/*###############################################################################################*/
// CLASSES
/*###############################################################################################*/
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
			_error(3300, "Parameter contains an non impelmented value(s)")
		}
		
		// check that a varlabel is set else return varname in P.label
		if (st_varlabel(P.varname)!="") P.label= st_varlabel(P.varname)
		else P.label= P.varname
		
		return(P)
}

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


/*###############################################################################################*/
// FUNCTIONS
/*###############################################################################################*/
void sig_param(real scalar param, real scalar sig, string scalar star, string scalar fmt) {
	string scalar parameter, text
	real matrix this_star
	real scalar i, level
	
	this_star= strtoreal(tokens(star))
	/*
	printf("{txt}param is:{result} %f\n", param)
	printf("{txt}sig is:{result} %f\n", sig)
	
	
	printf("{txt}format of this_star is:{result} %s %s\n", eltype(this_star), orgtype(this_star))
	printf("{txt}format of this_star is:{result} %s %s\n", eltype(this_star), orgtype(this_star))

	"star is:"
    this_star
	
	printf("{txt}fmt is:{result} %s:\n", fmt)
	*/
	if (param==1 | param==0) {
		parameter= "(base)"
	}
	else {
		parameter= subinstr(strofreal(param, fmt) ," ","")
		for(i=1; i<=cols(this_star); i++) {
			if  (sig < this_star[i]) parameter= parameter + "*"
		
		}
	}
	st_local("param", parameter)

	
}

void model_beta_table(string scalar models, string scalar varlist, string scalar stats){
	string scalar model, param
	string vector this_models, this_varlist, this_stats, rownames, colnames
	real scalar a, b, c, nummodels, rowvarlist, rowmodel, col, mlenth, rowsum
	real vector baselevels	// vector of booleans= TRUE if row of model_betas only contains 1 or .
	real matrix model_betas, model_p, rtable, eform
	string matrix A
	
	// convert string scalar to string vector
	this_models= tokens(models)
	this_varlist= tokens(varlist)
	this_stats= tokens(stats)
	
	model_betas= J(length(this_varlist), length(this_models), .)
	model_p= J(length(this_varlist), length(this_models), .)
	eform= J(length(this_varlist), length(this_models), .)
	
	col=1
	for (a=1; a<=length(this_models); a++) {
		model= this_models[1,a]
		
		//get matrix rtable created by running estimates replay `model' in get_models
		rtable= st_matrix(model)
		rownames= st_matrixrowstripe(model) //get varlist of model
		colnames= st_matrixcolstripe(model) //get stats of model
		colnames= colnames[.,2] 			//remove first row that is all missing
		rownames= rownames[.,2] 			//remove first row that is all missing
		
		// remove letters indicating base, omitted, continious from rownames
		// as these are removed from varlist in function models_varlist that
		// is passed to this function from get_models
		for (b=1; b<=length(rownames); b++) {
			//remove b, o, c only from part of string before the .
			rownames[b,1]=subinstr(rownames[b,1], "b.", ".")
			rownames[b,1]=subinstr(rownames[b,1], "o.", ".")	
		}
		//loop over varlist and populate matrix model_betas, model_p, eform
		for (c=1; c<=length(this_varlist); c++) {
			param= this_varlist[1,c]
			//check if param is in rownames of the model
			if (anyof(rownames, param)){ //if param is in the list of varnames get the index
				
				rowvarlist= getindex(param, this_varlist) //find row of param in unique varlist
				rowmodel= getindex(param, rownames)       //find row of param in rownames
				model_betas[rowvarlist, col]= rtable[rowmodel, getindex("b", colnames)]
				model_p[rowvarlist, col]= rtable[rowmodel, getindex("pvalue", colnames)]
		
				eform[rowvarlist, col]= rtable[rowmodel, getindex("eform", colnames)]
			}
			
		}
		//increment column
		++col
	}
	
	//create colvector baselevels indicating rows that only contain 1:s or . ==baselevel
	baselevels= J(rows(model_betas), 1, .)
	
	for (a=1; a<=rows(model_betas); a++) {
		rowsum=0
		
		for (b=1; b<=cols(model_betas); b++) {
			if (model_betas[a,b]==. | model_betas[a,b]==1 | model_betas[a,b]==0) rowsum++
		}
		// if rowsum== columns of model_betas row only contains baselevels
		if (rowsum== cols(model_betas)) baselevels[a,1] = 1
		else baselevels[a,1] = 0
	}
	
	st_matrix("model_betas", model_betas)
	st_matrix("model_p", model_p)
	st_matrix("eform", eform)
	st_matrix("baselevels", baselevels)
	
	//måste lägga till en tom rad för att funka med colstripe etc. nedan
	A= J(length(this_varlist), 1, "")
	this_varlist= this_varlist'
	this_varlist= A,this_varlist
	
	A= J(length(this_models), 1, "")
	this_models= this_models'
	this_models= (A,this_models)
	
	// set the row and colnames of the returned matrices
	st_matrixrowstripe("model_betas", this_varlist)
	st_matrixrowstripe("model_p", this_varlist)
	st_matrixrowstripe("eform", this_varlist)
	st_matrixcolstripe("model_betas", this_models)
	st_matrixcolstripe("model_p", this_models)
	st_matrixcolstripe("eform", this_models)
}

void models_varlist(string scalar models, |string scalar cofkeep){
	string scalar model, param, level
	string vector this_models
	real scalar i, ii, found, nummodels
	string matrix rownames, allvars, unique
	
	// convert string scalar to string vector
	this_models= tokens(models)
	nummodels=length(this_models)
	
	//declare colvector allvars
	allvars= J(0, 1, "") 
	
	//loop over vector this_models and get rownames
	for (i=1; i<=nummodels; i++) {
		model= this_models[1,i]
		//printf("{txt}Model is:{c |}  {res}%s\n", model)
		
		rownames= st_matrixrowstripe(model) //get varlist of model
		rownames= rownames[.,2] //remove first row that is all missing
		allvars= rownames\allvars  //add model parameters as additionl rows in allvars
	}
	
	// remove letters indicating base, omitted, continious
	for (i=1; i<=length(allvars); i++) {
		//remove b, o, c only from part of string before the .
		allvars[i,1]=subinstr(allvars[i,1], "b.", ".")
		allvars[i,1]=subinstr(allvars[i,1], "o.", ".")	
	}
		
	//set first cell in vector unique to first paramater in allvars
	unique= allvars[1,1]

	//loop over complete list of parameters and add ones not in unique
	for (i=2; i<=length(allvars); i++) {
		//boolean for indicating if paramter is added or not the the unique list
		found=0
		//set string scalar param to paramter i of allvars
		param= allvars[i,1]
		
		// loop over unique and set found==TRUE if parameter is already in list
		for (ii=1; ii<=length(unique); ii++) {
			if (strmatch(unique[ii,1], param)) found=1				
		}
		//if param is not already in list add it to vector unique and string parameters
		//printf("{txt}param: {res}%s {txt}found: {res}%f\n", param, found)
		if(!found){
			unique= unique\param
			}
	}
	//"uniqrows is:"
	//test= uniqrows(allvars) 
	//test
	//"uniqe is:"
	//unique
	//printf("{txt}Content of pramaters is {res}%s\n", paramaters)
	
	//IMPLEMENT KEEP OPTION HERE
	// function taking colvector unique as argument and returning sorted and
	// constrained version using string scalar cofkeep as selection criteria
	if(args()==2) unique= keeping(unique, cofkeep)
	
	st_local("modelvars", invtokens(unique'))
	st_local("numparams", strofreal(length(unique)))
	
}

string colvector keeping(string colvector unique, string scalar vars) {
	string colvector this_unique, keepvars, modelvars
	real scalar i, ii
	string scalar cof
	
	// make rowvector of string keepvars (list of variables to be retained in table)
	keepvars= tokens(vars)
	
	//declare colvector this_unique => limited and ordered version of coiffcents returned
	modelvars= J(0, 1, "")
	
	//check that all keepvars exists in models
		for (i=1; i<=length(unique); i++) {
			//make colvector of the coifficents in models diregarding levels
			// remove i. and c. from coef in unique
			cof= unique[i,1]
			while(regexm(cof, "[0-9]+\.")) cof= regexr(cof, "[0-9]+\.", "")
			while(regexm(cof, "c\.")) cof= regexr(cof, "c\.", "")
			modelvars= modelvars\cof
		}
		
		for (i=1; i<=length(keepvars); i++) {
			// if a varaible in keepwars is not found in modelvars trow error
			if(!anyof(modelvars, keepvars[1,i])) _error(193, "Variable specfied in keep does not exist in models")
		}
		
	//declare colvector this_unique => limited and ordered version of coiffcents returned
	this_unique= J(0, 1, "")
	
	for (i=1; i<=length(keepvars); i++) {
			
		for (ii=1; ii<=length(unique); ii++) {
			// calc cof from unique to match against current value of keepvar =>
			// include in this_unique if coef matches value of keepvars 
			cof= unique[ii,1]
			while(regexm(cof, "[0-9]+\.")) cof= regexr(cof, "[0-9]+\.", "")
			while(regexm(cof, "c\.")) cof= regexr(cof, "c\.", "")
			
			//check if cof is equal to keepvars and include it in this_unique if it is
			if(keepvars[1,i]==cof) this_unique= this_unique\unique[ii,1]
		}
	}
	
	return(this_unique)
}

real scalar getindex(string scalar val, string vector names) {
	real scalar i
	//if a colvector is passed transpose to rowvector
	if(orgtype(names)=="colvector") names= names'
	//"names"
	//names
	for (i=1; i<=length(names); i++) {
				
		if (names[1,i]== val) {
			//printf("{txt}index of {res}%s {txt}is {res}%f\n",val, i)
			return(i)
		}
	}
}


void paramtype(string scalar param) {
	class parameter scalar P
	
	P.setup(param)
	st_local("paramtype", P.paramtype)
	st_local("vlab", P.combvlab)
	st_local("label", P.comblabel)


}


end

	
	
	
	
	
	
	
	
	
	





