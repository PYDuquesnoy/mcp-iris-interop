/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %PMML

Class %DeepSee.PMML.Definition.abstractNode Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, Inheritance = right, System = 3 ]
{

/// Ensures <method>%ValidateObject</method> is called for this node and all its nested
/// %PMML subnodes.
/// This works depth-first, so all nested elements are validated before the nesting element
/// itself gets validated. Therefore, <method>%OnValidateObject</method> methods may assume
/// nested elements are fully validated.
Method %ValidatePMML(pForce As %Boolean = 0) As %Status [ CodeMode = objectgenerator, Final, ForceGenerate ]
{
	#define Write(%c) do %code.WriteLine($c(9)_%c)
	set tSC = $$$OK
	try {
		$$$Write("set tSC = $$$OK")
		
		for i = 1:1:%compiledclass.Properties.Count() {
			#dim tProp As %Dictionary.CompiledProperty = %compiledclass.Properties.GetAt(i)
			continue:'$$IsDerivedFrom^%occLibrary(tProp.Type,"%DeepSee.PMML.Definition.abstractNode")
			
			if tProp.Collection = "list" {
				
				$$$Write("if $isobject(i%"_tProp.Name_") {")
				$$$Write("	for j = 1:1:i%"_tProp.Name_".Count() {")
				$$$Write("		set tPropObj = i%"_tProp.Name_".GetAt(j)")
				$$$Write("		continue:tPropObj=""""")
				$$$Write("		set tSC = tPropObj.%ValidatePMML(pForce)")
				$$$Write("		quit:$$$ISERR(tSC)")
				$$$Write("	}")
				$$$Write("	quit:$$$ISERR(tSC) tSC")
				$$$Write("}")
				
			} else {
				
				$$$Write("set:i%"_tProp.Name_"'="""" tSC = i%"_tProp.Name_".%ValidatePMML(pForce)")
				$$$Write("quit:$$$ISERR(tSC) tSC")	
							
			}
		}
		quit:$$$ISERR(tSC)
		
		$$$Write("quit ..%ValidateObject(pForce)")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
