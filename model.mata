
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
		void setup()         // setup takes a name of a stored estimate in memory
		void print()         // prints object properties to screen
		`SS' get_beta()      // returns beta as string for a given level
		`SS' get_pvalue()    // returns pvalue as string for a given level
		`SS' get_ci()        // returns ci as string for a given level
		
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
		printf("{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}{txt}1234{c |}6789{c |}\n\n")
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





end