/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.XML.Object.Service.Standard is the base service class for services which read an XML document and
/// then use %XML.Reader to convert the document to a set of persistent classes.
Class EnsLib.XML.Object.Service.Standard Extends Ens.BusinessService [ Abstract, ProcedureBlock, System = 4 ]
{

/// Configuration items to which to send Documents
Property TargetConfigNames As %String(MAXLEN = 1000);

/// The name of the class to correlate to the entire XML document or element in the XML  document.
Property ClassName As %String;

/// The name of the element to correlate in the XML document.
/// The element must correspond to the specified ClassName.
/// If there are multiple occurences of this element, then a separate message will be sent to the target for each matching element.
/// If no element name is specified, then the root element will be correlated to the class.
Property ElementName As %String;

/// The format of the XML document: "literal", "encoded" or "encoded12".
/// This parameter may be overriden by the Open... format parameter.
Property Format As %String(VALUELIST = ",literal,encoded,encoded12") [ InitialExpression = "literal" ];

/// The runtime specification of the XMLIGNORENULL parameter to %XML.Adaptor.
/// <property>IgnoreNull</property> specifies the value of 
/// XMLIGNORENULL at runtime as either 0 or 1.  
Property IgnoreNull As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},ClassName:Basic:selector?context={%ZEN.Portal.ContextSearch/Classes?super=%XML.Adaptor&classtype=persistent&system=0&internal=0},ElementName:Basic,Format:Basic,IgnoreNull:Basic";

/// Set the needed %XML.Reader properties.
/// This method may be overridden to add or change which proeprties are to be set.
Method SetProperties(pReader As %XML.Reader)
{
	Set pReader.Format=..Format
	Set pReader.IgnoreNull=..IgnoreNull
}

Method standardOnProcessInput(pInput As %Stream.Object, pOutput As %RegisteredObject) As %Status [ Internal ]
{
	// Log source
	If pInput.%Extends("%IO.I.Stream") {
		Set tSource=pInput.Name
	} Else {
		Try {
			Set tSource=pInput.Filename
		} Catch {
			Set tSource=""
		}
	}
	If tSource="",pInput.%Extends("%Library.AbstractStream") {
		Set tSource=$get(pInput.Attributes("Source"),$get(pInput.Attributes("Name"),$get(pInput.Attributes("Filename"))))
	}
	$$$sysTRACE("Reading XML document stream "_pInput_"("_pInput.Size_") from '"_tSource_"'")

	// Get a reader and set its properties
	Set tReader=##class(%XML.Reader).%New()
	Do ..SetProperties(tReader)
	
	/// Open the stream in %XML.Reader
	Set tSC=tReader.OpenStream(pInput)
	If $$$ISERR(tSC) Quit tSC
	
	/// Correlate and create classes.
	/// If no ElementName then correlate to document root element.
	Set tCount=0
	If ..ElementName="" {
		// Correlate entire document since no element name specified
		Do tReader.CorrelateRoot(..ClassName)
	} Else {
		Do tReader.Correlate(..ElementName,..ClassName)
	}
	
	// Send correlated objects to the targets
	While tReader.Next(.tRequest,.tSC) {
		Set tCount=tCount+1
		Set tSC=..sendRequest(tRequest)
		If $$$ISERR(tSC) Quit
	}
	If $$$ISERR(tSC) Quit tSC

	If tCount=0 {
		$$$LOGWARNING("No objects created for XML document.")
	}
	Quit $$$OK
}

/// Send the correlated object to the requested targets.
Method sendRequest(pRequest As %Persistent) As %Status [ Internal ]
{
	Set tSC=$$$OK
	For i=1:1:$length(..TargetConfigNames,",") {
		Set tOneTarget=$zstrip($piece(..TargetConfigNames,",",i),"<>W")
		If tOneTarget="" Continue
		Set tSC1=..SendRequestAsync(tOneTarget,pRequest)
		If $$$ISERR(tSC1) Set tSC=$$$ADDSC(tSC,tSC1)
	}
	Quit tSC
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

Method OnInit() As %Status
{
	Set tSC=##super()
	If $$$ISERR(tSC) Quit tSC
	
	// Target must be configured
	If ..TargetConfigNames="" {
		Quit $$$ERROR($$$EnsErrGeneral,"No Target Config Name configured")
	}
	
	/// A class name must be specified.	
	If ..ClassName="" {
		Quit $$$ERROR($$$EnsErrGeneral,"Unable to process XML documents.  ClassName property is not specified.")
	}
	
	Quit $$$OK
}

}
