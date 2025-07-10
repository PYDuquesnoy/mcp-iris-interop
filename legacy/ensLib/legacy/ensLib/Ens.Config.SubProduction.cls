/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Config.SubProduction Extends (%SerialObject, %XML.Adaptor) [ ProcedureBlock, System = 4 ]
{

Property Name As %String(MAXLEN = 128, XMLPROJECTION = "CONTENT") [ Required ];

Property Enabled As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

ClassMethod Test()
{
	s p=##class(Ens.Config.Production).%New()
	s p.Name="Test.Mo.NewProduction3"
	;
	s s1=##class(Ens.Config.SubProduction).%New()
	s s1.Name="Test.File.Production"
	s s1.Enabled=1
	d p.SubProductions.Insert(s1)
	;
	s s2=##class(Ens.Config.SubProduction).%New()
	s s2.Name="Test.HL7.Production"
	d p.SubProductions.Insert(s2)
	;
	w p.%Save()
	w p.SaveToClass()
	;
}

ClassMethod Parse(pFileName = "c:\xyz.xml")
{
	set tSC=$$$OK
	try {
		Set reader = ##class(%XML.Reader).%New()
		Set tSC = reader.OpenFile(pFileName) Quit:$$$ISERR(tSC)
		Do reader.Correlate("Production","Ens.Config.Production")
		
		While (reader.Next(.entry,.tSC)) {
			break
			Set tSC = entry.%Save()
			Quit:$$$ISERR(tSC)
		}
	} catch {
		set tSC=$$$ERROR($$$EnsSystemError,$ZE)
	}
	quit tSC


		#; Find the XDATA itself
		set tSC=##class(Ens.Util.XML.XDataEntityResolver).EntityFromXDATA(.tStream,$$$CurrentClass,pClassName)
		if $$$ISERR(tSC) quit
		
		#; Create a SAX resolver for the Schema
		set tResolver=##class(Ens.Util.XML.XDataEntityResolver).%New("Ens.Config.Production")
 		$$$ASSERT($IsObject(tResolver))
 		
 		set tSC=##class(Ens.Util.XML.Validator).ValidateStream(tStream,tResolver,"Schema")
 		if $$$ISERR(tSC) quit
}

Storage Default
{
<Data name="SubProductionState">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Enabled</Value>
</Value>
</Data>
<State>SubProductionState</State>
<StreamLocation>^Ens.Config.SubProductionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
