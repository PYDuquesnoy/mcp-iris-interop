Class DataMining.ClusterAnalysis.ZenDemoPage Extends %DeepSee.extensions.clusters.TableAnalysis
{

Parameter APPLICATION = "DataMining.ClusterAnalysis.GraphicalDemoApp";

Parameter PAGENAME = "Cluster Analysis Demo";

Parameter SPECIALVALUES = 1;

XData tableSelectPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup>
<spacer width="20"/>
<label value="Select Dataset: "/>
<spacer width="10"/>
<select id="tables" valueList="DataMining.ClusterAnalysis.SimpleTest,DataMining.IrisDataset"
displayList="Simple,Iris"
showEmpty="true" value=""
onchange="zenPage.demoChanged()"/>
<button caption="Set" onclick="zenPage.setRequested()"/>
</hgroup>
</pane>
}

ClientMethod demoChanged() [ Language = javascript ]
{
	this.classname = zen('tables').getValue();
	if (this.classname == "") {
		zen('update').setDisabled(true);
	} else {
		if (this.classname == "DataMining.ClusterAnalysis.SimpleTest") {
			this.defaultRadius = 1
			zen('chart').setProperty('radius',5);
		} else {
			this.defaultRadius = 0.2
			zen('chart').setProperty('radius',0.75);
		}
		this.datasetHasChanged = 1;
		zenPage.tableChanged();
		
		//var select = zen('columnY');
		//alert(select.valueList +": " + this.propNameY + "/" + select.getValue());
		
		zen('update').setDisabled(false);
		zenPage.run();
	}
}

ClientMethod debugDemoChanged() [ Language = javascript ]
{
		this.datasetHasChanged = 1;
		var err = zenPage.OnSelectClass();
		zenPage.alertIfError(err);
		err = zenPage.RestoreDefaults();
		zenPage.alertIfError(err);
		//zenPage.tableChanged();
		zen('update').setDisabled(false);
		
		var select = zen('columnY');
		alert(select.valueList +": " + this.propNameY + "/" + select.getValue());
		select.setValue(this.propNameY);
		alert(select.valueList +": " + this.propNameY + "/" + select.getValue());
		//zenPage.run();
}

ClientMethod setRequested() [ Language = javascript ]
{
		err = zenPage.RestoreDefaults();
		zenPage.alertIfError(err);
}

Method %OnAfterCreatePage() As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	Try {
		set tSC = ##class(DataMining.ClusterAnalysis.SimpleTest).populate()
		Quit:$$$ISERR(tSC)
		set tSC = ##class(DataMining.ClusterAnalysis.Iris).checkData()
		Quit:$$$ISERR(tSC)
		set ..%GetComponentById("update").disabled = 1
	} Catch(ex) {
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
		Set tSelect  = ..%GetComponentById("tables")
		Set tMSelect = ..%GetComponentById("columns")
		
		Set properties = ""
		if (tSelect.value="DataMining.ClusterAnalysis.SimpleTest") {
			Set properties = "X,Y"
			Set tSelect = ..%GetComponentById("columnX")
			Set ..propNameX = "X"
			Set tSelect.value = ..propNameX
			Set tSelect.valueList = properties
			Set tSelect = ..%GetComponentById("columnY")
			Set ..propNameY = "Y"
			Set tSelect.value = ..propNameY
			Set tSelect.valueList = properties
			Set tSelect = ..%GetComponentById("ncl")
			Set tSelect.value = 2
		} elseif (tSelect.value="DataMining.IrisDataset") {
			Set properties = "PetalLength,PetalWidth,SepalLength,SepalWidth"
			Set tSelect = ..%GetComponentById("columnX")
			Set ..propNameX = "Species"
			Set tSelect.value = ..propNameX
			Set tSelect = ..%GetComponentById("columnY")
			Set ..propNameY = "SepalLength"
			Set tSelect.value = ..propNameY
			Set tSelect = ..%GetComponentById("ncl")
			Set tSelect.value = 3
		} else {
			set tSC = $$$ERROR($$$GeneralError,"Invalid Sample Selected: "_tSelect.value)
			Quit
		}
		set tMSelect.value = properties
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit ..ErrObj(tSC)
}

Method %OnGetValue(ByRef value, classname As %String, property As %String) As %Status
{
	if ((classname="DataMining.IrisDataset") && (property="Species")) {
		set value = $case(value,"Iris-setosa":1,"Iris-virginica":6,"Iris-versicolor":11,:16)
	}
	Quit $$$OK
}

}

