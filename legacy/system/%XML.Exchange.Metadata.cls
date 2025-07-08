/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Configuration Management Metadata
/// 
/// Details pertaining to an individual Exchange Item. <br>
/// This class is used to include this information in the XML export.  Across different Exchange Item types the id,
/// code and description may be kept in different tags.  The metadata section provides these details in a consistent manner.  
Class %XML.Exchange.Metadata Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property GUID As %RawString(XMLPROJECTION = "ATTRIBUTE");

Property Id As %String(MAXLEN = "");

Property ClassName As %String(MAXLEN = "");

Property Description As %String(MAXLEN = "");

Property Content As array Of %String(MAXLEN = "", XMLITEMNAME = "Class", XMLKEYNAME = "Version");

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set sc = $$$OK
	Set oref=$g(initvalue)
	If $IsObject(oref) {
		Set oid = oref.%Oid()
		Set ..GUID = oref.GUID
		Set ..Id = $$$oidPrimary(oid)
		Set ..ClassName = $$$oidClassName(oid)
		Set ..Description = ##class(%XML.Exchange).GetDescription(oref.%Oid())
		Set sc = ..LoadContent(oref)
	}
	Quit sc
}

Method LoadContent(oref As %RegisteredObject) As %Status [ Private ]
{
	If '$IsObject(oref) Quit $$$OK
	Set class = $classname(oref)
	
	#; Class version details already included.
	If '..Content.IsDefined(class) {
		#; Add source version for this class.
		Do ..InsertClass(class)
	}
	
	#; Attribute Values
	Set ivar="", sc=$$$OK
	For {
		Set ivar=$$$comMemberNext(class,$$$cCLASSinstancevar,ivar)
		If ivar="" Quit
		
		If '$$$comMemberKeyGet(class,$$$cCLASSproperty,ivar,$$$cPROPprivate) {
			Set propertyOref=$Property(oref, ivar)
			
			Set propertyType=$$$comMemberKeyGet(class,$$$cCLASSproperty,ivar,$$$cPROPtype)
			Set classType=$$$comClassKeyGet(propertyType,$$$cCLASSclasstype)
			If classType'="",classType'="datatype",$ClassMethod(propertyType,"%Extends","%XML.Exchange.Adaptor"),$IsObject(propertyOref) {
				Set propertyXMLRef=$$$comMemberArrayGet(class,$$$cCLASSproperty,ivar,$$$cPROPparameter,"XMLREFERENCE")
				
				If propertyXMLRef="COMPLETE" {
					Set propertyRunttimeType=$$$comMemberKeyGet(class,$$$cCLASSproperty,ivar,$$$cPROPruntimetype)
					If (propertyRunttimeType="%Collection.ListOfObj")||(propertyRunttimeType="%Library.ListOfObjects")||(propertyRunttimeType="%Library.RelationshipObject") {
						Set key=""
						For {
							Set itemOref=propertyOref.GetNext(.key)
							If key="" Quit
							If $IsObject(itemOref) {
								Set sc=..LoadContent(itemOref)
							}
							Do propertyOref.%UnSwizzleAt(key)
							Kill listOref
						}
					} Else {
						Set sc=..LoadContent(propertyOref)
					}
				}
			}
			Kill propertyOref
		}
	}
	
	Quit sc
}

Method InsertClass(ClassName As %String)
{
	Set srcVer=$ClassMethod(ClassName,"%GetParameter","SrcVer")
	#; Strip leading '$_Id:' and trailing '$' to avoid RCS keyword expansion when added to Perforce.
	Set key=..GetKey(srcVer)
	Do ..Content.SetAt(ClassName,key)
}

/// Strip leading '$_Id:' and trailing '$' to avoid RCS keyword expansion when added to Perforce.
Method GetKey(SrcVer As %String) [ CodeMode = expression ]
{
$ZStrip($p(SrcVer,":",2),"<>W","$")
}

/// This callback method is invoked by the <METHOD>%ValidateObject</METHOD> method to 
/// provide notification that the current object is being validated.
/// 
/// <P>If this method returns an error then <METHOD>%ValidateObject</METHOD> will fail.
Method %OnValidateObject() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set sc=$$$OK, key=""
	For {
		Set class=..Content.GetNext(.key)
		If key="" Quit
		
		Set srcVer=$ClassMethod(class,"%GetParameter","SrcVer")
		If key'=..GetKey(srcVer) {
			#; Mismatch between versions.
			Set sc=$$$ADDSC(sc,$$$ERROR($$$GeneralError, "Content version mismatch of '"_class_"'"))
		}
	}
	Quit sc
}

}
