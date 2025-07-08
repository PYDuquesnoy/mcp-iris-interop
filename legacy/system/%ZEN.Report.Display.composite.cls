/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.composite Extends (%ZEN.Report.Display.template, %ZEN.Report.Display.tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Developers should override this XData block to provide the default contents of this composite group
/// In addtion, the %OnAfterCreateComposite() method may be overridden in order to dynamically modify
/// the default composition.
XData Display [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<composite xmlns="http://www.intersystems.com/zen/report/display">

</composite>
}

/// This callback is called after the children of this composite
/// component have been created.
Method %OnAfterCreateComposite() As %Status [ Abstract ]
{
	Quit $$$OK
}

/// This internal method creates the contents of the composite component.
Method %CreateComposite() As %Status [ CodeMode = objectgenerator, GenerateAfter = %OnAfterCreateComposite, ProcedureBlock = 0 ]
{
	If (%class.Name = "%ZEN.Report.Display.composite") {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Do %code.WriteLine(" New tSC")
	Do %code.WriteLine(" Set tSC = $$$OK")

	// set up composite context
	Do %code.WriteLine(" New %composite")
	Do %code.WriteLine(" Set %composite = ##this")

	// figure out if this page should provide automatic localization
	// For library (system) classes, localization occurs for %ZEN domain
	// For non-library classes, check for non-%ZEN domain
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
	}

	#; find XDATA block named Display
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Display")

	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into composite object (with children)
			Set tReader = ##class(%XML.Reader).%New()
			Set tSC = tReader.OpenStream(tStream) If $$$ISERR(tSC) Quit tSC
			Do tReader.Correlate("composite","%ZEN.Report.Display.composite")
			
			#; there should only be one composite object defined
			Do tReader.Next(.tComposite,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tComposite) Quit $$$ERROR($$$GeneralError,"No <composite> element defined in Display block.")
	#;Method %GenerateCode(pCode As %CharacterStream, pLocalize As %Boolean, pCollection As %String, pLevel As %Integer = 1, pKey As %String = "", pParentVar As %String = "unknown", pReturnInParent As %Boolean = 0,pMode="report") [ CodeMode = objectgenerator, Internal ]

			#; have composite object generate code to recreate itself at run-time
			Do tComposite.%GenerateCode(%code,tLocalize,"children",,,,,"composite")
		}
	}

	#; set property to indicate that children have been created
	#; Do %code.WriteLine(" Set ..childrenCreated = 1")

	#; check for callback
	If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnAfterCreateComposite",$$$cMETHrunnable)) {
		Do %code.WriteLine(" Set tSC=..%OnAfterCreateComposite()")
	}

	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

}
