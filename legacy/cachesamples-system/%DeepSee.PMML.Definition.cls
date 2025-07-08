/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%PMML, %DeepSee, %occSAX)

/// <p>This class represents a predictive model described in PMML (Predictive Modelling Markup Language),
/// an XML standard managed by the Data Mining Group (<a href="http://www.dmg.org/" target="_new">www.dmg.org</a>)
/// for describing Predictive Analytics models.</p>
/// <p>Subclasses of this class should provide this XML in an XData block named <XData>PMML</XData>,
/// so it will be validated and interpreted upon compiling the class. Upon compilation, additional
/// helper classes will be automatically generated:
/// <ul>
/// <li>A single <class>%DeepSee.PMML.Data</class> class representing the data fields required by this model.</li>
/// <li>A class for each model described in this PMML fragment (can be more than one), with dedicated
/// code to execute this model.</li>
/// <li><class>%DeepSee.PMML.ModelInput</class> and <class>%DeepSee.PMML.ModelOutput</class> classes
/// for each model, which are instantiated and managed automatically by the model class.</li>
/// </ul>
/// <p>In addition to the generated classes, subclasses of this class are also available
/// as Zen pages so the models they define can be run from a User Interface.</p>
/// <p>Use this class' <method>%GetModelClassName</method> to retrieve the model class for a named
/// model in the PMML definition and then invoke its %Execute* methods as desired. See also the
/// <class>%DeepSee.PMML.Model.AbstractModel</class> class reference for more information about 
/// these execution options, or <class>%DeepSee.PMML.Utils</class> for executing the model against
/// a batch of records at once.</p>
Class %DeepSee.PMML.Definition Extends %ZEN.Component.page [ Abstract, CompileAfter = %DeepSee.PMML.Definition.PMML, System = 4 ]
{

Parameter DOMAIN = "PMML";

/// Set to 1 to disable the use of tracing model output altogether
Parameter DISABLETRACING [ Internal ] = 0;

/// The XData block containing the actual PMML specification.
XData PMML [ XMLNamespace = "http://www.intersystems.com/deepsee/pmml" ]
{
}

ClassMethod %GetDefinition(Output pPMML As %DeepSee.PMML.Definition.PMML) As %Status [ CodeMode = objectgenerator, Internal ]
{
    set tSC = $$$OK
    try {
        
        // exit if we're not in an actual PMML definition
        if (%class.Abstract || (%class.Name = "%DeepSee.PMML.Definition")) {
            do %code.WriteLine(" quit """"")
            quit
        }
        
        // first locate the PMML XData block
        set tXDataIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||PMML")
        if (tXDataIndex="") {
            set tSC = $$$ERROR($$$GeneralError, "No PMML XData block")
            quit
        }
        set tXDataStream = %compiledclass.XDatas.GetAt(tXDataIndex).Data
        do tXDataStream.Rewind()
        if (tXDataStream.Size <= 0) {
            set tSC = $$$ERROR($$$GeneralError, "PMML XData block is empty")
            quit
        }
        
        // correlate the XData stream with %DeepSee.PMML.Definition.PMML
        set tReader = ##class(%XML.Reader).%New()
        set tReader.SAXFlags = $$$SAXNOVALIDATION // BDB738
        set tSC = tReader.OpenStream(tXDataStream)
        quit:$$$ISERR(tSC)
        
        do tReader.Correlate("PMML","%DeepSee.PMML.Definition.PMML")
        
        do tReader.Next(.tPMML,.tSC)
        quit:$$$ISERR(tSC)
        
        #dim tPMML As %DeepSee.PMML.Definition.PMML
        if '$isobject(tPMML) {
            set tSC = $$$ERROR($$$GeneralError,"No <PMML> element in XData.")
            quit
        }
        
        // validate PMML contents
        new %PMMLTransformations // BDB839
        set tSC = tPMML.%ValidatePMML(1)
        quit:$$$ISERR(tSC)
        kill %PMMLTransformations // BDB839
        
        set tSC = ##class(%DeepSee.PMML.Generator).%CreateClasses(tPMML, %class.Name)
        quit:$$$ISERR(tSC)
        
        // now output actual implementation in case code would need %DeepSee.PMML.Definition object
        #define WriteLine(%c) do %code.WriteLine($c(9)_%c)
        $$$WriteLine("set tSC = $$$OK")
        $$$WriteLine("try {")
        $$$WriteLine("	set tXData = ##class(%Dictionary.CompiledXData).%OpenId("""_%compiledclass.Name_"||PMML"")")
        $$$WriteLine("	set tReader = ##class(%XML.Reader).%New()")
        $$$WriteLine("	set tReader.SAXFlags = $$$SAXNOVALIDATION") // BDB738
        $$$WriteLine("	set tSC = tReader.OpenStream(tXData.Data)")
        $$$WriteLine("	quit:$$$ISERR(tSC)")
        $$$WriteLine("	do tReader.Correlate(""PMML"",""%DeepSee.PMML.Definition.PMML"")")
        $$$WriteLine("	do tReader.Next(.pPMML,.tSC)")
        $$$WriteLine("	quit:$$$ISERR(tSC)")
        $$$WriteLine("} catch (ex) {")
        $$$WriteLine("	set tSC = ex.AsStatus()")
        $$$WriteLine("}")
        $$$WriteLine("quit tSC")
    } catch (ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
}

/// This method returns a <class>%DeepSee.PMML.Model.AbstractModel</class> instance for the model in
/// this definition corresponding to <var>pModelName</var>.
ClassMethod %GetModelInstance(ByRef pModelName As %String = "", ByRef pModel As %DeepSee.PMML.Model.AbstractModel) As %Status
{
	set tSC = $$$OK
	try {
		set tModelClassName = ..%GetModelClassName(.pModelName)
		if (tModelClassName="") {
			set tSC = $$$ERROR($$$GeneralError, "Unknown model name: '"_pModelName_"'")
			quit
		}
		set pModel = $classmethod(tModelClassName, "%New")
		set:pModel="" tSC = %objlasterror
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the class name of the model identified by <var>pModelName</var> in <xdata>PMML</xdata>.
/// If left blank, returns the class name of the first model in the model definition, setting
/// <var>pModelName</var> to its logical name at the same time.
ClassMethod %GetModelClassName(ByRef pModelName As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = %GetDefinition ]
{
    // default to the first one
    set i = "", tIsFirst=1
	for {
		set i = $order(%PMML("Models",i), 1, tModelClassName)
		quit:i=""
		continue:i="DATA"
		set tModelName = %PMML("Classes",$$$UPPER(tModelClassName))
		if (tIsFirst) {
			do %code.WriteLine("	if (pModelName="""") || (pModelName = "_$$$QUOTE(tModelName)_") {")
			do %code.WriteLine("		set pModelName = "_$$$QUOTE(tModelName))
		} else {
			do %code.WriteLine("	} elseif (pModelName = "_$$$QUOTE(tModelName)_") {")
		}
		set tIsFirst=0
		do %code.WriteLine("		quit "_$$$QUOTE(tModelClassName))
	}
	do:'tIsFirst %code.WriteLine("	}")
	do %code.WriteLine("	quit """"")
    quit $$$OK
}

/// Returns the name of the <class>%DeepSee.PMML.Data</class> class generated upon compiling
/// this PMML definiton.
ClassMethod %GetDataClassName() As %String
{
    quit $classname()_".Data"
}

ClassMethod %CreateDataset(pDataSource As %String = "", Output pDataset As %DeepSee.PMML.Dataset) As %Status [ Internal ]
{
	quit $classmethod(..%GetDataClassName(), "%CreateDataset", pDataSource, .pDataset)
}

/// <p>Returns pModels(n) = $lb(modelName, class, type)</p>
/// <p>If <var>pIncludeSecondary</var>=1, models nested within composite models will also be returned.
/// Note that these cannot necessarily be invoked separately.</p>
ClassMethod %GetModels(Output pModels, pIncludeSecondary As %Boolean = 0) As %Status [ CodeMode = objectgenerator, GenerateAfter = %GetModelClassName, Internal ]
{
	do %code.WriteLine("	kill pModels")
    set i = ""
	for {
		set i = $order(%PMML("Models",i), 1, tModelClassName)
		quit:i=""
		continue:i="DATA"
		set tModelName = %PMML("Classes",$$$UPPER(tModelClassName))
		set tModelType = $g(%PMML("Classes",$$$UPPER(tModelClassName),"type"))
		set tIsSecondary = ($g(%PMML("Models",i,"parent"))'="")
		do %code.WriteLine("	set"_$s(tIsSecondary:":pIncludeSecondary", 1:"")_" pModels($i(pModels)) = $lb("_$$$QUOTE(tModelName)_", "_$$$QUOTE(tModelClassName)_", "_$$$QUOTE(tModelType)_")")
	}
	do %code.WriteLine("	quit $$$OK")
	kill %PMML
	quit $$$OK
}

/// XData block defining the contents of the GUI presenting a manual interfacte for running the
/// models described in <xdata>PMML</xdata>
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" enclosingStyle="padding-top:30px;"
     title="PMML Model test page" width="100%" height="100%" layout="horizontal">
<jsonProvider id="json" OnGetTargetObject="OnGetData" OnSubmitContent="OnSubmitData" />
<spacer width="15%" />
<vgroup width="70%">
<titleBox title="PMML Model test page" />
<spacer height="15" />
<hgroup width="100%" cellVAlign="top">

<vgroup width="45%" cellVAlign="top" height="100%">
<titleBox title="Data object" />
<spacer height="10" />
<form labelPosition="left" id="frmProperties" controllerId="json" />
<spacer height="10" />
<link caption="Go to batch test page" id="lnkBatchTestPage" />
</vgroup>

<spacer width="25" />

<vgroup width="45%" cellVAlign="top" height="100%">
<select id="selModel" label="Model" onchange="zenPage.onChangeModel(zenThis.getValue());" />
<spacer height="20" />
<label label="Predicted value:" />
<html id="htmlOutput" OnDrawContent="DrawOutput" />
<spacer height="20" />
<label label="Trace info:" />
<html id="htmlTrace" OnDrawContent="DrawTrace" />
</vgroup>

</hgroup>
</vgroup>
<spacer width="15%" />
</page>
}

Method OnGetData(ByRef pParameters, Output pObject As %RegisteredObject) As %Status [ Internal ]
{
    set pObject = $classmethod(..%GetDataClassName(), "%New")
    quit $$$OK
}

Method OnSubmitData(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pObject As %RegisteredObject, Output pResponse As %RegisteredObject) As %Status [ Internal ]
{
    set tSC = $$$OK 
    try {
        if '$isobject(pObject) {
	        set %session.Data("pmml", $zcrc($classname(),7)) = ""
	        quit
        }
        
        // first ensure all getters are called to populate derived fields
        do pObject.%GetAsArray(.tArray,.tStatusArray)
        set tSC = pObject.%SerializeObject(.tSerial)
	    quit:$$$ISERR(tSC)
	    
	    // store serialized form for pickup by DrawOutput() and DrawTrace()
        set %session.Data("pmml", $zcrc($classname(),7)) = $g(tSerial)
        
        // send back the response, which should contain updated derived fields
        set pResponse = pObject
        
        // update status hints
        set tField = ""
        for {
	        set tField = $order(tStatusArray(tField),1, tStatus)
	        quit:tField=""
	        set tInputName = "input"_$$$PROPERTYNAME(tField)
	        &js<zen('#(tInputName)#').setProperty('hint','#(tStatus)#');>
        }
        
    } catch (ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
}

/// Populates the properties and models on this Zen page according to the contents of <xdata>PMML</xdata>
Method %OnAfterCreatePage() As %Status
{
    set tSC = $$$OK 
    try {
        
        // populate properties form
        set tSC = ..%AddProperties()
        quit:$$$ISERR(tSC)
        
        
        // populate selModel
        set tSC = ..%GetModels(.tModels)
        quit:$$$ISERR(tSC)
        set (tValueList,tDisplayList) = ""
        for i = 1:1:$g(tModels) {
	        set tValueList = tValueList _ "," _ $li(tModels(i),1)
	        set tDisplayList = tDisplayList _ "," _ $li(tModels(i),1) _ " ("_$li(tModels(i),3)_")"
        }
        set tSelModel = ..%GetComponentById("selModel")
        set tSelModel.valueList = $e(tValueList,2,*)
        set tSelModel.displayList = $e(tDisplayList,2,*)
        set tSelModel.value = $g(%request.Data("MODEL",1))
        
        // populate link to batch test page
        set tLink = ..%GetComponentById("lnkBatchTestPage")
        if $g(%request.Data("EMBEDDED",1)) {
	        set tLink.hidden = 1
        } else {
	        set tLink.href = "_DeepSee.PMML.UI.ModelTester.zen?CLASS="_$classname()
        }
        
    } catch (ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
}

Method %AddProperties() As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
	    set tForm = ..%GetComponentById("frmProperties")
	    
	    set tSC = ..%GetDefinition(.tDefinition)
	    quit:$$$ISERR(tSC)
	    quit:'$isobject(tDefinition.DataDictionary)
	    
	    #dim tDataField As %DeepSee.PMML.Definition.DataField
	    #dim tValue As %DeepSee.PMML.Definition.Util.Value
	    set tAllPropNames = ""
	    for i = 1:1:tDefinition.DataDictionary.DataFields.Count() {
		    set tDataField = tDefinition.DataDictionary.DataFields.GetAt(i)
			
		    if (tDataField.dataType="boolean") {
			    
		        set tInput = ##class(%ZEN.Component.select).%New()
		        set tInput.valueList = "0,1"
		        set tInput.displayList = "false,true"
		        
		    } elseif tDataField.Values.Count() && (tDataField.optype'="continuous") {
		    
		        set tInput = ##class(%ZEN.Component.select).%New()
		        set (tValueList, tDisplayList) = ""
		        for j = 1:1:tDataField.Values.Count() {
			        set tValue = tDataField.Values.GetAt(j)
			        continue:'tValue.%Extends("%DeepSee.PMML.Definition.Util.Value")
			        set tValueList = tValueList_","_tValue.value
			        set tDisplayList = tDisplayList_","_$s(tValue.displayValue'="":tValue.displayValue, 1:tValue.value)
		        }
		        set tInput.valueList = $e(tValueList,2,*)
		        set tInput.displayList = $e(tDisplayList,2,*)
		        
		    } else {
		    
		        set tInput = ##class(%ZEN.Component.text).%New()
		        
		    }
		    
		    set tPropName = $$$PROPERTYNAME(tDataField.name)
		    set tAllPropNames = tAllPropNames _ "," _ tPropName
		    set tInput.id = "input"_tPropName
		    set tLabel = $s(tDataField.displayName'="":tDataField.displayName, 1:tDataField.name)
		    $$$CAMELSPACE(tLabel,tLabelFormatted)
		    set tInput.label = tLabelFormatted
		    set tInput.dataBinding = $$$PROPERTYNAME(tDataField.name)
		    set tInput.hint = "missing"
		    set tInput.labelStyle = "margin-right:10px;"
		    set tInput.onchange = "zenPage.update('"_tPropName_"',zenThis.getValue());"
		    
		    do tForm.%AddChild(tInput)
	    }
	    
	    if $isobject(tDefinition.TransformationDictionary) {
		    #dim tDerivedField As %DeepSee.PMML.Definition.DerivedField
		    for i = 1:1:tDefinition.TransformationDictionary.DerivedFields.Count() {
			    set tDerivedField = tDefinition.TransformationDictionary.DerivedFields.GetAt(i)
				
			    set tInput = ##class(%ZEN.Component.text).%New()
			    set tPropName = $$$PROPERTYNAME(tDerivedField.name)
			    set tAllPropNames = tAllPropNames _ "," _ tPropName
			    set tInput.id = "input"_tPropName
			    set tLabel = $s(tDerivedField.displayName'="":tDerivedField.displayName, 1:tDerivedField.name)
			    $$$CAMELSPACE(tLabel,tLabelFormatted)
		   		set tInput.label = tLabelFormatted
			    set tInput.dataBinding = $$$PROPERTYNAME(tDerivedField.name)
			    set tInput.hint = "missing"
			    set tInput.labelStyle = "margin-right:10px;"
			    set tInput.readOnly = 1
			    set tInput.disabled = 1
			    
			    do tForm.%AddChild(tInput)
		    }
	    }
	    
	    set tButton = ##class(%ZEN.Component.button).%New()
	    set tButton.caption="reset", tButton.id="reset", tButton.onclick="zenPage.reset();"
	    do tForm.%AddChild(tButton)
	    
	    set tHidden = ##class(%ZEN.Component.hidden).%New()
	    set tHidden.id = "hidPropNames"
	    set tHidden.value = $e(tAllPropNames,2,*)
	    do tForm.%AddChild(tHidden)
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
    quit $$$OK
}

Method GetInputFieldsForModel(pModel As %String, pSeparator As %String) As %String [ Internal, ZenMethod ]
{
	set tFieldList = ""
	quit:pModel="" ""
	
	do $classmethod(..%GetModelClassName(pModel), "%GetDefinition", .tModelDef)
	
	// first build a list of all the fields used by this model
	kill tModelFields
	for i = 1:1:tModelDef.MiningSchema.MiningFields.Count() {
		set tMiningField = tModelDef.MiningSchema.MiningFields.GetAt(i)
		continue:$$$PMMLusageTypeIsTarget(tMiningField.usageType)
		set tModelFields(tMiningField.name) = ""
	}
	if ($isobject(tModelDef.LocalTransformations)) {
		for i = 1:1:tModelDef.LocalTransformations.DerivedFields.Count() {
			set tDerivedField = tModelDef.LocalTransformations.DerivedFields.GetAt(i)
			set tModelFields(tDerivedField.name) = ""
			do tDerivedField.Expression.%GetInputFields(.tModelFields)
		}
	}
	
	// append eventual inputs found through TransformationDictionary
	do ..%GetDefinition(.tPMML)
	if $isobject(tPMML.TransformationDictionary) {
		for i = 1:1:tPMML.TransformationDictionary.DerivedFields.Count() {
			set tDerivedField = tPMML.TransformationDictionary.DerivedFields.GetAt(i)
			continue:'$d(tModelFields(tDerivedField.name))
			do tDerivedField.Expression.%GetInputFields(.tModelFields)
		}
	}
	
	// now build the actual list based on the DataDictionary
	for i = 1:1:tPMML.DataDictionary.DataFields.Count() {
		set tDataField = tPMML.DataDictionary.DataFields.GetAt(i)
		continue:'$d(tModelFields(tDataField.name))
		set tFieldList = tFieldList _ pSeparator _ $$$PROPERTYNAME(tDataField.name)
	}
	quit $e(tFieldList,1+$l(pSeparator),*)
}

/// Update test page contents based on user input
ClientMethod update(id, value) [ Language = javascript ]
{
    var sc = zen('json').submitContent('save');
    zen('htmlOutput').refreshContents();
    zen('htmlTrace').refreshContents();
	zenPage.disableUnusedFields();
}

ClientMethod reset() [ Language = javascript ]
{
	var sc = zen('json').reloadContents();
	
	// reset hints
	var ctrls = zen('frmProperties').getControlList();
	for (var i = 0; i < ctrls.length; i++) {
		var id = ctrls[i].id;
		if (id == 'reset') continue;
		zen(id).setProperty('hint', 'missing'); 
	}
	
    zenPage.update();
}

ClientMethod disableUnusedFields() [ Language = javascript ]
{
	var model = zen('selModel').getValue();
	var fieldsInUse = this._inputFields;
	// disable all controls not used for this model
	var ctrls = zen('frmProperties').getControlList();
	for (var i = 0; i < ctrls.length; i++) {
		var id = ctrls[i].id;
		if (id == 'reset') continue;
		zen(id).setProperty('disabled', !fieldsInUse || (fieldsInUse.indexOf('^'+id.substring(5)+'^') < 0)); 
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	// initialize input fields if model is set through URL parameter
    var model = zen('selModel').getValue();
    if ((model!='') && (model!=null)) {
	    this._inputFields = '^'+zenPage.GetInputFieldsForModel(model,'^')+'^';
    }
    
    // invoke update() so status information is initialized
	zenPage.update();
}

/// Invoked when selecting a model in the GUI
ClientMethod onChangeModel(model) [ Language = javascript ]
{
	this._inputFields = '^'+zenPage.GetInputFieldsForModel(model,'^')+'^';
	var sc = zen('htmlOutput').setProperty('seed', model);
	var sc = zen('htmlTrace').setProperty('seed', model);
	
	zenPage.reset();
}

Method GetTestOutput(pModelName As %String, Output pModel As %DeepSee.PMML.Model.AbstractModel, Output pOutput As %DeepSee.PMML.ModelOutput, pTrace As %Boolean = 0) As %Status [ Internal, Private ]
{
    set tSC = $$$OK
    try {
        set tSerial = $g(%session.Data("pmml", $zcrc($classname(),7)))
        set tDataObject = $classmethod(..%GetDataClassName(), "%Open", tSerial)
        if (tDataObject="") {
	        set tSC = %objlasterror
	        quit
        }
        
        set tSC = ..%GetModelInstance(pModelName, .pModel)
        quit:$$$ISERR(tSC)
        
        // execute model
     	set:'..#DISABLETRACING pModel.Tracing = pTrace
        set tSC = pModel.%ExecuteModel(tDataObject, .pOutput)
        quit:$$$ISERR(tSC)
        
    } catch (ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
}

Method DrawTrace(pSeed As %String) As %Status [ Internal ]
{
    set tSC = $$$OK
    try {
	    quit:pSeed=""
	    
	    #dim tOutput As %DeepSee.PMML.ModelOutput
	    set tSC = ..GetTestOutput(pSeed, .tModel, .tOutput, '..#DISABLETRACING)
	    quit:$$$ISERR(tSC)
	    
	    if ..#DISABLETRACING {
		    &html<<p>disabled</p>>
	    } else {
		    set tSC = tModel.%DrawTraceInfo(tOutput)
		    quit:$$$ISERR(tSC)
	    }
	        
    } catch (ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
}

Method DrawOutput(pSeed As %String) As %Status [ Internal ]
{
    set tSC = $$$OK
    try {
	    quit:pSeed=""
	    
	    #dim tOutput As %DeepSee.PMML.ModelOutput
	    set tSC = ..GetTestOutput(pSeed,, .tOutput)
	    quit:$$$ISERR(tSC)
	    quit:$g(tOutput)=""
	    
	    set tPredictedValue = $zconvert(tOutput.%GetFeatureValue("predictedValue"),"O","HTML")
	    set tPredictedValue = $$FormatValue(tPredictedValue)
	    write "<div style='font-size:25px;font-weight:bold;'>"_tPredictedValue_"</div>"
        
        do tOutput.%GetFields(.tFields)
        
        // don't display anything else if there is only one output field
        quit:$o(tFields(""))=$o(tFields(""),-1) 
        
	    &html<<table style="margin-top:20px;">>
        set tPropName = ""
        for {
            set tPropName = $order(tFields(tPropName),1,tInfo)
            quit:tPropName=""
            set tFeature = $li(tInfo,1), tDisplayName = $li(tInfo,3)
            set tValue = $$FormatValue($property(tOutput, $$$PROPERTYNAME(tPropName)))
            
            &html<<tr><td>#(tDisplayName)#:</td><td width="10">&nbsp;</td><td>#(tValue)#</td></tr>>
        }
        &html<</table>>
        
    } catch (ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
    
FormatValue(tValue)
    set:tValue="" tValue = "[null]"
    set:+tValue&&(tValue#1) tValue = $fnumber(tValue,"",4)
    quit tValue
}

}
