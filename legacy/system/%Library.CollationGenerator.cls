/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements expression generators for all collations.
/// 
/// <p>A collation expression is used by code generators to tranform logical data values into 
/// values used by indices.
/// <p>For example, you may wish that a query by name finds 
/// the same results for both "ELVIS" and "elvis". Using a case-insensitive 
/// index transformation, such as String, will accomplish this. If you want an exact 
/// match, use Exact.
/// 
/// <p>Collations are specified via a property's <var>COLLATION</var> parameter. Every datatype 
/// has a default <var>COLLATION</var> value, which matches one of the methods of the 
/// <nobr><b>%Collation</b></nobr> class. 
/// The <var>COLLATION</var> parameter can be overwritten by an individual property or by 
/// a specific index definition.
/// 
/// <p>Note that changing a property's <var>COLLATION</var> value will corrupt any index values 
/// currently stored for that property and will require you to manually repopulate the 
/// index.
Class %Library.CollationGenerator [ System = 2 ]
{

/// This method generates the appropriate collation expression as requested by the parameters.
/// 
/// collation = 
/// <p><b>AlphaUp</b>	Converts a logical value to upper case, strips all punctuation and white space (except for ',' and '?').
/// <p>This method is included for compatability with earlier products; use <b>String</b> instead.
/// 
/// <p><b>Exact</b>	Performs no transformation; the index value is exactly the logical value.
/// 
/// <p><b>Minus</b>	Prepends a minus ('-') sign to the logical value.
/// <p>This method is included for compatability with earlier products; you should not 
/// need it in new applications.
/// 
/// <p><b>MVR</b>	MULTI VALUE Collation
/// 
/// <p><b>Plus</b>	Prepends a plus ('+') sign to the logical value.
/// <p>This method is included for compatability with earlier products; you should not 
/// need it in new applications.
/// 
/// <p><b>Space</b>	Prepends a space (' ') character to the logical value.
/// <p>This method is included for compatability with earlier products; you should not 
/// need it in new applications.
/// 
/// <p><b>SqlString</b>	Prepends a space to force string collation and strips trailing whitespace.
/// <p>This method is used to insure that strings are collated case-sensitively and that numeric 
/// string values are collated correctly.
/// 
/// <p><b>SqlUpper</b>	Converts a logical value to upper case, strips trailing whitespace and prepends a space to force string collation.
/// <p>This collation is used to insure that strings are collated case-insensitively and that numeric 
/// string values are collated correctly.
/// 
/// <p><b>String</b>	Converts a logical value to upper case, strips all punctuation and white space 
/// (except for ',').
/// 
/// <p><b>Truncate</b>	Performs no transformation; the index value is exactly the logical value.  However, the value will be truncated to
/// the length specified by the optional length argument.  Truncate with no length is the same as Exact.
/// 
/// <p><b>Upper</b>	Converts a logical value to upper case without removing any characters.
/// 
/// <p>%val	the expression being collated
/// <p>parms	collation parameters as expected by collation
ClassMethod CollationExpression(collation As %String = "", %val As %String, parms As %String) As %String
{

 Set collation = $zcvt(collation,"U")
 if ($g(parms)[","){
	 // this collation might be COLLATE, 
	 // parms looks like:"'prepend-space, strip-trailing-whitespace', 5" 
 	do getCollateParms^%qaqcpre(parms,.parm1,.parm2)
 }
 else{
	set parm1 = $g(parms)
 }
 If collation = "SQLUPPER" Quit $$$SQLUPPERTCodeGen(%val,$s($g(parm1)="":32768,1:parm1))
 If collation = "ALPHAUP" Quit $$$ALPHAUPCodeGen(%val)
 If collation = "UPPER" Quit $$$UPPERCodeGen(%val)
 If collation = "SQLSTRING" Quit $$$SQLSTRINGTCodeGen(%val,$s($g(parm1)="":32768,1:parm1))
 If collation = "STRING" Quit $$$STRINGTCodeGen(%val,$s($g(parm1)="":32768,1:parm1))
 If collation = "MVR" Quit $$$MVRCodeGen(%val)
 If collation = "TRUNCATE" Quit $$$TRUNCATETCodeGen(%val,$s($g(parm1)="":32768,1:parm1))
 If collation = "EXACT" Quit %val
 If collation = "PLUS" Quit "+"_%val
 If collation = "SPACE" Quit """ ""_"_%val
 If collation = "MINUS" Quit "-"_%val
 If collation = "COLLATE" Quit $$$COLLATETCodeGen(%val,parm1,$s($g(parm2)="":32768,1:parm2))
}

ClassMethod IsValid(collation As %RawString = "") [ CodeMode = expression ]
{
(''$Find("|SQLUPPER|ALPHAUP|EXACT|UPPER|SQLSTRING|STRING|PLUS|SPACE|MINUS|MVR|TRUNCATE|COLLATE||","|"_$$$ucase($Piece(collation,"(",1))_"|"))&&((collation'["(")||($Find("|SQLUPPER|SQLSTRING|STRING|TRUNCATE|COLLATE|","|"_$$$ucase($Piece(collation,"(",1))_"|")))
}

ClassMethod Nulls(collation As %String = "", collationparms As %String = "") As %Boolean
{
	Set collation = $zcvt(collation,"U")
	If collation = "SQLUPPER" Quit 0
	If collation = "ALPHAUP" Quit 1
	If collation = "UPPER" Quit 1
	If collation = "MVR" Quit 0
	If collation = "SQLSTRING" Quit 0
	If collation = "STRING" Quit 0
	If collation = "EXACT" Quit 1
	If collation = "PLUS" Quit 0
	If collation = "SPACE" Quit 0
	If collation = "MINUS" Quit 0
	If collation = "TRUNCATE" Quit 1
	If collation = "COLLATE" {
		do getCollateParms^%qaqcpre(collationparms,.parm1)
		Quit:(parm1["prepend-space")||(parm1["mode=+")||(parm1["mode=-") 0
	}
	Quit 1
}

/// Generate collation expression for COLLATE collation
ClassMethod CollateCodeGen(val As %String, transSpec As %String = "", length As %String = "") As %String
{
	set ps = transSpec["prepend-space", stw = transSpec["strip-trailing-whitespace", sa = transSpec["strip-accents"
	if $P(transSpec,"mode=",2)'="" {
		set m = $E($P(transSpec,"mode=",2))
	} else{
		set m = ""
	}
	if (transSpec["translate=") {
		set t = $P(transSpec,"translate=",2)
		if t["," {
			set t = $zcvt($P(t,",",1),"U")	
		}
	} else{
		set t = ""	
	}
	// check if this is same as any existing collation 
	if transSpec=""{// same as %TRUNCATE
		quit $s(length:$$$TRUNCATETCodeGen(val,length),1:$$$TRUNCATECodeGen(val))	
	} elseif ps&&stw&&('sa)&&('t)&&(m="u"){// same as %SQLUPPER
		quit $s(length:$$$SQLUPPERTCodeGen(val,length),1:$$$SQLUPPERCodeGen(val))
	} elseif ps&&stw&&('sa)&&('t)&&(m=""){// same as %SQLSTRING
		quit $s(length:$$$SQLSTRINGTCodeGen(val,length),1:$$$SQLSTRINGCodeGen(val))	
	} elseif ('(ps||stw||sa||t))&&(m="u")&&(length=0){ // same as %UPPER
		quit $$$UPPERCodeGen(val)
	} else { // this collation is different from all the existing collations
		set colExp = val
		if sa {
			if m="u" {
				set colExp = "$zcvt("_colExp_",""AU"")"	
				set m = ""
			} elseif m="l" {
				set colExp = "$zcvt("_colExp_",""AL"")"	
				set m = ""
			} else{
				set colExp = "$zcvt("_colExp_",""A"")"	
			}
		}
		if stw {
			if ps {
				set ps = 0
				set colExp = "$zu(28,"_colExp_",8)"	
			} else{
				set colExp = "$e($zu(28,"_colExp_",8),2,*)"	
			}	
		}
		if m="u" {
			set colExp = "$zcvt("_colExp_",""U"")"	
		}elseif m="l" {
			set colExp = "$zcvt("_colExp_",""L"")"	
		}elseif m="+" {
			set colExp = "+"_colExp	
		}elseif m="-" {
			set colExp = "-"_colExp	
		}
		if t'="" {
			set colExp = "$zcvt("_colExp_",""O"","_$$$quote(t)_")"	
		}
		if ps {
			set colExp = "("" ""_"_colExp_")"
		} 
		if length {
			set colExp = "$e("_colExp_",1,"_length_")"	
		}
		quit colExp
	}
	quit val
}

}
