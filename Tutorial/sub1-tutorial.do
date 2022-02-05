/******************************************************************************/
/**SUB-ROUTINES  **/
/******************************************************************************/
	capture program drop stata_output_docx
	program stata_output_docx
		version 15.1
		syntax using/ [, title(string)]
		
		if "`title'"!="" {
			putdocx text (`"`title'"'), bold font(Garamond, 13) 
		}
		
		//start paragraph with format for Stata output
		putdocx paragraph, halign(left) font(Consolas, 8) spacing(line, 0.18) ///
		shading(ghostwhite , black,  clear)
		
		//open textfile with Stata output and read in lines to Word
		file open x using "`using'", read
        file read x line
        while r(eof)==0 {
			//local line= strtrim("`line'")
			if (regexm("`line'","^.?\s*$")){
					//do not print line with just carraige returns
				}
				else if (strmatch("`line'","* log *") ) {
					//do not print line with call to log
                }
				else {
					putdocx text (`"`line'"'), linebreak
				}
				file read x line
        }
		
		// close file and exit
		file close x
		
	end
/*############################################################################*/		
