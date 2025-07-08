/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XMLA.Server
Class %DeepSee.XMLA.Server Extends %SOAP.WebService [ ProcedureBlock, System = 4 ]
{

/// Name of the WebService.
Parameter SERVICENAME = "XMLA";

/// SOAP Namespace for the WebService
Parameter NAMESPACE = "urn:schemas-microsoft-com:xml-analysis";

/// Namespaces of referenced classes will be used in the WSDL.
Parameter USECLASSNAMESPACES = 1;

Parameter CONTENTTYPE = "text/xml";

Parameter CHARSET;

Parameter NOCHARSETCONVERT = 1;

Parameter XMLIGNORENULL = 1;

Parameter SOAPHEADERS = "BeginSession:%DeepSee.XMLA.BeginSessionHeader,EndSession:%DeepSee.XMLA.EndSessionHeader";

ClassMethod ParseRestrictions(property As %String, valueStr As %String, coln As %Collection.ListOfDT) As %Status
{
	if (valueStr = "") { quit $$$OK }
	
	set restrictions = "<"_property_">"_valueStr_"</"_property_">"
	set error = "Error while parsing the restrictions argument."
	set status = ##class(%XML.TextReader).ParseString(restrictions, .reader)
	if ($$$ISERR(status)) { quit status }
	
	if ('reader.Read()) { quit $$$ERROR($$$GeneralError, error_" Expected <"_property_">.") } // property
	
	if ('reader.Read()) { quit $$$ERROR($$$GeneralError, error_" Expected the value for the <"_property_"> element.") }
	if (reader.NodeType = "chars") { // single value
		do coln.Insert($zcvt(reader.Value, "U"))
		if ('reader.Read() || (reader.NodeType '= "endelement") || (reader.Name '= property)) {
			quit $$$ERROR($$$GeneralError, error_" Expected </"_property_">.")
		}
		quit status
	}
	
	set done = 0
	while ('done) {
		if ((reader.NodeType '= "element") || (reader.Name '= "Value")) { // <Value> element
			set status = $$$ERROR($$$GeneralError, error_" Expected <Value>.")
			quit 
		}
		
		if ('reader.Read() || (reader.NodeType '= "chars")) {  // element value
			set status =  $$$ERROR($$$GeneralError, error_" Expected the value for the <Value> element.")
			quit
		}

		do coln.Insert($zcvt(reader.Value, "U"))

		if ('reader.Read() || (reader.NodeType '= "endelement") || (reader.Name '= "Value")) { // </Value> element
			set status =  $$$ERROR($$$GeneralError, error_" Expected </Value>.")
			quit
		}
		
		if ('reader.Read()) {
			set status = $$$ERROR($$$GeneralError, error_" Expected <Value> or </"_property_">.")
		}
		
		if ((reader.NodeType = "endelement") && (reader.Name = property)) { set done = 1 }
	}
	
	quit status
}

Method ImportRestrictions(arg As %String, className As %String, ByRef status As %Status = {$$$OK}) As DataSourcesRestrictions
{
	set reader = ##class(%XML.Reader).%New()
	set status = reader.OpenString(arg)
	if ($$$ISERR(status)) { quit "" }
	
	do reader.Correlate("RestrictionList", className)
	do reader.Next(.res,.status)
	if ($$$ISERR(status)) { quit "" }
	
	set status = res.Normalize()
	if ($$$ISERR(status)) { quit "" }
			
	quit res
}

Method Discover(RequestType As %XML.String, Restrictions As %XML.String, Properties As Properties) As %XML.GlobalCharacterStream(XMLNAME="return") [ SoapAction = "urn:schemas-microsoft-com:xml-analysis:Discover", WebMethod ]
{
	zn Properties.PropertyList.Catalog
	
	set restrictions = ""
		
	if (RequestType = "DISCOVER_DATASOURCES") {
		if (Restrictions '= "") {
			set restrictions = ..ImportRestrictions(Restrictions, "%DeepSee.XMLA.DataSourcesRestrictions", .status)
			if ($$$ISERR(status)) {	goto restrictionsParsingError }
		}
		quit ..DiscoverDataSources(restrictions)
	}
	elseif (RequestType = "DISCOVER_ENUMERATORS") {
		if (Restrictions '= "") {
			set restrictions = ..ImportRestrictions(Restrictions, "%DeepSee.XMLA.EnumerationsRestrictions", .status)
			if ($$$ISERR(status)) { goto restrictionsParsingError }			
		}
		quit ..DiscoverEnumerations(restrictions)		
	}
	elseif (RequestType = "DISCOVER_KEYWORDS") {
		if (Restrictions '= "") {
			set restrictions = ..ImportRestrictions(Restrictions, "%DeepSee.XMLA.KeywordsRestrictions", .status)
			if ($$$ISERR(status)) { goto restrictionsParsingError }
		}
		quit ..DiscoverKeywords(restrictions)
	}
	elseif (RequestType = "DISCOVER_LITERALS") {
		if (Restrictions '= "") {
			set restrictions = ..ImportRestrictions(Restrictions, "%DeepSee.XMLA.LiteralsRestrictions", .status)
			if ($$$ISERR(status)) { goto restrictionsParsingError }
		}
		quit ..DiscoverLiterals(restrictions)
	}
	elseif (RequestType = "DISCOVER_PROPERTIES") {
		if (Restrictions '= "") {
			set restrictions = ..ImportRestrictions(Restrictions, "%DeepSee.XMLA.PropertiesRestrictions", .status)
			if ($$$ISERR(status)) { goto restrictionsParsingError }			
		}
		quit ..DiscoverProperties(restrictions)
	}
	elseif (RequestType = "DISCOVER_SCHEMA_ROWSETS") {
		if (Restrictions '= "") {
			set restrictions = ..ImportRestrictions(Restrictions, "%DeepSee.XMLA.SchemasRestrictions", .status)
			if ($$$ISERR(status)) { goto restrictionsParsingError }			
		}
		quit ..DiscoverSchemas(restrictions)
	}
	
	quit ""	
	
restrictionsParsingError
	set fault = ..MakeStatusFault(, "Error while parsing the restrictions argument", status)
	do ..ReturnFault(fault)
}

Method DiscoverDataSources(restrictions As DataSourcesRestrictions) As %XML.GlobalCharacterStream
{
	s out = ##class(%XML.GlobalCharacterStream).%New()

	// do out.WriteLine("<return xmlns=""urn:schemas-microsoft-com:xml-analysis"">")
	do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">")

	// write the output schema

	do out.WriteLine("<xsd:schema targetNamespace=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:sql=""urn:schemas-microsoft-com:xml-sql"" elementFormDefault=""qualified"">")
	do out.WriteLine("  <xsd:element name=""root"">")
	do out.WriteLine("    <xsd:complexType>")
	do out.WriteLine("      <xsd:sequence minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xsd:element name=""row"" type=""row"" />")
	do out.WriteLine("      </xsd:sequence>")
	do out.WriteLine("    </xsd:complexType>")
	do out.WriteLine("  </xsd:element>")
	do out.WriteLine("  <xsd:simpleType name=""uuid"">")
	do out.WriteLine("    <xsd:restriction base=""xsd:string"">")
	do out.WriteLine("      <xsd:pattern value=""[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"" />")
	do out.WriteLine("    </xsd:restriction>")
	do out.WriteLine("  </xsd:simpleType>")
	do out.WriteLine("  <xsd:complexType name=""xmlDocument"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:any />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("  <xsd:complexType name=""row"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:element sql:field=""DataSourceName"" name=""DataSourceName"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""DataSourceDescription"" name=""DataSourceDescription"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""URL"" name=""URL"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""DataSourceInfo"" name=""DataSourceInfo"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""ProviderName"" name=""ProviderName"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""ProviderType"" name=""ProviderType"" type=""xsd:string"" minOccurs=""0"" maxOccurs=""unbounded"" />")
	do out.WriteLine("      <xsd:element sql:field=""AuthenticationMode"" name=""AuthenticationMode"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("</xsd:schema>")

	// write the data

	set instance = "Cache91U"  // TBD need the real data
	set providerName = "InterSystems Analytics" // TBD ok name?
	
	set namespaces("SAMPLES") = "" // TBD need the real data
	set namespaces("USER") = ""
	
	set nsp = ""
	do {
		set nsp = $order(namespaces(nsp))
		if (nsp = "") continue	
		
		set datasource = instance_" "_nsp
		if (restrictions '= "") {
			if ((restrictions.AuthenticationMode '= "") && (restrictions.AuthenticationMode '= "AUTHENTICATED")) continue
			if ((restrictions.DataSourceName '= "") && (restrictions.DataSourceName '= $zcvt(datasource, "U"))) continue
			if ((restrictions.ProviderName '= "") && (restrictions.ProviderName '= $zcvt(providerName, "U"))) continue
			if ((restrictions.ProviderTypeList.Count() > 0) && (restrictions.ProviderTypeList.Find("MDP") = "")) continue
			// TBD skipped the URL
		}
		
		do out.Write("<row>")
		do out.Write("<DataSourceName>"_datasource_"</DataSourceName>")
		do out.Write("<DataSourceDescription />")
		do out.Write("<URL />") // TBD should every data source have a different URL?
		do out.Write("<DataSourceInfo />") // TBD should the namespace go here?
		do out.Write("<ProviderName>"_providerName_"</ProviderName>")
		do out.Write("<ProviderType>MDP</ProviderType>") // TBD support for the tabular format?
		do out.Write("<AuthenticationMode>Authenticated</AuthenticationMode>") // TBD how do we do authentication for XMLA?
		do out.Write("</row>")
	} 
	while (nsp '= "")
	
	// done
	
	do out.Write("</root>")
	quit out
}

Method DiscoverEnumerations(restrictions As EnumerationsRestrictions) As %XML.GlobalCharacterStream [ PublicList = SQLCODE ]
{
	s out = ##class(%XML.GlobalCharacterStream).%New()
		
	if (restrictions '= "") { set restrictionsEnumName = restrictions.EnumNameList.Serialize() }
	else { set restrictionsEnumName = "" }
	
	new SQLCODE,%ROWCOUNT,%ROWID
	
	&sql(declare cEnumerationsRowset cursor for 
         select EnumName, EnumDescription, EnumType, ElementName, ElementDescription, ElementValue
         into %EnumName, %EnumDescription, %EnumType, %ElementName, %ElementDescription, %ElementValue
         from %DeepSee_XMLA.EnumerationsRowset
         where (:restrictionsEnumName is NULL) or (EnumName %inlist :restrictionsEnumName))
	
 	&sql(open cEnumerationsRowset)
 	&sql(fetch cEnumerationsRowset)
 	
	do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">")

	// write the output schema

	do out.WriteLine("<xsd:schema targetNamespace=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:sql=""urn:schemas-microsoft-com:xml-sql"" elementFormDefault=""qualified"">")
	do out.WriteLine("  <xsd:element name=""root"">")
	do out.WriteLine("    <xsd:complexType>")
	do out.WriteLine("      <xsd:sequence minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xsd:element name=""row"" type=""row"" />")
	do out.WriteLine("      </xsd:sequence>")
	do out.WriteLine("    </xsd:complexType>")
	do out.WriteLine("  </xsd:element>")
	do out.WriteLine("  <xsd:simpleType name=""uuid"">")
	do out.WriteLine("    <xsd:restriction base=""xsd:string"">")
	do out.WriteLine("      <xsd:pattern value=""[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"" />")
	do out.WriteLine("    </xsd:restriction>")
	do out.WriteLine("  </xsd:simpleType>")
	do out.WriteLine("  <xsd:complexType name=""xmlDocument"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:any />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("  <xsd:complexType name=""row"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:element sql:field=""EnumName"" name=""EnumName"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""EnumDescription"" name=""EnumDescription"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""EnumType"" name=""EnumType"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""ElementName"" name=""ElementName"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""ElementDescription"" name=""ElementDescription"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""ElementValue"" name=""ElementValue"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("</xsd:schema>")	 	

	// write the data
	
 	while (SQLCODE = 0) {
		do out.Write("<row>")
		do out.Write("<EnumName>"_%EnumName_"</EnumName>")
		do out.Write("<EnumDescription>"_%EnumDescription_"</EnumDescription>")
		do out.Write("<EnumType>"_%EnumType_"</EnumType>")
		do out.Write("<ElementName>"_%ElementName_"</ElementName>")
		do out.Write("<ElementDescription>"_%ElementDescription_"</ElementDescription>")
		do out.Write("<ElementValue>"_%ElementValue_"</ElementValue>")
		do out.Write("</row>")	 		 
	 	
		&sql(fetch cEnumerationsRowset)
 	}
 	
 	&sql(close cEnumerationsRowset)	
	
	// done
	
	do out.Write("</root>")
	
	quit out
}

Method DiscoverKeywords(restrictions As KeywordsRestrictions) As %XML.GlobalCharacterStream [ PublicList = SQLCODE ]
{
	s out = ##class(%XML.GlobalCharacterStream).%New()
	
	if (restrictions '= "") { set restrictionsKeyword = restrictions.KeywordList.Serialize() }
	else { set restrictionsKeyword = "" }	

	do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">")

	// write the output schema

	do out.WriteLine("<xsd:schema targetNamespace=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:sql=""urn:schemas-microsoft-com:xml-sql"" elementFormDefault=""qualified"">")
	do out.WriteLine("  <xsd:element name=""root"">")
	do out.WriteLine("    <xsd:complexType>")
	do out.WriteLine("      <xsd:sequence minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xsd:element name=""row"" type=""row"" />")
	do out.WriteLine("      </xsd:sequence>")
	do out.WriteLine("    </xsd:complexType>")
	do out.WriteLine("  </xsd:element>")
	do out.WriteLine("  <xsd:simpleType name=""uuid"">")
	do out.WriteLine("    <xsd:restriction base=""xsd:string"">")
	do out.WriteLine("      <xsd:pattern value=""[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"" />")
	do out.WriteLine("    </xsd:restriction>")
	do out.WriteLine("  </xsd:simpleType>")
	do out.WriteLine("  <xsd:complexType name=""xmlDocument"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:any />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("  <xsd:complexType name=""row"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:element sql:field=""Keyword"" name=""Keyword"" type=""xsd:string"" />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("</xsd:schema>")
	
	// write the data
	
	new SQLCODE,%ROWCOUNT,%ROWID
	
	&sql(declare cKeywordsRowset cursor for 
         select Keyword
         into %Keyword
         from %DeepSee_XMLA.KeywordsRowset
         where (:restrictionsKeyword is NULL) or (Keyword %inlist :restrictionsKeyword))
	
 	&sql(open cKeywordsRowset)
 	&sql(fetch cKeywordsRowset)
 	
 	while (SQLCODE = 0) {
		do out.Write("<row>")
		do out.Write("<Keyword>"_%Keyword_"</Keyword>")
		do out.Write("</row>")	 		 
	 	
		&sql(fetch cKeywordsRowset)
 	}
 	
 	&sql(close cKeywordsRowset)	
	
	// done
	
	do out.Write("</root>")
	
	quit out
}

Method DiscoverLiterals(restrictions As LiteralsRestrictions) As %XML.GlobalCharacterStream [ PublicList = SQLCODE ]
{
	s out = ##class(%XML.GlobalCharacterStream).%New()

	do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">")

	// write the output schema

	do out.WriteLine("<xsd:schema targetNamespace=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:sql=""urn:schemas-microsoft-com:xml-sql"" elementFormDefault=""qualified"">")
	do out.WriteLine("  <xsd:element name=""root"">")
	do out.WriteLine("    <xsd:complexType>")
	do out.WriteLine("      <xsd:sequence minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xsd:element name=""row"" type=""row"" />")
	do out.WriteLine("      </xsd:sequence>")
	do out.WriteLine("    </xsd:complexType>")
	do out.WriteLine("  </xsd:element>")
	do out.WriteLine("  <xsd:simpleType name=""uuid"">")
	do out.WriteLine("    <xsd:restriction base=""xsd:string"">")
	do out.WriteLine("      <xsd:pattern value=""[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"" />")
	do out.WriteLine("    </xsd:restriction>")
	do out.WriteLine("  </xsd:simpleType>")
	do out.WriteLine("  <xsd:complexType name=""xmlDocument"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:any />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("  <xsd:complexType name=""row"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:element sql:field=""LiteralName"" name=""LiteralName"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""LiteralValue"" name=""LiteralValue"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""LiteralInvalidChars"" name=""LiteralInvalidChars"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""LiteralInvalidStartingChars"" name=""LiteralInvalidStartingChars"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""LiteralMaxLength"" name=""LiteralMaxLength"" type=""xsd:int"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""LiteralNameEnumValue"" name=""LiteralNameEnumValue"" type=""xsd:int"" minOccurs=""0"" />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("</xsd:schema>")
	
	// write the data
	
	if (restrictions '= "") { set restrictionsLiteralName = restrictions.LiteralNameList.Serialize() }
	else { set restrictionsLiteralName = "" }
	
	new SQLCODE,%ROWCOUNT,%ROWID
	
	&sql(declare cLiteralsRowset cursor for 
         select LiteralName, LiteralValue, LiteralInvalidChars, LiteralInvalidStartingChars, LiteralMaxLength, LiteralNameEnumValue
         into %LiteralName, %LiteralValue, %LiteralInvalidChars, %LiteralInvalidStartingChars, %LiteralMaxLength, %LiteralNameEnumValue
         from %DeepSee_XMLA.LiteralsRowset
         where (:restrictionsLiteralName is NULL) or (LiteralName %inlist :restrictionsLiteralName))
	
 	&sql(open cLiteralsRowset)
 	&sql(fetch cLiteralsRowset)

 	while (SQLCODE = 0) {
		do out.Write("<row>")
		do out.Write("<LiteralName>"_%LiteralName_"</LiteralName>")
		do out.Write("<LiteralValue>"_%LiteralValue_"</LiteralValue>")
		do out.Write("<LiteralInvalidChars>"_%LiteralInvalidChars_"</LiteralInvalidChars>")
		do out.Write("<LiteralInvalidStartingChars>"_%LiteralInvalidStartingChars_"</LiteralInvalidStartingChars>")
		do out.Write("<LiteralMaxLength>"_%LiteralMaxLength_"</LiteralMaxLength>")
		do out.Write("<LiteralNameEnumValue>"_%LiteralNameEnumValue_"</LiteralNameEnumValue>")
		do out.Write("</row>")
	 	
		&sql(fetch cLiteralsRowset)
 	}
 	
 	&sql(close cLiteralsRowset)	
	
	// done
	
	do out.Write("</root>")
	
	quit out
}

Method DiscoverProperties(restrictions As PropertiesRestrictions) As %XML.GlobalCharacterStream [ PublicList = SQLCODE ]
{
	s out = ##class(%XML.GlobalCharacterStream).%New()

	do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">")

	// write the output schema

	do out.WriteLine("<xsd:schema targetNamespace=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:sql=""urn:schemas-microsoft-com:xml-sql"" elementFormDefault=""qualified"">")
	do out.WriteLine("  <xsd:element name=""root"">")
	do out.WriteLine("    <xsd:complexType>")
	do out.WriteLine("      <xsd:sequence minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xsd:element name=""row"" type=""row"" />")
	do out.WriteLine("      </xsd:sequence>")
	do out.WriteLine("    </xsd:complexType>")
	do out.WriteLine("  </xsd:element>")
	do out.WriteLine("  <xsd:simpleType name=""uuid"">")
	do out.WriteLine("    <xsd:restriction base=""xsd:string"">")
	do out.WriteLine("      <xsd:pattern value=""[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"" />")
	do out.WriteLine("    </xsd:restriction>")
	do out.WriteLine("  </xsd:simpleType>")
	do out.WriteLine("  <xsd:complexType name=""xmlDocument"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:any />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("  <xsd:complexType name=""row"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:element sql:field=""PropertyName"" name=""PropertyName"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""PropertyDescription"" name=""PropertyDescription"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""PropertyType"" name=""PropertyType"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""PropertyAccessType"" name=""PropertyAccessType"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""IsRequired"" name=""IsRequired"" type=""xsd:boolean"" minOccurs=""0"" />")
	do out.WriteLine("      <xsd:element sql:field=""Value"" name=""Value"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("</xsd:schema>")
	
	// write the data
	
	if (restrictions '= "") { set restrictionsPropertyName = restrictions.PropertyNameList.Serialize() }
	else { set restrictionsPropertyName = "" }
	
	new SQLCODE,%ROWCOUNT,%ROWID
	
	&sql(declare cPropertiesRowset cursor for 
         select PropertyName, PropertyDescription, PropertyType, PropertyAccessType, IsRequired, Value
         into %PropertyName, %PropertyDescription, %PropertyType, %PropertyAccessType, %IsRequired, :%Value
         from %DeepSee_XMLA.PropertiesRowset
         where (:restrictionsPropertyName is NULL) or (PropertyName %inlist :restrictionsPropertyName))
	
 	&sql(open cPropertiesRowset)
 	&sql(fetch cPropertiesRowset)

 	while (SQLCODE = 0) {
		do out.Write("<row>")
		do out.Write("<PropertyName>"_%PropertyName_"</PropertyName>")
		do out.Write("<PropertyDescription>"_%PropertyDescription_"</PropertyDescription>")
		do out.Write("<PropertyType>"_%PropertyType_"</PropertyType>")
		do out.Write("<PropertyAccessType>"_%PropertyAccessType_"</PropertyAccessType>")
		do out.Write("<IsRequired>"_%IsRequired_"</IsRequired>")
		do out.Write("<Value>"_%Value_"</Value>")
		do out.Write("</row>")
	 	
		&sql(fetch cPropertiesRowset)
 	}
 	
 	&sql(close cPropertiesRowset)	
	
	// done
	
	do out.Write("</root>")
	
	quit out
}

Method DiscoverSchemas(restrictions As SchemasRestrictions) As %XML.GlobalCharacterStream [ PublicList = SQLCODE ]
{
	s out = ##class(%XML.GlobalCharacterStream).%New()

	do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">")

	// write the output schema

	do out.WriteLine("<xsd:schema targetNamespace=""urn:schemas-microsoft-com:xml-analysis:rowset"" xmlns:sql=""urn:schemas-microsoft-com:xml-sql"" elementFormDefault=""qualified"">")
	do out.WriteLine("  <xsd:element name=""root"">")
	do out.WriteLine("    <xsd:complexType>")
	do out.WriteLine("      <xsd:sequence minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xsd:element name=""row"" type=""row"" />")
	do out.WriteLine("      </xsd:sequence>")
	do out.WriteLine("    </xsd:complexType>")
	do out.WriteLine("  </xsd:element>")
	do out.WriteLine("  <xsd:simpleType name=""uuid"">")
	do out.WriteLine("    <xsd:restriction base=""xsd:string"">")
	do out.WriteLine("      <xsd:pattern value=""[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"" />")
	do out.WriteLine("    </xsd:restriction>")
	do out.WriteLine("  </xsd:simpleType>")
	do out.WriteLine("  <xsd:complexType name=""xmlDocument"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:any />")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("  <xsd:complexType name=""row"">")
	do out.WriteLine("    <xsd:sequence>")
	do out.WriteLine("      <xsd:element sql:field=""SchemaName"" name=""SchemaName"" type=""xsd:string"" />")
	do out.WriteLine("      <xsd:element sql:field=""Restrictions"" name=""Restrictions"" minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xsd:complexType>")
	do out.WriteLine("          <xsd:sequence>")
	do out.WriteLine("            <xsd:element sql:field=""Name"" name=""Name"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("            <xsd:element sql:field=""Type"" name=""Type"" type=""xsd:string"" minOccurs=""0"" />")
	do out.WriteLine("          </xsd:sequence>")
	do out.WriteLine("        </xsd:complexType>")
	do out.WriteLine("      </xsd:element>")
	do out.WriteLine("    </xsd:sequence>")
	do out.WriteLine("  </xsd:complexType>")
	do out.WriteLine("</xsd:schema>")
	
	// write the data
	
	if (restrictions '= "") { set restrictionsSchemaName = restrictions.SchemaNameList.Serialize() }
	else { set restrictionsSchemaName = "" }
	
	new SQLCODE,%ROWCOUNT,%ROWID
	
	&sql(declare cSchemasRowset cursor for 
         select SchemaName, Restrictions
         into %SchemaName, %Restrictions
         from %DeepSee_XMLA.SchemasRowset
         where (:restrictionsSchemaName is NULL) or (SchemaName %inlist :restrictionsSchemaName))
	
 	&sql(open cSchemasRowset)
 	&sql(fetch cSchemasRowset)

 	while (SQLCODE = 0) {
		do out.Write("<row>")
		do out.Write("<SchemaName>"_%SchemaName_"</SchemaName>")
		set count = $ll(%Restrictions)
		for ii=1:1:count {
			do out.Write("<Restrictions>")
			do out.Write("<Name>"_$li(%Restrictions,ii)_"</Name>")
			do out.Write("<Type>xsd:string</Type>")
			do out.Write("</Restrictions>")
		}
		do out.Write("</row>")
	 	
		&sql(fetch cSchemasRowset)
 	}
 	
 	&sql(close cSchemasRowset)	
	
	// done
	
	do out.Write("</root>")
	
	quit out
}

Method Execute(Command As ExecuteCommand, Properties As Properties) As %XML.GlobalCharacterStream(XMLNAME="return") [ SoapAction = "urn:schemas-microsoft-com:xml-analysis:Execute", WebMethod ]
{
	
	zn Properties.PropertyList.Catalog
	
	s out = ##class(%XML.GlobalCharacterStream).%New()
	
	// write the output schema
	
	if (Command.Statement = $c(0)) {
		do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:empty""/>")	
		quit out
	}
	
	// do ##class(TestExecute).ExecuteTest(out)
	// quit out

	do out.WriteLine("<root xmlns=""urn:schemas-microsoft-com:xml-analysis:mddataset"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"">")
	do out.WriteLine("<xs:schema targetNamespace=""urn:schemas-microsoft-com:xml-analysis:mddataset"" elementFormDefault=""qualified"" xmlns=""urn:schemas-microsoft-com:xml-analysis:mddataset"" xmlns:xs=""http://www.w3.org/2001/XMLSchema"">")
	do out.WriteLine("  <xs:complexType name=""MemberType"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:any namespace=""##targetNamespace"" minOccurs=""0"" maxOccurs=""unbounded"" processContents=""skip"" />")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("    <xs:attribute name=""Hierarchy"" type=""xs:string"" />")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:complexType name=""PropType"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:element name=""Default"" minOccurs=""0"" />")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("    <xs:attribute name=""name"" type=""xs:string"" use=""required"" />")
	do out.WriteLine("    <xs:attribute name=""type"" type=""xs:QName"" />")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:complexType name=""TupleType"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:element name=""Member"" type=""MemberType"" maxOccurs=""unbounded"" />")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:complexType name=""MembersType"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:element name=""Member"" type=""MemberType"" minOccurs=""0"" maxOccurs=""unbounded"" />")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("    <xs:attribute name=""Hierarchy"" type=""xs:string"" use=""required"" />")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:complexType name=""TuplesType"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:element name=""Tuple"" type=""TupleType"" minOccurs=""0"" maxOccurs=""unbounded"" />")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:group name=""SetType"">")
	do out.WriteLine("    <xs:choice>")
	do out.WriteLine("      <xs:element name=""Members"" type=""MembersType"" />")
	do out.WriteLine("      <xs:element name=""Tuples"" type=""TuplesType"" />")
	do out.WriteLine("      <xs:element name=""CrossProduct"" type=""SetListType"" />")
	do out.WriteLine("      <xs:element name=""Union"">")
	do out.WriteLine("        <xs:complexType>")
	do out.WriteLine("          <xs:group ref=""SetType"" minOccurs=""0"" maxOccurs=""unbounded"" />")
	do out.WriteLine("        </xs:complexType>")
	do out.WriteLine("      </xs:element>")
	do out.WriteLine("    </xs:choice>")
	do out.WriteLine("  </xs:group>")
	do out.WriteLine("  <xs:complexType name=""SetListType"">")
	do out.WriteLine("    <xs:group ref=""SetType"" minOccurs=""0"" maxOccurs=""unbounded"" />")
	do out.WriteLine("    <xs:attribute name=""Size"" type=""xs:unsignedInt"" />")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:complexType name=""OlapInfo"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:element name=""CubeInfo"">")
	do out.WriteLine("        <xs:complexType>")
	do out.WriteLine("          <xs:sequence>")
	do out.WriteLine("            <xs:element name=""Cube"" maxOccurs=""unbounded"">")
	do out.WriteLine("              <xs:complexType>")
	do out.WriteLine("                <xs:sequence>")
	do out.WriteLine("                  <xs:element name=""CubeName"" type=""xs:string"" />")
	do out.WriteLine("                  <xs:element name=""LastDataUpdate"" minOccurs=""0"" type=""xs:dateTime"" />")
	do out.WriteLine("                  <xs:element name=""LastSchemaUpdate"" minOccurs=""0"" type=""xs:dateTime"" />")
	do out.WriteLine("                </xs:sequence>")
	do out.WriteLine("              </xs:complexType>")
	do out.WriteLine("            </xs:element>")
	do out.WriteLine("          </xs:sequence>")
	do out.WriteLine("        </xs:complexType>")
	do out.WriteLine("      </xs:element>")
	do out.WriteLine("      <xs:element name=""AxesInfo"">")
	do out.WriteLine("        <xs:complexType>")
	do out.WriteLine("          <xs:sequence>")
	do out.WriteLine("            <xs:element name=""AxisInfo"" maxOccurs=""unbounded"">")
	do out.WriteLine("              <xs:complexType>")
	do out.WriteLine("                <xs:sequence>")
	do out.WriteLine("                  <xs:element name=""HierarchyInfo"" minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("                    <xs:complexType>")
	do out.WriteLine("                      <xs:sequence>")
	do out.WriteLine("                        <xs:any namespace=""##targetNamespace"" minOccurs=""0"" maxOccurs=""unbounded"" processContents=""skip"" />")
	do out.WriteLine("                      </xs:sequence>")
	do out.WriteLine("                      <xs:attribute name=""name"" type=""xs:string"" use=""required"" />")
	do out.WriteLine("                    </xs:complexType>")
	do out.WriteLine("                  </xs:element>")
	do out.WriteLine("                </xs:sequence>")
	do out.WriteLine("                <xs:attribute name=""name"" type=""xs:string"" />")
	do out.WriteLine("              </xs:complexType>")
	do out.WriteLine("            </xs:element>")
	do out.WriteLine("          </xs:sequence>")
	do out.WriteLine("        </xs:complexType>")
	do out.WriteLine("      </xs:element>")
	do out.WriteLine("      <xs:element name=""CellInfo"">")
	do out.WriteLine("        <xs:complexType>")
	do out.WriteLine("          <xs:choice minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("            <xs:any namespace=""##targetNamespace"" minOccurs=""0"" maxOccurs=""unbounded"" processContents=""skip"" />")
	do out.WriteLine("          </xs:choice>")
	do out.WriteLine("        </xs:complexType>")
	do out.WriteLine("      </xs:element>")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:complexType name=""Axes"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:element name=""Axis"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xs:complexType>")
	do out.WriteLine("          <xs:group ref=""SetType"" minOccurs=""0"" maxOccurs=""unbounded"" />")
	do out.WriteLine("          <xs:attribute name=""name"" type=""xs:string"" />")
	do out.WriteLine("        </xs:complexType>")
	do out.WriteLine("      </xs:element>")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:complexType name=""CellData"">")
	do out.WriteLine("    <xs:sequence>")
	do out.WriteLine("      <xs:element name=""Cell"" minOccurs=""0"" maxOccurs=""unbounded"">")
	do out.WriteLine("        <xs:complexType>")
	do out.WriteLine("          <xs:sequence>")
	do out.WriteLine("            <xs:any namespace=""##targetNamespace"" minOccurs=""0"" maxOccurs=""unbounded"" processContents=""skip"" />")
	do out.WriteLine("          </xs:sequence>")
	do out.WriteLine("          <xs:attribute name=""CellOrdinal"" type=""xs:unsignedInt"" use=""required"" />")
	do out.WriteLine("        </xs:complexType>")
	do out.WriteLine("      </xs:element>")
	do out.WriteLine("    </xs:sequence>")
	do out.WriteLine("  </xs:complexType>")
	do out.WriteLine("  <xs:element name=""root"">")
	do out.WriteLine("    <xs:complexType>")
	do out.WriteLine("      <xs:sequence>")
	do out.WriteLine("        <xs:any namespace=""http://www.w3.org/2001/XMLSchema"" processContents=""strict"" minOccurs=""0"" />")
	do out.WriteLine("        <xs:element name=""OlapInfo"" type=""OlapInfo"" minOccurs=""0"" />")
	do out.WriteLine("        <xs:element name=""Axes"" type=""Axes"" minOccurs=""0"" />")
	do out.WriteLine("        <xs:element name=""CellData"" type=""CellData"" minOccurs=""0"" />")
	do out.WriteLine("      </xs:sequence>")
	do out.WriteLine("    </xs:complexType>")
	do out.WriteLine("  </xs:element>")
	do out.WriteLine("</xs:schema>")
		
	set tRS=##class(%DeepSee.ResultSet).%ExecuteDirect(Command.Statement)
	
	do out.WriteLine("<OlapInfo>")

	do out.WriteLine("<CubeInfo>")

	do out.WriteLine("<Cube>")
	do out.WriteLine("<CubeName>"_tRS.%GetCubeName()_"</CubeName>")	
	do out.Write("<LastDataUpdate xmlns=""http://schemas.microsoft.com/analysisservices/2003/engine"">")
	do out.Write(tRS.%GetLastDataUpdate())
	do out.WriteLine("</LastDataUpdate>")
	do out.Write("<LastSchemaUpdate xmlns=""http://schemas.microsoft.com/analysisservices/2003/engine"">")
	do out.Write(tRS.%GetLastSchemaUpdate())
	do out.WriteLine("</LastSchemaUpdate>")
	do out.WriteLine("</Cube>")
	
	do out.WriteLine("</CubeInfo>")
	
	// AxesInfo

	do out.WriteLine("<AxesInfo>")

	set axesCount = tRS.%GetAxisCount()
	
	for axis = 0:1:axesCount {
		set status=tRS.%GetAxisMembers(axis,.key)
		if ($$$ISERR(status)) {
			set fault = ..MakeStatusFault(, "Error while processing the meta information for <AxesInfo>", status)
			kill ^||DeepSee.AxisMembers
			do ..ReturnFault(fault)			
		}
		
		if ($d(^||DeepSee.AxisMembers(key, axis)) = 0) { continue }
		
		if (axis = 0) {	do out.WriteLine("<AxisInfo name=""SlicerAxis"">") }
		else { do out.WriteLine("<AxisInfo name=""Axis"_(axis - 1)_""">") }
		
		set tupleIdx = 1
		set memberIdx = 0
		while ($data(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx))) {
			while ($data(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx))) {
				set dimensionName = $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 3)
				set hierarchyName = $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 4)
				if (dimensionName '= "Measures") {
					set hierarchyCompleteName = "["_dimensionName_"].["_hierarchyName_"]" }
				else {
					set hierarchyCompleteName = "[Measures]"
				}
				set hierarchyNames(hierarchyCompleteName) = ""
				
				set memberIdx = memberIdx + 1
			}
			
			set tupleIdx = tupleIdx + 1
			set memberIdx = 0
		}
		
		set hierarchyCompleteName = $order(hierarchyNames(""))
		while (hierarchyCompleteName '= "") {
			do out.WriteLine("<HierarchyInfo name="""_hierarchyCompleteName_""">")
			do out.WriteLine("<UName name="""_hierarchyCompleteName_".[MEMBER_UNIQUE_NAME]"" type=""xsd:string"" />")
			do out.WriteLine("<Caption name="""_hierarchyCompleteName_".[MEMBER_CAPTION]"" type=""xsd:string"" />")
			do out.WriteLine("<LName name="""_hierarchyCompleteName_".[LEVEL_UNIQUE_NAME]"" type=""xsd:string"" />")
			do out.WriteLine("<LNum name="""_hierarchyCompleteName_".[LEVEL_NUMBER]"" type=""xsd:int"" />")
			do out.WriteLine("<DisplayInfo name="""_hierarchyCompleteName_".[DISPLAY_INFO]"" type=""xsd:unsignedInt"" />")
			do out.WriteLine("</HierarchyInfo>")

			set hierarchyCompleteName = $order(hierarchyNames(hierarchyCompleteName))
		}
		
		do out.WriteLine("</AxisInfo>")
		kill hierarchyNames
	}

	do out.WriteLine("</AxesInfo>")	
	
	// CellInfo
	
	do out.WriteLine("<CellInfo>")

	do out.WriteLine("<Value name=""VALUE"" />")
	do out.WriteLine("<FmtValue name=""FORMATTED_VALUE"" type=""xsd:string"" />")
	do out.WriteLine("<CellOrdinal name=""CELL_ORDINAL"" type=""xsd:unsignedInt"" />")

	do out.WriteLine("</CellInfo>")	
	
	do out.WriteLine("</OlapInfo>")
	
	// Axes
	
	do out.WriteLine("<Axes>")
	for axis = 0:1:axesCount {
		if ($d(^||DeepSee.AxisMembers(key, axis)) = 0) { continue }

		if (axis = 0) {	do out.WriteLine("<Axis name="_"""SlicerAxis"">") }
		else { do out.WriteLine("<Axis name=""Axis"_(axis - 1)_""">") }				

		do out.WriteLine("<Tuples>")

		set tupleIdx = 1
		set memberIdx = 0
		while ($data(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx))) {
			do out.WriteLine("<Tuple>")			
			while ($data(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx))) {
				set label =  $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 2)
				set dimensionName = $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 3)
				set hierarchyName = $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 4)
				set levelName = $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 5)
				set memberKey =  $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 6)				
				set levelNumber = $list(^||DeepSee.AxisMembers(key, axis, tupleIdx, memberIdx), 9)
				
				if (levelNumber > 0) { set levelNumber = levelNumber - 1 }
				if (dimensionName = "Measures") { 
					set hierarchyCompleteName = "[Measures]" 
					set levelName = "MeasuresLevel"
				}
				else { set hierarchyCompleteName = "["_dimensionName_"].["_hierarchyName_"]" }
				
				do out.WriteLine("<Member Hierarchy="""_hierarchyCompleteName_""">")
				do out.Write("<UName>")
				if (dimensionName = "Measures") {
					do out.Write("[Measures].["_label_"]")		
				}
				elseif (memberKey = "") { 
					if (levelName = "") { do out.Write(hierarchyCompleteName) }
					else { do out.Write(hierarchyCompleteName_".["_levelName_"]") }
				}
				else { do out.Write(hierarchyCompleteName_".["_levelName_"].&amp;["_memberKey_"]") }
				do out.WriteLine("</UName>")
				do out.WriteLine("<Caption>"_label_"</Caption>")
				do out.WriteLine("<LName>"_hierarchyCompleteName_".["_levelName_"]"_"</LName>")
				do out.WriteLine("<LNum>"_levelNumber_"</LNum>")
				do out.WriteLine("<DisplayInfo>0</DisplayInfo>")
				do out.WriteLine("</Member>")
								
				set memberIdx = memberIdx + 1
			}
			do out.WriteLine("</Tuple>")
			
			set tupleIdx = tupleIdx + 1
			set memberIdx = 0
		}
		
		do out.WriteLine("</Tuples>")
		do out.WriteLine("</Axis>")
	}

	do out.WriteLine("</Axes>")
	
	// CellData
	
	do out.WriteLine("<CellData>")
	set axisCount = tRS.%GetAxisCount()
	for axis = 1:1:axisCount {
		set axisSize(axis) = tRS.%GetAxisSize(axis)
	}
	
	set offset(1) = 1
	for ii=2:1:axisCount { set offset(ii) = offset(ii - 1) * axisSize(ii - 1) }

	if (axisCount = 1) {
		for axis1 = 1:1:axisSize(1) {
			set value = tRS.%GetOrdinalValue(axis1)
			set ordinal = axis1 - 1
			do ..CalcCellInfo(value, .valueType, .formatValue)
						
			do out.WriteLine("<Cell CellOrdinal="""_ordinal_""">")
			do out.WriteLine("<Value xsi:type="_valueType_">"_value_"</Value>")
			do out.WriteLine("<FmtValue>"_formatValue_"</FmtValue>")
			do out.WriteLine("</Cell>")
		}
	}
	elseif (axisCount = 2) {
		for axis1 = 1:1:axisSize(1) {
			for axis2 = 1:1:axisSize(2) {
				set value = tRS.%GetOrdinalValue(axis1, axis2)
				set ordinal = (axis1 - 1) * offset(1) + (axis2 - 1) * offset(2)
				do ..CalcCellInfo(value, .valueType, .formatValue)

				do out.WriteLine("<Cell CellOrdinal="""_ordinal_""">")
				do out.WriteLine("<Value xsi:type="""_valueType_""">"_value_"</Value>")
				do out.WriteLine("<FmtValue>"_formatValue_"</FmtValue>")
				do out.WriteLine("</Cell>")
			}
		}		
	}
	do out.WriteLine("</CellData>")
	
	// done
	
	do out.WriteLine("</root>")
	
	kill ^||DeepSee.AxisMembers	
	quit out
}

Method CalcCellInfo(value As %String, ByRef valueType As %String, formatValue As %String)
{
	if ($IsValidNum(value)) {
		if (value = (value\1)) {
			set valueType = "xsd:long"
			set formatValue = $FN(value, ",",0) 
		}
		else { 
			set valueType = "xsd:double" 
			set formatValue = $FN(value, ",",2)
		}
	}
	else {
		set valueType = "xsd:string"
		set formatValue = value
	}
}

ClassMethod OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	If ('$System.Security.Check("%DeepSee_Portal","USE")) {
		Quit 0
	}
	Quit ##super()
}

}
