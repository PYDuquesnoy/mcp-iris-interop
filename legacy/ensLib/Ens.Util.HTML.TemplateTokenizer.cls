/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Tokenizer for the template language.<br/>
/// Syntax:<br/>
/// &nbsp;&nbsp;&nbsp;n&lt;tag&gt;n[Text]{varname} <br/>
/// also: <br/>
/// &nbsp;&nbsp;&nbsp;n&lt;tag,attr1=[Text],attr2=[Text],attr3={varname}&gt;
Class Ens.Util.HTML.TemplateTokenizer Extends Ens.Util.HTML.TokenClassifier [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Type= (tag, text, varname)
Property Type As %String;

Property Value As %String;

/// number of repetitions of the token to find.
Property Count As %Integer;

Property attrs [ MultiDimensional ];

Property input As %String;

Property Pos As %Integer;

Property cLen As %Integer;

Property Rep As %Boolean;

Property RepPos As %Integer;

Property numReps As %Integer;

Parameter start = 0;

Parameter space = 1;

Parameter text = 2;

Parameter num = 3;

Parameter tag = 4;

Parameter varname = 5;

Parameter attr = 6;

Parameter attrstart = 7;

Parameter attrval = 8;

Parameter attrvar = 9;

Parameter done = 10;

Method GetAttrs(ByRef attrs)
{
	Merge attrs = ..attrs
}

Method %OnNew(initvalue As %RawString) As %Status
{
	do ..initTab()

	s cLen = $Length($G(initvalue))
	Q:'cLen $$$ERROR($$$GeneralError,"Empty Tokenizer template string")

	s ..Type = "none"

	s ..input = initvalue
	set ..cLen = cLen
	set ..Pos = 1

	s ..Rep = 0
	s ..numReps = 0
	s ..RepPos = 0

	//w "New Tokenizer: <" _ ..input _ ">",!

	Q $$$OK
}

Method NextToken(ByRef pSC As %Status = {$$$OK}) As %Boolean
{
	if (..Pos > ..cLen) && ('..Rep) { Quit 0 }
	elseif (..Pos > ..cLen) && (..Rep) {
		s ..Pos = ..RepPos
		s ..numReps = ..numReps + 1
	}
	if ((..Type = "+") && (..Pos '= ..RepPos))
	{
		s ..Pos = ..RepPos
		s ..numReps = ..numReps + 1
	}

	s c = $Extract(..input, ..Pos)
	set ctype = ..Classify(c)
	s ..Count = 1
	s ..Type = ""
	s ..Value = ""
	k ..attrs

	//$zobjmethod(mname, params, 
	s tDone = 0
	set tState = ..#start
	s extrachar = 0

	while (1) {
		//*!!!*/ w "state,c=" _ tState _ "'" _c,!
		if tState = ..#start {
			if (c = "+"){
				s tState = ..#done
				s ..Type = "+"
				if '(..Rep) {
					s ..Rep = 1
					s ..numReps = 1
					s ..RepPos = ..Pos + 1
				}
			}
			elseif (c="=") {
				s tState = ..#done
				s ..Type = "="
				s ..Value = "="
			}
			elseif (c = "~") {
				s tState = ..#done
				s ..Type = "~"
				s ..Value = "~"
			}
			elseif c="<" {
				s tState = ..#tag
				s ..Type = "tag"
				s tWordpos = ..Pos+1
			}
			elseif c="[" {
				s tState = ..#text
				s ..Type = "text"
				s tWordpos = ..Pos+1
			}
			elseif c="{" {
				s tState = ..#varname
				s ..Type = "varname"
				s tWordpos = ..Pos+1
			}
			elseif ctype = ..#tokDIGIT {
				s tState = ..#num
				s ..Count = c
			}
			elseif ctype= ..#tokSPACE {
				//s tState = ..#space
				//*!!!*/ w "space",!
			} else {
				//*!!!*/ w "bogus:/"_c_"/"_ctype _ "/",!
				Set pSC=$$$ADDSC(pSC,$$$ERROR($$$GeneralError,"Util.HTML.TemplateTokenizer - Parse char '"_c_"'/"_$A(c)))
			}
		}
		elseif tState = ..#space {
			if ctype '= ..#tokSPACE {
				s extrachar = 1
				s tState = ..#done
			}
		}
		elseif tState = ..#num {
			if ctype = ..#tokDIGIT {
				s ..Count = ..Count*10 + c
			}
			elseif ctype = ..#tokSPACE {
				s tState = ..#space
			}
			else {
				s extrachar = 1
				s tState = ..#start
			}
		}
		elseif tState = ..#tag {
			if c = ">" {
				s tState = ..#done
				s ..Value = $extract(..input, tWordpos, ..Pos-1)
			}
			elseif c = "," {
				s tState = ..#attrstart
				s ..Value = $extract(..input, tWordpos, ..Pos-1)
			}
		}
		elseif tState = ..#attrstart {
			if ctype '= ..#tokSPACE {
				s tState = ..#attr
				s tWordpos = ..Pos
			}
		}
		elseif tState = ..#varname {
			if c = "}" {
				s tState = ..#done
				s ..Value = $extract(..input, tWordpos, ..Pos-1)
			}
		}
		elseif tState = ..#text {
			if c = "]" {
				s tState = ..#done
				s ..Value = $extract(..input, tWordpos, ..Pos-1)
			}
		}
		elseif tState = ..#attr {
			if c = "=" {
				s tState = ..#attrval
				s attrname = $extract(..input, tWordpos, ..Pos-1)
				s tWordpos = ..Pos+1
				//*!!!*/ w "attrname:" _ attrname,!
			}
			elseif c = "," {
				//s tState = ..#attr
				s ..attrs($extract(..input, tWordpos, ..Pos-1)) = ""
				s tWordpos = ..Pos+1
			}
			elseif c = ">" {
				s tState = ..#done
				s ..attrs($extract(..input, tWordpos, ..Pos-1)) = ""
			}
		}
		elseif tState = ..#attrval {
			if c = "," {
				s tState = ..#attr
				s ..attrs(attrname, "value") = $extract(..input, tWordpos, ..Pos-1)
				s tWordpos = ..Pos+1
				//*!!!*/ w "attrval:" _ ..attrs(attrname,"value"),!
			}
			elseif c = ">" {
				s tState = ..#done
				s ..attrs(attrname, "value") = $extract(..input, tWordpos, ..Pos-1)
				//*!!!*/ w "attrval:" _ ..attrs(attrname,"value"),!
			}
			elseif c = "{" {
				s tState = ..#attrvar
				s ..attrs(attrname, "value") = ""
				s tWordpos = ..Pos+1
			}
		}
		elseif tState = ..#attrvar {
			if c = "}" {
				s tState = ..#attrval
				s ..attrs(attrname,"varname") = $extract(..input, tWordpos, ..Pos-1)
				s tWordpos = ..Pos+1 // not expecting any more stuff in attrval, but just in case...
				//*!!!*/ w "attrvar:" _ ..attrs(attrname,"varname"),!
			}
		}

		if tState = ..#done {
			s ..Pos = ..Pos+1
			s tState = ..#start
			Quit
		}
		Quit:tDone // all done
		if extrachar { s extrachar = 0 }
		else { 
			s ..Pos = ..Pos+1
			if ..Pos > ..cLen { s tDone=1, c=0, ctype= ..#tokSPACE } // go through one more time to finish up
			else {
				s c = $Extract(..input, ..Pos)
				set ctype = ..Classify(c)
			}
		}
	} // end while
	Set:tState'=..#start pSC=$$$ADDSC(pSC,$$$ERROR($$$GeneralError,"Template parse ended with bad state "_tState))

	//*!!!*/ w:'tDone "Token: " _ ..Type _ "," _ ..Value _ "," _ ..Count  _ "," _ $d(..attrs),!
	Quit 'tDone
}

}
