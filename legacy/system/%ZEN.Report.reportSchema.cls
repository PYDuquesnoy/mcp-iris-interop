/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Utilities for ZEN Report schema.
Class %ZEN.Report.reportSchema [ Abstract, Deprecated, System = 4 ]
{

/// Generate a schema for a report and write it to a file
ClassMethod %DrawToXSD(pClassName As %String(MAXLEN=""), outputfile As %String(MAXLEN="")) As %Status
{
	set tXSD = ##class(%Stream.GlobalCharacter).%New()
	set tSC = ..GenerateSchema(pClassName,tXSD)
	if $$$ISOK(tSC) {
		do tXSD.Rewind()
		Open outputfile:("NW")
		s t=$io u outputfile
		set tSC = tXSD.OutputToDevice()
		u t
		Close outputfile
	}
	quit tSC
}

/// generate XSD from a compiled Zen report definition
ClassMethod GenerateSchema(pClassName As %String(MAXLEN=""), pXSD As %Stream.Object) As %Status
{
	#dim tCompiledClass as %Dictionary.CompiledClass
	set tCompiledClass = ##class(%Dictionary.CompiledClass).IDKEYOpen(pClassName,,.tSC)
	if $isobject(tCompiledClass) {
		if (tCompiledClass.Abstract) {
			Quit $$$OK
		}
 
			#; find XDATA block named ReportDefinition
		; set tIndex = tCompiledClass.XDatas.FindObjectId(%class.Name_"||ReportDefinition")
		if ##class(%Dictionary.CompiledXData).IDKEYExists(tCompiledClass.Name,"ReportDefinition",.tReportDefId) {
			#; get XDATA as stream
			Set tXData = ##class(%Dictionary.CompiledXData).%OpenId(tReportDefId,,.tSC)
				#; ignore tSC for now, if the open failed it is because the compiled class is corrupt
			Do tXData.Data.Rewind()
	
			If (tXData.Data.Size > 0) {
	
				#; render the stream into report object (with children)
				Set tReader = ##class(%XML.Reader).%New()
				Set tSC = tReader.OpenStream(tXData.Data) If $$$ISERR(tSC) Quit tSC
				Do tReader.Correlate("report","%ZEN.Report.report")
	
				#; there should only be one report defined
				Do tReader.Next(.tReport,.tSC)
				If $$$ISERR(tSC) Quit tSC
				If '$IsObject(tReport) Quit $$$ERROR($$$GeneralError,"No <report> element defined in ReportDefinition block.")
	
				set tSC = ..writeSchema(tCompiledClass,tReport,pXSD)
			}
		}
		Else {
			#; if XData did not create a report, return an error.
			set tSC = $$$ERROR($$$GeneralError,"No ReportDefinition block defined in "_pClassName_".")
		}
	}
	quit tSC
}

