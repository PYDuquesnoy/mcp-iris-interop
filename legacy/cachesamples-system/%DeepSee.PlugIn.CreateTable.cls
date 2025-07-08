/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This plugin runs code to generate a new source class from a selection in a pivot table.
Class %DeepSee.PlugIn.CreateTable Extends %DeepSee.KPIPlugIn [ System = 4 ]
{

Parameter CACHEABLE = 0;

Parameter ASYNC = 0;

/// Cube(s) that this plug-in is based on.
Parameter BASECUBE = "*";

Parameter LISTINGSOURCE = "SourceTable";

Parameter PLUGINTYPE = "Aggregate";

XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi name="%DeepSee.CreateTable" displayName="CreateTable" caption="CreateTable" >
<property name="CREATETABLE" displayName="CreateTable" description="Dummy property so we can use KPI PlugIn Infrasctructure" />
<filter name="%cube" displayName="Subject Area"/>
<filter name="%listingFields" displayName="listingFields"/>
<filter name="%listingName" displayName="listingName"/>
<filter name="%tableName" displayName="tableName"/>
</kpi>
}

/// Get the base query for this plug-in.
Method %OnGetMDX(ByRef pMDX As %String) As %Status
{
	Set tBaseCube = ""

	// Use %cube filter to find the base cube
	If $IsObject(..%filterValues) {
		If (..%filterValues.%cube'="") {
			Set tBaseCube = ..%filterValues.%cube
		}
	}

	If (tBaseCube'="") {
		Set pMDX = "SELECT FROM "_tBaseCube
	}
	
	Quit $$$OK
}

/// Returns the field list (RETURN clause) of the listing used to supply data for this plug-in.
/// In this case, determine which measure we need.
Method %OnGetListingFields() As %String
{
	Set tListingFields="ID"
	Try {
		If $IsObject(..%filterValues) {
			// DTB434 - Try to add more fields to the field list in addition to the default ID
			// Find the fields requested for the table
			If (..%filterValues.%listingFields'="")&&(..%filterValues.%listingFields'="*") {
				Set tRequestedFields = ..%filterValues.%listingFields
			}
			ElseIf (..%filterValues.%listingName'="")&&(..%filterValues.%cube'="") {
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..%filterValues.%cube,.tInfo)
				If $$$ISERR(tSC) Quit
				
				Set tCubeName = $$$UPPER($G(tInfo(1)))		// DTB549
				Set tTargetListingName = ..%filterValues.%listingName
				
				// DTB746 - Parse to remove []
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tTargetListingName,.tInfo)
				If $$$ISERR(tSC) Quit
				Set tTargetListingName = tInfo(1)
				
				Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(tCubeName,.tListings)
				If $$$ISERR(tSC) Quit
				
				Set tListingName =$O(tListings(""),1,tListingInfo)
				While (tListingName'="")&&($$$UPPER(tListingName)'=$$$UPPER(tTargetListingName)) {
					Set tListingName =$O(tListings(tListingName),1,tListingInfo)
				}

				Set tRequestedFields = $LG(tListingInfo,2)
			}
			
			// Add the requested fields to the field list
			For f=1:1:$L(tRequestedFields,",") {
				Set tField = $P(tRequestedFields,",",f)
				If (tField'="ID")&&(tField'="%ID") {
					Set tListingFields = tListingFields _ "," _ tField	
				}
			}
		}
	}
	Catch ex {
		// DTB434 - Always default to the ID as the singular field.
		Set tListingFields = "ID"
	}
	
	Quit tListingFields
}

