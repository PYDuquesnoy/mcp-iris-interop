/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occXSLT, EnsXPATHErrors)

/// This is an abstract base class that provides most of the functionality for transforming XML via XSLT
Class EnsLib.XSLT.Transformer Extends (Ens.BusinessOperation, EnsLib.XSLT.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.XSLT.TransformationRequest"> 
		<Method>TransformMessage</Method>
	</MapItem>
</MapItems>
}

/// Default operation is to use a TransformationRequest to transform the input XML into the output
Method TransformMessage(pRequest As EnsLib.XSLT.TransformationRequest, Output pResponse As EnsLib.XSLT.TransformationResponse) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	do {
		// Grab the input content and the stylesheet key
		Set tInput = pRequest.Content
		Set tSSKey = pRequest.StylesheetKey
		
		Set tSC = ..Transform(tInput,tSSKey,pRequest.Parameters,.tOutput)
				
		If $$$ISOK(tSC) {
			Set pResponse = ##class(EnsLib.XSLT.TransformationResponse).%New()
			Set pResponse.Content = tOutput
		}
		
	} while (0)
Exit Quit tSC
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

}
