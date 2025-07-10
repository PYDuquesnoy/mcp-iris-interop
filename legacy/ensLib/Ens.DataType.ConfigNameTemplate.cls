/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Template class for building config names
Class Ens.DataType.ConfigNameTemplate Extends Ens.DataType.ConfigName [ System = 4 ]
{

/// Start of the replacement marker
Parameter STARTREPLACEABLE As %String = "${";

/// End of the replacement marker
Parameter ENDREPLACEABLE As %String = "}";

/// Check for a canonical config name (i.e. one that doesn't have replacable values)
ClassMethod IsCanonical(pConfigName As Ens.DataType.ConfigNameTemplate) As %Boolean [ CodeMode = expression ]
{
(pConfigName'[..#STARTREPLACEABLE)
}

/// Used to replace values in a config name string
ClassMethod ReplaceWithObjectProperties(pConfigName As Ens.DataType.ConfigNameTemplate, pObject As %RegisteredObject) As Ens.DataType.ConfigName
{
	#dim tSC     As %Status
	#dim tResult As %String
	#dim tStart  As %String = ..#STARTREPLACEABLE
	#dim tEnd    As %String = ..#ENDREPLACEABLE
	
	Set tSC=$$$OK,tResult=pConfigName
	While(1) {

		#dim p         As %Integer
		#dim q         As %Integer
		#dim tToken    As %String
		#dim tProperty As %String
		#dim tValue    As %String
		
		Set p=$FIND(tResult,tStart)
		Quit:'p
		
		Set q=$FIND(tResult,tEnd,p)
		Quit:'q
		
		// Grab the token
		Set tToken = $EXTRACT(tResult,p,q-2)
		
		Set tValue = pObject.GetValueAt(tToken,,.tSC)
		Quit:$$$ISERR(tSC)
		
		// Insert the new value
		Set tResult = $EXTRACT(tResult,1,p-3)_$GET(tValue)_$EXTRACT(tResult,q,$LENGTH(tResult))
	}
	
	Set %objlasterror = tSC
	
	Quit tResult
}

}
