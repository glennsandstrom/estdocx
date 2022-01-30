
void test_array(){
	class AssociativeArray scalar A
	transmorphic i, ii
	transmorphic keys
	real matrix rtable
	real colvector beta
	string matrix rownames, colnames
	real scalar val
		//get matrix rtable created by running estimates replay `model' in get_models
		rtable= st_matrix("M")
		rownames= st_matrixrowstripe("M") //get varlist of model
		colnames= st_matrixcolstripe("M") //get stats of model
		colnames= colnames[.,2] 			//remove first col that is all missing
		rownames= rownames[.,2] 			//remove first col that is all missing
		
		"rtable"
		rtable
		"rownames"
		rownames
		"colnames"
		colnames
		
	beta= rtable[.,1]
	"beta"
	beta
		
	A.reinit("string", 3) // reinit as array with 3 dimention string keys
	A.notfound(99)
	
	//A.put(("b", rownames[1]), beta[1])
	//printf("{txt}%s  {res}%f\n",rownames[1], A.get(("b",rownames[1])))
	//A.get(("b", rownames[1]))

	for (i=1; i<=length(beta); i++) {
		A.put(("b", "MODEL1", rownames[i]), beta[i])
		
		
	}
	
	
	
	"N"
	A.N()
	"notfound"
	
	A.notfound()

	for (i=1; i<=length(rownames); i++) {
		printf("{txt}%s  {res}%f\n",rownames[i], A.get(("b","MODEL1", rownames[i])))
	
	
	}
	
	
	keys= A.keys()
	"KEYS ARE:"
	keys
	
	

//A.firstloc()
//A.nextloc()

//loop over elements
for (ii=1; ii<=length(keys); ii++) {
	keys[ii]
	A.get(keys[ii])
	
	
}



	
	
}

