/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// A specialized KPI that gets its values from a saved "worksheet".
/// The worksheet information is obtained using the <class>%DeepSee.UserLibrary.Worksheet</class> class.
Class %DeepSee.KPIWorksheet Extends %DeepSee.AbstractKPI [ System = 4 ]
{

/// Return the logical name for this KPI.
ClassMethod %GetKPIName(pName As %String = "") As %String
{
	If (pName="") {
		Quit ""
	}
	Quit $G($$$DeepSeeMetaGLVN("kpis",$$$UPPER(pName),"name"))
}

/// Return the caption as defined in the XML for this KPI.
ClassMethod %GetKPICaptionName(pName As %String = "") As %String
{
	If (pName="") {
		Quit ""
	}
	Quit $G($$$DeepSeeMetaGLVN("kpis",$$$UPPER(pName),"name"))
}

/// Add additional properties beyond those defined in the KPI block.
/// This takes the form:<br/>
/// pList(n) = name<br/>
/// pList(n,"defaultValue") = value<br/>
/// pList(n,"columnNo") = #<br/>
/// <var>pPropNo</var> is the number of next open slot in the list.
ClassMethod %OnGetKPIPropertyInfo(ByRef pList As %String, pPropNo As %Integer, pModelId As %String = "") As %Status
{
	Set tSC = $$$OK

	Try {
		// pModelId should contain the "worksheet" name
		// this takes the form "Name.worksheet"
		If (pModelId'="") {
			// get properties from Worksheet
			Set tWorksheet = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pModelId)

			// loop and get property names
			If $IsObject(tWorksheet) {
				Set tColCount = tWorksheet.columnHeaders.Count()
				For c = 1:1:tColCount {
					Set tCol = tWorksheet.columnHeaders.GetAt(c)
					Set pList(pPropNo) = tCol.name
					Set pPropNo = pPropNo + 1
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Notify subclass that KPI is has just be executed.
/// This is a good place to override properties, such as range and threshold.
Method %OnLoadKPI() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%seriesCount = 0

		// %id holds the actual Worksheet name
		If (..%id'="") {
			// get data from Worksheet
			Set tWorksheet = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..%id)

			If $IsObject(tWorksheet) {

				// series are rows
				Set tRowCount = tWorksheet.rowHeaders.Count()
				For r = 1:1:tRowCount {
					Set tRow = tWorksheet.rowHeaders.GetAt(r)
					If (tRow.name'="") {
						// skip unnamed rows
						Set ..%seriesCount = ..%seriesCount + 1
						Set ..%seriesNames(..%seriesCount) = tRow.name
						Set tRowMap(..%seriesCount) = r
					}
				}

				// proplist (cols)
				Set tPropCount = 0
				Set tColCount = tWorksheet.columnHeaders.Count()
				For c = 1:1:tColCount {
					Set tCol = tWorksheet.columnHeaders.GetAt(c)
					If (tCol.name'="") {
						Set tPropCount = tPropCount + 1
						Set tProps(tPropCount) = tCol.name
					}
				}

				// recalc
				Set tSC = tWorksheet.%Calculate()
				If $$$ISERR(tSC) Quit

				// get values from worksheet
				// (use resolved values)
				For series=1:1:..%seriesCount {
					For prop=1:1:tPropCount {
						Set:$D(tProps(prop)) ..%data(series,tProps(prop)) = $G(tWorksheet.%values(tRowMap(series),prop))
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get a specific value from this KPI.<br/>
/// Overridden to bypass the generic machinery in the abstract base class implementation.
ClassMethod %GetKPIValue(pKPIName As %String, Output pValue As %String, pKPIProperty As %String = "", pSeries As %String = "", ByRef pFilters As %String, pCellContext As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set pValue = " " // return " " for no results!

		// get data from Worksheet
		Set tWorksheet = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pKPIName)
		If '$IsObject(tWorksheet) {
			Set pValue = "Invalid KPI"
			Quit
		}

		// return ""
		If ((pKPIProperty = "") || (pSeries = "")) {
			Quit
		}
		Else {
			// recalc
			Set tSC = tWorksheet.%Calculate()
			If $$$ISERR(tSC) Quit

			Set tSeriesNo = 1
			If (pSeries'="") {
				Set tName = $$$UPPER(pSeries)
				Set tSeriesNo = +pSeries

				// try to find number for series name
				// series are rows
				Set tRowCount = tWorksheet.rowHeaders.Count()
				For r = 1:1:tRowCount {
					Set tRow = tWorksheet.rowHeaders.GetAt(r)
					If ($$$UPPER(tRow.name) = tName) {
						Set tSeriesNo = r
						Quit
					}
				}
			}

			// find prop #
			Set tPropNo = ""
			Set tName = $$$UPPER(pKPIProperty)
			Set tColCount = tWorksheet.columnHeaders.Count()
			For c = 1:1:tColCount {
				Set tCol = tWorksheet.columnHeaders.GetAt(c)
				If ($$$UPPER(tCol.name) = tName) {
					Set tPropNo = c
					Quit
				}
			}
			If (tPropNo="") {
				Set pValue = "Invalid Property"
			}
			Else {
				Set pValue = $G(tWorksheet.%values(tSeriesNo,tPropNo)," ")
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
