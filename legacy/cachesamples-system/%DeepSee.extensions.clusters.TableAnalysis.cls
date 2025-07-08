/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.extensions.clusters.TableAnalysis Extends (%ZEN.Component.page, %DeepSee.extensions.clusters.DataController, %DeepSee.extensions.clusters.ChartModel) [ System = 4 ]
{

/// Application this page belongs to.
Parameter APPLICATION = "%DeepSee.extensions.clusters.ZenApplication";

Parameter SPECIALVALUES = 0;

Parameter PAGENAME = "Clusters";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal";

/// Measure to use for analysis.
Property propNameX As %ZEN.Datatype.string;

/// Measure to use for analysis.
Property propNameY As %ZEN.Datatype.string;

Property className As %ZEN.Datatype.string;

Property schemaName As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

#objectInspector {
	border: 1px solid darkblue;
	height: 400px;
	width: 400px;
	overflow: auto;
}

</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="Cluster Analysis for SQL Table">
<hgroup>
<spacer width="5"/>
<vgroup>
<spacer height="2"/>
<pane paneName="tableSelectPane"/>
<spacer height="5"/>
<pane paneName="tableControlPane"/>
<spacer	height="3"/>
<pane paneName="clusteringOptions"/>
<spacer	height="3"/>
<pane paneName="status1Pane"/>
<spacer height="2"/>
<pane paneName="status2Pane"/>

<svgFrame id="svg" backgroundStyle="fill:#D0D0D0;"  height="600" width="800">
<bubbleChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	backgroundStyle="fill: url(#glow-blue);"
	title="Clusters"
	radius="0.75"
	seriesSize="1000"
	seriesCount="9"
	plotStyle="stroke-width: 0px;"
	plotAreaStyle="fill:url(#glow-silverDiag);"
	titleStyle="fill:white;"
	labelStyle="fill:white;"
	width="800" 
	height="600">
<xAxis id="xAxis" />
<yAxis id="yAxis"
	baseValue=""
	minValue="" 
	maxValue="" 
	majorUnits=""
	minorUnits=""
	minorGridLines="true"/>
</bubbleChart>

</svgFrame>
</vgroup>
</hgroup>
</page>
}

XData tableSelectPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup>
<select id="schemas" label="Schema: " 
queryClass="%DeepSee.extensions.clusters.TableAnalysis" queryName="Schemas" showEmpty="true"
onchange="zenPage.schemaChanged()"/>
<spacer width="20"/>
<select id="tables" label="Class: " 
showEmpty="true"
onchange="zenPage.tableChanged()"/>
</hgroup>
</pane>
}

ClientMethod onYRefresh() [ Language = javascript ]
{
	alert("onYRefresh");
	zen('columnY').setValue(this.propNameY);
}

ClientMethod getChartData(series) [ Language = javascript ]
{
	var data = zenPage.getData(series);
	//alert(series + ": " + data);
	return data
}

ClientMethod schemaChanged() [ Language = javascript ]
{
	var err = zenPage.OnSelectSchema();
	zenPage.alertIfError(err);
}

ClientMethod tableChanged() [ Language = javascript ]
{
	this.datasetHasChanged = 1;
	var err = zenPage.OnSelectClass();
	zenPage.alertIfError(err);
	zen('controlBar').refreshContents(true);
	err = zenPage.RestoreDefaults();
	zenPage.alertIfError(err);
}

ClientMethod datasetChanged() [ Language = javascript ]
{
	this.datasetHasChanged = 1;
}

ClientMethod run() [ Language = javascript ]
{
	zenPage.setParameters();
	var confirm = zenPage.checkParameters ();
	if (!confirm)
		return;
	
	//var select = zen('columnY');
	//alert(select.valueList +": " + this.propNameY + "/" + select.getValue());
	
	zen('chart').beginWaitState();
	var sc = zenPage.RunAndUpdate();
	zen('chart').endWaitState();
	zenPage.alertIfError(sc);
	zen('chart').updateChart();
}

