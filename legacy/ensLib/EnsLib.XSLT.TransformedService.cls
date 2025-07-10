/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A generic business service that applies an XSLT transform to the incoming request
/// and to the outbound response.
Class EnsLib.XSLT.TransformedService Extends (Ens.BusinessService, EnsLib.XSLT.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Property InboundStylesheet As %String(MAXLEN = 512);

Property OutboundStylesheet As %String(MAXLEN = 512);

Parameter SETTINGS = "InboundStylesheet,OutboundStylesheet";

/// The compiled inbound stylesheet
Property InboundCompiledStylesheet As %XML.XSLT.CompiledStyleSheet [ InitialExpression = {$$$NULLOREF}, Private, Transient ];

/// The compiled outbound stylesheet
Property OutboundCompiledStylesheet As %XML.XSLT.CompiledStyleSheet [ InitialExpression = {$$$NULLOREF}, Private, Transient ];

/// Parameters
Property Params [ MultiDimensional, Private, Transient ];

Method OnProcessInput(pInput As %RegisteredObject, pOutput As %RegisteredObject) As %Status
{
	
	Quit $$$ERROR($$$NotImplemented)
}

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		// Load the inbound and outbound stylesheets
		For tProp = "Inbound", "Outbound" {
			Set tURL = $ZOBJPROPERTY($this, tProp_"Stylesheet")
			If tURL '= "" {
				
				Set tSC = ##class(Ens.Util.URLStream).GetURLStream(tURL,.tStream)
				If $$$ISOK(tSC) {
					Set tSC = ##class(%XML.XSLT.CompiledStyleSheet).CreateFromStream(tStream,.tCSS)
					If $$$ISOK(tSC) {
						// Store the compiled stylesheet
						Set $ZOBJPROPERTY($this, tProp_"CompiledStylesheet") = tCSS
					}
				}
				
				If $$$ISERR(tSC) {
					$$$TRACE(tSC)
				}
			}
		}

		// Grab any parameters
		Do ..getParameters(..Parameters,.tParams)
		Merge ..Params = tParams
	
	} While (0)
Exit
	Quit
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This user callback method is called just before %OnClose()
Method OnTearDown() As %Status
{
	// Compiled stylesheets will go out of scope and be released as this object is released.
	
	Quit $$$OK
}

}
