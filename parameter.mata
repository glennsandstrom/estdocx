version 15.1
mata: mata set matastrict on
mata: mata set matalnum on

mata:

class parameter {
	public:
		string scalar paramtype
		string scalar label 
		string scalar vlab
		
		void setup()
		void print()
	
	
		string scalar paramtxt
		real scalar interaction					
		string scalar varname
		string scalar prefix		//entire string before . in paramtxt
		string scalar level			
		real scalar base
		real scalar omitted
		string matrix intervars	
}

void parameter::setup(string scalar user_txt) {
	//make sure all propretis are null when setup is run
	this.paramtype = this.label = this.label = this.vlab = this.varname = this.prefix = this.level = ""
	this.base = this.omitted =.
	
	this.paramtxt= user_txt // text defining the complete paramteter
	
	//check if parameter is an interaction
	this.interaction= strrpos(this.paramtxt,"#")
	
	if (this.interaction) {
		"do complicated things for interaction paramters"
		this.intervars=tokens(subinstr(this.paramtxt, "#", " ") ) //matrix with varnames forming the interaction
	}
	else {
		"do easy things for factors and continious variables"
		// assign the part of the string efter . to this.varname 
		this.varname= substr(this.paramtxt , strrpos(this.paramtxt,".")+1 ,  strlen(this.paramtxt))
		
		// assignpart of string before . to this.prefix
		this.prefix= substr(this.paramtxt , 1 , strrpos(this.paramtxt,".")-1 )
		
		//check if prefix contains numeric character then it is a factor
		if (regexm(this.prefix, "[0-9]")) {
			
			this.paramtype= "factor"
			
			// check if prefix is base
			this.base= strrpos(this.prefix,"b")  > 0
			
			// check if prefix is ommitted
			this.omitted= strrpos(this.prefix,"o")  > 0
			
			//get only the numeric value in prefix if it contains letters to get valuelabel with st_varvaluelabel()
			// match the numbers with regexm and tehn return them with regexs
			regexm(this.prefix, "[0-9]+") 
this.level= regexs()
	
			
			// check that value labels are set and set vlab to correct value label in this.vlab 
			if (st_varvaluelabel(this.varname)!="") this.vlab = st_vlmap(st_varvaluelabel(this.varname), strtoreal(this.level))
			else this.vlab = this.level
			
			// sometimes the value lable is set but is null string => set to level of factor
			if (this.vlab=="") this.vlab = this.level
		}
		else if (this.prefix=="" | this.prefix=="c" | this.prefix=="co") {
			this.vlab= "" // paramter is not factor vlab should be null
			this.paramtype= "continious"
			
			//contionios variables haver no base-level
			this.base= 0
			
			// check if paramter is omitted 
			this.omitted= strrpos(this.prefix,"o") > 0
		
		}
		else {
			_error(3300, "Parameter contains an non impelmented value")
		}
		
		// check that a varlabel is set else return varname in P.label
		if (st_varlabel(this.varname)!="") this.label= st_varlabel(this.varname)
		else this.label= this.varname
		

		
	
	}
}

void parameter::print() {
	printf("{txt}--------------------------------------------------\n")
	printf("{txt}paramtxt is:{result} %s\n", this.paramtxt)
	printf("{txt}varname is:{result} %s\n", this.varname)
	printf("{txt}prefix is:{result} %s\n", this.prefix)
	printf("{txt}level is:{result} %s\n", this.level)
	printf("{txt}base is:{result} %f\n", this.base)
	printf("{txt}omitted is:{result} %f\n", this.omitted)
	printf("{txt}interaction is:{result} %f\n", this.interaction)
	this.intervars
	printf("{txt}label is:{result} %s\n", this.label)
	printf("{txt}vlab is:{result} %s\n", this.vlab)
	printf("{txt}paramtype is:{result} %s\n", this.paramtype)
	printf("{txt}--------------------------------------------------\n")
}

end
