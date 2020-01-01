version 15.1
mata: mata set matastrict on
mata: mata set matalnum on

mata:

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

class parameter {
	public:
		string scalar paramtype
		string scalar comblabel 
		string scalar combvlab
		
		string scalar paramtxt
		real scalar interaction
		string matrix intervars
		
		struct paramvar rowvector vars //vector of different variables forming the parameter
				
		void setup()
		void print()
		struct paramvar parsevar()
	
	
		
}

void parameter::setup(string scalar user_txt) {
	//make sure all propretis are null when setup is run
	this.vars = J(0,0, this.vars)
	
	this.paramtxt= user_txt // text defining the complete paramteter
	
	//check if parameter is an interaction
	this.interaction= strrpos(this.paramtxt,"#")
	
	if (this.interaction) {
		//"do complicated things for interaction paramters"
		this.intervars=tokens(subinstr(this.paramtxt, "#", " ") ) //matrix with varnames forming the interaction
		// fill colvector this.vars with strcutures for each varaible in interaction stored in intervars
		
	}
	else {
		//"do easy things for factors and continious variables"
		//create a single element vector with one paramvar structure
		this.vars= this.parsevar(this.paramtxt)
		this.comblabel= this.vars[1].label
		this.combvlab= this.vars[1].vlab
		this.paramtype= this.vars[1].vartype
		//liststruct(this.vars[1])
		
	
	}
}

struct paramvar parameter::parsevar(string scalar vartext){
		struct paramvar scalar P
		
		
		// assign the part of the string efter . to P.varname 
		P.varname= substr(vartext , strrpos(vartext,".")+1 ,  strlen(vartext))
		
		// assign part of string before . to P.prefix
		P.prefix= substr(vartext , 1 , strrpos(vartext,".")-1 )
		
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
			_error(3300, "Parameter contains an non impelmented value")
		}
		
		// check that a varlabel is set else return varname in P.label
		if (st_varlabel(P.varname)!="") P.label= st_varlabel(P.varname)
		else P.label= P.varname
		
		return(P)
}

void parameter::print() {
	real scalar i
		printf("{txt}___________________________________________________________\n")
	for(i=1; i<=rows(this.vars); i++) {
		
		
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

end
