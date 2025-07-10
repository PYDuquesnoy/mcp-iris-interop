/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Defines data about an InterSystems IRIS Business Partner Profile.<br/>
/// A Business Partner is any organization or application that an production connects to.
/// You can use the Business Partner table to hold additional information about such partners. The data in
/// this data is informational only. It does has no effect on the running of the system.
Class Ens.Config.BusinessPartner Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Index PartnerName On PartnerName [ IdKey, PrimaryKey ];

/// Name of this Business Partner.
/// This must be unique.
Property PartnerName As %String(MAXLEN = 255, XMLPROJECTION = "ATTRIBUTE");

/// Details on the primary contact for this Business Partner.
Property PrimaryContact As Ens.Config.BusinessPartnerContact;

/// Details on the alternative contact for this Business Partner.
Property AlternativeContact As Ens.Config.BusinessPartnerContact;

/// Description of this Business Partner.
Property Description As %String(MAXLEN = 5000, XMLPROJECTION = "ELEMENT");

Query List() As %SQLQuery
{
Select PartnerName,Description,PrimaryContact_Name As PrimaryContact, PrimaryContact_PhoneNumber As Phone from Ens_Config.BusinessPartner
}

/// Import Business Partner definitions from an xml file.<br/>
/// If <var>pReplace</var> is true, replace an existing item with the same name.<br/>
/// If <var>pVerbose</var> is true, write status to the console.<br/>
/// If <var>pKill</var> is true, then delete all existing items before import!<br/>
ClassMethod %Import(pFile As %String, pReplace As %Boolean = 0, pVerbose As %Boolean = 1, pKill As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill %objlasterror

		// Create an instance of %XML.Reader
		Set tReader = ##class(%XML.Reader).%New()
	
		// Begin processing of the file
		Set tSC = tReader.OpenFile(pFile)
		If $$$ISERR(tSC) Quit

		Do tReader.Correlate("BusinessPartner","Ens.Config.BusinessPartner")

		// Read objects from xml file
	    While (tReader.Next(.tItem,.tSC)) {
		    Set tExists = ..%ExistsId(tItem.PartnerName)
			If (tExists=2) {
				Set tSC = $$$ERROR($$$GeneralError,"Business Partner with given name already exists and you do not have permission to replace it: "_tItem.PartnerName)
				Quit
			}
			ElseIf (tExists=1) {
				If (pReplace) {
					Write:pVerbose "Replacing: ",tItem.PartnerName,!
				    Set tSC = ..%DeleteId(tItem.PartnerName)
					If $$$ISERR(tSC) Quit
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Business Partner with given name already exists: "_tItem.PartnerName)
					Quit
				}
		    }
		    Else {
				Write:pVerbose "Importing: ",tItem.PartnerName,!
		    }
			Set tSC = tItem.%Save()
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If ($$$ISERR(tSC)&&pVerbose) {
		Write !
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// Export all Business Partner definitions to an xml file.
ClassMethod %ExportAll(pFile As %String = "", pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Set io = ""
	Try {

		// make sure we can open the file
		Open pFile:"WNU":0 Else  Set tSC = $$$ERROR($$$GeneralError,"Unable to open file: "_pFile) Quit
		Close pFile

		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare("Select PartnerName from Ens_Config.BusinessPartner")
		If $$$ISERR(tSC) Quit

		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.Indent = 1
		Set tSC = tWriter.OutputToFile(pFile)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.StartDocument()
		If $$$ISERR(tSC) Quit

		Set tSC = tWriter.RootElement("PartnerList")
		If $$$ISERR(tSC) Quit

		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.PartnerName '="") {
				Set tItem = ..%OpenId(tRS.PartnerName)

				Write:pVerbose tItem.PartnerName,!
				Set tSC = tWriter.Object(tItem)
				If $$$ISERR(tSC) Quit
			}
		}

		Set tSC = tWriter.EndRootElement()
		If $$$ISERR(tSC) Quit

		Set tSC = tWriter.EndDocument()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If ($$$ISERR(tSC)&&pVerbose) {
		Write !,$System.Status.DisplayError(tSC)
	}

	Quit tSC
}

/// Export a Business Partner definition to an xml file.
ClassMethod %Export(pName As %String, pFile As %String = "", pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Set io = ""
	Try {
		Set tItem = ..%OpenId(pName,.tSC)
		If '$IsObject(tItem) {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to find Business Partner: "_pName)
			Quit
		}

		// make sure we can open the file
		Open pFile:"WNU":0 Else  Set tSC = $$$ERROR($$$GeneralError,"Unable to open file: "_pFile) Quit
		Close pFile

		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.Indent = 1
		Set tSC = tWriter.OutputToFile(pFile)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.StartDocument()
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.RootObject(tItem)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.EndDocument()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If ($$$ISERR(tSC)&&pVerbose) {
		Write !,$System.Status.DisplayError(tSC)
	}

	Quit tSC
}

Storage Default
{
<Data name="BusinessPartnerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>PrimaryContact</Value>
</Value>
<Value name="4">
<Value>AlternativeContact</Value>
</Value>
</Data>
<DataLocation>^Ens.Config.BusinessPartnerD</DataLocation>
<DefaultData>BusinessPartnerDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Config.BusinessPartnerD</IdLocation>
<IndexLocation>^Ens.Config.BusinessPartnerI</IndexLocation>
<StreamLocation>^Ens.Config.BusinessPartnerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
