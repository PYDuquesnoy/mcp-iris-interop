/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class lets an Business Metric act as a DeepSee KPI and drive DeepSee dashboards.
/// This class is for internal InterSystems use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class Ens.BusinessMetricKPI Extends %DeepSee.AbstractKPI [ System = 4 ]
{

/// Return the logical name for this KPI.
ClassMethod %GetKPIName() As %String
{
	Quit "Business Metric KPI"
}

/// Return the caption as defined in the XML for this KPI.
ClassMethod %GetKPICaptionName() As %String
{
	Quit "Business Metric KPI"
}

/// Add additional properties beyond those defined in the KPI block.
/// This takes the form:<br/>
/// pList(n) = name<br/>
/// pList(n,"defaultValue") = value<br/>
/// pList(n,"columnNo") = #<br/>
/// <var>pPropNo</var> is the number of next open slot in the list.
ClassMethod %OnGetKPIPropertyInfo(ByRef pList As %String, pPropNo As %Integer, pDataSourceName As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// pModelId should contain the "datasource" name;
		// this takes the form "Production/HostName.metric"
		If (pDataSourceName'="") {
			// get property list from metric class
			Set tMetricClass = ..%GetBusinessMetricClass(pDataSourceName)
			If (tMetricClass'="") {
				Set tSC = $classmethod(tMetricClass,"%GetPropertyInfo",.tInfo)
			}
			Set k=""  For { Set k=$O(tInfo(k))  Quit:k=""
				Set pList(pPropNo) = k
				Set pPropNo = pPropNo + 1
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
		// Get current instance name from filter
		Set tProps = $$stripWhite(..%filterValues.Properties)  Set:""'=tProps tProps = ","_tProps_","
		Set tMaxHist = ..%filterValues.MaxHistory
		Set tInstances = $$stripWhite(..%filterValues.Instances)  Set:""'=tInstances tInstances = ","_$ZCVT(tInstances,"U")_","

		// %id holds the actual BusinessMetric name
		If (..%id'="") {
			// we only return values if we are connected to the current production
			Set tMetricClass = ..%GetBusinessMetricClass(..%id,.tProduction,.tHostName)
			If (tProduction = ##class(EnsPortal.Utils).GetCurrentProductionName()) {
				// get series (instance) names
				If (tMetricClass'="") {
					Set tSC = $classmethod(tMetricClass,"GetInstances",.tInstSet)
				}
				// get property list from metric class
				If '$D(tInstSet) {
					Set ..%seriesCount = 1
					Set ..%seriesNames(1) = 1
				} Else {
					// if there is an instance filter, then only return series in it
					Set ..%seriesCount = 0
					Set n=""  For { Set n=$O(tInstSet(n),1,tName)  Quit:n=""
						If ((tInstances="") || (tInstances [ (","_$ZCVT(tName,"U")_","))) {
							Set ..%seriesCount = ..%seriesCount + 1
							Set ..%seriesNames(..%seriesCount) = tName
						}
					}
				}
				// get values from metric global
				Merge tData = $$$EnsMetrics(tHostName)

				// Either we can get multiple history values for one Series (aka Instance) or one value for multiple series
				#; assume all properties are in the global
				For n=1:1:..%seriesCount {
					If +$G(tData(..%seriesNames(n),"%IsRunning")) {
						Set tMaxHFound=1, tMinHFound=100001
						Set tPropName=""  For { Set tPropName=$O(tData(..%seriesNames(n),tPropName),1,tVal)  Quit:tPropName=""
							Continue:((tProps'="") && (tProps '[ (","_tPropName_",")))
							If ..%seriesCount>1 {
								Set ..%data(n,tPropName) = tVal ; set inst n from that instance's top node
							} Else {
								Set ..%data(1,tPropName) = tVal ; set hist pos 1 from the top node
								Set tHistPos=$O(tData(..%seriesNames(n),tPropName,""),-1,tVal) ; skip the first hist pos because we got it from the top node
								Continue:""=tHistPos
								$$$ASSERT(tVal=..%data(1,tPropName))
								Set:""=tMaxHist tMaxHist=100000
								For h=2:1:tMaxHist { Set tHistPos=$O(tData(..%seriesNames(n),tPropName,tHistPos),-1,tVal)  Quit:tHistPos=""
									Set ..%data(h,tPropName) = tVal ; set the rest of the history positions for this property
								} Set:tHistPos="" h=h-1
								Set:h>tMaxHFound tMaxHFound=h
								Set:h<tMinHFound tMinHFound=h
								Set:h=2 tHasHist(tPropName)=1
							}
						}
						If (..%seriesCount=1) && (tMaxHFound>1) {
							#; Flip the history data
							For h=1:1:tMaxHFound\2 {
								Merge tTemp=..%data(h)                   Kill ..%data(h)
								Merge ..%data(h)=..%data(tMaxHFound+1-h) Kill ..%data(tMaxHFound+1-h)
								Merge ..%data(tMaxHFound+1-h)=tTemp      Kill tTemp
							}
							#; If uneven history lengths backfill with empty-string values / un-flip the scalar ones
							Set tPropName=""  For { Set tPropName=$O(tData(..%seriesNames(n),tPropName))  Quit:tPropName=""
								Continue:((tProps'="") && (tProps '[ (","_tPropName_",")))
								For h=1:1:tMaxHFound-tMinHFound {
									If '$D(..%data(h,tPropName)) {
										If h=1 &&'$G(tHasHist(tPropName)) {
											Set ..%data(h,tPropName) = $G(..%data(tMaxHFound,tPropName))
											Set ..%data(tMaxHFound,tPropName) = ""
										} Else {
											Set ..%data(h,tPropName) = ""
										}
									}
								}
							}
							Set ..%seriesCount=tMaxHFound
							For inew=1:1:tMaxHFound { Set ..%seriesNames(inew)=inew }
						}
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
stripWhite(namstr)
	#; take off leading and trailing curly brackets
	Set:"{"=$E($ZStrip(namstr,"<W"),1) namstr=$E($ZStrip(namstr,"<W"),2,*)
	Set:"}"=$E($ZStrip(namstr,">W"),*) namstr=$E($ZStrip(namstr,">W"),1,*-1)

	#; strip whitespace between items but not within them
	Set namstrout="", ich=$L(namstr,",")
	For ich=ich:-1:1 { Set nampc=$ZStrip($P(namstr,",",ich),"<>W") Continue:""=nampc
		Set namstrout=nampc_$S(""=namstrout:"",1:","_namstrout)
	}
	Quit namstrout
}

/// Return list of all known Business Metrics in this namespace.
ClassMethod %GetBusinessMetricList(Output pList) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		#; Enumerate all config items in the given Production whose class is derived from Ens.BusinessMetric
		Kill %objlasterror
		Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateConfigItemNames")
		If '$IsObject(tRS) {
			Set tSC = $$$ERROR($$$EnsErrGeneral,"Failed to create ResultSet for query Ens.Config.Production:EnumerateConfigItemNames : "_$$$StatusDisplayString($G(%objlasterror)))
			Quit
		}
		Do tRS.Execute("","Ens.BusinessMetric")
		While (tRS.Next(.tSC) && $$$ISOK(tSC)) {
			Set tProduction = tRS.Data("Production")
			Set tHost = tRS.Data("ConfigName")

			// attach production name to host name
			Set tMetricName = tProduction _ "/" _ tHost
			Set pList(tMetricName) = $LB(tMetricName,tHost,"","metric")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a full name (production/host.metric) for a Business Metric, return the class name that implements it.
ClassMethod %GetBusinessMetricClass(pDataSourceName As %String, Output pProductionName As %String, Output pHostName As %String) As %String [ Final ]
{
	Set tSC = $$$OK
	Set tClassname = ""
	Try {
		Set tFullName = $P(pDataSourceName,".",1,$L(pDataSourceName,".")-1)
		Set tFullName = $P(tFullName,"/")_"||"_$P(tFullName,"/",2,$L(tFullName,"/"))
		Do ##class(Ens.Director).ParseConfigItemName(tFullName,.pProductionName,.pHostName)
		&sql(DECLARE C1 CURSOR FOR
			SELECT ClassName
				INTO :tClassname
				FROM Ens_Config.Item 
				WHERE Production = :pProductionName AND Name = :pHostName
			)
		&sql(OPEN C1)
		For i=1:1 { &sql(FETCH C1)  Quit:SQLCODE
			try {
				If '$classmethod(tClassname,"%Extends","Ens.BusinessMetric") {
					Set tClassname = ""
				}
			} catch {
				Set tClassname = ""
			}
			Quit:""'=tClassname
		} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
		Set:SQLCODE tClassname = ""
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tClassname = ""
	}
	Quit tClassname
}

/// Callback to get additional actions for a KPI.
/// This takes the form:<br/>
/// pActions($I(pActions))=$LB(name,caption)<br/>
ClassMethod %OnGetActionList(ByRef pActions As %List, pDataSourceName As %String = "") As %Status
{
	Set tSC = $$$OK
	Set tMetricClass = ..%GetBusinessMetricClass(pDataSourceName,,.tHostName)

	// get action list from metric class
	If (tMetricClass'="") {
		Set tSC = $classmethod(tMetricClass,"%OnGetActionList",.pActions,tHostName)
	}
	Quit tSC
}

/// This callback is invoked from a dashboard when an action defined by this dashboard is invoked.<br/>
/// <var>pAction</var> is the logical name of the action.<br/>
/// <var>pContext</var> is a proxy object that contains various information about the action and
/// provides a way for the method to return information to the client.
ClassMethod %OnDashboardAction(pAction As %String, pContext As %ZEN.proxyObject, pDataSourceName As %String = "") As %Status
{
	Set tSC = $$$OK
	Set tMetricClass = ..%GetBusinessMetricClass(pDataSourceName,,.tHostName)

	// dispatch to metric class
	If (tMetricClass'="") {
		Set tSC = $classmethod(tMetricClass,"%OnDashboardAction",pAction,pContext,tHostName)
	}
	Quit tSC
}

/// Callback to get additional possible filters for this KPI.
/// This drives the list of filter selections for widget connected to this KPI.
/// This takes the form:<br/>
/// pFilters($I(pFilters))=$LB(name,caption,value,multiSelect)<br/>
ClassMethod %OnGetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status
{
	Set pFilters($I(pFilters))=$LB("Instances","Instances","",0)
	Set pFilters($I(pFilters))=$LB("MaxHistory","MaxHistory","",0)
	Set pFilters($I(pFilters))=$LB("Properties","Properties","",1)
	Quit $$$OK
}

/// Callback to get additional members for a KPI filter.
/// This takes the form:<br/>
/// pMembers($I(pMembers))=$LB(text,value)<br/>
/// <var>pSearchKey</var> is the search key entered by the user, if applicable.
ClassMethod %OnGetFilterMembers(pFilter As %String, Output pMembers As %List, pSearchKey As %String = "", pDataSourceName As %String = "") As %Status
{
	Set tMetricClass = ..%GetBusinessMetricClass(pDataSourceName)
	If pFilter="Instances" {
		#; Add members for Instances filter - get series (instance) names
		If (tMetricClass'="") {
			Set tSearchKeyU=$ZCVT(pSearchKey,"U")
			Set tSC = $classmethod(tMetricClass,"GetInstances",.tInstSet)
			Set n=""  For { Set n=$O(tInstSet(n),1,tName)  Quit:n=""
				If (pSearchKey="")||($ZCVT(tName,"U")[tSearchKeyU) {
					Set pMembers($I(pMembers))=$LB(tName,tName)
				}
			}
		}
	} ElseIf pFilter="MaxHistory" {
		#; Add members for MaxHistory filter
		Set pMembers($I(pMembers))=$LB(5,5)
		Set pMembers($I(pMembers))=$LB(10,10)
		Set pMembers($I(pMembers))=$LB(30,30)
		Set pMembers($I(pMembers))=$LB(50,50)
		Set pMembers($I(pMembers))=$LB(100,100)
	} ElseIf pFilter="Properties" && ("" '= tMetricClass) {
		#; Add members for Properties filter
		Set tClassDef=##class(%Dictionary.ClassDefinition).%OpenId(tMetricClass)
		Set tProperty=""  For { Set tProp=tClassDef.Properties.GetNext(.tProperty)  Quit:tProperty=""
			Set pMembers($I(pMembers))=$LB(tProp.Name,tProp.Name)
		}
	}
	Quit $$$OK
}

}