ClassMethod writeSchema(pCompiledClass As %Dictionary.CompiledClass, pReport As %ZEN.Report.report, pXSD As %Stream.Object) As %Status
{
	do pXSD.Write("<s:schema id="""_pReport.name_""" ")
	if ##class(%Dictionary.CompiledParameter).IDKEYExists(pCompiledClass.Name,"REPORTXMLNAMESPACE",.tParameter) {
		set tReportNamespace = ##class(%Dictionary.CompiledParameter).%OpenId(tParameter).Default
	}
	else { set tReportNamespace = "" }
	If tReportNamespace'="" {
		do pXSD.Write("targetNamespace="""_tReportNamespace_""" xmlns="""_tReportNamespace_""" ")
	} Else {
		do pXSD.Write("xmlns="""" ")
	}
	
	do pXSD.Write("attributeFormDefault=""qualified"" elementFormDefault=""qualified"" ")
	do pXSD.WriteLine("xmlns:s=""http://www.w3.org/2001/XMLSchema"">")
	do pXSD.WriteLine("  <s:element name="""_pReport.name_""">")
	do pXSD.WriteLine("    <s:complexType>")
	do pXSD.WriteLine("      <s:sequence>")
 
	set tCount = pReport.children.Count()
	for tPtr = 1:1:tCount {
		set tNode = pReport.children.GetAt(tPtr)
		if (tNode.%IsA("%ZEN.Report.element")) {
				#; May seem foolish to do this inside the loop but eventually we will use metadata to retrieve the node type. Default to %String for now.
			set type=..TypeToXSD("%Library.String",.hasXSDToLogical,.hasLogicalToXSD)
			do pXSD.WriteLine("        <s:element name="""_$tr(tNode.name,"%.","__")_""" type=""s:"_type_""" minOccurs=""0"" />")
		} elseif (tNode.%IsA("%ZEN.Report.attribute")) {
		}
		else {
			if tNode.%IsA("%ZEN.Report.group") {
				set tGroup($increment(tGroup)) = tNode
				do pXSD.WriteLine("        <s:element name="""_$tr(tNode.name,"%.","__")_""" type="""_tNode.name_""" minOccurs=""0"" maxOccurs=""unbounded""/>")
			}
		}
	}
 	#; aggregates must come after elements since they follow them in XML
	for tPtr = 1:1:tCount {
		set tNode = pReport.children.GetAt(tPtr)
		if (tNode.%IsA("%ZEN.Report.aggregate")) {
				#; May seem foolish to do this inside the loop but eventually we will use metadata to retrieve the node type. Default to %String for now.
			set type=..TypeToXSD("%Library.String",.hasXSDToLogical,.hasLogicalToXSD)
			do pXSD.WriteLine("        <s:element name="""_$tr(tNode.name,"%.","__")_""" type=""s:"_type_""" minOccurs=""0"" />")
		}
	}

	do pXSD.WriteLine("       </s:sequence>")
	for tPtr = 1:1:tCount {
		set tNode = pReport.children.GetAt(tPtr)
		if (tNode.%IsA("%ZEN.Report.attribute")) {
			set type=..TypeToXSD("%Library.String",.hasXSDToLogical,.hasLogicalToXSD)
			do pXSD.WriteLine("        <s:attribute name="""_$tr(tNode.name,"%.","__")_""" type=""s:"_type_"""  />")
		}
	}

	do pXSD.WriteLine("    </s:complexType>")
	
	/* This is all possible if we adopt the runtime model for schema generation or if we implement a %GetMetadata classmethod that returns an rsmd object
	Set id=$listget(..IdInfo,1)
	if id>0 {
		Set unique=1
		Set class=$listget(..GetColumnExtInfo(1),1) 
		For i=2:1:$listlength(..ColInfo) { 
			If class'=$listget(..GetColumnExtInfo(i),1) Set unique=0 Quit
		}
		If class="" Set unique=0
		If unique {
			do pXSD.WriteLine("    <s:unique name=""Constraint1"" msdata:PrimaryKey=""true"">")
			do pXSD.WriteLine("      <s:selector xpath="".//"_$select(..Namespace'="":"mstns:",1:"")_..QueryName_""" />")
			do pXSD.WriteLine("      <s:field xpath="""_$select(..Namespace'="":"mstns:",1:"")_$tr($list($list(..ColInfo,id),1),"%.","__")_""" />")
			do pXSD.WriteLine("    </s:unique>")
		}
	}
	*/	
	do pXSD.WriteLine("  </s:element>")
		
	for tPtr=1:1:$g(tGroup) {
		Do ..writeGroupType(tGroup(tPtr),pXSD)
	}
	do pXSD.WriteLine("</s:schema>")
	Quit $$$OK
}

ClassMethod writeGroupType(pGroup As %ZEN.Report.group, pXSD As %Stream.Object)
{
	do pXSD.WriteLine("  <s:complexType name="""_pGroup.name_""">")
	do pXSD.WriteLine("    <s:sequence>")

	set tCount = pGroup.children.Count()
	Set tPtr=0
	set tGroup=0
	for tPtr = 1:1:tCount {
		set tNode = pGroup.children.GetAt(tPtr)
		if (tNode.%IsA("%ZEN.Report.element")) {
				#; May seem foolish to do this inside the loop but eventually we will use metadata to retrieve the node type. Default to %String for now.
			set type=..TypeToXSD("%Library.String",.hasXSDToLogical,.hasLogicalToXSD)
			do pXSD.WriteLine("        <s:element name="""_$tr(tNode.name,"%.","__")_""" type=""s:"_type_""" minOccurs=""0"" />")
		} elseif (tNode.%IsA("%ZEN.Report.attribute")) {
		}
		else {
			if tNode.%IsA("%ZEN.Report.group") {
				set tGroup($increment(tGroup)) = tNode
				do pXSD.WriteLine("        <s:element name="""_$tr(tNode.name,"%.","__")_""" type="""_tNode.name_""" minOccurs=""0"" maxOccurs=""unbounded""/>")
			}
		}
	}
	#; aggregates must come after elements since they follow them in XML
	for tPtr = 1:1:tCount {
		set tNode = pGroup.children.GetAt(tPtr)
		if (tNode.%IsA("%ZEN.Report.aggregate")) {
				#; May seem foolish to do this inside the loop but eventually we will use metadata to retrieve the node type. Default to %String for now.
			set type=..TypeToXSD("%Library.String",.hasXSDToLogical,.hasLogicalToXSD)
			do pXSD.WriteLine("        <s:element name="""_$tr(tNode.name,"%.","__")_""" type=""s:"_type_""" minOccurs=""0"" />")
		}
	}
	
 	do pXSD.WriteLine("     </s:sequence>")
	for tPtr = 1:1:tCount {
		set tNode = pGroup.children.GetAt(tPtr)
		if (tNode.%IsA("%ZEN.Report.attribute")) {
			set type=..TypeToXSD("%Library.String",.hasXSDToLogical,.hasLogicalToXSD)
			do pXSD.WriteLine("        <s:attribute name="""_$tr(tNode.name,"%.","__")_""" type=""s:"_type_"""  />")
		}
	}

	do pXSD.WriteLine("  </s:complexType>")
	for tPtr=1:1:tGroup {
		Do ..writeGroupType(tGroup(tPtr), pXSD)
	}
}

/// Converts a ClientType enum to its equivalent SOAP xsd type<br>
/// 1       BINARY           %Binary<br>
/// 2       DATE             %Date<br>
/// 3       DOUBLE           %Double<br>
/// 4       HANDLE           %ObjectHandle<br>
/// 5       INTEGER          %Integer<br>
/// 6       LIST             %List<br>
/// 7       LONGVARCHAR      VarChar, %Stream<br>
/// 8       TIME             %Time<br>
/// 9       TIMESTAMP        %Timestamp<br>
/// 10      VARCHAR          %String<br>
/// 11      STATUS           %Status<br>
/// 12      BINARYSTREAM     BINARYSTREAM<br>
/// 13      CHARACTERSTREAM  CHARACTERSTREAM<br>
/// 14      NUMERIC          %Numeric<br>
/// 15      CURRENCY         %Currency<br>
/// 16      BOOLEAN          %Boolean<br>
/// 17      OID              OID<br>
/// 18      BIGINT           %BigInt<br>
/// 19      FDATE            %FilemanTimeStamp<br>
/// 20      FTIMESTAMP       %FilemanDate<br>
/// 21      DECIMAL          %Float<br>
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<br><br>
ClassMethod TypeToXSD(Type As %Integer, ByRef hasXSDToLogical As %Boolean, ByRef hasLogicalToXSD As %Boolean) As %String [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	#define GENERATE(%line)    Set %code($increment(%code))=%line
	$$$GENERATE(" ;")
	For typeindex=1:1:21 {
		If typeindex=1 { Set xsd="base64Binary" }
		ElseIf typeindex=2 { Set xsd="date" }
		ElseIf typeindex=3 { Set xsd="double" }
		ElseIf typeindex=4 { Set xsd="string" }
		ElseIf typeindex=5 { Set xsd="long" }
		ElseIf typeindex=6 { Set xsd="string" }
		ElseIf typeindex=7 { Set xsd="string" }
		ElseIf typeindex=8 { Set xsd="time" }
		ElseIf typeindex=9 { Set xsd="dateTime" }
		ElseIf typeindex=10 { Set xsd="string" }
		ElseIf typeindex=11 { Set xsd="base64Binary" }
		ElseIf typeindex=12 { Set xsd="base64Binary" }
		ElseIf typeindex=13 { Set xsd="string" }
		ElseIf typeindex=14 { Set xsd="decimal" }
		ElseIf typeindex=15 { Set xsd="decimal" }
		ElseIf typeindex=16 { Set xsd="boolean" }
		ElseIf typeindex=17 { Set xsd="base64Binary" }
		ElseIf typeindex=18 { Set xsd="long" }
		ElseIf typeindex=19 { Set xsd="dateTime" }
		ElseIf typeindex=20 { Set xsd="date" }
		ElseIf typeindex=21 { Set xsd="double" }

		Set class="%xsd."_xsd
	    Set hasLogicalToXSD=$$$comMemberKeyGet(class,$$$cCLASSmethod,"LogicalToXSD",$$$cMETHrunnable)
	    Set hasXSDToLogical=$$$comMemberKeyGet(class,$$$cCLASSmethod,"XSDToLogical",$$$cMETHrunnable)
		$$$GENERATE("	If Type="_typeindex_" {")
		$$$GENERATE("		Set hasXSDToLogical="_hasXSDToLogical_",hasLogicalToXSD="_hasLogicalToXSD)
		$$$GENERATE("		Quit """_xsd_"""")
		$$$GENERATE("	}")
	}
	
	Set class="%xsd.string"
    Set hasLogicalToXSD=$$$comMemberKeyGet(class,$$$cCLASSmethod,"LogicalToXSD",$$$cMETHrunnable)
    Set hasXSDToLogical=$$$comMemberKeyGet(class,$$$cCLASSmethod,"XSDToLogical",$$$cMETHrunnable)
	$$$GENERATE("	Set hasXSDToLogical="_hasXSDToLogical_",hasLogicalToXSD="_hasLogicalToXSD)
	$$$GENERATE("	Quit ""string""")

	Quit $$$OK
}

}
