/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.extensions.clusters.ChartModel [ Abstract, System = 4 ]
{

XData clusteringOptions [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup id="hg1">
<spacer width="20"/>
<label label="Algorithm: "/>
<spacer width="10"/>
<select id="method"  valueList="PAM,PAM/SA,CLARA" showEmpty="false" value="PAM/SA" onchange="zenPage.methodChanged();"/>
<spacer width="20"/>
<label label="Sample Size: "/>
<spacer width="10"/>
<select id="sample"  valueList="50,75,100,150,200" showEmpty="false" onchange="zenPage.sampleSizeChanged()"/>
<spacer width="20"/>
<label label="Number of Clusters: "/>
<spacer width="10"/>
<select id="ncl" onchange="zenPage.nclChanged()" showEmpty="false" valueList="2,3,4,5,6,7,8,9" value="3"/>
<spacer width="10"/>
<button id="update" caption="Run" onclick="zenPage.run()"/>
</hgroup>
</pane>
}

XData status1Pane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup>
<label id="itemCount" label="Items:" value=""/>
<spacer width="5"/>
<!--
<label id="nullCount" label="Missing:" value=""/>
-->
<spacer width="10"/>
<label value="X: ["/>
<label id="minValue" value=""/>
<spacer width="1"/>
<label value=";"/>
<label id="maxValue" value=""/>
<label value="]"/>
<spacer width="15"/>
<label value="Y: ["/>
<label id="minYValue" value=""/>
<spacer width="1"/>
<label value=";"/>
<label id="maxYValue" value=""/>
<label value="]"/>
</hgroup>
</pane>
}

XData status2Pane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup cellVAlign="top" labelPosition="left" cellStyle="padding-left:4px;">
<label id="Indices" label="Validation Info: " value="" hidden="true"/>
<spacer width="5"/>
<label id="status"/>
</hgroup>
</pane>
}

XData tableControlPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup id="controlBar" cellVAlign="top" labelPosition="left" cellStyle="padding-left:4px;">
<vgroup>
<label label="Properties To Include in Clustering:"/>
<spacer height="5"/>
<hgroup align="center">
<button caption="All" onclick="zen('columns').selectAll();"/>
<spacer width="20"/>
<button caption="None" onclick="zen('columns').selectNone();"/>
</hgroup>
<spacer height="10"/>
<checkbox id="propPatternCheck" onchange="zen('propPattern').setDisabled(!zen('propPatternCheck').getValue());"
caption="Limit to matching properties"/>
<spacer height="10"/>
<text id="propPattern" size="10" onchange="zenPage.tableChanged();" disabled="true"/>
</vgroup>
<spacer width="5"/>
<multiSelectSet id="columns" onchange="zenPage.datasetChanged();"/>
<spacer width="10"/>
<vgroup id="axisControl">
<select id="columnX" label="Input (X) Property" showEmpty="false" onchange="zenPage.axisChanged();"/>
<spacer height="2"/>
<select id="columnY" label="Response (Y) property" showEmpty="false" onchange="zenPage.axisChanged();"/>
<!--
	onrefresh="zenPage.onYRefresh();"/>
-->
</vgroup>
<spacer width="5"/>
</hgroup>
</pane>
}

/// The name of the clustering model
Property Dataset As %String;

/// Number of data points in the whole dataset
Property dsCount As %ZEN.Datatype.integer;

/// Number of Dimensions included in current model. 
Property dimensionality As %ZEN.Datatype.integer;

/// True if data has been updated
Property datasetHasChanged As %ZEN.Datatype.boolean;

/// True if clustering options have been updated
Property clusteringHasChanged As %ZEN.Datatype.boolean;

Property method As %ZEN.Datatype.string;

/// Number of Clusters as calculated by current model. 
Property NClusters As %Integer;

/// Are we working with the sample or with the whole dataset? True for CLARA.
Property sampling As %ZEN.Datatype.boolean;

/// Sample Size for samling methods
Property sampleSize As %ZEN.Datatype.integer;

Property Normalize As %Boolean [ InitialExpression = 0 ];

Property Ready As %Boolean;

/// The minimum value on current X axis 
Property XMin As %ZEN.Datatype.float;

/// The maximum value on current X axis 
Property XMax As %ZEN.Datatype.float;

/// The minimum value on current Y axis 
Property YMin As %ZEN.Datatype.float;

/// The maximum value on current Y axis 
Property YMax As %ZEN.Datatype.float;

Property ErrorStatus As %Status;

ClientMethod onYRefresh() [ Language = javascript ]
{
}

ClientMethod checkParameters() [ Language = javascript ]
{
	var n = (this.dimensionality > 1);
	
	if (this.dsCount > 2000 && n) {
		var response = confirm ("You have more than 2000 records and multiple measures. Clustering might take very long time. Are you sure?");
		if (!response)
			return 0;
	}
	if (this.dsCount > 50000) {
		var response = confirm ("You have more than 50000 records. Clustering might take very long time. Are you sure?");
		if (!response)
			return 0;
	}
	if (this.dsCount > 3000) {
		if (!this.sampling) {
			var response = confirm ("You have more than 3000 records. Clustering with " + this.method + 
			" might take very long time. CLARA is recommended for large datasets. Are you sure?");
			if (!response)
				return 0;
		}
	}
	
	return 1;
}

ClientMethod alertIfError(sc) [ Language = javascript ]
{
	if (sc.code == 0)
		return;
	alert (sc.text);
}

