/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occVector

/// Datatype class for storing vector content, such as embeddings, in the native $vector format.
/// See also the TO_VECTOR() SQL function to convert user input to the VECTOR datatype
Class %Library.Vector Extends %DataType [ SqlCategory = VECTOR, System = 1 ]
{

/// The datatype of the elements stored in the vector. 
/// Default to FLOAT (SQL type, corresponds to 'xf32' in ObjectScript), a significantly more storage-conscious option for Vector Search.
Parameter DATATYPE [ Constraint = ",DOUBLE,DECIMAL,FLOAT,INT,INTEGER,TIMESTAMP,VARCHAR," ] = "FLOAT";

/// The number of elements the vector can contain.
Parameter LEN As INTEGER;

/// The number of elements the vector can contain.
Parameter STORAGEDEFAULT As STRING = "GLOBALNODE";

ClassMethod IsValid(%val As %Vector) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
    // Validate LEN parameter - either NULL, "", or a positive integer ; YWH022
	If ($Get(%parameter("LEN")) '= "") && (('$isvalidnum(%parameter("LEN"),,1)) || (((+%parameter("LEN")\1)) '= +%parameter("LEN"))) { Quit $$$ERROR($$$DatatypeParameterIntegerNotPositive,%class_"::"_%property,"LEN",%parameter("LEN")) }
	
	// check for a valid $vector value with length restriction if length is specified
    $$$GENERATE("  RETURN:'$isvector(%val) $$$ERROR($$$DTNotVector,%val)") 
    if %parameter("LEN")'="" {
        $$$GENERATE("    RETURN:$vop(""length"",%val)'="""_(+%parameter("LEN"))_""" $$$ERROR($$$DTVectorLenMismatch, %val, """_(+%parameter("LEN"))_""")")
    }

	// enforce that there should be no empty internal slots, do this after the 
	$$$GENERATE("  RETURN:'($vop(""length"", %val)=$vop(""count"", %val)) $$$ERROR($$$DTVectorNulls,%val)") 
	
	// cast $vector to have the correct datatype 
	set voptype=$s(%parameter("DATATYPE")="FLOAT":"xf32",%parameter("DATATYPE")="INT":"integer",1:$$$LOWER(%parameter("DATATYPE")))
	$$$GENERATE("  set:($vop(""type"",%val)'="""_voptype_""") %val=$vop(""convert"",%val,"""_voptype_""")")
    $$$GENERATE("  RETURN $$$OK")
}

ClassMethod Normalize(%val As %Vector) As %Vector [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE(" quit %val")
	QUIT $$$OK
}

/// DisplayToLogical - If this is passed a dynamic array e.g. 
/// 'Set dynArray=[1,2,3,4]' then detect this with $isobject(%val) 
/// and then if it is an oref then test if it is a dynamic array 
/// and if so then walk this turning it into a vector so
///  we can support JSON and dynamic arrays.
/// 
ClassMethod DisplayToLogical(%val As %String) As %Vector [ CodeMode = generator, ServerOnly = 1 ]
{
	// At the moment, Display and ODBC haven't diverged
	$$$GENERATE(" RETURN ..OdbcToLogical(%val)")
	QUIT $$$OK
}

ClassMethod LogicalToDisplay(%val As %Vector) As %String
{
	set vecDisplay=""
	if $vop("type", %val) = "string" { // quote entries and replace internal quotes "" with \" for string types
		for ptr=1:1:$vop("length",%val) { set vecDisplay=vecDisplay_""""_$replace($ve(%val,ptr),"""","\""")_""""_", " }	
	} else {
		for ptr=1:1:$vop("length",%val) { set vecDisplay=vecDisplay_$ve(%val,ptr)_", " }
	}
	quit $e(vecDisplay,1,*-2)
}

ClassMethod LogicalToOdbc(%val As %Vector) As %String [ ServerOnly = 1 ]
{
	set vecDisplay=""
	if $vop("type", %val) = "string" { // quote entries and replace internal quotes "" with \" for string types
		for ptr=1:1:$vop("length",%val) { set vecDisplay=vecDisplay_""""_$replace($ve(%val,ptr),"""","\""")_""""_"," }	
	} else {
		for ptr=1:1:$vop("length",%val) { set vecDisplay=vecDisplay_$ve(%val,ptr)_"," }
	}
	quit $e(vecDisplay,1,*-1)
}

ClassMethod OdbcToLogical(%val As %String) As %Vector [ CodeMode = generator, ServerOnly = 1 ]
{
	set voptype=$s(%parameter("DATATYPE")="FLOAT":"xf32",%parameter("DATATYPE")="INT":"integer",1:$$$LOWER(%parameter("DATATYPE")))
	$$$GENERATE(" RETURN:%val="""" """"") // return null right away if null
	$$$GENERATE(" try {")
	$$$GENERATE(" 	RETURN:$isvector(%val) %val") // no conversion needed if already a $vector
	$$$GENERATE("	set vec = """"")
	// Input being converted to string (avoid whitespace issues) and input already in a Dynamic Array will use dynamic array iterator
	$$$GENERATE("	if "_$s(voptype="string": "1", 1:"$isobject(%val) && ($classname(%val) = ""%Library.DynamicArray"")")_" {")
	$$$GENERATE("		if ($isobject(%val)) {")
	$$$GENERATE("			set iterator = %val.%GetIterator()")
	$$$GENERATE("		} else {")
	$$$GENERATE("			set iterator = {}.%FromJSON(""[""_$zstrip(%val, ""<>W"", ""[]"")_""]"").%GetIterator()")
	$$$GENERATE("		}")
	$$$GENERATE(" 		while iterator.%GetNext(.key, .value, .jsonElementType) {")
	$$$GENERATE("			if (jsonElementType = ""null"") {")
	$$$GENERATE("				set %msg = $$$FormatText($$$Text(""Failed to convert %1 to logical vector value: Cannot insert NULL into vector"",""%SQL.Function""), $e(%val,1,100))")
								// This will end up just being a ztrap "SQER" and setting SQLCODE, but let's keep the conversion error handling in the one centralized method
	$$$GENERATE("				do ..HandleConversionError("""", %val)")
	$$$GENERATE("			}")
	$$$GENERATE("   		set $vector(vec,key+1,"""_voptype_""") = value")
	$$$GENERATE(" 		}")	
	$$$GENERATE("	} else {")
	$$$GENERATE("		set strippedInput = $zstrip(%val, ""*W"", ""[]"")")
	$$$GENERATE("		if (("",""_$zcvt(strippedInput, ""U"")_"","") [ ("",NULL,"")) {")
	$$$GENERATE("			set %msg = $$$FormatText($$$Text(""Failed to convert %1 to logical vector value: Cannot insert NULL into vector"",""%SQL.Function""), $e(%val,1,100))")
	$$$GENERATE("			do ##class(%Library.Vector).HandleConversionError("""", %val)")
	$$$GENERATE("		}")
	$$$GENERATE("		set vec = $vop(""fromstring"", strippedInput, """_voptype_""", "","", 3)")
    $$$GENERATE(" 	}")
	$$$GENERATE(" 	RETURN vec")
	$$$GENERATE(" } catch ex {")
	$$$GENERATE(" 	do ..HandleConversionError(ex, %val)")
	$$$GENERATE(" }")
	
	QUIT $$$OK
}

ClassMethod HandleConversionError(ex As %RawString, conversionInput As %String) [ Internal, PublicList = SQLCODE ]
{
	if ex.Name = "Parsing error" { // failed to convert string to DynamicArray
		// can't use $piece because what if a string has comma in it
		set inputAsList = $lfs($zstrip(conversionInput,"<>W", "[]"), ",", 2) // flag = 2 means ignore delimiters within quotes in the string
		set %msg = $$$FormatText($$$Text("Failed to convert %1 to logical vector value: Invalid input","%SQL.Function"), $e(conversionInput,1,100))
		set ptr = 0
		while $listnext(inputAsList, ptr, item) {
			// Error is unquoted string, check if NULL specifically otherwise generic
			// Note that null, as in the JSON type null (distinct from NULL, NuLl etc), must be handled when iterating over the input during the conversion
			// so it's already handled at this point
			if $e(item) '= """", '$isvalidnum(item) {
				if $zcvt(item,"U")="NULL" { // first/last items might have []
					set %msg= $$$FormatText($$$Text("Failed to convert %1 to logical vector value: Cannot insert NULL into vector","%SQL.Function"), $e(conversionInput,1,100))
				} else {
					set %msg = $$$FormatText($$$Text("Failed to convert %1 to logical vector value: Literal string '%2' must be quoted","%SQL.Function"), $e(conversionInput,1,100), item)
				}
				QUIT // found at least one bad item, exit loop
			}
		}
	}
	ztrap "VCON" // vector conversion error; this function is called from CQs, should always be error trap set
}

ClassMethod CalculateODBCLength(datatype As %String = "FLOAT", len As %Integer = "") [ Internal ]
{
	RETURN:(len="" || (datatype="STRING")) $$$MaxStringLength
	// (maxTypeDisplaySize * len) + (len-1)
	// len - 1 is to account for the commas that delimit the entries in the ODBC string
	RETURN ($case(datatype, "DOUBLE": $$$MaxDoubleDisplayLength, "DECIMAL": $$$MaxDecimalDisplayLength, "FLOAT": $$$MaxDoubleDisplayLength, :$$$MaxIntegerDisplayLength) * len +  (len - 1))
}

}
