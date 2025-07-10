/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%systemInclude, Ensemble)

IncludeGenerator %systemInclude

/// Contains the APIs needed to convert a legacy Ensemble Dashboard to a DeepSee Dashboard.
/// This is not intended to perform a 100% conversion, but to get a reasonable amount of content moved over that can then
/// be finished using the dashboard editor.
Class Ens.DashboardConverter [ Abstract, System = 4 ]
{

/// Convert the legacy Ensemble dashboard class, <var>pDashboardClass</var> to a DeepSee Dashboard definition
/// in folder item <var>pNewName</var>.
ClassMethod %Convert(pProductionName As %String, pDashboardClass As %String, pNewName As %String, pVerbose As %Boolean = 1) As %Status
{
	Set tSC = $$$OK, pNewName=$TR(pNewName,"-","/")
	Set:".dashboard"'=$E(pNewName,*+1-$L(".dashboard"),*) pNewName=pNewName_".dashboard"
	Try {
		If (($G(pProductionName)="") || '$$$comClassDefined(pProductionName)) {
			Set tSC = $$$ERROR($$$GeneralError,"Production not found: "_$G(pProductionName))
			Quit
		}

		If (($G(pDashboardClass)="") || '$$$comClassDefined(pDashboardClass)) {
			Set tSC = $$$ERROR($$$GeneralError,"Class not found: "_$G(pDashboardClass))
			Quit
		}

		Set tSC = $classmethod(pDashboardClass,"CreateDashboard",.tDashboard)
		If $$$ISERR(tSC) Quit

		If ('$IsObject($G(tDashboard))) {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to load dashboard definition: "_pDashboardClass)
			Quit
		}

		// walk down dashboard and convert to one list
		Set tLastMeter = ""
		Set tSC = ..%ProcessList(.tInfo, tDashboard.Meters,.tLastMeter,0,pVerbose)
		If $$$ISERR(tSC) Quit

		If pVerbose {
			Set tDB = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pNewName)
			If $IsObject(tDB) {
				Write !,"Deleting existing dashboard '"_pNewName_"' stored as document '"_tDB.documentName_"'."
			}
		}
		Do ##class(%DeepSee.Dashboard.Utils).%DeleteDashboard(pNewName)

		Set tNewDB = ##class(%DeepSee.Dashboard.Definition).%New()
		// global settings

		Set tNewDB.title = tDashboard.Label

		// walk down info list
		// Position!
		Set y = 50
		Set x = 50
		Set tGroup = $O(tInfo(""))
		While (tGroup'="") {
			Set tGroupMeter = $G(tInfo(tGroup))

			// process first item
			Set tItem = $O(tInfo(tGroup,""))
			If (tItem'="") {
				Set tMeter = tInfo(tGroup,tItem)

				Set tMetricName = $S($IsObject(tGroupMeter):tGroupMeter.Metric,1:"")
				Set:tMeter.Metric'="" tMetricName = tMeter.Metric

				// strip off {instance}
				Set tMetricName = $P(tMetricName,"(")

				Set tDataSource = pProductionName_"/"_tMetricName_".metric"

				Set tWidget = ##class(%DeepSee.Dashboard.Widget).%New()
				Set tWidget.title = $S($IsObject(tGroupMeter):tGroupMeter.Label,1:"")
				Set tWidget.name = "Widget "_$I(tWidgetCount)

				If (tWidgetCount=1) {
					// add dashboard wide controls to first widget
					Set tControl = ##class(%DeepSee.Dashboard.Control).%New()
					Set tControl.action = "refresh"
					Set tControl.type = "auto"
					Set tControl.target = "*"
					Set tControl.title = "Refresh the dashboard"
					Set tControl.location = "dashboard"
					Do tWidget.controls.Insert(tControl)

					If (+tDashboard.RefreshRate>0) {
						Set tControl = ##class(%DeepSee.Dashboard.Control).%New()
						Set tControl.action = "refresh"
						Set tControl.type = "timer"
						Set tControl.target = "*"
						Set tControl.timeout = tDashboard.RefreshRate/1000
						Do tWidget.controls.Insert(tControl)
					}
				}


				Set tWidget.dataSource = tDataSource
				Do tNewDB.widgets.Insert(tWidget)
		
				Set tWidget.top = y
				Set tWidget.left = x
				Set tWidget.width = 200
				Set tWidget.height = 200
				Set x = x + 100

				// pick widget type based on first item
				If (tMeter.%IsA("CSPX.Dashboard.Chart")) {
					Set tWidget.type = "pivot"
					If (tMeter.%IsA("CSPX.Dashboard.LineChart")) {
						Set tWidget.subtype = "lineChart"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.PieChart")) {
						Set tWidget.subtype = "pieChart"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.BarChart")) {
						Set tWidget.subtype = "columnChart"
					}
					Else {
						Set tWidget.subtype = "barChart"
					}
				}
				ElseIf (tMeter.%IsA("CSPX.Dashboard.Grid")) {
					Set tWidget.type = "scoreCardWidget"
				}
				Else {
					Set tWidget.type = "meter"
					If (tMeter.%IsA("CSPX.Dashboard.FuelGauge")) {
						Set tWidget.subtype = "fuelGauge"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.Smiley")) {
						Set tWidget.subtype = "smiley"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.LightBar")) {
						Set tWidget.subtype = "lightBar"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.TrafficLight")) {
						Set tWidget.subtype = "trafficLight"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.Odometer")) {
						Set tWidget.subtype = "textMeter"
					}
					Else {
						Set tWidget.subtype = "speedometer"
					}

					Set tDataProp = ##class(%DeepSee.Dashboard.DataProperty).%New()
					// strip off {instance}
					Set tDataProp.dataValue = tMeter.Property
					Set tDataProp.label = $Replace(tMeter.Label,"{Instance}","")
					Set tDataProp.rangeLower = tMeter.RangeLower
					Set tDataProp.rangeUpper = tMeter.RangeUpper
					Set tDataProp.thresholdLower = tMeter.ThresholdLower
					Set tDataProp.thresholdUpper = tMeter.ThresholdUpper

					Do tWidget.dataProperties.Insert(tDataProp)
				}


				/// are there more items?
				Set tItem = $O(tInfo(tGroup,""))
				While (tItem'="") {
					Set tMeter = tInfo(tGroup,tItem)
				
					Set tDataProp = ##class(%DeepSee.Dashboard.DataProperty).%New()
					// strip off {instance}
					Set tDataProp.dataValue = tMeter.Property
					Set tDataProp.label = $Replace(tMeter.Label,"{Instance}","")

					If (tMeter.%IsA("CSPX.Dashboard.FuelGauge")) {
						Set tDataProp.subtype = "fuelGauge"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.Smiley")) {
						Set tDataProp.subtype = "smiley"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.LightBar")) {
						Set tDataProp.subtype = "lightBar"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.TrafficLight")) {
						Set tDataProp.subtype = "trafficLight"
					}
					ElseIf (tMeter.%IsA("CSPX.Dashboard.Odometer")) {
						Set tDataProp.subtype = "textMeter"
					}
					Else {
						Set tDataProp.subtype = ""
					}

					Set tDataProp.rangeLower = tMeter.RangeLower
					Set tDataProp.rangeUpper = tMeter.RangeUpper
					Set tDataProp.thresholdLower = tMeter.ThresholdLower
					Set tDataProp.thresholdUpper = tMeter.ThresholdUpper

					Do tWidget.dataProperties.Insert(tDataProp)

					Set tItem = $O(tInfo(tGroup,tItem))
				}
			}
			Set tGroup = $O(tInfo(tGroup))
		}

		Set tNewDB.fullName = pNewName
		Set tSC = tNewDB.%Save()

	} Catch {
		Set tSC = $$$SystemError
	}
	
	If (pVerbose) {
		If $$$ISERR(tSC) {
			Do $System.Status.DisplayError(tSC)
		} Else {
			Write !,"Converted dashboard class '"_pDashboardClass_"' to DeepSee Folder Item '"_tNewDB.documentName_"'."
		}
	}
	Quit tSC
}

