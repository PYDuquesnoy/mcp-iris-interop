/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsEDIXML, %systemInclude)

Class EnsLib.EDI.XML.MsgBodyMethods Extends Ens.Util.MessageBodyMethods [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

Method %GetContentType() As %String
{
	Quit "text/xml"
}

Method %ShowContents(pZenOutput As %Boolean = 0)
{
	If (%response.ContentType="application/json") {
			Do ..WriteNoJSONFormat($this)
	} Else {
		&html<<?xml version="1.0" ?>
		<?xml-stylesheet href="ensemble/Ensemble_XMLDisplay.xsl" type="text/xsl" ?>
		<!-- type: #($classname())#  id: #(..%Id())# -->
		>
		Do ..OutputToDevice()
	}
}

/// This method is used to provide the Statistics Site Dimension if not already set
Method GetStatsDimension() As %String
{
	#dim tDimension As %String = $$$StatsDefaultDimension
	Try { Set tDimension = ..Name } Catch {}
	Quit tDimension
}

}
