/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Context base class for requesting evaluation of a rule that uses The ExtensionsAssist class
Class Ens.Rule.ExtensionInputs Extends %RegisteredObject [ Abstract ]
{

/// JSON string of Rule inputs
Property %JSON As %String(MAXLEN = "") [ Internal ];

/// Object representation of JSON string
Property %Inputs As %DynamicObject [ Internal, Transient ];

/// Counter for JSON changes while in memory
Property %JSONUpd As %Integer [ InitialExpression = 1, Internal, Transient ];

/// Flag for Inputs matching JSON update while in memory
Property %InputsUpd As %Integer [ Internal, Transient ];

/// Override this JSON in a subclass to enable editing the associated Rule with Rule Extensions supported by the Ens.Rule.ExtensionsAssist class.
/// The format is a JSON object containing a sub-object for each described input name. The sub-object contains an extension "type" property for the input.
/// An optional "pluginSchema" property naming the semantic subtype for the input.
/// An optional "displayName" property, if present, overrides the way the input name is presented in the rule editor UI.
XData InputTypesSpec [ MimeType = application/json ]
{
{}
}

Method %OnNew(initvalue As %String) As %Status
{
	If $IsObject($Get(initvalue)) { Set ..%Inputs = initvalue }
	Else { Set i%%JSON = $Get(initvalue) }

	Set classname = $classname()
    Set tSC = ..ContextList(classname,.propsList)
    Quit:$$$ISERR(tSC) tSC

	// iterate over: properties, inputTypes, inputs
	Set iProp = propsList.%GetIterator() While iProp.%GetNext(.idx, .propAttrs) {
		//{"name":(propName),"irisType":(propType),"pluginType":(pluginType.type),"pluginSchema":(pluginType.pluginSchema)})
		// construct each property from input based on input datatype and inputType
		Kill propData,propVal
		Set propName = propAttrs.name
		Set propData = $S($IsObject(..%Inputs):..%Inputs.%Get(propName), 1:"")
		If $L(propAttrs.pluginClass) {
			try {
				Set propVal = $classmethod(propAttrs.pluginClass,"Create",propData,.tSC)
			} catch ex {
				Set:ex.Name'="<METHOD DOES NOT EXIST>" tSC = ex.AsStatus()
			}
		}
		/*
			Two stage identification of propData:
				1. must only have 2 properties class and id which must equal non empty literals
				2. class identified by class property must exist and extend declared irisType
		*/
		If ($$$ISOK(tSC) && '$D(propVal) && $IsObject(propData)) {
			Set tJustClassAndIdLiteralProperties = 0
			Set iPropData=propData.%GetIterator()
			While iPropData.%GetNext(.key) {
				If ((key'="class")&&(key'="id"))||$IsObject(propData.%Get(key))||(propData.%Get(key)= "") {
					Set tJustClassAndIdLiteralProperties = 0
					Quit
				}
				Do $Increment(tJustClassAndIdLiteralProperties)
			}
			If (tJustClassAndIdLiteralProperties=2)&&##class(%Dictionary.CompiledClass).%ExistsId(propData.class)&&$classmethod(propData.class,"%Extends",propAttrs.irisType) {
				try {
					Set propVal = $classmethod(propData.class,"%OpenId",propData.id,,.tSC)
					Set:'$IsObject(propVal) tSC=$G(%objlasterror,$$$ERROR($$$GeneralError,"Failed to open "_propAttrs.irisType_" object with "_propData.%ToJSON()_" : "_$$$StatusDisplayString(tSC)))
				} catch ex {
					Set tSC = ex.AsStatus()
				}
			}
		}
		If $$$ISOK(tSC) && '$D(propVal) {
			try {
				Kill %objlasterror
				Set propVal = $classmethod(propAttrs.irisType,"%New",propData)
				Set:'$IsObject(propVal) tSC=$G(%objlasterror,$$$ERROR($$$GeneralError,"Failed to instantiate "_propAttrs.irisType_" with data "_propData))
				Set:propVal.%Extends("Ens.VDoc.Interface") propVal.DocType = propAttrs.pluginSchema
			} catch ex {
				Set:ex.Name'="<METHOD DOES NOT EXIST>" tSC = ex.AsStatus()
			}
		}
		If $$$ISOK(tSC) && '$D(propVal) {
			Set propVal = propData
		}
		Quit:$$$ISERR(tSC)
		Set $property($this,propName) = propVal
	}

	// warn on leftover inputs

	Quit tSC
}

Method %JSONSet(tJSON As %String) As %Status
{
	Set i%%JSON = tJSON
	Set ..%JSONUpd = ..%JSONUpd+1
	Quit $$$OK
}

Method %InputsGet() As %DynamicObject
{
	Quit:..%InputsUpd=..%JSONUpd r%%Inputs
	If $E(..%JSON) '= "{" {
		Set r%%Inputs = $$$NULLOREF
	} Else {
		Do ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(..%JSON,,.obj) ; support parsing unquoted property names
		Do ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tStream,obj,,,,"aeilow4")
		Set r%%Inputs = ##class(%DynamicObject).%FromJSON(tStream)
	}
	Set ..%InputsUpd = ..%JSONUpd
	Quit r%%Inputs
}