/// Process a list of meters in the dashboard definition.
ClassMethod %ProcessList(ByRef pInfo, pList As %AbstractList, ByRef pLastMeter, pLevel As %Integer, pVerbose As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		For n = 1:1:pList.Count() {
			Set tMeter = pList.GetAt(n)
			If $IsObject(tMeter) {
				Set tSC = ..%ProcessMeter(.pInfo, tMeter,.pLastMeter,pVerbose)
				If $$$ISERR(tSC) Quit

				If (tMeter.%IsA("CSPX.Dashboard.Group")) {
					Set tSC = ..%ProcessList(.pInfo,tMeter.Meters,.pLastMeter,pLevel+1,pVerbose)
					If $$$ISERR(tSC) Quit
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add one meter to the process list; place into correct grouping.
ClassMethod %ProcessMeter(ByRef pInfo, pMeter As CSPX.Dashboard.Meter, ByRef pLastMeter As CSPX.Dashboard.Meter, pVerbose As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If (pMeter.%IsA("CSPX.Dashboard.Spacer"))||(pMeter.%IsA("CSPX.Dashboard.TickerTape")) {
			// ignore
			Quit
		}

		If (pMeter.%IsA("CSPX.Dashboard.Group")) {
			// start new grouping
			Set g = $I(pInfo)
			Set pInfo(pInfo) = pMeter
			Quit
		}
		ElseIf (pMeter.%IsA("CSPX.Dashboard.Chart")) {
			// start new grouping and add this item
			Set g = $I(pInfo)
			Set pInfo(pInfo) = $G(pInfo(pInfo-1))
		}
		ElseIf $$$IsdefObject(pLastMeter) {
			If (pLastMeter.%IsA("CSPX.Dashboard.Chart")) {
				// start new grouping and add the current item
				Set g = $I(pInfo)
				Set pInfo(pInfo) = $G(pInfo(pInfo-1))
			}
			ElseIf (pLastMeter.Metric '= pMeter.Metric) {
				// start new grouping and add the current item
				Set g = $I(pInfo)
				Set pInfo(pInfo) = $G(pInfo(pInfo-1))
			}
		}
		Set idx = $I(pInfo(pInfo))
		Set pInfo(pInfo,idx) = pMeter
		
		Set pLastMeter = pMeter
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
