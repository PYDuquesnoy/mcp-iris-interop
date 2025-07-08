/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a computed dimension that uses an external SET definition
/// to resolve members.<br/>
/// 
Class %DeepSee.ComputedDimension.SET Extends %DeepSee.ComputedDimension.Base [ System = 4 ]
{

/// Type reported back to the UI. This determines what type of control to display
/// for filters based on this class.
Parameter DIMTYPE = "mdx";

/// Array of arguments from the SET class spec.
Property %args As %String [ MultiDimensional ];

/// Test if <var>pName</var> is a valid member name.
Method %FindComputedMemberByName(pName As %String, Output pFlag As %Boolean, Output pMemberKey As %String, Output pMemberId As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set tSC = ..%GetComputedMembers(.tMemberList)
		If $$$ISERR(tSC) Quit

		Set k = $O(tMemberList(""))
		While (k'="") {
			Set tName = $LG(tMemberList(k),2)
			If ($$$UPPER(tName)=$$$UPPER(pName)) {
				// compute id for this member
				Set pMemberKey = $LG(tMemberList(k),3)
				Set tSC = ..%ComputeBitset(pMemberKey,.pMemberId)
				If $$$ISERR(tSC) Quit
				Set pFlag = 1
				Quit
			}
			Set k = $O(tMemberList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Build the bitset that corresponds to the given computed dimension "spec".
Method %OnComputeBitset(pSpec As %String, pIndexKey As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// pSpec is the name of a ResultSet class that returns an ID property
		// pSpec can be class(arg:value,arg:value); check for this
		// Built-in args include:
		// %source:fact|source	where ids come from; default is source
		// 
		Kill ..%args
		Kill tArgs
		Set tClass = $P(pSpec,"(",1)
		Set tArgList = $P(pSpec,"(",2)
		If (tArgList'="") {
			Set tSC = ..%ParseArgList("("_tArgList,.tArgs)
			If $$$ISERR(tSC) Quit
			Merge ..%args = tArgs
		}

		// instantiate result set
		Set tRS = $classmethod(tClass,"%New",,.tArgs)

		If ($IsObject(tRS)&&tRS.%IsA("%SQL.StatementResult")) {
			// translate from source to fact id if %source=source
			Set tTranslate = $G(..%args("%source"),"source")="source"
			Set tSC = ..%CreateIndexFromSQL("",pIndexKey,tRS,tTranslate)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid SET: " _ pSpec)
		}
		Set tRS = ""
	}
	Catch(ex) {
		//Set tSC = ex.AsStatus()
		Set tSC = $$$ERROR($$$GeneralError,"Invalid SET: " _ pSpec)
	}
	Quit tSC
}

/// Execute a search for members.<br/>
/// Return a list of the form:<br/>
/// pList(n) = $LB(value,key)
Method %MemberSearch(pSearchKey As %String, Output pList As %List) As %Status
{
	Quit ..%MemberSearchByMembers(pSearchKey,.pList)
}

/// Parse an argument list "(arg:value,arg:value)" for a SET class.
/// Return an array of names and values.
ClassMethod %ParseArgList(pArgList As %String, Output pList As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// pull apart args: (arg:value)
		Set tState = 0
		Set tArgName = ""
		Set tArgValue = ""
		For p = 1:1:$L(pArgList) {
			Quit:$$$ISERR(tSC)
			Set ch = $E(pArgList,p)
			
			If (tState=0) {
				If (ch="(") {
					Set tState = 1
				}
			}
			ElseIf (tState=1) {
				// arg
				If (ch=":") {
					Set tArgName = $ZSTRIP(tArgName,"<>W")
					If (tArgName="") {
						Set tSC = $$$ERROR($$$GeneralError,"Missing argument name (1)")
					}
					Set tState = 2
				}
				ElseIf (ch=",") {
					Set tSC = $$$ERROR($$$GeneralError,"Missing argument value (2)")
					Set tArgName = ""
				}
				ElseIf (ch'=")") {
					Set tArgName = tArgName _ ch
					Set tArgValue = ""
				}
			}
			ElseIf (tState=2) {
				// wait for value
				If ((ch=")")||(ch=",")) {
					Set tSC = $$$ERROR($$$GeneralError,"Missing argument value (3)")
				}
				ElseIf (ch="""") {
					Set tState = 4
				}
				ElseIf (ch'=" ") {
					Set tArgValue = ch
					Set tState = 3
				}
			}
			ElseIf (tState=3) {
				// value (unquoted)
				If ((ch=",")||(ch=")")) {
					Set tArgValue = $ZSTRIP(tArgValue,"<>W")
					If (tArgValue="") {
						Set tSC = $$$ERROR($$$GeneralError,"Missing argument value (4)")
					}
					Set pList(tArgName) = tArgValue
					Set tState = 1
					Set tArgName = ""
					Set tArgValue = ""
				}
				Else {
					Set tArgValue = tArgValue _ ch
				}
			}
			ElseIf (tState=4) {
				// value (quoted)
				If (ch="""") {
					Set pList(tArgName) = tArgValue
					Set tState = 5
					Set tArgName = ""
					Set tArgValue = ""
				}
				Else {
					Set tArgValue = tArgValue _ ch
				}
			}
			ElseIf (tState=5) {
				// end of quoted value
				If (ch=",") {
					Set tState = 1
				}
			}
		}

		If $$$ISOK(tSC) {
			If (tState=3) {
				Set tSC = $$$ERROR($$$GeneralError,"Missing closing parens (5)")
			}
			ElseIf (tState=4) {
				Set tSC = $$$ERROR($$$GeneralError,"Missing closing quotes (6)")
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
