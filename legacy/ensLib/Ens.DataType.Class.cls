/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Datatype for use on settings representing a classname in order to clearly indicate the type of a setting.
Class Ens.DataType.Class Extends %String [ System = 3 ]
{

/// The maximum number of characters a classname can contain.
Parameter MAXLEN As COSEXPRESSION = "$$$MAXCLASSNAMELENGTH";

/// The name of a class that this type should extend
Parameter EXTENDS As %String;

/// A flag that indicates if non-existent classes can be specified
Parameter MUSTEXIST As %Boolean = 0;

/// Use %IsClassnameValid^%occName to validate the class name
ClassMethod IsValid(%val As %String) As %Status [ CodeMode = generator, GenerateAfter = IsValidDT, ServerOnly = 1 ]
{
	$$$GENERATE("	Set %val=$$$NormalizeClassname(%val)")
	$$$GENERATE("	Set tSC = $$IsClassnameValid^%occName(,%val) Quit:$$$ISERR(tSC) tSC")
	
	// If the class doesn't exist, then if MUSTEXIST is specifed, we return ClassDoesNotExist, otherwise OK
	$$$GENERATE("	If '$D(^rINDEXCLASS($ZCVT(%val,""U""))) Quit "_$S(+$G(%parameter("MUSTEXIST")):"$$$ERROR($$$ClassDoesNotExist,%val)",1:"$$$OK"))
	
	// If EXTENDS was specified, and at this point we know the class exists, so we must call %Extends to ensure that it is of the right type.
	If $G(%parameter("EXTENDS"))'="" {
		// If the EXTENDS parameter is specified, then %val must be derived from the specified class
		$$$GENERATE("	If %val'="""_%parameter("EXTENDS")_""",'$$IsDerivedFrom^%occLibrary(%val,"""_%parameter("EXTENDS")_""") {")
		$$$GENERATE("		Quit $$$ERROR($$$EnsErrClassNotDerived,%val,"""_%parameter("EXTENDS")_""")")
		$$$GENERATE("	}")
	}
	$$$GENERATE("	Quit $$$OK")
	Quit $$$OK
}

}
