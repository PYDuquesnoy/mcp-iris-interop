/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An XML resolver that uses the information 
/// <CLASS>%XML.Catalog</CLASS> class.
Class %XML.CatalogResolver Extends %RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

Method resolveEntity(publicID As %Library.String, systemID As %Library.String) As %Library.Integer
{
	New id,components,ret,io
	
	Set ret = ""

	If (publicID '= "") {
		// use catalog
		Set ret = ##class(Catalog).ResolvePublic(publicID)
		If (ret = "") {
		 	Set io = $io
		 	Use 0
		 	Write "ERROR: Unable to resolve Formal Public Identifier: ",!,"""",publicID,"""",!
	 		Use io
		}
	}
 	Else {
	 	// use systemID
	 	// !!!
	 	Quit ""
 	}
 	
 	Quit ret
}

}
