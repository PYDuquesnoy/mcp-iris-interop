/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Exchange Adaptor
/// 
/// Sub-classes of %XML.Exchange.Adaptor are included in 
/// Configuration Management.  Configuration Mangement is used to export 
/// and import Exchange Items.  The items are written in XML such that
/// the data is readable and different revisions of the item may 
/// be compared to identify changes.
Class %XML.Exchange.Adaptor Extends %XML.Adaptor [ Abstract, System = 3 ]
{

/// If this parameter is set to 1 then a GUID will be assigned (to the %GUID property) to each new object.
/// When the object is saved for the first time this GUID value will be recorded in a namespace
/// index which will allow GUID to be resolved to OIDs.
Parameter GUIDENABLED = 1;

/// Default value of XMLREFERENCE that specifies how to project references to XML.
/// XMLREFERENCE may be overridden for each property.
/// SUMMARY indicates that only the summary properies of the referenced class
/// are used to represent the reference.  SUMMARY is the default.  Note that by
/// default all properties are of the referenced class are in the summary.
/// COMPLETE indicates that all properties of the referenced class are used
/// to represent the reference.
/// ID indicates that the id of a persistent or serial class is used to represent 
/// the reference.
/// OID indicates that the oid of a persistent or serial class is used to represent 
/// the reference.  The form of the oid will be classname,id.
/// GUID indicates the the GUID of a persistent class is used to represent the reference.
Parameter XMLDEFAULTREFERENCE As STRING = "GUID";

Property GUID As %RawString(XMLPROJECTION = "ATTRIBUTE") [ Transient ];

Method GUIDGet() As %RawString [ ServerOnly = 1 ]
{
	#if $$$comClassKeyGet(%classname,$$$cCLASSclasstype)="persistent"
		If i%GUID="" {
			Set i%GUID = ..%GUID(..%Oid())
		}
		Quit i%GUID
	#endif
	Quit ""
}

Method GUIDSet(Arg As %RawString) As %Status [ ServerOnly = 1 ]
{
	#if $$$comClassKeyGet(%classname,$$$cCLASSclasstype)="persistent"
		Set i%GUID = Arg
		If ..%Id() = "" {
			Do ..%OverrideGuidAssignment(Arg)
		}
	#endif
	Quit $$$OK
}

/// Return the Oid of the Exchange Item that contains this object.
ClassMethod XMLGetElement(id As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %String [ CodeMode = generator, GenerateAfter = %GenerateParameters ]
{
	If $$$comMemberKeyGet(%class,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)   {
		Set root = %class, searching = 1, rootPropetyPath = ""
		While searching {
			Set property=""
			For {
				Set property=$$$defMemberNext(root,$$$cCLASSproperty,property)
				If property = "" {
					#; This class has no parent relationship.
					Set searching = 0
					Quit
				}
				Set relationship=$$$defMemberKeyGet(root,$$$cCLASSproperty,property,$$$cPROPrelationship)
				If relationship {
					Set cardinality=$$$defMemberKeyGet(root,$$$cCLASSproperty,property,$$$cPROPcardinality)
					If (cardinality="parent") {
						#; Use the oddCOM to get the class name resolved.
						Set root = $$$comMemberKeyGet(root,$$$cCLASSproperty,property,$$$cPROPtype)
						Set rootPropetyPath = rootPropetyPath_"."_property
						Quit
					}
				}
			}
		}
		If root = %class {
			#; Use the Object parameter when it's available.
			$$$GENERATE("   If $IsObject(Object),Object.%Id()'="""" Quit Object.%Oid()")
			$$$GENERATE("   Quit $$$oidCompose(id,"""_%class_""")")
			Quit $$$OK
		}
		
		#; Get root id length
		Set idLen = 1, index = ""
		For  {
			Set index=$$$defMemberNext(root,$$$cCLASSindex,index)
			If index="" Quit
			Set idKey=$$$defMemberKeyGet(root,$$$cCLASSindex,index,$$$cINDEXidkey)
			If idKey {
				#; Use the number of properties that make up the Id Key index to determine the length of the id.
				Set idLen=$Length($$$defMemberKeyGet(root,$$$cCLASSindex,index,$$$cINDEXproperties),",")
				Quit
			}
		}
		#; Take just the id portion that is the parent's id.
		$$$GENERATE("   Set id = $Piece(id,""||"","_$Select(idLen=1:1,1:"1,"_idLen)_")")
		#; If the Object.%Id() is empty then call the parent's XMLGetElement method.
		#; This caters for the case when there is a new child to an existing parent.
		$$$GENERATE("   If $IsObject(Object),Object.%Id()="""" Quit Object"_rootPropetyPath_".XMLGetElement(id,Object"_rootPropetyPath_")")
		$$$GENERATE("   Quit $$$oidCompose(id,"""_root_""")")
	}
	Quit $$$OK
}

/// Returns an value to identify the object.
/// This method may be overriden to return a code or description.
ClassMethod XMLExchangeName(id As %String) As %String [ CodeMode = expression ]
{
id
}

/// For very large tables it is necessary to break the records down into
/// sub-directories.  This method returns the sub-directory name to be used
/// for the given id.<p>
/// The sub-directory returned is then appended to the path using ##class(%File).SubDirectoryName()<p>
ClassMethod XMLExchangePath(id As %String) As %String [ CodeMode = expression ]
{
$ClassName($this)
}

/// Get an instance of an XML enabled class.<br><br>
/// 
/// You may override this method to do custom processing (such as initializing
/// the object instance) before returning an instance of this class.
/// However, this method should not be called directly from user code.<br>
/// Arguments:<br>
///     document is the document with %XML.Node or macros in %xmlDOM.inc.<br>
///     nodeId is a node id of the node which defines this object.
///         An %XML.Node object may be obtained for this node using document.GetNode(nodeId)<br>
///     containerOref is the containing object instance when called from XMLImport and
///         is "" when called from %XML.Reader for Correlate'd objects.<br>
ClassMethod XMLNew(document As %XML.Document, node As %Integer, containerOref As %RegisteredObject = "") As %RegisteredObject [ ProcedureBlock = 0, ServerOnly = 1 ]
{
	#define className ##expression(""""_%classname_"""")
	#if $$$comClassKeyGet(%classname,$$$cCLASSclasstype)="persistent"
		New guid, oid, obj
		#; Match based on GUID.
		Set guid = $$$xmlGetAttribute(document.DocumentId,node,"GUID")
		If guid'="" {
			Set oid = ##class(%Library.GUID).%GUIDFind(guid)
			If $Get(oid)'="" {
				If ..%Exists(oid) {
					Set obj = ..%Open(oid)
					Quit obj
				} Else {
					#; GUID refers to an Object which no longer exists.
					#; Remove ^OBJ.GUID references so that the object
					#; being loaded may use the GUID.
					Kill ^OBJ.GUID(0,guid)
					Kill ^OBJ.GUID(1,oid)
				}
			}
		}
		
		Set obj=..%New(),obj.GUID=guid
		Quit obj
	#else
		Quit ..%New()
	#endif
}

/// Returns a matching object based on unique indices
ClassMethod XMLLoadGUID(document As %XML.Document, node As %Integer, containerOref As %RegisteredObject = "") As %RegisteredObject [ CodeMode = generator, ProcedureBlock = 0 ]
{
	If ($$$comClassKeyGet(%class,$$$cCLASSclasstype)="persistent") {
		Set storageName = $$$comClassKeyGet(%class,$$$cCLASSstoragestrategy)
		Set storageType = $$$comMemberKeyGet(%class,$$$cCLASSstorage,storageName,$$$cSDEFtype)
		$$$GENERATE(" Set documentId=document.DocumentId")
		Set SQLCODE=""
		#; Loop ththe unique indices and try to find a match
		&sql(DECLARE indices CURSOR FOR
			SELECT Name, Properties INTO :indexName, :keyName
			FROM %Dictionary.IndexDefinition
		WHERE parent = :%class AND _Unique = 1)
		&sql(OPEN indices)
		&sql(FETCH indices)
		While (SQLCODE=0) {
			If $Length(keyName, ",")=1 {
				Set indices(indexName)=keyName
			}
			&sql(FETCH indices)
		}
		&sql(CLOSE indices)
		
		If $Data(indices) {
			$$$GENERATE(" Set childId = """"")
			$$$GENERATE(" For  {")
			$$$GENERATE("   Set childId = $$$xmlGetNextChild(documentId,node,childId)")
			$$$GENERATE("   If childId = """" Quit")
			Set indexName = ""
			For {
				Set indexName = $Order(indices(indexName))
				If indexName="" Quit
				Set keyName=indices(indexName)
				$$$GENERATE("   If $$$xmlGetLocalName(documentId,childId)="""_keyName_""" {")
				$$$GENERATE("   Set valueId = $$$xmlGetFirstChild(documentId,childId)")
				$$$GENERATE("   Set "_keyName_" = $$$xmlGetNodeValue(documentId,valueId)")
				$$$GENERATE("  }")
			}
			$$$GENERATE(" }")
			$$$GENERATE(" Set matchedId = """"")
			Set indexName = ""
			For {
				Set indexName = $Order(indices(indexName))
				If indexName="" Quit
				Set keyName=indices(indexName)
				$$$GENERATE(" If $g("_keyName_")'="""" {")
				$$$GENERATE("  If '.."_indexName_"Exists("_keyName_", .id) Quit """"")
				$$$GENERATE("  If matchedId="""" {")
				$$$GENERATE("   Set matchedId=id")
				$$$GENERATE("  } ElseIf matchedId'=id {")
				$$$GENERATE("   Quit """"")
				$$$GENERATE("  }")
				$$$GENERATE(" }")
			}
			$$$GENERATE(" If (matchedId'="""") {")
			$$$GENERATE("  Set obj = ..%OpenId(matchedId)")
			$$$GENERATE("  Set obj.GUID = $$$xmlGetAttribute(document.DocumentId,node,""GUID"")")
			$$$GENERATE("  Quit obj")
			$$$GENERATE(" } ")
		}
	}
	$$$GENERATE(" Quit """"")
}

/// Clear propety values in preparation for the values from XML import
Method XMLClear() [ CodeMode = generator ]
{
	Set property=$$$defMemberNext(%class,$$$cCLASSproperty,"")
	While property'="" {
		Set calculated=$$$defMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPcalculated)
		If 'calculated {
			Set xmlprojection=$$$comMemberArrayGet(%class,$$$cCLASSproperty,property,$$$cPROPparameter,"XMLPROJECTION")
			If xmlprojection '= "NONE" {
				Set cardinality=$$$defMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPcardinality)
				Set collection=$$$defMemberKeyGet(%class,$$$cCLASSproperty,property,$$$cPROPcollection)
				If (cardinality="children")||(cardinality="many")||(collection'="") {
					$$$GENERATE(" d .."_property_".Clear()")
				} Else {
					$$$GENERATE(" s .."_property_"=""""")
				}
			}
		}
		Set property=$$$comMemberNext(%class,$$$cCLASSproperty,property)
	}
}

/// This callback method is invoked by the <METHOD>%Delete</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being deleted.
/// 
/// <P>If this method returns an error then the object will not be deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set sc = $$$OK
	Set className = $ClassName($this)
	#; Classes that use %Storage.SQL call to the same code that would be used to perform SQL UPDATE and therefore will fire the SQL trigger.
	#; To avoid firing the change control event twice for these classes we will not include the code for the object event.
	Try {
		If $$$comClassKeyGet(className,$$$cCLASSstoragestrategy)'=""&&('$$$SQLStorageIsSQL($$$comMemberKeyGet(className,$$$cCLASSstorage,$$$comClassKeyGet(className,$$$cCLASSstoragestrategy),$$$cSDEFtype))) {
			If $$$comMemberKeyGet(className,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault) {
				If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
				If $IsObject($Get(%ChangeControl)) {
					Set tmp=%ChangeControl
					New %ChangeControl
					Set sc=tmp.%BeforeDelete(oid)
					Quit
				}
			}
		}
	} Catch {
		Do BACK^%ETN
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
	#; Classes that use %Storage.SQL call to the same code that would be used to perform SQL UPDATE and therefore will fire the SQL trigger.
	#; To avoid firing the change control event twice for these classes we will not include the code for the object event.
	#If $$$comClassKeyGet(%classname,$$$cCLASSstoragestrategy)'=""&&('$$$SQLStorageIsSQL($$$comMemberKeyGet(%classname,$$$cCLASSstorage,$$$comClassKeyGet(%classname,$$$cCLASSstoragestrategy),$$$cSDEFtype)))
		#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
			Set sc = $$$OK
			Try {
				If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
				If $IsObject($Get(%ChangeControl)) {
					Set tmp=%ChangeControl
					New %ChangeControl
					Set sc=tmp.%AfterDelete(oid)
					Quit
				}
			} Catch {
				Do BACK^%ETN
			}
			Quit sc
		#EndIf
	#EndIf
	Quit $$$OK
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	#; Classes that use %Storage.SQL call to the same code that would be used to perform SQL UPDATE and therefore will fire the SQL trigger.
	#; To avoid firing the change control event twice for these classes we will not include the code for the object event.
	Set sc = $$$OK
	Set className = $ClassName($This)
	Try {
		If $$$comClassKeyGet(className,$$$cCLASSstoragestrategy)'=""&&('$$$SQLStorageIsSQL($$$comMemberKeyGet(className,$$$cCLASSstorage,$$$comClassKeyGet(className,$$$cCLASSstoragestrategy),$$$cSDEFtype))) {
			If $$$comMemberKeyGet(className,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault) {
				If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
				If $IsObject($Get(%ChangeControl)) {
					Set tmp=%ChangeControl
					New %ChangeControl
					Set sc=tmp.%BeforeSave(..%Oid(),$This,insert)
					Quit
				}
			}
		}
	} Catch {
		Do BACK^%ETN
	}
	Quit sc
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called after 
/// the object's data has been successfully written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	#; ChangeControl.%AfterSave is done here is guid is blank on SQL AfterInsertTrigger.
	#; On Update, ChangeControl might run twice, but that's ok. Hopefully...
	Set sc = $$$OK
	Set className = $ClassName($this)
	Try {
		If $$$comMemberKeyGet(className,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault) {
			If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
			If $IsObject($Get(%ChangeControl)) {
				Set tmp=%ChangeControl
				New %ChangeControl
				Set sc=tmp.%AfterSave(..%Oid(),$This,insert)
				Quit
			}
		}
	} Catch {
		Do BACK^%ETN
	}
	Quit sc
}

/// This callback method is invoked by the <METHOD>%Open</METHOD> method to 
/// provide notification that the object specified by <VAR>oid</VAR> is being opened.
/// 
/// <P>If this method returns an error then the object will not be opened.
Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	#if $$$comClassKeyGet(%classname,$$$cCLASSclasstype)="persistent"
		#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
			Set sc = $$$OK
			Try {
				If $IsObject($Get(%ChangeControl)) {
					Set tmp=%ChangeControl
					New %ChangeControl
					Set sc=tmp.%BeforeLoad(..%Oid())
					Quit
				}
			} Catch {
				Do BACK^%ETN
			}
			Quit sc
		#EndIf
	#EndIf
	Quit $$$OK
}

Trigger ChangeControlBeforeInsert [ Event = INSERT ]
{
	#define className ##expression(""""_%classname_"""")
	#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		Try {
			If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
			If $IsObject($Get(%ChangeControl)) {
				New oid, sc
				#; %d(1) used to access row id.
				#; The column name will vary between tables.
				Set oid=$$$oidCompose(%d(1),$$$className)
				Set sc=%ChangeControl.%BeforeInsertTrigger(oid, .%d)
				If $$$ISERR(sc) Set %ok=0, %msg=$System.Status.GetErrorText(sc)
			}
		} Catch {
			Do BACK^%ETN
		}
	#EndIf
}

Trigger ChangeControlAfterInsert [ Event = INSERT, Order = 9, Time = AFTER ]
{
	#define className ##expression(""""_%classname_"""")
	#Define storageName $$$defClassKeyGet(%classname,$$$cCLASSstoragestrategy)
	#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		Try {
			#If $Length($$$defClassKeyGet(%classname,$$$cCLASSstoragestrategy))
				#If $Length($$$defMemberKeyGet(%classname,$$$cCLASSstorage,$$$storageName,$$$cSDEFidlocation))
					#Define idLocation ##expression($$$defMemberKeyGet(%classname,$$$cCLASSstorage,$$$storageName,$$$cSDEFidlocation))
					If $Get(%xmlExchangeItem) {
						#; Child object.
						#; Ensure that any child id counter is equal or greater than this object id.
						Set childsub=$Piece(%d(1),"||",$Length(%d(1),"||"))
						If $Get($$$idLocation) < childsub {
							Set $$$idLocation = childsub
						}
					}
				#EndIf
			#EndIf
			If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
			If $IsObject($Get(%ChangeControl)) {
				New oid, sc
				#; %d(1) used to access row id.
				#; The column name will vary between tables.
				Set oid=$$$oidCompose(%d(1),$$$className)
				Set sc=%ChangeControl.%AfterInsertTrigger(oid, .%d)
				If $$$ISERR(sc) Set %ok=0, %msg=$System.Status.GetErrorText(sc)
			}

		} Catch {
			Do BACK^%ETN
		}
	#EndIf
}

Trigger ChangeControlBeforeUpdate [ Event = UPDATE ]
{
	#define className ##expression(""""_%classname_"""")
	#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		Try {
			If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
			If $IsObject($Get(%ChangeControl)) {
				New oid, sc
				#; %d(1) used to access row id.
				#; The column name will vary between tables.
				Set oid=$$$oidCompose(%d(1),$$$className)
				Set sc=%ChangeControl.%BeforeUpdateTrigger(oid, .%d)
				If $$$ISERR(sc) Set %ok=0, %msg=$System.Status.GetErrorText(sc)
			}
		} Catch {
			Do BACK^%ETN
		}
	#EndIf
}

Trigger ChangeControlAfterUpdate [ Event = UPDATE, Order = 9, Time = AFTER ]
{
	#define className ##expression(""""_%classname_"""")
	#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		Try {
			If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
			If $IsObject($Get(%ChangeControl)) {
				New oid, sc
				#; %d(1) used to access row id.
				#; The column name will vary between tables.
				Set oid=$$$oidCompose(%d(1),$$$className)
				Set sc=%ChangeControl.%AfterUpdateTrigger(oid, .%d)
				If $$$ISERR(sc) Set %ok=0, %msg=$System.Status.GetErrorText(sc)
			}
		} Catch {
			Do BACK^%ETN
		}
	#EndIf
}

Trigger ChangeControlBeforeDelete [ Event = DELETE ]
{
	#define className ##expression(""""_%classname_"""")
	#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		Try {
			If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
			If $IsObject($Get(%ChangeControl)) {
				New oid, sc
				#; %d(1) used to access row id.
				#; The column name will vary between tables.
				Set oid=$$$oidCompose(%d(1),$$$className)
				Set sc=%ChangeControl.%BeforeDeleteTrigger(oid)
				If $$$ISERR(sc) Set %ok=0, %msg=$System.Status.GetErrorText(sc)
			}
		} Catch {
			Do BACK^%ETN
		}
	#EndIf
}

Trigger ChangeControlAfterDelete [ Event = DELETE, Order = 9, Time = AFTER ]
{
	#define className ##expression(""""_%classname_"""")
	#Define storageName $$$defClassKeyGet(%classname,$$$cCLASSstoragestrategy)
	#If $$$comMemberKeyGet(%classname,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault)
		Try {
			#If $Length($$$defClassKeyGet(%classname,$$$cCLASSstoragestrategy))
				#If $Length($$$defMemberKeyGet(%classname,$$$cCLASSstorage,$$$storageName,$$$cSDEFidlocation))
					#Define idLocation ##expression($$$defMemberKeyGet(%classname,$$$cCLASSstorage,$$$storageName,$$$cSDEFidlocation))
					If $Get(%xmlExchangeItem) {
						#; Child object.
						#; Ensure that any child id counter is equal or greater than this object id.
						If $Order($$$idLocation)="" {
							Kill $$$idLocation
						}
					}
				#EndIf
			#EndIf
			If '$Data(%ChangeControl) Do ##class(%XML.Exchange.ChangeControlInterface).ChangeControlCreate($Select($IsObject($Get(%session)):$Get(%session.Data("LOGON.USERID")),1:""))
			If $IsObject($Get(%ChangeControl)) {
				New oid, sc
				#; %d(1) used to access row id.
				#; The column name will vary between tables.
				Set oid=$$$oidCompose(%d(1),$$$className)
				Set sc=%ChangeControl.%AfterDeleteTrigger(oid)
				If $$$ISERR(sc) Set %ok=0, %msg=$System.Status.GetErrorText(sc)
			}
		} Catch {
			Do BACK^%ETN
		}
	#EndIf
}

}
