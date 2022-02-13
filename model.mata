
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
		string scalar    estname
		real   matrix    rtable
		string colvector parameters
		string colvector statistics
		string colvector varnames
		real   colvector base
		real   colvector omitted
		
		//public functions
		void setup() // setup takes a namlist of stored estimates
		void print()
		
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
		
		rtable= st_matrix("M")
		parameters= st_matrixrowstripe("M") //get varlist of model
		statistics= st_matrixcolstripe("M") //get stats of model
		statistics= statistics[.,2] 		//remove first col that is all missing
		parameters= parameters[.,2] 		//remove first col that is all missing
		
		
		
		
		
		
	}
	/***************************************************************************
	Function prints object propeties to screen
	****************************************************************************/
	void model::print() {
		printf("{txt}--- Object model: --------------------------------------\n")
		printf("{txt}estname is:{result} %s\n", this.estname)
		printf("{txt}___________________________________________________________\n")
		"parameters"
		this.parameters
		"varnames"
		this.varnames
		"statistics"
		this.statistics
		printf("{txt}___________________________________________________________\n")
		
	}





end