Method %InputsSet(tInputsObj As %DynamicObject) As %Status
{
	If $classname(tInputsObj) = "%Library.DynamicObject" {
		Set r%%Inputs = tInputsObj
		Set i%%JSON = tInputsObj.%ToJSON()
	} Else {
		Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%WriteJSONStreamFromObject(.tStream,tInputsObj,,,,"aeilow4")
		Quit:$$$ISERR(tSC) tSC
		Set i%%JSON = tStream.Read()
		Set r%%Inputs = ##class(%DynamicObject).%FromJSON(i%%JSON)
	}
	Set (..%JSONUpd,..%InputsUpd) = 1
	Quit $$$OK
}

/// Return a dynamic array of objects describing the set of properties of the named rule context class
ClassMethod ContextList(pContextClassname As %String, ByRef pBody As %DynamicArray) As %Status [ Internal ]
{
    Quit:'##class(%Dictionary.CompiledClass).%ExistsId(pContextClassname) $$$ERROR($$$GeneralError,"Extension Context class '"_pContextClassname_"' not found")
    Quit:'$classmethod(pContextClassname,"%Extends","Ens.Rule.ExtensionInputs") $$$ERROR($$$GeneralError,"Extension Context class '"_pContextClassname_"' does not extend 'Ens.Rule.ExtensionInputs'")

    Set tSC = ..ExtensionsList(,.dtMap)
    Quit:$$$ISERR(tSC) tSC

    Set tXDataObj = ##class(%Dictionary.CompiledXData).%OpenId(pContextClassname_"||InputTypesSpec",,.tSC)
    Quit:$$$ISERR(tSC) tSC
	try {
		Set propTypes = ##class(%Library.DynamicObject).%FromJSON($S(tXDataObj.Data.Size:tXDataObj.Data,1:"{}"))
	} catch ex {
		Set tSC = ex.AsStatus()
		Do tXDataObj.Data.Rewind()
	}
    Quit:$$$ISERR(tSC) $$$ERROR($$$GeneralError,"Extension Context class '"_pContextClassname_"' InputTypesSpec JSON XData '"_tXDataObj.Data.Read()_"' is not well formed:"_$$$StatusDisplayString(tSC))
    Set pBody = []
    &sql(DECLARE Cgcp CURSOR FOR
            SELECT Name, Type, RuntimeType, Collection, Description INTO :propName, :propType, :propRuntimeType, :propCollection, :propDescription
            FROM %Dictionary.CompiledProperty
            WHERE parent = :pContextClassname AND $EXTRACT(Name,1) <> '%' AND Private<>1 AND Internal<>1 AND Calculated<>1)
    &sql(OPEN Cgcp) For { &sql(FETCH Cgcp) Quit:SQLCODE
            Set pluginType = propTypes.%Get(propName)
            If $IsObject(pluginType) {
                    If $D(dtMap(pluginType.type),pluginClass)#2 {
                            Set pluginName = $parameter(pluginClass,"PluginName")
                    } Else { Set (pluginClass,pluginName) = "" }
                    Do pBody.%Push({"name":(propName),"irisType":(propType),"displayName":(pluginType.displayName),"pluginType":(pluginType.type),"pluginSchema":(pluginType.pluginSchema),"pluginClass":(pluginClass),"pluginName":(pluginName),"description":(propDescription)})
            } Else {
                    &sql(SELECT ClassType INTO :classType FROM %Dictionary.CompiledClass WHERE name = :propType)
                    If SQLCODE {
                            Set tSC=$$$ERROR($$$GeneralError,"SELECT Error for ClassType of context property '"_propName_"' class '"_propType_"'; SQLCODE = "_SQLCODE_$S(""=%msg:"", 1:" / "_%msg))
                            Quit
                    }
                    If $Case(classType,"datatype":0,"donotuse":0,"":0,:1) {
                            Do pBody.%Push({"name":(propName),"irisType":(propType),"pluginType":"IRISClass","pluginSchema":(propType),"pluginClass":"Ens.Rule.ClassdefExtension","pluginName":"IRISClass"})
                    } Else {
                            Do pBody.%Push({"name":(propName),"irisType":(propType)})
                    }
            }
    } Set tCode=SQLCODE,tMsg=$G(%msg) &sql(CLOSE Cgcp) Set:'SQLCODE SQLCODE=tCode,%msg=tMsg
    Set:SQLCODE&&(SQLCODE'=100) tSC=$$$ERROR($$$GeneralError,"FETCH Error for properties of context class "_pContextClassname_"; SQLCODE = "_SQLCODE_$S(""=%msg:"", 1:" / "_%msg))

    // warn on leftover properties or inputs or inputTypes (but not shortage of inputTypes if default ok)

    Quit tSC
}

/// Return a dynamic array of objects describing the set of installed Rule Extension classes
ClassMethod ExtensionsList(ByRef pBody As %DynamicArray, ByRef pDTmap) As %Status [ Internal ]
{
	Set pBody = []
	Set tRS = ##class(%Library.ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("Ens.Rule.Extension","%YZ")
	While $$$ISOK(tSC) && tRS.Next(.tSC) { Set name = tRS.Data("Name")
		Set dataTypes = $parameter(name,"DataTypes")
		For i = 1:1:$L(dataTypes,",") { Set tDT = $ZStrip($P(dataTypes,",",i),"<>W")
			Set:""'=tDT pDTmap(tDT) = name
		}
		Do pBody.%Push({"class":(name), "plugin":($parameter(name,"PluginName")), "dataTypes":(dataTypes)})
	} Set:tSC'=0 tSCc=tRS.Close() Set tSC=$S(tSC'=0&&$$$ISERR(tSC):tSC, tSC'=0:tSCc, 1:$$$ERROR($$$GeneralError,"Failed to create %ResultSet "_$$$StatusDisplayString($g(%objlasterror))))
	Quit tSC
}

}
