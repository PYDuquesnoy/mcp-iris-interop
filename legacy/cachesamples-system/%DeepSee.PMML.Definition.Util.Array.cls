/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Array Extends AbstractArray [ System = 3 ]
{

Property type As %DeepSee.PMML.Datatype.String(VALUELIST = ",int,string,real", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property Values As %DeepSee.PMML.Datatype.String(MAXLEN = "", XMLPROJECTION = "CONTENT");

Method ValuesAsArray(Output pArray) As %Status
{
	kill pArray
	set tSC = $$$OK
	try {
		set pArray = 0
		
		set tValues = $zstrip(..Values,"<>WC"), tQuoted = 0
		quit:tValues=""
		
		while 1 {
			
			// find the next spacer or end quote
			if $e(tValues,1)="""" {
				set tQuoted = 1, tPos=1
				while 1 {
					set tPos = $find(tValues,"""",tPos+1)
					if 'tPos { set tSC = $$$ERROR($$$GeneralError, "unterminated quote in Array values") quit }
					quit:$e(tValues,tPos-2)'="\"
				}
				quit:$$$ISERR(tSC)
				set tPos = tPos+1
			} else {
				set tPos = $find(tValues," ")
			}
			if 'tPos {
				set tValue = tValues
				set tValues=""
			} else {
				set tValue = $e(tValues,1,tPos-2)
				set tValues = $zstrip($e(tValues,tPos,*),"<W")
			}
			
			// un-quote
			if tQuoted {
				set tValue = $e(tValue,2,*-1)
				set tQuoted=0
			}
			set tValue = $replace(tValue,"\""","""")
			
			set pArray($i(pArray)) = tValue
			quit:tValues=""
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method Length(Output pSC As %Status = {$$$OK}) As %Integer
{
	set pSC = $$$OK
	quit:..n ..n
	set pSC = ..ValuesAsArray(.tArray)
	quit $s($$$ISERR(pSC):"", 1:$g(tArray,0))
}

Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		set tSC = ..ValuesAsArray(.tArray)
		quit:$$$ISERR(tSC)
		
		if ..n && (tArray '= ..n) {
			set tSC = $$$ERROR($$$GeneralError, "Array value count does not match n")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
