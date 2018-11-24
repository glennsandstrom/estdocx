
/**************************************************************************/
/**SUB-ROUTINES  **/
/**************************************************************************/
	/*########################################################################*/
	//capture program drop create_docx
	program create_docx
		version 15.1
		syntax namelist(name=models), [title(string)] [landscape]
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
			if "`landscape'"!="" putdocx begin, pagesize(A4) landscape
			else putdocx begin, pagesize(A4)
			
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
			putdocx table esttable(1,1) = ("Variables"), bold font(Garamond, 10) halign(left)
			
			
			forvalues col=2/`COLUMNS' {
				local mod= `col'-1
				local model: word `mod' of `models'
				putdocx table esttable(1,`col') = ("`model'"),	bold font(Garamond, 10) halign(left)
				
			}
	end
	/*########################################################################*/
	//capture program drop get_models
	program get_models, rclass
	version 15.1
	  
		syntax namelist(min=1)
			
		local models= "`namelist'" //space sparated list of estimates
		
			foreach model in `models' {
				//get stored estimates
				capture qui estimates replay `model'
				if _rc==111 {
					di _newline(3)  
					di as error "ERROR: `model' is not in the list of stored estimates in memory; check the supplied model names"
					di _newline  
					di as result "The estimates currently stored in memory are:" 
					estimates dir
					exit _rc
				}

				mat `model'= r(table)
				
				//transpose to get variables as rows
				mat `model'= `model''
				
				//remove the equation-name
				matrix roweq `model' = "" 
			
			}
			
			// call mata to form the matrix with model paramters
			mata: models_varlist("`models'")
			mata: model_stats("`models'", "`modelvars'", "b pvalue")
			
			return local params "`modelvars'"
			return scalar numparams= `numparams'
			return matrix model_betas= model_betas
			return matrix model_p= model_p
	end
	/*########################################################################*/
	//capture program drop write_continious
	program write_continious
		version 15.1
		syntax namelist(min=1), ///
		row(integer) ///
		var(string) ///
		varlabel(string) ///
		bdec(real) ///
		star(string)
			
		local models= "`namelist'" //space sparated list of estimates
		mat B= r(model_betas)
		mat P= r(model_p)
		
		// add row for _cons to table
		putdocx table esttable(`row',.), addrows(1)
		local row= `row'+1
		putdocx table esttable(`row',1) = ("`varlabel'"), bold font(Garamond, 10) halign(left)
		
		
		//loop over models and write paramter for all models
		local col=2
		foreach model of local models {
			local b= B[rownumb(B,"`var'") ,colnumb(B,"`model'")]
			local p= P[rownumb(P,"`var'") ,colnumb(P,"`model'")]
			mata: sig_param(`b', `p', "`star'", `bdec') // returns local param 
			putdocx table esttable(`row',`col') = ("`param'"), halign(left)
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
		bdec(real) ///
		star(string)
			
		local models= "`namelist'" //space sparated list of estimates
		
		mat B= r(model_betas)
		mat P= r(model_p)
		
		// add row for factor level to table
		putdocx table esttable(`row',.), addrows(1)
		local row= `row'+1
		
		// print level header in first column
		putdocx table esttable(`row',1) = ("`vlab'"), ///
		italic font(Garamond, 10) halign(center)
		
		//loop over models and write paramters
		local col=2
		foreach model of local models {
				local b= B[rownumb(B,"`var'") ,colnumb(B,"`model'")]
				local p= P[rownumb(P,"`var'") ,colnumb(P,"`model'")]
				
				// returns local param => string with sig marker
				mata: sig_param(`b', `p', "`star'", `bdec') 
				
				putdocx table esttable(`row',`col') = ("`param'"), halign(left)
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
		font(Garamond, 10) halign(left) colspan(`col') ///
		border(bottom, nil) ///
		border(top)
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
		[bdec(real .01)] ///
		[star(string)] ///
		[baselevels] ///
		[landscape]
	
	// set local holding the names of estimates to be reported in table
	local models= "`namelist'" //space separated list of estimates
	
	// defualt significanse values if none are provided
	if ("`star'"=="") local star ".05 .01 .001"
	if ("`saving'"=="") local saving "estimates_table.docx"
	
	/**************************************************************************/
	/** CREATE TABLE                     **/
	/**************************************************************************/

	create_docx `models', title(`title') `landscape'
	//putdocx describe esttable
	/**************************************************************************/
	/** Get unique varlist from estimates for each of the specified models **/
	/**************************************************************************/
	get_models `models' 
	
	// returns 
	// 1. r(params)= MACRO STRING nicley formated list of unique paramters making 
	//    up rows in matrix r(model_betas) & r(model_p)
	// 2. r(numparams)= SCALAR Number of paramters
	// 3. r(model_betas) MATRIX beta of all models
	// 4. r(model_p) MATRIX pvalues of all models
	/**************************************************************************/
	/** PRINT ALL THE UNIQUE VARIABLES OCCURING IN THE MODELS AND THEIR LEVELS*/
	/**************************************************************************/
	local row= 1
	
	forvalues param=1/`r(numparams)' {
		//get varname from list of paramters 
		local var: word `param' of `r(params)'
		
		/**************************************************************************/	
		// Check the type of the parameter 1. CONTINIOUS/CONS 2. FACTOR 3.INTERACTION 
		/**************************************************************************/
		mata: paramtype("`var'") //returns locals: paramtype, label, vlab, base, omit

		if "`paramtype'"=="factor" | "`paramtype'"=="f#f" | "`paramtype'"=="c#f"{
			// Always print if base==FALSE and only print if baselevels== TRUE if base==TRUE
			if !`base' | "`baselevels'"!="" {
				//check if varname is in the list of printed varnames
				local lab= subinstr("`label'", " ", "", .) //remove all whitespeace
				
				local print : list posof "`lab'" in printed
				//header row with variable label for factor has not been printed => add header row
				if !`print' {
					// add header row with varname of factor variable
					putdocx table esttable(`row',.), addrows(1)
					local ++row
					putdocx table esttable(`row',1) = ("`label'"), bold font(Garamond, 10) halign(left)
					local printed "`printed' `lab'" //add varname to list of printed headers
				}
				
				// print row with parameters for all the models
				write_level `models', row(`row') var(`var') vlab(`vlab') bdec(`bdec') star("`star'")
				local ++row
			}
		} 
		else if "`paramtype'"=="continious" | "`paramtype'"=="c#c" | "`paramtype'"=="constant" {
		
			write_continious `models', row(`row') var(`var') varlabel(`label') bdec(`bdec') star("`star'")
			local ++row
			local printed "`printed' `lab'"
				
		}
		else {
			di as error "{error} Program does not support this type of parameter"
		
		}
	
	}
	
	// set border on bottom of header row
	putdocx table esttable(1,.), border(bottom)
	
	// print a legend with significance values
	local c: word count `models'
	local ++c
	write_legend, star(`star') row(`row') col(`c')
	/**************************************************************************/
	/** Save worddocument             **/
	/**************************************************************************/
	//putdocx describe esttable
	putdocx save "`saving'", replace

end
version 15.1
mata: mata set matastrict on
mata: mata set matalnum on

mata:
/*###############################################################################################*/
// STRUCTURES
/*###############################################################################################*/

struct paratype {
	real scalar omit, base					// public return values as stata macros
	string scalar paramtype, label, vlab	// public return values as stata macros
	
	real scalar interaction					// private
	string scalar param, varname, level		// private
	string matrix intervars					// private

}
/*###############################################################################################*/
// FUCNTIONS
/*###############################################################################################*/
void sig_param(real scalar param, real scalar sig, string scalar star, real scalar fmt) {
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
	if (param==1) {
		parameter= "(base)"
	}
	else {
		parameter= subinstr(strofreal(round(param, fmt))," ","")
		for(i=1; i<=cols(this_star); i++) {
			if  (sig < this_star[i]) parameter= parameter + "*"
		
		}
	}
	st_local("param", parameter)

	
}

void model_stats(string scalar models, string scalar varlist, string scalar stats){
	string scalar model, param
	string vector this_models, this_varlist, this_stats, rownames, colnames
	real scalar i, ii, nummodels, rowvarlist, rowmodel, col, mlenth
	
	real matrix model_betas, model_p, rtable
	string matrix A
	
	// convert string scalar to string vector
	this_models= tokens(models)
	this_varlist= tokens(varlist)
	this_stats= tokens(stats)
	
	model_betas= J(length(this_varlist), length(this_models), .)
	model_p= J(length(this_varlist), length(this_models), .)
	col=1
	for (i=1; i<=length(this_models); i++) {
		model= this_models[1,i]
		rtable= st_matrix(model)			//get mat 
		rownames= st_matrixrowstripe(model) //get varlist of model
		colnames= st_matrixcolstripe(model) //get stats of model
		colnames= colnames[.,2] 			//remove first row that is all missing
		rownames= rownames[.,2] 			//remove first row that is all missing

		//loop over varlist
		for (ii=1; ii<=length(this_varlist); ii++) {
			param= this_varlist[1,ii]
			
			//check if param is in rownames of the model
			if (anyof(rownames, param)){ //if param is in  is get the index
				
				rowvarlist= getindex(param, this_varlist) //find row of param in unique varlist
				rowmodel= getindex(param, rownames)       //find row of param in model rownames
				model_betas[rowvarlist,col]= rtable[rowmodel,getindex("b", colnames)]
				model_p[rowvarlist,col]= rtable[rowmodel,getindex("pvalue", colnames)]
			}
			
		}
		//increment column
		++col
	}
	
	st_matrix("model_betas", model_betas)
	st_matrix("model_p", model_p)
	
	A= J(length(this_varlist), 1, "")
	this_varlist= this_varlist'
	this_varlist= A,this_varlist
	
	A= J(length(this_models), 1, "")
	this_models= this_models'
	this_models= (A,this_models)
	st_matrixrowstripe("model_betas", this_varlist)
	st_matrixrowstripe("model_p", this_varlist)
	st_matrixcolstripe("model_betas", this_models)
	st_matrixcolstripe("model_p", this_models)
}

void models_varlist(string scalar models){
	string scalar model, param, paramaters, level
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
	
	//setstring scalar paramaters to value of first cell in allvars
	paramaters= allvars[1,1]
	
	//boolean for indicating if paramter is added or not the the unique list
	found=0
	
	//loop over complete list of pramaters and add ones not in unique
	for (i=2; i<=length(allvars); i++) {
		//set string scalar param to paramter i of allvars
		param= allvars[i,1]
		
		// loop over unique and set found==TRUE if parameter is already in list
		for (ii=1; ii<=length(unique); ii++) {
			if (unique[ii,1]==param) found=1
		}
		//if param is not already in list add it to vector unique and string parameters
		if(!found){
			unique= unique\param
			paramaters= paramaters + " " + param
			}
	}
		
	//printf("{txt}Content of pramaters is {res}%s\n", paramaters)
	st_local("modelvars", paramaters)
	st_local("numparams", strofreal(length(unique)))
	
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

void interaction_type(struct paratype scalar P) {
	real scalar i
	string matrix levels
	
	P.intervars=tokens(subinstr(P.param, "#", " ") ) //matrix with varnames forming the interaction
	P.omit= P.base = 0 // intialize to false
	
	levels= J(cols(P.intervars), 1 , "")
	//determine type of interaction
	for(i=1; i<=cols(P.intervars); i++) {
		P.level= substr(P.intervars[i] , 1 , strrpos(P.intervars[i],".")-1 )
				
		//check if one of the included parameters in the interaction is a base or omitted category
		if(!P.omit) P.omit= strrpos(P.level,"o") // if level contains o it´s an omitted parameter
		if(!P.base) P.base= strrpos(P.level,"b") // if level contains b it´s a base parameter
				
		//remove base, omitted prefix from level => st_vlmap(string varname, real level)
		P.level= subinstr(P.level, "b", "")
		P.level= subinstr(P.level, "o", "")
		// regular expression matching if first letter is real => factor
		if (regexm(P.level, "^[0-9]")) P.level= "f"
		levels[i]= P.level
		
	}
	// sort the colvector of levels
	levels= sort(levels, 1)
	
	//form the interaction type and store in P.interaction
	levels= levels'
	for(i=1; i<=cols(P.intervars); i++) {
		if (i < cols(P.intervars)) P.paramtype= P.paramtype + levels[i] + "#"
		else P.paramtype= P.paramtype + levels[i]
	}

}

void paramtype(string scalar param) {
	// returns as macros paramtype, label, vlab, base, omit
	// paramtype: the type of parameter: continious, factor, constant, f#f, c#f, c#c
	// label: the full combination of label(s) to print in the header column
	// vlab: the full combination of valuelabel(s) to print if it is a factor involved
	// base: if one of the included parameters are base=> base== TRUE
	// omit: if one of the included parameters are omitted=> omit== TRUE
	real scalar i
	struct paratype scalar P
	P.param= param
	
	
	//check if parameter is an interaction
	P.interaction= strrpos(P.param,"#") // if param contains # it´s an interaction
	
	//tokenise into string matrix holding each varname if it is an interaction
	if(P.interaction) { 
		
		interaction_type(P)	
		
		// paramter is a factor#factor or continious#factor interaction
		if (P.paramtype=="f#f" | P.paramtype=="c#f") {
		
			for(i=1; i<=cols(P.intervars); i++) {
				P.varname= substr(P.intervars[i] , strrpos(P.intervars[i],".")+1 ,  strlen(P.intervars[i]))
				// returns the variable label associated with var, such as "Sex of Patient", 
				// or it returns "" if var has no variable label.	
				
				//concatenate variable labels
				if (i < cols(P.intervars)) P.label= P.label + st_varlabel(P.varname) + " * "
				else P.label= P.label + st_varlabel(P.varname)
				
				P.level= substr(P.intervars[i] , 1 , strrpos(P.intervars[i],".")-1 )
				
				//remove base, omitted prefix from level => st_vlmap(string varname, real level)
				P.level= subinstr(P.level, "b", "")
				P.level= subinstr(P.level, "o", "")
				
				// throw error if P.level is more than 1 character in lenght
				if (strlen(P.level) > 1) _error(3300, "Level of factor has an non implmented value")
								
				// returns the value-label name associated with var, such as "origin", or it returns "" if var has no
				// value label.  st_varvaluelabel(var, labelname) changes the value-label name associated with var.
				if (P.level=="c") {
				//concatenate the valuelabels
				
					if (i < cols(P.intervars)) P.vlab= P.vlab + st_varlabel(P.varname) + " * "
					else P.vlab = P.vlab + st_varlabel(P.varname)
				}
				else {
					if (i < cols(P.intervars)) P.vlab= P.vlab + st_vlmap(st_varvaluelabel(P.varname), strtoreal(P.level)) + " * "
					else P.vlab = P.vlab + st_vlmap(st_varvaluelabel(P.varname), strtoreal(P.level))
			
				}
			}
		}
		else if(P.paramtype=="c#c") { // paramter is a continious#continious interaction
			for(i=1; i<=cols(P.intervars); i++) {
				P.varname= substr(P.intervars[i] , strrpos(P.intervars[i],".")+1 ,  strlen(P.intervars[i]))
				// returns the variable label associated with var, such as "Sex of Patient", 
				// or it returns "" if var has no variable label.	
				
				//concatenate variable labels
				if (i < cols(P.intervars)) P.label= P.label + st_varlabel(P.varname) + " * "
				else P.label= P.label + st_varlabel(P.varname)
			}
		}
		
	}
	else {
		P.varname= substr(P.param , strrpos(P.param,".")+1 ,  strlen(P.param))
		P.level= substr(P.param , 1 , strrpos(P.param,".")-1 )
		P.omit= strrpos(P.level,"o") // if level contains o it´s an omitted parameter
		P.base= strrpos(P.level,"b") // if level contains b it´s a base parameter
		
		P.level= subinstr(P.level, "b", "")
		P.level= subinstr(P.level, "o", "")
		
		if(P.level!="") {
			P.paramtype= "factor"
			P.label= st_varlabel(P.varname)
			P.vlab = st_vlmap(st_varvaluelabel(P.varname), strtoreal(P.level))
			}
			else {
				if(P.varname=="_cons") {
					P.paramtype= "constant"
					P.label= P.varname
				}
				else {
					P.paramtype= "continious"
					P.label= st_varlabel(P.varname)
				}
			}
			
	}
	/*	
	printf("{txt}param is:{result} %s\n", P.param)
	printf("{txt}varname is:{result} %s\n", P.varname)
	printf("{txt}level is:{result} %s\n", P.level)
	printf("{txt}interaction is:{result} %f\n", P.interaction)
	printf("{txt}label is:{result} %s\n", P.label)
	printf("{txt}vlab is:{result} %s\n", P.vlab)
	printf("{txt}paramtype is:{result} %s\n", P.paramtype)
	printf("{txt}base is:{result} %f\n", P.base)
	printf("{txt}omit is:{result} %f\n", P.omit)
	*/
	st_local("paramtype", P.paramtype)
	st_local("vlab", P.vlab)
	st_local("label", P.label)
	st_local("base", strofreal(P.base))
	st_local("omit", strofreal(P.omit))
	
	//liststruct(P)
}



end

	
	
	
	
	
	
	
	
	
	





