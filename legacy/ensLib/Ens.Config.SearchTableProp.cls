/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsSearchTableErrors)

/// Persistent SearchTable Property specifier object, stored for use in generating SearchTable code and queries
Class Ens.Config.SearchTableProp Extends (%Persistent, Ens.Config.SearchTablePropAttrs) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 2 ]
{

Parameter XMLNAME = "Property";

Parameter XMLIGNORENULL = 1;

Property Name As %String(XMLPROJECTION = "ATTRIBUTE");

/// Was this property created by an explicit SearchTable property declaration or just by being referenced in a SearchTable item
Property IsImplicit As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Id of the property definition within its SearchTable class extent
/// Storing the PropId instead of the property Name saves storage space in the SearchTable
Property PropId As %Integer(XMLPROJECTION = "NONE");

/// Base class for the database extent of the class defining this property
Property ClassExtent As %String(MAXLEN = 128, XMLPROJECTION = "NONE");

/// Full inheritance path for the class defining this property, down to Ens.VDoc.SearchTable
/// This is used to identify which particular SearchTable subclass defined a particular property
Property ClassDerivation As %String(MAXLEN = 1011, XMLPROJECTION = "NONE");

/// Name of class from which this property is derived
Property SourceClass As %String [ Calculated, Transient ];

Index indexClassProp On (ClassExtent, Name) [ IdKey ];

Index indexPropId On PropId;

Method SourceClassGet() As %String [ CodeMode = expression ]
{
$piece(..ClassDerivation, "~")
}

ClassMethod UpdateOrCreate(pTemplate As Ens.Config.SearchTableProp, Output pProp As Ens.Config.SearchTableProp, pClassExtent As %String, pLockTimeout As %Numeric = 5) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pProp = $$$NULLOREF
		Set tHaveLock = 0
		Set pTemplate.ClassExtent=pClassExtent
		Lock +^EnsSearchTableProps(pTemplate.ClassExtent):pLockTimeout
		If '$Test {
			Set tStatus = $$$ERROR($$$LockFailedToAcquireExclusive, $name(^EnsSearchTableProps(pTemplate.ClassExtent)))
			Quit
		}
		Else { Set tHaveLock = 1 }
		
		Set pProp=..%OpenId(pTemplate.ClassExtent_"||"_pTemplate.Name,,.tStatus)
		If $IsObject(pProp) {
			If pTemplate.ClassDerivation=pProp.ClassDerivation { ; only allow updates if the same SearchTable class is doing it
				#; update property attribute values
				Set pProp.IsImplicit=pTemplate.IsImplicit, pProp.IndexType=pTemplate.IndexType, pProp.StoreNulls=pTemplate.StoreNulls, pProp.PropType = pTemplate.PropType, pProp.Unselective = pTemplate.Unselective
				Set tStatus=pProp.%Save()
			}
			Else {
				Set tTemplateLen = $length(pTemplate.ClassDerivation, "~")
				Set tPropLen = $length(pProp.ClassDerivation, "~")
				If $piece(pTemplate.ClassDerivation, "~", tTemplateLen - tPropLen + 1, tTemplateLen) '= pProp.ClassDerivation {
					Set tStatus = $$$ERROR($$$EnsSearchTablePropCollision, pTemplate.Name, pTemplate.SourceClass, pProp.SourceClass)
				}
			}
		} ElseIf $$$StatusEquals(tStatus,$$$LoadObjectNotFound) { ; if ID did not exist
			Set pProp=pTemplate
			Set tStatus=pProp.%Save() 
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $get(tHaveLock) Lock -^EnsSearchTableProps(pTemplate.ClassExtent)
	Quit tStatus
}

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ProcedureBlock = 1 ]
{
	If insert && (..PropId = "") {
		Set ..PropId=$Increment(^Ens.Config.SearchTablePropC(..ClassExtent))
	}
	Quit $$$OK
}

Storage Default
{
<Data name="SearchTablePropDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ClassDerivation</Value>
</Value>
<Value name="3">
<Value>IndexType</Value>
</Value>
<Value name="4">
<Value>IsImplicit</Value>
</Value>
<Value name="5">
<Value>PropId</Value>
</Value>
<Value name="6">
<Value>PropType</Value>
</Value>
<Value name="7">
<Value>StoreNulls</Value>
</Value>
<Value name="8">
<Value>Unselective</Value>
</Value>
</Data>
<DataLocation>^Ens.Config.SearchTablePropD</DataLocation>
<DefaultData>SearchTablePropDefaultData</DefaultData>
<IdLocation>^Ens.Config.SearchTablePropD</IdLocation>
<IndexLocation>^Ens.Config.SearchTablePropI</IndexLocation>
<StreamLocation>^Ens.Config.SearchTablePropS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