ClientMethod methodChanged() [ Language = javascript ]
{
	this.clusteringHasChanged = 1
	zenPage.setParameters();
}

ClientMethod sampleSizeChanged() [ Language = javascript ]
{
	this.clusteringHasChanged = 1
}

ClientMethod nclChanged() [ Language = javascript ]
{
	this.clusteringHasChanged = 1
}

ClientMethod setParameters() [ Language = javascript ]
{
	this.method = zen('method').getValue();
	this.NClusters  = zen('ncl').getValue();
	
	if (this.method == "CLARA") {
		this.sampling = 1;
		this.sampleSize = zen('sample').getValue();
	} else {
		this.sampling = 0;
	}
	//alert(this.method + ":" + this.sampling);

	zen('sample').setDisabled(!(this.sampling));
	
	var columns = zen('columns').getValue();
	this.dimensionality = columns.split(",").length;
}

Method UpdateDataset() As %ZEN.proxyObject [ ZenMethod ]
{
	#dim sc As %Status
	
	Set sc = ..%UpdateAll()

	Quit ..ErrObj(sc)
}

Method UpdateView() As %ZEN.proxyObject [ ZenMethod ]
{
	#dim sc As %Status

	Set sc = ..%UpdateView()
	Quit ..ErrObj(sc)
}

Method %Init() As %Status
{
	#dim sc As %Status = $$$OK
	
	set ..Ready = 0
	set ..datasetHasChanged = 1
	
	Quit $$$OK
}

Method %UpdateAll() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim changed As %Boolean

	Try {	
		set changed = ..%HasDataChanged()
		if (changed) {
			Set sc = ..%SetModelData()
			Quit:$$$ISERR(sc)
			set ..datasetHasChanged = 0
		}
	
		set changed = changed || ..%HasClusteringChanged()
		if (changed) {
			Set sc = ..%SetClusteringParameters()
			Quit:$$$ISERR(sc)
			set ..clusteringHasChanged = 0
		}
	
		Set sc = ..%ExecuteAnalysis()
		Quit:$$$ISERR(sc)

		Set sc = ..%UpdateView()
		Quit:$$$ISERR(sc) 
		Set sc = ..%UpdateStatusInfo()
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method %UpdateView() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		Quit:'..Ready
			
		Set sc = ..%ComputeValues()
		Quit:$$$ISERR(sc) 
		Set sc = ..%UpdateControls()
	} Catch (ex) {
		Set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method %GetCurrentNCL() As %Integer
{
	Quit:..Dataset="" 0
	Quit:'##class(%DeepSee.extensions.clusters.AbstractModel).Exists(..Dataset) 0
	Quit ##class(%DeepSee.extensions.clusters.PAM).Open(..Dataset).GetNumberOfClusters()
}

Method %HasDataChanged() As %Boolean
{
	#dim exists As %Boolean
	#dim dim As %Integer
	
	Quit:..datasetHasChanged 1
	
	set exists = ##class(%DeepSee.extensions.clusters.AbstractModel).Exists(..Dataset)
	Quit:'exists 1
	
	set dim = ##class(%DeepSee.extensions.clusters.PAM).Open(..Dataset).GetDimensions()
	Quit:dim'=..dimensionality 1
	
	Quit 0
}

Method %HasClusteringChanged() As %Boolean
{
	Quit:..clusteringHasChanged 1
	
	if (..NClusters'=..%GetCurrentNCL()) {
		Quit 1
	}
	
	Quit 0
}

Method %ExecuteAnalysis() As %Status
{
	#dim sc As %Status = $$$OK
	#dim pam As %DeepSee.extensions.clusters.PAM

	if (..method="PAM") {
		set pam = ##class(%DeepSee.extensions.clusters.PAM).Open(..Dataset)
	} elseif (..method="PAM/SA") {
		set pam = ##class(%DeepSee.extensions.clusters.PAMSA).Open(..Dataset)
	} elseif (..method="CLARA") {
		set pam = ##class(%DeepSee.extensions.clusters.CLARA).Open(..Dataset)
		set pam.SampleSize = ..sampleSize
		set pam.NIdle = 7
		set ..sampling = 1
	}

	set pam.Verbose = 0
	set pam.Normalize = ..Normalize
	if ('pam.IsPrepared()) {
		set sc = pam.Prepare()
		Quit:$$$ISERR(sc)
	}

	set pam.K = ..NClusters

	$$$Trace(2,"clustering:"_..Dataset_":method",pam.%ClassName())
	#dim ts = $zts
	set sc = pam.Execute()
	$$$Trace(2,"clustering:"_..Dataset_":time",($p($zts,",",2)-$p(ts,",",2))_"s")

	set ..Ready = 1

	Quit sc
}

ClassMethod ErrObj(sc As %Status) As %ZEN.proxyObject
{
	set err = ##class(%ZEN.proxyObject).%New()
	if ($$$ISERR(sc)) {
		set err.code = $p($system.Status.GetErrorCodes(sc),",",1)
		set err.text = $system.Status.GetErrorText(sc)
	} else {
		set err.code = 0
		set err.text = ""
	}
	
	Quit err
}

Method %SetModelData() As %Status [ Abstract ]
{
}

Method %SetClusteringParameters() As %Status [ Abstract ]
{
}

Method %ComputeValues() As %Status [ Abstract ]
{
}

Method %UpdateControls() As %Status [ Abstract ]
{
}

Method %UpdateStatusInfo() As %Status [ Abstract ]
{
}

}