ClientMethod axisChanged() [ Language = javascript ]
{
	zen('chart').beginWaitState();
	this.propNameX = zen('columnX').getValue();
	this.propNameY = zen('columnY').getValue();
	//alert("axisChanged: " + this.propNameY);
	var sc = zenPage.UpdateView();
	zen('chart').endWaitState();
	zenPage.alertIfError(sc);
	zen('chart').updateChart();
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);

	var winHeight = zenGetWindowHeight();
	var winWidth = zenGetWindowWidth();

	var svg = zen('svg');

	// adjust size of svg frame
	var svgWid = winWidth - 25;
	var svgHgt = winHeight - 200;
	svg.setProperty("width",svgWid+'px');
	svg.setProperty("height",svgHgt+'px');

	// adjust chart
	var chart = zen('chart');
	if (chart) {
		chart.setProperty("width",svgWid);
		chart.setProperty("height",svgHgt);
	}
}

Method OnSelectSchema() As %ZEN.proxyObject [ ZenMethod ]
{
	#dim ex As %Exception.AbstractException
	#dim tSC = $$$OK
	#dim tSelect As %ZEN.Component.select
	#dim tValueList, className As %String

	Try{
		Set tSelect = ..%GetComponentById("schemas")
		set ..schemaName = tSelect.value

		Set tSC = ..%OnChangeSchema()	
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit ..ErrObj(tSC)
}

Method OnSelectClass() As %ZEN.proxyObject [ ZenMethod ]
{
	#dim ex As %Exception.AbstractException
	#dim tSC = $$$OK
	#dim tSelect As %ZEN.Component.select
	#dim tValueList, className As %String

	Try{
		Set tSelect = ..%GetComponentById("tables")
		Set ..className = tSelect.value
		
		Set tSC = ..%OnSelectClass()
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit ..ErrObj(tSC)
}

Method RunAndUpdate() As %ZEN.proxyObject [ ZenMethod ]
{
	#dim sc As %Status
	
	set ..Dataset = ..className_"||Extent"
	
	Set sc = ..%UpdateAll()

	Quit ..ErrObj(sc)
}

Method %OnChangeSchema() As %Status
{
	#dim ex As %Exception.AbstractException
	#dim tSC = $$$OK
	#dim tSelect As %ZEN.Component.select
	#dim tValueList, className As %String

	Try{
		Set rset = ##class(%ResultSet).%New()
		Set rset.ClassName = "%SQL.Manager.Catalog"
		Set rset.QueryName = "Tables"
		
		Set tSelect = ..%GetComponentById("tables")
		Set tSelect.disabled = 0
		
		Set tSC = rset.Execute(..schemaName)
		Quit:$$$ISERR(tSC)
		
		Set tValueList = ""
		While (rset.Next()) {
			Set className = rset.Get("CLASSNAME")
			Continue:className=""
			
			if (tValueList="") {
				set tValueList = className
			} else {
				set tValueList = tValueList_","_className
			}
		}
		d rset.Close()
		
		Set tSelect.valueList = tValueList
		set tSelect.value = ..className
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

Method %OnAfterCreatePage() As %Status
{
	#dim tSC = $$$OK
	#dim tSelect As %ZEN.Component.select
	#dim tMSelect As %ZEN.Component.multiSelectSet
	#dim ex As %Exception.AbstractException
	#dim k,m As %Integer
	#dim properties As %String
	
	Try {
		Set ..className   = $G($$$DeepSeeChartsGLVN("SQLAnalyzer","lastClass"))
		if (..className'="") {
			set classDef = ##class(%Dictionary.CompiledClass).%OpenId(..className,-1,tSC)
			Quit:$$$ISERR(tSC)
			
			Set ..schemaName = classDef.SqlSchemaName
			Set tSelect = ..%GetComponentById("schemas")
			Set tSelect.value = ..schemaName
			
			Set tSC = ..%OnChangeSchema()	
			Quit:$$$ISERR(tSC)

			set tSC = ..%OnSelectClass()
			Quit:$$$ISERR(tSC)
			
			Do ..RestoreDefaults()
		} else {
			Set tMSelect = ..%GetComponentById("columns")
			Set tMSelect.disabled = 1
			Set tSelect = ..%GetComponentById("columnX")
			Set tSelect.disabled = 1
			Set tSelect = ..%GetComponentById("columnY")
			Set tSelect.disabled = 1
			Set tSelect = ..%GetComponentById("tables")
			Set tSelect.disabled = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method %OnSelectClass() As %Status
{
	#dim tSC = $$$OK
	#dim tSelect As %ZEN.Component.select
	#dim tMSelect As %ZEN.Component.multiSelectSet
	#dim tChart As %ZEN.SVGComponent.chart
	#dim tValueList, tDisplayList As %String
	#dim tPropXFound, tPropYFound, tMCount As %Integer
	#dim ex As %Exception.AbstractException
	#dim i,k,m,n As %Integer
	#dim properties, column, pattern As %String
	#dim propDef As %Dictionary.CompiledProperty
	
	Try {
		If (..className="") Quit

		Set ..Dataset = ..className_"||Extent"
		Set $$$DeepSeeChartsGLVN("SQLAnalyzer","lastClass") = ..className
		
		Set ..propNameX = $G($$$DeepSeeChartsGLVN(..className,"column","X"))
		Set ..propNameY = $G($$$DeepSeeChartsGLVN(..className,"column","Y"))
		Set ..sampleSize  = $G($$$DeepSeeChartsGLVN(..className,"clustering","sampleSize"), 75)
		Set ..NClusters   = $G($$$DeepSeeChartsGLVN(..className,"clustering","NCL"), 3)

		Set tChart = ..%GetComponentById("chart")

		Set tMCount = 0
		Set tPropXFound = 0
		Set tPropYFound = 0
		Set tValueList = ""
		Set tDisplayList = ""
		
		set classDef = ##class(%Dictionary.CompiledClass).%OpenId(..className,-1,tSC)
		Quit:$$$ISERR(tSC)

		if (..%GetComponentById("propPatternCheck").value = 1) {
			set pattern = ..%GetComponentById("propPattern").value
		} else {
			set pattern = ""
		}
		set n = classDef.Properties.Count()
		for i=1:1:n {
			#dim tName, tType   As %String

			Set propDef = classDef.Properties.GetAt(i)
			Set tName    	= propDef.Name

			Continue:propDef.Private
			Continue:propDef.Transient
			
			set column = propDef.SqlFieldName
			
			Continue:column=""
			if (pattern '= "") {
				if ('$match(column,pattern)) {
					Continue
				}
			}
			
			set tType = propDef.Type
			//if ('$zobjclassmethod(tType,"%IsA","%Library.Datatype")) {
			
			Set tTypeDef = ##class(%Dictionary.CompiledClass).%OpenId(tType,-1,tSC)
			Quit:$$$ISERR(tSC)
			if (tTypeDef.ClassType'="datatype") {
				Continue
			}
			
			Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ tName
			Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ column
			
			Set tMCount = tMCount + 1
			If (..propNameX = column) {
				Set tPropXFound = tMCount
			}
			If (..propNameY = column) {
				Set tPropYFound = tMCount
			}
		}

		Set tMSelect = ..%GetComponentById("columns")
		Set tMSelect.disabled = 0
		Set tMSelect.valueList = tValueList
		Set tMSelect.displayList = tDisplayList
		
		Set tSelect = ..%GetComponentById("columnX")
		Set tSelect.disabled = 0
		Set tSelect.valueList = tDisplayList // We need property name (not column name here)
		Set tSelect.displayList = tDisplayList
		Set:tPropXFound=0 ..propNameX = $p(tValueList, ",", 1)

		Set tSelect = ..%GetComponentById("columnY")
		Set tSelect.disabled = 0
		Set tSelect.valueList = tDisplayList // We need property name (not column name here)
		Set tSelect.displayList = tDisplayList
		Set:tPropYFound=0 ..propNameY = $p(tValueList, ",", 2)
		Set:..propNameY="" ..propNameY = ..propNameX

		If (tMCount=0) {
			Set tChart.title = $$$Text("There are no properties to analyze")
		}

		set ..dsCount = ..%EstimateCount(.tSC)
		Set ..%GetComponentById("itemCount").value = $FN(..dsCount,",",0)

		set tSelect = ..%GetComponentById("sample")
		set tSelect.value = ..sampleSize
		set tSelect = ..%GetComponentById("ncl")
		set tSelect.value = ..NClusters
		set tSelect = ..%GetComponentById("method")
		if (..dsCount<300) {
			set tSelect.value = "PAM/SA"
			set ..%GetComponentById("sample").disabled = 1
		} else {
			set tSelect.value = "CLARA"
			set ..%GetComponentById("sample").disabled = 0
		}
		
		set ..XMin = ""
		set ..XMax = ""
		set ..YMin = ""
		set ..YMax = ""

		set tSC = ..%Init()
		Quit:$$$ISERR(tSC)

		d ..%ClearStatusInfo()
		set tSC = ..%UpdateControls()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method RestoreDefaults() As %ZEN.proxyObject [ ZenMethod ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tSelect As %ZEN.Component.select
	#dim tMSelect As %ZEN.Component.multiSelectSet
	#dim tValueList, tDisplayList, properties As %String

	Try {
		Set tMSelect = ..%GetComponentById("columns")
		set tValueList   = tMSelect.valueList
		set tDisplayList = tMSelect.displayList
		
		Set properties = $G($$$DeepSeeChartsGLVN(..className,"clustering","columns"),tValueList)
		set tMSelect.value = properties
		
		$$$Trace(2,"clustering:"_..Dataset_":dimensions:all",tValueList)
		$$$Trace(2,"clustering:"_..Dataset_":dimensions:selected",tMSelect.value)
	
		Set tSelect = ..%GetComponentById("columnX")
		Set tSelect.value = ..propNameX
		Set tSelect = ..%GetComponentById("columnY")
		Set tSelect.value = ..propNameY
}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit ..ErrObj(tSC)
}

/// Update value of controls.
Method %UpdateControls() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim select As %ZEN.Component.select
	#dim chart As %ZEN.SVGComponent.chart
	#dim status As %ZEN.Component.label
	#dim ncl As %Integer

	set chart = ..%GetComponentById("chart")

	Set ..%GetComponentById("itemCount").value = $FN(..dsCount,",",0)
	//Set ..%GetComponentById("nullCount").value = $FN(..DSNullCount,",",0)
	
	set ncl = ..%GetCurrentNCL()
	if (ncl > 0) {
		set select = ..%GetComponentById("ncl")
		set select.value = ncl
	}

	Quit:chart="" tSC

	if ((..Ready=0) || (..NClusters=0)) {
		set:chart'="" chart.seriesCount = 1
		set:chart'="" chart.seriesSize = 0
	} else {
		set chart.seriesSize = ..%GetSeriesSize()
		set chart.seriesCount = 4 // (..NClusters) * 2
	}
	
	set status = ..%GetComponentById("minValue")
	set status.value = ..%Round(..XMin)
	set status = ..%GetComponentById("maxValue")
	set status.value = ..%Round(..XMax)
	
	set status = ..%GetComponentById("minYValue")
	set status.value = ..%Round(..YMin)
	set status = ..%GetComponentById("maxYValue")
	set status.value = ..%Round(..YMax)

	Quit tSC
}

Method %UpdateStatusInfo() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim status As %ZEN.Component.label
	#dim msg As %String
	#dim asw, r, ch, cost As %Double
	#dim model As %DeepSee.extensions.clusters.PAM

	set status = ..%GetComponentById("status")

	set model = ##class(%DeepSee.extensions.clusters.PAM).Open(..Dataset, .tSC)
	Quit:$$$ISERR(tSC) tSC
	set model.Normalize = ..Normalize
	
	if (..sampling) {
		set r = model.GetPearsonGammaIndex().calculateForSample(..sampleSize,.tSC)
		Quit:$$$ISERR(tSC) tSC
		set asw = model.GetASWIndex().calculateForSample(..sampleSize,.tSC)
		Quit:$$$ISERR(tSC) tSC
	} else {
		set asw = model.GetASWIndex().calculate(.tSC)
		Quit:$$$ISERR(tSC) tSC
		set r = model.GetPearsonGammaIndex().calculate(.tSC)
		Quit:$$$ISERR(tSC) tSC
		set ch = model.GetCalinskiHarabaszIndex().calculate(.tSC)
		Quit:$$$ISERR(tSC) tSC
	}
	set cost = model.TotalCost()

	set msg = "Total Cost: "_$fn(cost,"",2)
	set msg = msg_". Validity Indices: "
	set msg = msg_"Average Silhouette Width (ASW) = "_$fn(asw,"",3)_"; "
	if ('..sampling) {
		set msg = msg_"Calinski-Harabasz (CH) = "_$fn(ch,"",2)_"; "
	}
	set msg = msg_"PearsonGamma = "_$fn(r,"",3)
	set status.value = msg
	
	Quit tSC
}

Method %ClearStatusInfo() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim status As %ZEN.Component.label

	set status = ..%GetComponentById("status")

	set status.value = ""
	
	Quit tSC
}

Method %SetModelData() As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tInput, tResponse, tYmax, tYmin As %Float
	#dim model As %DeepSee.extensions.clusters.AbstractModel
	#dim tSelect As %ZEN.Component.multiSelectSet
	#dim tMaxRows, dim, i As %Integer
	#dim columns, sql, table As %String

	Try {
		Set ..dsCount = 0
		
		Set tSelect = ..%GetComponentById("columns")
		Set columns = tSelect.value
		if (columns="") {
			Set tSC = $$$ERROR($$$GeneralError,"No properties are included!")
			Quit
		}
		set $$$DeepSeeChartsGLVN(..className,"clustering","columns") = columns
		
		set classDef = ##class(%Dictionary.CompiledClass).%OpenId(..className,-1,tSC)
		If $$$ISERR(tSC) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid Class: "_..className)
			Quit
		}
		
		set table = classDef.SqlSchemaName_"."_classDef.SqlTableName
		if (table="") {
			Set tSC = $$$ERROR($$$GeneralError,"No SQL Table for class: "_..className)
			Quit
		}

		set dim = $l(columns,",")

		$$$Trace(2,"clustering:ds",..Dataset)
		$$$Trace(2,"clustering:"_..Dataset_":columns",columns)
		$$$Trace(2,"clustering:"_..Dataset_":dim",dim)
		
		// use SQL result set to get answers
		
		set sql = "select %ID, "_columns_" from "_table
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set tSC = rs.Prepare(sql)
		Quit:$$$ISERR(tSC)
		set tSC = rs.Execute()
		Quit:$$$ISERR(tSC)

		set tSC = ##class(%DeepSee.extensions.clusters.AbstractModel).Delete(..Dataset)
		set model = ##class(%DeepSee.extensions.clusters.PAM).New(..Dataset,tSC)
		
		set tSC = model.SetData(rs, dim)
		
		set ..dsCount = model.GetCount()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %SetClusteringParameters() As %Status
{
	#dim sc As %Status = $$$OK
	#dim k As %Integer

	set ..sampling = 0
	if (..method="CLARA") {
		set $$$DeepSeeChartsGLVN(..className,"clustering","sampleSize") = ..sampleSize
		set ..sampling = 1
	}

	set $$$DeepSeeChartsGLVN(..className,"clustering","NCL") = ..NClusters

	Quit sc
}

Method %ComputeValues() As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim model As %DeepSee.extensions.clusters.AbstractModel
	#dim nk, k, i, n As %Integer
	#dim max As %Integer = 1200
	#dim random as %Boolean
	#dim id As %String
	#dim xv, yv
	#dim fact
	
	Try {

		If (..Dataset = "") {
			Quit
		}

		do ..%ClearDataset()
		set model = ##class(%DeepSee.extensions.clusters.PAM).Open(..Dataset,.tSC)
		Quit:$$$ISERR(tSC)

		$$$Trace(2,"clustering:"_..Dataset_":x",..propNameX)
		$$$Trace(2,"clustering:"_..Dataset_":y",..propNameY)
		set nk = ..%GetCurrentNCL()
	
		set n = model.GetCount()
		set random = (n > max)
	
		set ..XMin = ""
		set ..XMax = ""
		set ..YMin = ""
		set ..YMax = ""
		for k = 1:1:nk {
			#dim count As %Integer = 0
		
			set i = ""
			While(1) {
				do model.iterateCluster(k, .i, .id)
				Quit:i=""
				if (random) {
					Continue:($r(n)>max)
				}
				set count = $i(count)
			
				set fact = $zobjclassmethod(..className, "%OpenId", id)
				set xv = $zobjproperty(fact, ..propNameX)
				if (..#SPECIALVALUES) {
					set tSC = ..%OnGetValue(.xv, ..className, ..propNameX)
					Quit:$$$ISERR(tSC)
				}
				set yv = $zobjproperty(fact, ..propNameY)
				if (..#SPECIALVALUES) {
					set tSC = ..%OnGetValue(.yv, ..className, ..propNameY)
					Quit:$$$ISERR(tSC)
				}
				
				if ((..XMin = "") || (xv < ..XMin)){
					set ..XMin = xv
				}
				if ((..XMax = "") || (xv > ..XMax)){
					set ..XMax = xv
				}
				if ((..YMin = "") || (yv < ..YMin)){
					set ..YMin = yv
				}
				if ((..YMax = "") || (yv > ..YMax)){
					set ..YMax = yv
				}
					
				do ..%InsertDataPoint(k, xv, yv)
			}
		
			$$$Trace(2,"clustering:"_..Dataset_":Count:"_k,count)
		}

		Set $$$DeepSeeChartsGLVN(..className,"column","X") = ..propNameX
		Set $$$DeepSeeChartsGLVN(..className,"column","Y") = ..propNameY
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %EstimateCount(Output pSC As %Status) As %Integer
{
	#dim ex As %Exception.AbstractException
	#dim count as %Integer = 0
	#dim table, sql As %String

	Try {
		set classDef = ##class(%Dictionary.CompiledClass).%OpenId(..className,-1,pSC)
		Quit:$$$ISERR(pSC)
		
		set table = classDef.SqlSchemaName_"."_classDef.SqlTableName
		Quit:$$$ISERR(pSC)
		
		// use SQL result set to get answers
		
		set sql = "select count(%ID) from "_table
		set rs = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set pSC = rs.Prepare(sql)
		Quit:$$$ISERR(pSC)
		set pSC = rs.Execute()
		Quit:$$$ISERR(pSC)
		
		do rs.%Next()
		set count = rs.%GetData(1)

	} Catch(ex) {
		Set pSC = ex.AsStatus()
	}
	
	$$$Trace(1,"clustering:"_..Dataset_":%Count",count)
	Quit count
}

Query Schemas(system As %Library.Boolean = 0) As %Library.Query(ROWSPEC = "SCHEMA_NAME:%Library.String") [ SqlName = Schemas, SqlProc ]
{
}

ClassMethod SchemasExecute(ByRef %q As %Library.Binary, system As %Library.Boolean = 0) As %Library.Status [ ProcedureBlock = 1 ]
{
	Quit ##class(%SQL.Manager.Catalog).SchemasExecute(.%q, system)
}

ClassMethod SchemasFetch(ByRef %q As %Library.Binary, ByRef Row As %Library.List, ByRef AtEnd As %Library.Integer) As %Library.Status [ ProcedureBlock = 1 ]
{
	Quit ##class(%SQL.Manager.Catalog).SchemasFetch(.%q, .Row, .AtEnd)
}

ClassMethod SchemasClose(ByRef %q As %Library.Binary) As %Library.Status [ ProcedureBlock = 1 ]
{
 	Quit ##class(%SQL.Manager.Catalog).SchemasClose(.%q)
}

Method %OnGetValue(ByRef value, classname As %String, property As %String) As %Status
{
	Quit $$$OK
}

}
