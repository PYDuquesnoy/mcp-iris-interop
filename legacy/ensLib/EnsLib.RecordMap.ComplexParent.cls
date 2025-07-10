/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class to implement common functions needed by objects that reference extensions of
/// <class>EnsLib.RecordMap.ComplexChild</class>, primarily the <class>EnsLib.RecordMap.ComplexSequence</class>
/// and all generated Record classes that are marked as complexBatchManaged.
Class EnsLib.RecordMap.ComplexParent Extends EnsLib.RecordMap.ComplexBase [ Abstract, System = 4 ]
{

/// Generated method to ensure that we correctly remove references from our children  and then delete
/// the children if they are no longer referenced.
ClassMethod DeleteRecords(pID As %String) As %Status [ CodeMode = objectgenerator, ServerOnly = 1 ]
{
	Do %code.WriteLine($c(9)_"Set tStatus = $$$OK")
	Do %code.WriteLine($c(9)_"Try {")
	Do %code.WriteLine($c(9,9)_"Set tRef = ..%OpenId(pID,,.tStatus)")
	Do %code.WriteLine($c(9,9)_"If $$$ISERR(tStatus) { If $SYSTEM.Status.Equals(tStatus,$$$LoadObjectNotFound) {Set tStatus = $SYSTEM.Status.Error($$$DeleteObjectNotFound,$classname(),pID)} Quit } ")
	Set tPropKey = ""
	For {
		Set tProp = %class.Properties.GetNext(.tPropKey)
		Quit:(tPropKey = "")
		If ("%" '= $extract(tProp.Name)) {
			Set tDoDelete = (tProp.Collection '= "") || 'tProp.Relationship
			If tDoDelete {
				Set tIndent = $c(9,9)
				If (tProp.Collection '= "") {
					Set tOIDExpression = "tOID"
					Do %code.WriteLine(tIndent_"Set tKey = """"")
					Do %code.WriteLine(tIndent_"For {")
					Set tIndent = tIndent _ $c(9)
					Do %code.WriteLine(tIndent_"Set "_tOIDExpression_" = tRef."_tProp.Name_".GetObjectNext(.tKey)")
					Do %code.WriteLine(tIndent_"Quit:(tKey = """")")
				}
				Else {
					Set tOIDExpression = "tRef."_tProp.Name_".""%%OID"""
					Do %code.WriteLine(tIndent_"If $IsObject(tRef."_tProp.Name_") && ("_tOIDExpression_" '= """") {")
					Set tIndent = tIndent _ $c(9)
				}
				Do %code.WriteLine(tIndent_"Set tChildID = $$$oidPrimary("_tOIDExpression_")")
				Do %code.WriteLine(tIndent_"Set tStatus = ##class("_tProp.Type_").%ParentRemove(tChildID,$classname(tRef),pID)")
				Do %code.WriteLine(tIndent_"If $$$ISERR(tStatus) Quit")
				Do %code.WriteLine(tIndent_"If '##class("_tProp.Type_").%IsReferenced(tChildID) {")
				Do %code.WriteLine(tIndent_$c(9)_"Set tStatus = ##class("_tProp.Type_").%Delete("_tOIDExpression_")")
				Do %code.WriteLine(tIndent_$c(9)_"If $system.Status.Equals(tStatus,$$$DeleteObjectNotFound,$$$NotAnInstanceError) Set tStatus = $$$OK")
				Do %code.WriteLine(tIndent_$c(9)_"If $$$ISERR(tStatus) Quit")
				Do %code.WriteLine(tIndent_"}")
				Set tIndent = $extract(tIndent,1,*-1)
				Do %code.WriteLine(tIndent_"}")
				If tProp.Collection '= "" {
					Do %code.WriteLine(tIndent_"If $$$ISERR(tStatus) Quit")
				}
			}
		}
	}
	Do %code.WriteLine($c(9)_"} Catch { Set tStatus = $$$SystemError }")
	Do %code.WriteLine($c(9)_"Quit tStatus")
	Quit $$$OK
}

Method UpdateReferences() As %Status [ CodeMode = objectgenerator, Private ]
{
	Do %code.WriteLine($c(9)_"Set tStatus = $$$OK")
	Do %code.WriteLine($c(9)_"Try {")
	Do %code.WriteLine($c(9,9)_"Set tID = ..%GetId()")
	
	Set tPropKey = ""
	For {
		Set tProp = %class.Properties.GetNext(.tPropKey)
		Quit:(tPropKey = "")
		If ("%" '= $extract(tProp.Name)) {
			Set tIndent = $c(9,9)
			If (tProp.Collection '= "") {
				Do %code.WriteLine(tIndent_"If .."_tProp.Name_".%IsModified() {")
				Set tIndent = tIndent _ $c(9)
				Do %code.WriteLine(tIndent_"Set tStatus  = ..updateArrayReferences("""_tProp.Name_""")")
			}
			Else {
				Do %code.WriteLine(tIndent_"Set tStatus  = ..updatePropertyReference("""_tProp.Name_""")")
			}
			Do %code.WriteLine(tIndent_"If $$$ISERR(tStatus) Quit")
			If (tProp.Collection '= "") {
				Set tIndent = $extract(tIndent,1,*-1)
				Do %code.WriteLine(tIndent_"}")
			}
		}
	}
	Do %code.WriteLine($c(9)_"} Catch { Set tStatus = $$$SystemError }")
	Do %code.WriteLine($c(9)_"Quit tStatus")
	Quit $$$OK
}

Method ValidateObject() As %Status [ CodeMode = objectgenerator ]
{
	Set tPropKey = ""
	For {
		Set tProp = %class.Properties.GetNext(.tPropKey)
		Quit:(tPropKey = "")
		Continue:("%" = $extract(tProp.Name))
		If (tProp.Collection '= "") || tProp.Relationship {
			Set tMinRepeats = tProp.Parameters.GetAt("MINREPEATS")
			If tMinRepeats {
				Do %code.WriteLine($c(9)_"If ("_tMinRepeats_" > .."_tProp.Name_".Count()) Quit $$$ERROR($$$EnsRecordMapErrRepeatMin,"_tMinRepeats_","""_tProp.Name_""")")
			}
			Set tMaxRepeats = tProp.Parameters.GetAt("MAXREPEATS")
			If tMaxRepeats {
				Do %code.WriteLine($c(9)_"If ("_tMaxRepeats_" < .."_tProp.Name_".Count()) Quit $$$ERROR($$$EnsRecordMapErrRepeatMax,"_tMaxRepeats_","""_tProp.Name_""")")
			}
		}
	}
	Do %code.WriteLine($c(9)_"Quit $$$OK")
	Quit $$$OK
}

/// Generated helper method to optimise the execution of <method>updatePropertyReference</method>()
/// and <method>updateArrayReferences</method>(). The method returns the type of a given property.
ClassMethod getPropType(pPropName As %String = "") As %String [ CodeMode = objectgenerator, Private ]
{
	Do %code.WriteLine($c(9)_"Quit $case(pPropName,")
	Set tPropKey = ""
	For {
		Set tProp = %class.Properties.GetNext(.tPropKey)
		Quit:(tPropKey = "")
		If "%" '= $extract(tProp.Name) {
			Do %code.WriteLine($c(9,9)_""""_tProp.Name_""": """_tProp.Type_""",")
		}
	}
	Do %code.WriteLine($c(9,9,9)_": """")")
	Quit $$$OK
}

/// Generated helper method to optimise the execution of the <method>updateArrayReferences</method>().
/// The method returns the SQL table name for a given array property.
ClassMethod getArraySQLTable(pPropName As %String = "") As %String [ CodeMode = objectgenerator, Private ]
{
	Do %code.WriteLine($c(9)_"Quit $case(pPropName,")
	Set tPropKey = ""
	For {
		Set tProp = %class.Properties.GetNext(.tPropKey)
		Quit:(tPropKey = "")
		If ("%" '= $extract(tProp.Name)) && (tProp.Collection = "array") {
			Set tSubTableName = $get($$$EXTPROPsqltablename($$$pEXT,%class.Name,tProp.Name))
			If tSubTableName '= "" Do %code.WriteLine($c(9,9)_""""_tProp.Name_""": """_tSubTableName_""",")
		}
	}
	Do %code.WriteLine($c(9,9,9)_": """")")
	Quit $$$OK
}

/// Helper method called from <method>UpdateReferences</method> to ensure that 
Method updateArrayReferences(pPropName As %String = "") As %Status [ Private ]
{
	Set tStatus = $$$OK
	Try {
		If pPropName = "" Quit
		Set tArray = $property($this,pPropName)
		Set tSubTable = ..getArraySQLTable(pPropName)
		Set tSQLSchema = $$$comClassKeyGet($classname($this),$$$cCLASSsqlschemaname)
		Set tThisTableName = $$$comClassKeyGet($classname($this),$$$cCLASSsqltablename)
		If (tThisTableName = "") Set tThisTableName = ..%ClassName()
		Set tChildClass = ..getPropType(pPropName)
		Set tID = ..%Id()
		If (tID = "") || (tSubTable = "") || (tSQLSchema = "") || (tChildClass = "") Quit

		Set tTemp = $increment($$$EnsRecordMapComplexBatchTemp)
		Set tKey = ""
		For {
			Set tChildID = tArray.GetObjectIdNext(.tKey)
			Quit:(tKey = "")
			If tChildID '= "" Set $$$EnsRecordMapComplexBatchTemp(tTemp,"add",tChildID) = ""
		}
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode = 0
		Set tStatus = tStatement.%Prepare("SELECT "_pPropName_" FROM "_tSQLSchema_"."_tSubTable_" WHERE "_tThisTableName_" = ?")
		If $$$ISERR(tStatus) Quit
		Set tRS = tStatement.%Execute(tID)
		While tRS.%Next() {
			Set tChildID = tRS.%Get(pPropName)
			If tChildID '= "" {
				If $data($$$EnsRecordMapComplexBatchTemp(tTemp,"add",tChildID)) {
					Kill $$$EnsRecordMapComplexBatchTemp(tTemp,"add",tChildID)
				}
				Else {
					Set $$$EnsRecordMapComplexBatchTemp(tTemp,"remove",tChildID) = ""
				}
			}
		}
		Set tClassname = $classname($this)
		Set tChildID = ""
		For {
			Set tChildID = $order($$$EnsRecordMapComplexBatchTemp(tTemp,"add",tChildID))
			Quit:(tChildID = "")
			Set tStatus = $classmethod(tChildClass,"%ParentAdd",tChildID,tClassname,tID)
			If $$$ISERR(tStatus) Quit
		}
		For {
			Set tChildID = $order($$$EnsRecordMapComplexBatchTemp(tTemp,"remove",tChildID))
			Quit:(tChildID = "")
			Set tStatus = $classmethod(tChildClass,"%ParentRemove",tChildID,tClassname,tID)
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch { Set tStatus = $$$SystemError }
	If $get(tTemp) Kill $$$EnsRecordMapComplexBatchTemp(tTemp)
	Quit tStatus
}

Method updatePropertyReference(pPropName As %String = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		If pPropName = "" Quit
		Set tChildClass = ..getPropType(pPropName)
		Set tID = ..%Id()
		If (tID = "") || (tChildClass = "") Quit
		Set tChildID = $$$oidPrimary($method($this,pPropName_"GetObject",1))
		Set tStoredID = $classmethod($classname($this),pPropName_"GetStored",tID)
		If tChildID = tStoredID Quit
		If tStoredID '= "" {
			Set tStatus = $classmethod(tChildClass,"%ParentRemove",tStoredID,$classname($this),tID)
			If $$$ISERR(tStatus) Quit
		}
		If tChildID '= "" {
			Set tStatus = $classmethod(tChildClass,"%ParentAdd",tChildID,$classname($this),tID)
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch { Set tStatus = $$$SystemError }
	Quit $$$OK
}

}