/// Return an <class>%SQL.StatementResult</class> object that will iterate over the facts used for analysis.
Method %OnGetAnalysisResultSet(Output pRS As %SQL.StatementResult, pSQL As %String) As %Status
{
	// Method added by DTB434
	Set tSC = $$$OK
	Try {
		If $IsObject(..%filterValues) {
			If (..%filterValues.%listingFields="")&&(..%filterValues.%listingName'="") {
				// See if there is custom sql. If so, try to create a listing
				// resultset and use that.
				If (..%filterValues.%cube'="") {
					Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..%filterValues.%cube,.tInfo)
					If $$$ISERR(tSC) Quit
					
					Set tCubeName = tInfo(1)
					Set tBaseCube = $$$UPPER(tCubeName)
				}
				Else {
					Quit
				}
				
				// DTB746 - Parse. Global storage will not have enclosing [] but the %listingName might
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..%filterValues.%listingName,.tInfo)
				If $$$ISERR(tSC) Quit
				Set tTargetListingName = tInfo(1)
				
				If (tBaseCube'="")&&(..%filterValues.%listingName'="")&&
						($D($$$DeepSeeListingGroupGLVN("cubes",tBaseCube,"listing",tTargetListingName,"sql")) ||
						($D($$$DeepSeeMetaGLVN("cubes",tBaseCube,"listing",tTargetListingName,"sql")))) {
					// Conditions for a custom sql listing. Add the context the to the
					// DRILLTHROUGH and generate the resultset.
					Set tMDX = " DRILLTHROUGH SELECT FROM ["_tBaseCube_"]"
					If $D(%dsCellContext(1)) {
						Set tMDX = tMDX _ " %FILTER " _ %dsCellContext(1)
					}
					
					Set tMDX = tMDX _ " %LISTING " _ ..%filterValues.%listingName
					
					Set tDRS = ##class(%DeepSee.ResultSet).%New()
					Set tSC = tDRS.%PrepareMDX(tMDX)
					If $$$ISERR(tSC) Quit
					
					Set tSC = tDRS.%Execute()
					If $$$ISERR(tSC) Quit
					
					Set tSC = tDRS.%GetListingResultSet(.pRS)
					If $$$ISERR(tSC) Quit
					
					Set %dsPluginRS($I(%dsPluginRS)) = tDRS		// DTB746 - Preserve a reference to the ResultSet until the task is finished
				}
				Else {
					Quit
				}
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Read the listing's resultset and generate a new class to contain the records.
Method %OnCompute(pSQLRS As %SQL.StatementResult, pFactCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		
		// Create Table
		Set tClassDefName = ..%filterValues.%tableName
		Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassDefName)
		If tClassDef = $$$NULLOREF {
			Set tSC=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition")
			Quit
		}
		Set tClassDef.Super = "%Library.Persistent"
		// Add property for each listing field
		Set tMetaData = pSQLRS.%GetMetadata()
		Set tIdColumnNo = 0
		
		For c=1:1:tMetaData.columnCount {
			Set tColumn = tMetaData.columns.GetAt(c)
			If (tColumn.colName="ID")||(tColumn.colName="%ID") {
				Set tIdColumnNo = c
			}
			Set tColName = $S(c=tIdColumnNo:"%sourceId",1:tColumn.colName)		// DTB434
			Set tProperty = ##class(%Dictionary.PropertyDefinition).%New()
			Set tProperty.Name = tColName
			Set tProperty.Type = $S(c=tIdColumnNo:"%Integer",1:tColumn.typeClass.Name)		// DTB434 - For now, this assumes IDs are %Integer
			Do tClassDef.Properties.Insert(tProperty)
		}

		// Save the table
		Set tSC = tClassDef.%Save()
		If $$$ISERR(tSC) Quit

		// Compile the class
		Set tSC = $system.OBJ.Compile(tClassDefName,"/display=none")
		If $$$ISERR(tSC) Quit
		
		While (pSQLRS.%Next(.tSC)) {
			If $$$ISERR(tSC) {
				Set tErrMsg = $System.Status.GetErrorText(tSC)
				Quit
			}
		
			// Write from appropriate listing fields into appropriate properties
			Set tRow = $classmethod(tClassDefName,"%New")
			
			For c=1:1:tMetaData.columnCount {
				Set tColumn = tMetaData.columns.GetAt(c)
				Set tColName = $S(c=tIdColumnNo:"%sourceId",1:tColumn.colName)	// DTB434
				Set $property(tRow,tColName) = pSQLRS.%GetData(c)
			}
			
			// Save this row
			Set tSC = tRow.%Save()
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

}
