/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements storage for various transformation objects.
/// 
/// Such objects use precalculated data to perform transformation. The data is multidimensional and thus 
/// can not be stored in usual way.
Class %DeepSee.extensions.BlackBox [ Abstract, System = 4 ]
{

Parameter MainSubscript = "md";

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called after 
/// the object's data has been successfully written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim cDef As %Dictionary.CompiledClass = ""
	#dim pDef As %Dictionary.CompiledProperty
	#dim global, pName, command As %String
	#dim i, n As %Integer
	#dim id, md As %String
	
	Try {
		set cDef = ..GetClassDef(.sc)
		Quit:$$$ISERR(sc)
		
		set sc = ..GetDataLocation(cDef, .global)
		Quit:$$$ISERR(sc)
		
		set n = cDef.Properties.Count()
		set id = ..%Id()
		set md = ..#MainSubscript
		for i=1:1:n {
			set pDef = cDef.Properties.GetAt(i)
			set pName = pDef.Name

			if (pDef.MultiDimensional) {
				set command = "Merge "_global_"("""_id_""","""_md_""","""_pName_""") = .."_pName
				//w command, !	
				x command
			}
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> has been deleted.
/// The callback occurs immediately after %DeleteData has been called. If %DeleteData returns
/// an error then %OnAfterDelete is not called.
/// 
/// <P>If %OnAfterDelete returns an error (%Status) then the transaction is rolled back.
ClassMethod %OnAfterDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim cDef As %Dictionary.CompiledClass = ""
	#dim global As %String
	#dim id, md As %String
	
	Try {
		set cDef = ..GetClassDef(.sc)
		Quit:$$$ISERR(sc)
		
		set sc = ..GetDataLocation(cDef, .global)
		Quit:$$$ISERR(sc)

		set id = $li(oid,1)
		set md = ..#MainSubscript
		k @global@(id,md)		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

/// This callback method is invoked by the <METHOD>%Open</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being opened.
/// 
/// <P>If this method returns an error then the object will not be opened.
Method %OnOpen1() As %Status [ Private, ServerOnly = 1 ]
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim cDef As %Dictionary.CompiledClass = ""
	#dim pDef As %Dictionary.CompiledProperty
	#dim global, pName, command As %String
	#dim i, n As %Integer
	#dim id, md As %String
	
	Try {
		set cDef = ..GetClassDef(.sc)
		Quit:$$$ISERR(sc)
		
		set sc = ..GetDataLocation(cDef, .global)
		Quit:$$$ISERR(sc)
		
		set n = cDef.Properties.Count()
		set id = ..%Id()
		set md = ..#MainSubscript
		for i=1:1:n {
			set pDef = cDef.Properties.GetAt(i)
			set pName = pDef.Name

			if (pDef.MultiDimensional) {
				set command = "Merge .."_pName_" = "_global_"("""_id_""","""_md_""","""_pName_""")"
				// w command, !	
				x command
			}
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod GetDataLocation(cDef As %Dictionary.CompiledClass, Output dataName) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim classId, storageId As %String
	#dim storage As %Dictionary.CompiledStorage
	#dim i, n As %Integer
	
	Try {
		
		set storageId = cDef.StorageStrategy
		set n = cDef.Storages.Count()
		set storage = ""
		for i=1:1:n {
			if (cDef.Storages.GetAt(i).Name = storageId) {
				set storage = cDef.Storages.GetAt(i)
				Quit
			}
		}
		
		if (storage = "") {
			set sc = $$$ERROR($$$GeneralError,"Storage not defined for class "_classId)
			Quit
		}
		
		set dataName = storage.DataLocation
		
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod GetClassDef(Output sc As %Status) As %String
{
	set sc = $$$OK
	#dim ex As %Exception.AbstractException
	#dim cDef As %Dictionary.CompiledClass = ""
	#dim classId As %String
	
	Try {
		set classId = ..%ClassName(1)
		set cDef = ##class(%Dictionary.CompiledClass).%OpenId(classId, -1, .sc)
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit cDef
}

Storage Default
{
<Data name="BlackBoxDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.extensions.BlackBoxD</DataLocation>
<DefaultData>BlackBoxDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%DeepSee.extensions.BlackBoxD</IdLocation>
<IndexLocation>^%DeepSee.extensions.BlackBoxI</IndexLocation>
<StreamLocation>^%DeepSee.extensions.BlackBoxS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
