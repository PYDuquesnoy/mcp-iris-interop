/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// This class manages and contains the list of class defintions 
/// that are created from an XML Schema. This class is intended for internal use by the 
/// XML Schema Wizard.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class.
Class %XML.Utils.SchemaResult Extends %RegisteredObject [ System = 3 ]
{

/// Messages for localization of XML Schema Wizard result.	
Parameter DOMAIN = "%TemplateMessages";

/// A multi-dimensional array of class names<BR>
/// Classes(name) = key (in original ClassTree)
Property Classes As %String [ MultiDimensional ];

/// SchemaReader that created this result
Property Reader As SchemaReader;

/// Array of feature codes for generated classes:
/// The possible nodes are as follows:<br>
///    Features("DEFAULTSEQUENCE") If this node exists, the wizard does not set the XMLSEQUENCE parameter in the generated classes.<br>
///    Features("JAVA") If this node exists, each class includes a Java projection.<br>
///    Features("NOSEQUENCE") If this node exists, the wizard sets the XMLSEQUENCE parameter to 0 in the generated classes.<br>
///    Features("POPULATE") If this node exists, each class extends %Populate in addition to %XML.Adaptor.<br>
///    Features("SQLCOLUMNS") If this node exists, each class property specifies a value for the SqlColumnNumber keyword, so that the properties have the same order in SQL that they have in the schema.<br>
///    Features("IGNORENULL") If this node is set, the XMLIGNORENULL parameter is set to this value for each class.
///    Features("BINARYASSTREAM") If this node exists, then use %Stream.GlobalBinary for base64Binary type
///    Features("XMLFORMAT") If this node is set, the XMLFORMAT parameter is set to this value for each class.
Property Features As %String [ MultiDimensional ];

/// Integer tree id within ^IRIS.Temp
Property Tree As %Integer;

/// Index for creating namespace prefixes.
Property PrefixIndex As %Integer [ InitialExpression = 0 ];

/// Create a Schema Result given a SchemaReader
ClassMethod CreateResult(pReader As SchemaReader, pPackage As %String = "", ByRef pFeatures As %String) As SchemaResult
{
	Set tResult = ""
	Set $ztrap = "Trap"

	Set tResult = ..%New()
	
	Set tResult.Reader = pReader
	Merge tResult.Features = pFeatures
	Set tResult.Tree = pReader.Tree

	Do tResult.SetupResult(pPackage)
	
	Quit tResult

Trap
	Set $ztrap = ""
	Quit ""
}

/// Setup a new Schema Result given a SchemaReader
Method SetupResult(pReader As SchemaReader, pPackage As %String = "", ByRef pFeatures As %String) As SchemaResult
{
	Do {
		// now make list of classes...
		Set tKey = $order($$$ClassTree(""))
		While (tKey '= "") {
			If ('$get($$$ClassTree(tKey,"Removed"))) {
				// figure out class name and add it to the array
				
				Set tCls = $get($$$ClassTree(tKey,"ClassName"))
				
				If tCls'="" {
					If (tCls [ ".") {
						Set tClassName = tCls
						//Set package = $P(cls,".",1,$L(cls,".")-1)
						//Set cls = $P(cls,".",$L(cls,"."))
					}
					ElseIf (pPackage '= "") {
						Set tClassName = pPackage _ "." _ tCls
					}
					Else {
						Set tClassName = tCls
					}
					
					// normalize the class name!!!
					Set tClassName = $TR(tClassName,"_","")
					
					Set ..Classes(tClassName) = tKey
				}
			}
			Set tKey = $order($$$ClassTree(tKey))
		}
		
	} While(0)
	
	Quit
}

/// Create a class definition for an entry in the class tree.
Method CreateClassDef(pClassName As %String, test As %Boolean = 0, ByRef pCDef As %Dictionary.ClassDefinition) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Set cdef = ""
	
	Do {
		// lookup up class key
		Set key = $get(..Classes(pClassName))

		Set tSeqNo = 0
		// SQL columns must be numbered starting at 2 (1 = ID)
		Set tColNo = 1

		
		Set tSrc = $get($$$ClassTree(key,"src"))
		If tSrc '= "" Set tSrc = ..Reader.ElementSrc(tSrc)

		If ('$ZName(pClassName,4)) {
			// invalid class name
			Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("Invalid Class Name")_": " _ pClassName)
			Quit
		}
		
		// Verify the XMLIGNORENULL parameter
	    If $data(..Features("IGNORENULL")),$case(..Features("IGNORENULL"),0:0,1:0,"inputonly":0,"runtime":0,:1) {
			Set tSC=$$$ERROR($$$XMLInvalidIgnoreNULL,..Features("IGNORENULL"))
			Quit
		}
		// Verify the XMLFORMAT parameter
		If $data(..Features("XMLFORMAT")),$case($zcvt(..Features("XMLFORMAT"),"L"),"":0,"encoded":0,"literal":0,:1) {
    		Set tSC=$$$ERROR($$$XMLInvalidFormatParameter)
    		Quit
		}

		Set cdef = ##class(%Dictionary.ClassDefinition).%New(pClassName)
		
		Set cdef.Name = pClassName
		Set cdef.ProcedureBlock = 1
		#; Force ClassVersion to 25 since LegacyInstanceContext is not needed
		Set cdef.ClassVersion=25
		
		// get class name...
		Set tShortName = $P(pClassName,".",$L(pClassName,"."))
		Set tPackage = $P(pClassName,".",1,$L(pClassName,".")-1)
		
		If $get($$$ClassTree(key,"CompileAfter"))'="" {
			Set cdef.CompileAfter = $$$ClassTree(key,"CompileAfter")

			// normalize the class name!!!
			Set cdef.CompileAfter = $TR(cdef.CompileAfter,"_","")
		
			// !!! remove ourself from CompileAfter list if we are in there!
			If (cdef.CompileAfter [ pClassName) {
				For ca = 1:1:$L(cdef.CompileAfter,",") {
					Set calist($P(cdef.CompileAfter,",",ca)) = ""
				}
			
				Kill calist(pClassName)
				Set cdef.CompileAfter = ""
				Set cacls = $order(calist(""))
				While (cacls '= "") {
					Set cdef.CompileAfter = cdef.CompileAfter _ $S(cdef.CompileAfter="":"",1:",") _ cacls
					Set cacls = $order(calist(cacls))
				}
			}
		}
		
		If (..IsSQLWord(tShortName)) {
			Set cdef.SqlTableName = "_" _ tShortName
		}
		
		Set cdef.Description = $get($$$ClassTree(key,"Description"))
		If 'test && (tSrc '= "") {
			Set:cdef.Description'="" cdef.Description = cdef.Description _ $C(13,10)
			Set query=$piece(tSrc,"?",2,$length(tSrc,"?"))
			If query '="" {
				Set path=$piece(tSrc,"?",1)
				Set newQuery=""
				For i=1:1:$length(query,"&") {
					Set queryPart=$piece(query,"&",i)
					If $case($piece(queryPart,"=",1),"IRISUsername":0,"IRISPassword":0,"CacheUserName":0,"CachePassword":0,:1) {
						If newQuery'="" Set newQuery=newQuery_"&"
						Set newQuery=newQuery_queryPart
					}
				}
				Set src=path_$select(newQuery="":"",1:"?"_newQuery)
			} Else {
				Set src=tSrc
			}
			Set cdef.Description = cdef.Description _ $$$Text("Created from")_": " _ src
		}
	
		If $get($$$ClassTree(key,"SuperClass"))="" {
			Set $$$ClassTree(key,"SuperClass") = ..Reader.TypeToClass($get($$$ClassTree(key,"Super")))
		}
		Set cdef.Super = $$$ClassTree(key,"SuperClass")
		// Support BINARYASSTREAM feature
		If $data(..Features("BINARYASSTREAM")),cdef.Super="%xsd.base64Binary",
		   '$get($$$ClassTree(key,"SuperAttribute")) {
			Set cdef.Super="%Stream.GlobalBinary"
		}
			
		Set ClassType = ..Reader.FindClassType(key)
		If $data($$$ClassTree(key,"abstract")) Set cdef.Abstract = 1
		
		// top-level (non-datatype) classes need to be XML adapted.
		// These are the only classes that can have POPULATE feature.
		If ((cdef.Super = "%Persistent") || (cdef.Super = "%SerialObject") || (cdef.Super = "%RegisteredObject")) {
			Set cdef.Super = cdef.Super _ ",%XML.Adaptor"
	
			If ($data(..Features("POPULATE"))) {
				Set cdef.Super = cdef.Super _ ",%Populate"
			}
		} ElseIf $data(..Features("SQLCOLUMNS")) {
			Set tColNo = tColNo + ..SuperPropertyCount(cdef.Super)
		}
		
		// Add MAXLEN = "" to datatype classes inheriting from %String
		If (cdef.Super = "%String") && '$data($$$ClassTree(key,"Parameter","MAXLEN")) {
			Set $$$ClassTree(key,"Parameter","MAXLEN")=""
		}
		
		/// Add Java projection if feature defined and not datatype class.
		If ($data(..Features("JAVA"))) && (ClassType'="datatype") {
			// add a Java projection
			Set pdef = ##class(%Dictionary.ProjectionDefinition).%New(pClassName _ ":Java")
			Set tSeqNo = tSeqNo + 1
			Set pdef.SequenceNumber = tSeqNo
			Set pdef.Type = "%Projection.Java"
			Do pdef.Parameters.SetAt(1,"MAKE")
			Do cdef.Projections.Insert(pdef)
		}
		
		// Create Query for typed dataset.
		Set dataset = $get($$$ClassTree(key,"dataset"))
		If (cdef.Super = "%XML.DataSet") && (dataset '= "") {
			Set datasetName = $list(dataset,1)
			Set queryName = $list(dataset,2)
			Set rowspec = $list(dataset,3)
			Set qrowspec = ""
			If rowspec'="" {
				For i=1:1:$length(rowspec,",") {
					Set spec = $piece(rowspec,",",i)
					Set fieldname = $piece(spec,":",1)
					Set type = ..Reader.TypeToClass($piece(spec,":",2))
					Set qrowspec = qrowspec _ fieldname _ ":" _ type _ ","
				}
			}
			Set $extract(qrowspec,$length(qrowspec)) = ""
			Set qu = ##class(%Dictionary.QueryDefinition).%New(pClassName_"."_dataset)
			Set tSeqNo = tSeqNo + 1
			Set qu.SequenceNumber = tSeqNo
			Set qu.Name = queryName
			Set qu.Description = $$$Text("Query for typed dataset")
			Set qu.Type = "%Library.Query"
 			Do qu.Parameters.SetAt(qrowspec,"ROWSPEC")
			Do cdef.Queries.Insert(qu)
			Set $$$ClassTree(key,"Parameter","XMLNAME")=datasetName
			Set $$$ClassTree(key,"Parameter","CLASSNAME")=pClassName
			Set $$$ClassTree(key,"Parameter","QUERYNAME")=queryName
			Kill $$$ClassTree(key,"Parameter","XMLSEQUENCE")
		}
	
		// parameters
		Set parm = $order($$$ClassTree(key,"Parameter",""))
		Set nosequence = $data(..Features("NOSEQUENCE"))
		Set defaultsequence = $data(..Features("DEFAULTSEQUENCE"))
		While (parm '= "") {
			Set skip=0
			Set val = $get($$$ClassTree(key,"Parameter",parm))
			If (val = "") && (parm '= "MAXLEN") {
				Set skip=1
			}
			
			If 'skip {
				Set pdef = ##class(%Dictionary.ParameterDefinition).%New(pClassName _ ":" _ parm)
				
				// normalize value for ELEMENTTYPE parm...
				If parm = "ELEMENTTYPE" {
					Set val = ..Reader.TypeToClass(val,.isCacheType)
					// Fixup Super in the case collections
					Set cdef.Super = $select(isCacheType:"%ListOfDataTypes",1:"%ListOfObjects")
				} ElseIf parm = "XMLSEQUENCE" {
					If nosequence {
						Set val = 0
					} ElseIf defaultsequence {
						Set skip=1
					}
				}
			}
			
			If 'skip {
				Set pdef.Default = val
				
				Set tSeqNo = tSeqNo + 1
				Set pdef.SequenceNumber = tSeqNo
				
				Do cdef.Parameters.Insert(pdef)
			}
	
			Set parm = $order($$$ClassTree(key,"Parameter",parm))
		}
	
		/// Add XMLIGNORENULL parameter if requested
		If $data(..Features("IGNORENULL")) && (ClassType'="datatype") {
			Set pdef = ##class(%Dictionary.ParameterDefinition).%New(pClassName _ ":" _ "XMLIGNORENULL")
			Set tSeqNo = tSeqNo + 1
			Set pdef.SequenceNumber = tSeqNo
			Set pdef.Default = ..Features("IGNORENULL")
			Do cdef.Parameters.Insert(pdef)
		}

		/// Add XMLFORMAT parameter if requested
		If $data(..Features("XMLFORMAT")) && (ClassType'="datatype") {
			Set pdef = ##class(%Dictionary.ParameterDefinition).%New(pClassName _ ":" _ "XMLFORMAT")
			Set tSeqNo = tSeqNo + 1
			Set pdef.SequenceNumber = tSeqNo
			Set pdef.Default = ..Features("XMLFORMAT")
			Do cdef.Parameters.Insert(pdef)
		}

		// Indices
		// make sure indices are listed first!
		Set ino = $order($$$ClassTree(key,"Index",""))
		While (ino '= "") {
			Set iname = $get($$$ClassTree(key,"Index",ino,"Name"))
			Set idef = ##class(%Dictionary.IndexDefinition).%New(pClassName _ ":" _ iname)
			Set idef.Type = $get($$$ClassTree(key,"Index",ino,"Type"))
			Set idef.Properties = $get($$$ClassTree(key,"Index",ino,"Property"))
		
			Set tSeqNo = tSeqNo + 1
			Set idef.SequenceNumber = tSeqNo
			Do cdef.Indices.Insert(idef)
	
			Set ino = $order($$$ClassTree(key,"Index",ino))
		}

		// Determine if identity property is to be added to the class
		// and add identity if needed.
		Set addIdentity = $zcvt(..Reader.AddIdentity,"U")
		If $case(addIdentity,"ID":1,"OID":1,"GUID":1,:0) && ($extract(cdef.Super,1,$length("%Persistent,"))="%Persistent,") {
			Set pname = "%identity"
			Set tProps(pname) = ""
			
			Set pdef = ##class(%Dictionary.PropertyDefinition).%New(pClassName _ ":" _ pname)
	
			Set tSeqNo = tSeqNo + 1
			Set pdef.SequenceNumber = tSeqNo
	
			If $data(..Features("SQLCOLUMNS")) {
				Set tColNo = tColNo + 1
				Set pdef.SqlColumnNumber= tColNo
			}
			
			Set pdef.Type = "%XML."_$case(addIdentity,"ID":"Id","OID":"Oid",:"GUID")		
			Do pdef.Parameters.SetAt("ATTRIBUTE","XMLPROJECTION")
			Do pdef.Parameters.SetAt("_identity","XMLNAME")
			Set pdef.Transient=1

			Do cdef.Properties.Insert(pdef)
		}		
		
		// properties
		Set missing = ""
		Set prop = $order($$$ClassTree(key,"Property",""))
		While (prop '= "") {
			Set perror = ""
			Set pname = $get($$$ClassTree(key,"Property",prop,"Name"))
			If $get($$$ClassTree(key,"Property",prop,"Parameter","XMLPROJECTION"))="NONE" {
				Set xmlname=""
			} Else {
				Set xmlname = $get($$$ClassTree(key,"Property",prop,"Parameter","XMLNAME"))
				if xmlname="" Set xmlname=pname
			}
			
			If (pname = "") {
				Set pname = "Missing" _ missing
				Set perror = $$$Text("ERROR: Missing Property name in Schema")_". "
				Set missing = missing + 1 
			}
			
			// keep track of property names to detect duplicates
			Set orig = pname, n = 0
			While ($D(tProps(pname))) {
				Set n = n + 1
				Set pname = orig _ n
				Set perror = $$$Text("ERROR: Duplicate Property name in Schema")_". "
			}

			Set tProps(pname) = ""
			
			If ('$ZName(pname,6)) {
				// invalid property name
				Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("Invalid Property Name")_": " _ pClassName _ ":" _ pname)
				Set cdef = ""
				Quit
			}

			Set pdef = ##class(%Dictionary.PropertyDefinition).%New(pClassName _ ":" _ pname)
			Set pdef.Description = perror _ $get($$$ClassTree(key,"Property",prop,"Description"))
	
			Set tSeqNo = tSeqNo + 1
			Set pdef.SequenceNumber = tSeqNo
	
			If $data(..Features("SQLCOLUMNS")) {
				Set tColNo = tColNo + 1
				Set pdef.SqlColumnNumber= tColNo
			}
			
			Set pdef.Type = ..Reader.TypeToClass($get($$$ClassTree(key,"Property",prop,"Type")))
			
			// normalize the class name for the type!!!
			Set pdef.Type = $TR(pdef.Type,"_","")
			
			// Support BINARYASSTREAM feature
			If $data(..Features("BINARYASSTREAM")),pdef.Type="%xsd.base64Binary",
			   $get($$$ClassTree(key,"Property",prop,"Parameter","XMLPROJECTION"))'["ATTRIBUTE" {
				Set pdef.Type="%Stream.GlobalBinary"
			}
			
			If (..IsSQLWord(pname)) {
				Set pdef.SqlFieldName = "_" _ pname
			}
	
			If ($get($$$ClassTree(key,"Property",prop,"Relationship")) = 1) {
				Set pdef.Relationship = 1
				Set pdef.Cardinality = $get($$$ClassTree(key,"Property",prop,"Cardinality"))
				Set pdef.Inverse = $get($$$ClassTree(key,"Property",prop,"Inverse"))
				// If cascading deletes, then add OnDelete=CASCADE to cardinality=one side of relationship
				If ..Reader.CascadeDeletes,ClassType="persistent",
				   $get($$$ClassTree(key,"Property",prop,"Cardinality"))="one" {
					   Set pdef.OnDelete="cascade"
				}
			} Else {
				Set pdef.Collection = $get($$$ClassTree(key,"Property",prop,"Collection"))
			}
	
			If ($get($$$ClassTree(key,"Property",prop,"Required")) = 1) {
				Set pdef.Required = 1
			}
			
			Set initialValue=$get($$$ClassTree(key,"Property",prop,"InitialExpression"))
			If initialValue '= "" {
				Set pdef.InitialExpression=""""_$replace(initialValue,"""","""""")_""""
						
			}
			
			Set readonly=$get($$$ClassTree(key,"Property",prop,"ReadOnly"))
			If readonly'="" {
				Set pdef.ReadOnly=readonly
			}
			
			// now add additional parms
			Set parm = $order($$$ClassTree(key,"Property",prop,"Parameter",""))
			While (parm '= "") {
				If (parm'="XMLNAME") {
					Set value=$$$ClassTree(key,"Property",prop,"Parameter",parm)
					If (value'="") || (parm = "REFNAMESPACE") {
						// skip parms with no value
						If (parm = "XMLFractionDigits" ) { // Fractional digits imply default SCALE
							Do pdef.Parameters.SetAt(value,"SCALE")
						}
						Do pdef.Parameters.SetAt(value,parm)
					}
				}
				Set parm = $order($$$ClassTree(key,"Property",prop,"Parameter",parm))
			}
			
			// Add MAXLEN = "" for strings
			If (pdef.Type = "%String") && 'pdef.Parameters.IsDefined("MAXLEN") {
				Do pdef.Parameters.SetAt("","MAXLEN")
			}
			
			// always set XMLNAME parameter if property is projected to XML
			If xmlname'="" {
				Do pdef.Parameters.SetAt(xmlname,"XMLNAME")
			}
	
			// Make sure that every collection/relationship has XMLPROJECTION set:
			If ((pdef.Relationship = 1) || (pdef.Collection '= "")) {
				If ('pdef.Parameters.IsDefined("XMLPROJECTION")) {
					Do pdef.Parameters.SetAt("ELEMENT","XMLPROJECTION")
				}
			}
			
			Do cdef.Properties.Insert(pdef)
	
			Set prop = $order($$$ClassTree(key,"Property",prop))
		}
		If $$$ISERR(tSC) Quit
		
		// We will only need to create list of properties for %OnDelete method, 
		// if cascaded deletes requested and class is persistent
		If ..Reader.CascadeDeletes,ClassType="persistent" {
			Do ..Reader.FindProperties(key,,.proporder,1)
			
			Kill persistentProperties
			Set index=""
			For {
				Set index=$order(proporder(index),1,plist)
				If index="" Quit
				
				Set pcls=$list(plist,1)
				Set pno=$list(plist,2)
				Set type=$get($$$ClassTree(pcls,"Property",pno,"Type"))
				Set pname=$get($$$ClassTree(pcls,"Property",pno,"Name"))
				
				// If property type is a persistent class, then add to %OnDelete List,
				// and property is not a parent/child relationship.
				If type'="" {
					If $get($$$ClassTree(pcls,"Property",pno,"Relationship")) '= 1 {
						Set typeName=$tr(..Reader.TypeToClass(type),"_","")
						Set cls=$get(..Reader.TypeIndex(type))
						If cls'="",..Reader.FindClassType(cls)="persistent" {
							Set collection=($get($$$ClassTree(pcls,"Property",pno,"Collection"))'="")
							Set persistentProperties($i(persistentProperties))=$lb(pname,typeName,collection)
						}
					}
				}
			}
			
			Set tSC=..AddOnDeleteMethod(cdef,.persistentProperties,tSeqNo)
			If $$$ISERR(tSC) Quit
		}
		
	} While (0)
	
Exit
	Set pCDef = cdef
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("CreateClass")_": " _ $ZE)
	Goto Exit
}

/// If Delete trigger needed, then create it now.
ClassMethod AddOnDeleteMethod(cdef As %Dictionary.ClassDefinition, persistentProperties, tSeqNo As %Integer) [ Internal ]
{
	Set tSC=$$$OK
	
	If $data(persistentProperties) {
		Set triggerDef=##class(%Dictionary.TriggerDefinition).%New(cdef.Name_":%DeleteTrigger")
		Set triggerDef.Description="The %DeleteTrigger unified trigger is generated in order to cascade SQL deletes of an XML tree."
		Set triggerDef.Event="DELETE"
		Set triggerDef.Foreach="row/object"
		Set triggerDef.CodeMode="code"

		// For each persistent property add code to delete the referenced object
		Set code=" New index,oid,oref,sc,sc1"_$c(13,10)
		Set code=code_" Set oref=..%OpenId({%%ID},,.sc) If $$$ISERR(sc) Quit sc"_$c(13,10)
		For i=1:1:persistentProperties {
			Set propDef=persistentProperties(i)
			Set pname=$list(propDef,1)
			Set ptype=$list(propDef,2)
			Set collection=$list(propDef,3)
			If collection {
				Set code=code_" Set index="""""_$c(13,10)
				Set code=code_" For {"_$c(13,10)
				Set code=code_"    Set oid=oref."_pname_".GetObjectNext(.index)"_$c(13,10)
				Set code=code_"    If index="""" Quit"_$c(13,10)
				Set code=code_"    If oid'="""" Set sc1=##class("_ptype_").%Delete(oid) If $$$ISERR(sc1),$$$GETERRORCODE(sc1)'=$$$ERRORCODE($$$DeleteObjectNotFound) Set sc=$$$ADDSC(sc,sc1)"_$c(13,10)
				Set code=code_" }"_$c(13,10)
			} Else {
				Set code=code_" Set oid=oref."_pname_"GetObject()"_$c(13,10)
				Set code=code_" If oid'="""" Set sc1=##class("_ptype_").%Delete(oid) If $$$ISERR(sc1),$$$GETERRORCODE(sc1)'=$$$ERRORCODE($$$DeleteObjectNotFound) Set sc=$$$ADDSC(sc,sc1)"_$c(13,10)
			}
		}
		Set code=code_" If $$$ISERR(sc) Set %ok=0,%msg=$system.Status.GetErrorText(sc) "_$c(13,10)
		Set code=code_" Quit"
		Set triggerDef.Code=code

		Set tSeqNo = tSeqNo + 1
		Set triggerDef.SequenceNumber=tSeqNo
		Set tSC=cdef.Triggers.Insert(triggerDef)
	}
	
	Quit tSC
}

/// Get number of properties in super classes
Method SuperPropertyCount(pClassName As %String) As %Integer [ Internal ]
{
	Set tSC = $$$OK
	Set propertyCount=0
	
	// lookup up class key
	Set key = $get(..Classes(pClassName))
	If key="" Quit 0
	
	// If super class, then ccount super class recursively
	If $get($$$ClassTree(key,"SuperClass"))="" {
		Set $$$ClassTree(key,"SuperClass") = ..Reader.TypeToClass($get($$$ClassTree(key,"Super")))
	}
	Set super = $$$ClassTree(key,"SuperClass")
	If super '= "%Persistent", super '= "%SerialObject", super '= "%RegisteredObject" {
		Set propertyCount = ..SuperPropertyCount(super)
	}
	
	// add on properties for this class
	Set prop=""
	For {
		Set prop = $order($$$ClassTree(key,"Property",prop))
		If prop="" Quit
		Set propertyCount = propertyCount + 1
	}
	
	Quit propertyCount
}

/// Save all the class definitions in this result to the database.
Method SaveClasses(verbose As %Boolean = 0, test As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	
	Do {
		Set tClassName = $order(..Classes(""))
		While (tClassName '= "") {
			Set tSC = ..CreateClassDef(tClassName,test,.cdef)
			If ($$$ISERR(tSC)) Quit
			
			// save the class
			Set tSC = ..SaveClass(cdef,verbose)
			If $$$ISERR(tSC) {
				// decorate status code
				Do $system.Status.DecomposeStatus(tSC,.err)
				Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("Error saving Class Definition")_": " _ tClassName _ ": " _$get(err(1)))
				Quit
			}
			
			Set tClassName = $order(..Classes(tClassName))
		}
	} While (0)

Exit
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("SaveClasses")_": " _ $ZE)
	Goto Exit
}

Method SaveClass(cdef As %Dictionary.ClassDefinition, verbose As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	
	Do {
		If (verbose) {
			Write "<div class=""CLASSMSG""><span class=""CLASSNAME"">",cdef.Name,"</span>",!
			Do:$D(%response) %response.Flush()
		}
	
		If (##class(%Dictionary.ClassDefinition).%ExistsId(cdef.Name)) {
			// Skip save if XMLKEEPCLASS parameter is true in definition of  existing class.
			Set keepclass=$$$defMemberKeyGet(cdef.Name,$$$cCLASSparameter,"XMLKEEPCLASS",$$$cPARAMdefault)
			If keepclass Quit
			
			If (verbose) {
				Write "<br>&nbsp;"_$$$Text("Deleting old version of class")_".",!
				Do:$D(%response) %response.Flush()
			}
			// delete old class definition
			Do ##class(%Dictionary.ClassDefinition).%DeleteId(cdef.Name)
		}
	
		Set tSC = cdef.%Save()
		If ($$$ISERR(tSC)) {
			If (verbose) {
				Write "<br>&nbsp;<span class=""ERROR"">"_$$$Text("Error saving class")_": ",cdef.Name," [<b>",$system.OBJ.DisplayError(tSC),"</b>]</span><br>"_$$$Text("Class Details")_":",!
				
				// show details of class:
				For i = 1:1:cdef.Properties.Count() {
					Set pdef = cdef.Properties.GetAt(i)
					Write "&nbsp;&nbsp;&nbsp;",pdef.Name," ",pdef.Type,"<br>",!
				}
				
				Write "</div>"
				
				Do:$D(%response) %response.Flush()
			}
			Else {
				// stop
				Quit
			}
		}
		
		If (verbose) {
			Write "<br>&nbsp;"_$$$Text("New version saved")_".</div>",!
		}
	} While (0)
	
Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("SaveClass")_": " _ $ZE)
	Goto Exit
}

/// Compile all the class definitions in this result
Method CompileClasses(verbose As %Boolean = 0, CompileFlags As %String = "dk") As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	
	// build list of classes to compile
	Set cls = $order(..Classes(""))
	While (cls '= "") {
		Set tList(cls_".cls")=""
		Set cls = $order(..Classes(cls))
	}
	
	// test if there is anything to compile...
	If $data(tList) Set tSC = $System.OBJ.CompileList(.tList,CompileFlags)

Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("CompileClasses")_": " _ $ZE)
	Goto Exit
}

/// !!!Test if name is a valid class name
ClassMethod IsValidClassName(%val As %Binary) As %Boolean
{
 s v=1
 f i=1:1:$l(%val,".") s p=$p(%val,".",i) d  q:v=0
 . s v=$s(i=1:p?1(1"%",1A).AN,1:p?1A.AN)
 q v
}

/// Test if name is an SQL reserved word
ClassMethod IsSQLWord(name As %String) As %Boolean
{
	If (name = "") {
		Quit ""
	}
	
	// check SQL meta info
	Quit $System.SQL.IsReservedWord(name)
}

/// List all the classes in this Result.
Method DisplayClasses()
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	
	Do {
		Set tClassName = $order(..Classes(""))
		While (tClassName '= "") {
			Set tSC = ..CreateClassDef(tClassName,0,.cdef)
			If ($$$ISERR(tSC)) Quit
			
			// display the class
			Set tSC = ..DisplayClass(cdef)
			If $$$ISERR(tSC) Quit
			
			Set tClassName = $order(..Classes(tClassName))
		}
	} While (0)

Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,$$$Text("DisplayClasses")_" " _ $ZE)
	Goto Exit
}

/// Write out a formatted version of a class definition
ClassMethod DisplayClass(cdef As %Dictionary.ClassDefinition) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do {
		If ('$IsObject(cdef)) {
			Set tSC = $$$ERROR($$$XMLSchemaWizardError,"DisplayClass: invalid class definition")
			Quit
		}
	
		Write "/// ---------------------------------------------------",!
		Write:(cdef.Description'="") "/// ",cdef.Description,!
	
		Write "Class ",cdef.Name," Extends (", cdef.Super,")"
		Write:cdef.CompileAfter'="" ", CompileAfter=(",cdef.CompileAfter,")"
		Write:cdef.SqlTableName'="" ", SqlTableName=",cdef.SqlTableName
		Write "]",!
		Write "{",!
				
		// parameters
		For i = 1:1:cdef.Parameters.Count() {
			Set pdef = cdef.Parameters.GetAt(i)
			Write "Parameter ",pdef.Name," = """,pdef.Default,""";",!
		}
		
		// indices
		For i = 1:1:cdef.Indices.Count() {
			Set idef = cdef.Indices.GetAt(i)
			Write "Index ",idef.Name," On ",idef.Properties
			Write:idef.Type'="" "[ type=",idef.Type,"]"
			Write ";",!
		}
	
		// properties
		For i = 1:1:cdef.Properties.Count() {
			Set pdef = cdef.Properties.GetAt(i)
			Write:(pdef.Description'="") "/// ",pdef.Description,!
	
			If (pdef.Relationship = 1) {
				Write "Relationship "
			}
			Else {
				Write "Property "
			}
					
			Write pdef.Name," As "
			Write:(pdef.Collection'="") pdef.Collection, " Of "
			Write pdef.Type
		
			Set hasparm = 0
			Set parm = ""
			Set value = pdef.Parameters.GetNext(.parm)
			While (parm '= "") {
				Write:'hasparm "("
				Set hasparm = 1
				Write parm,"=""",value,""""
				Set value = pdef.Parameters.GetNext(.parm)
				Write:parm'="" ","
			}
					
			Write:hasparm ")"
	
			// property keywords
			Set haskw = 0
	
			If (pdef.Required) {
				Write:'haskw " ["
				Write:haskw ","
				Write "required"
				Set haskw = 1
			}
	
			If (pdef.Relationship) {
				Write:'haskw " ["
				Write:haskw ","
				Write "Cardinality=",pdef.Cardinality,","
				Write "Inverse=",pdef.Inverse
				Set haskw = 1
			}
	
			Write:haskw "]"
			Write ";",!
		}
	
		Write "}",!,!
	} While(0)

Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,"DisplayClass: " _ $ZE)
	Goto Exit
}

/// Provide an HTML list of classes (for Wizard)
Method DisplayClassesHTML() As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do {
		&html<<table class="SchemaTable" cellspacing="0" cellpadding="0">>
		&html<<tr>
		<!--<th class="Row">&nbsp;</th>-->
		<th class="Data"><a title='#($$$Text("The name of the class that will be created."))#' name="aclass">#($$$Text("Class"))#</a></th>
		<th class="Data"><a title='#($$$Text("The super class or type of the class that will be created."))#' name="atype">#($$$Text("Extends/Type"))#</a></th>
		<th class="Data"><a title='#($$$Text("A list of the properties of the class that will be created."))#' name="aproperties">#($$$Text("Properties"))#</a></th>
		</tr>>
	
		Set tClassName = $order(..Classes(""))
		While (tClassName '= "") {
			Set row = $get(row) + 1
			
			Set tSC = ..CreateClassDef(tClassName,0,.cdef)
			If ($$$ISERR(tSC)) Quit

			Set tSC = ..DisplayClassHTML(row,cdef)
			If ($$$ISERR(tSC)) Quit

			Set tClassName = $order(..Classes(tClassName))
		}

		&html<</table><input type="hidden" id="TotalClasses" value="#(row)#">>
	} While(0)

Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,"DisplayClassesHTML: " _ $ZE)
	Goto Exit
}

Method DisplayClassHTML(row As %Integer, cdef As %Dictionary.ClassDefinition) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do {
		If ('$IsObject(cdef)) {
			Set tSC = $$$ERROR($$$XMLSchemaWizardError,"DisplayClassesHTML: "_$$$Text("invalid class definition"))
			Quit
		}
		
		Write "<tr class=""",$S(row#2:"DarkRow",1:"LightRow"),""">",!
		
		// short class name
		Set clsname = $P(cdef.Name,".",$L(cdef.Name,"."))
		
		// Write "<td class=""Row""><input type=""checkbox"" checked></td>"
		Write "<td class=""Data"">"
		Write "<b>",cdef.Name,"</b>"
				
		If (cdef.Description '= "") {
			Write "<br><span class=""Description"">["
			Write $E(cdef.Description,1,100)
			Write:$L(cdef.Description)>100 "..."
			Write "]</span>"
		}
				
		Write "</td>"
	
		Set primary = $P(cdef.Super,",",1)
		
		If ((primary = "%Persistent") || (primary = "%SerialObject") || (primary = "%RegisteredObject")) {
			Write "<td class=""Type"">"
			#;YSD2529 Write "<input type=""radio"" name=""TYPE_",cdef.Name,""" value=""persistent"""
			Set iid = "radio_" _ row _ "_" _ 1
			Write "<input type=""radio"" id=""",iid,""" name=""TYPE_",cdef.Name,""" value=""persistent"""
			Write:primary="%Persistent" " checked"
			Write "><nobr>"
			Write:primary="%Persistent" "<b>"
			Write $$$Text("Persistent")
			Write:primary="%Persistent" "</b>"
			Write "</nobr><br>",!
			
			Set iid = "radio_" _ row _ "_" _ 2
			Write "<input type=""radio"" id=""",iid,""" name=""TYPE_",cdef.Name,""" value=""serial"""
			Write:primary="%SerialObject" " checked"
			Write "><nobr>"
			Write:primary="%SerialObject" "<b>"
			Write $$$Text("Serial")
			Write:primary="%SerialObject" "</b>"
			Write "</nobr><br>",!
			
			Set iid = "radio_" _ row _ "_" _ 3
			Write "<input type=""radio"" id=""",iid,""" name=""TYPE_",cdef.Name,""" value=""registered"""
			Write:primary="%RegisteredObject" " checked"
			Write "><nobr>"
			Write:primary="%RegisteredObject" "<b>"
			Write $$$Text("Registered")
			Write:primary="%RegisteredObject" "</b>"
			Write "</nobr><br>",!
			Write "</td>",!
		}
		Else {
			Write "<td class=""Data"" nowrap>"
			
			If (primary [ "%") {
				Write "<span class=""PropType"">",primary,"</span>"
			}
			Else {
				// make link to the super class row
				Write "<a href=""#",primary,"""><span class=""PropType"">",primary,"</span></a>"
			}
	
			Write "</td>",!
		}
		
		Write "<td class=""Prop"">"
		If cdef.Properties.Count()>0 Write "<table class=""PropTable"" cols=""2"" width=""100%"" cellspacing=""0"">",!
		#;YSD2529: add the following line so that the td style is carried out for when there is no properties.
		Else  Write "&nbsp;"
		// properties
		For i = 1:1:cdef.Properties.Count() {
			Set pdef = cdef.Properties.GetAt(i)
			
			Write "<tr class=""",$S((i)#2:"DarkRowP",1:"LightRowP"),""">",!
	
			If (($ZCVT(pdef.Type,"U") = "UNKNOWN") ||
				('..IsValidClassName(pdef.Type)) ||
				($E(pdef.Description,1,6) = "ERROR:") ||
				(pdef.Name = "")) {
					
				// error
				If (i = 1) {
					&html<<td class="PropCell1Error" title="#(pdef.Description)#">>
				}
				Else {
					&html<<td class="PropCellError" title="#(pdef.Description)#">>
				}
			}
			Else {
				If (i = 1) {
					If pdef.Description'="" {
						&html<<td class="PropCell1" title="#(pdef.Description)#">>
					} Else {
						&html<<td class="PropCell1">>
					}
				}
				Else {
					If pdef.Description'="" {
						&html<<td class="PropCell" title="#(pdef.Description)#">>
					} Else {
						&html<<td class="PropCell">>
					}
				}
			}
					
			Write "<span class=""PropName"">",pdef.Name,"</span> As "
			Write:(pdef.Collection'="") pdef.Collection, " Of "
			Write "<span class=""PropType""><nobr>",pdef.Type,"</nobr></span>"
	
			If (pdef.Relationship) {
				Write " ["_$$$Text("Relationship")_"]"
			}
		
			If (i = 1) {
				Write "</td><td class=""PropCell1"" align=""right"">"
			}
			Else {
				Write "</td><td class=""PropCell"" align=""right"">"
			}
	
			If ('pdef.Relationship || (pdef.Cardinality = "one")) && (pdef.Collection = "") {
				Set iname = "INDEX_" _ cdef.Name _ "_" _ pdef.Name
				#;YSD2529 Write "<span class=""IndexLabel"">"_$$$Text("Index")_"<input type=""checkbox"" name=""",iname,""" value=""""></span>",!
				Set iid = "check_" _ row _ "_" _ i
				Write "<span class=""IndexLabel"">"_$$$Text("Index")_"<input type=""checkbox"" id=""",iid,""" name=""",iname,""" value=""""></span>",!

			}
			Else {
				Write "&nbsp;"
			}
	
			Write "</td></tr>",!
		}
	
		If cdef.Properties.Count()>0 Write "</table>",!
		Write "</td></tr>",!
		
		If ($IsObject($get(%response))) {
			Do %response.Flush()
		}
	} While (0)
	
Exit	
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$XMLSchemaWizardError,"DisplayClassHTML: " _ $ZE)
	Goto Exit
}

/// Output an XSchema format file based on the parsed XML schema.
Method XSchemaToFile(filepath As %String) As %Status
{
	Set isfileopen=0
	Set $zt = "Trap"
	Set sc=$$$OK
	Set reader=..Reader
	
	// Kill global data structure
	Kill ^||%xmlXSchema
	
	// Add top level elements to XSchema data structure
	Do ..ElementsToXSchema()
	
	// Loop over classes and add to XSchema data structure
	Set className = $order(..Classes(""))
	While (className '= "") {
		Set sc=..AddToXSchema(className)
		If $$$ISERR(sc) Quit
		Set className = $order(..Classes(className))
	}
	
	If $$$ISOK(sc) {
		// Output XSchema
		Open filepath:"wns"
		Set isfileopen=1
		Use filepath
		Set targetnsno=$select(reader.TargetNS'="":reader.NSIndex(reader.TargetNS),1:0)
		If $data(^||%xmlXSchema(targetnsno)) {
			Do ..OutputXSchema(targetnsno)
		}
		Set nsno=$order(^||%xmlXSchema(""))
		While nsno'="" {
			If nsno'=targetnsno Do ..OutputXSchema(nsno)
			Set nsno=$order(^||%xmlXSchema(nsno))
		}
		Close filepath
	}

Exit	
	//Kill ^||%xmlXSchema
	Quit sc

Trap  Set $zt=""
	If isfileopen Close filepath
	Set sc=$$$ERROR($$$XMLSchemaWizardError,"XSchema: " _ $ZE)
	Goto Exit
}

/// Add top level elements to the XSchema data structure
Method ElementsToXSchema() As %Status
{
	Set reader=..Reader
	
	Set element="",num=0
	For {
		Set element = $order(reader.Elements(element))
		If element="" Quit
		
		Set ensno=$piece(element,"^",1)
		If ensno="" Set ensno=0
		Set ename=$piece(element,"^",2)
		
		// Remember top level element
		Set typeref=..GetTypeRef(ensno,reader.Elements(element),.nsno,.localname)
		Set ^||%xmlXSchema(ensno,"<>",$i(num),"E",ename)=typeref
	}
}

/// Create the XSchema data Structure for one class
Method AddToXSchema(classname As %String) As %Status
{
	Set reader=..Reader
	Set sc=$$$OK
	
	// lookup up class key
	Set cls = $get(..Classes(classname))

	If ('$zname(classname,4)) {
		// invalid class name
		Set sc=$$$ERROR($$$XMLSchemaWizardError,$$$Text("Invalid Class Name")_": "_classname)
		Goto Exit
	}
	
	If $data($$$ClassTree(cls,"abstract")) Goto Exit

	If ..GetTypeRef("",cls,.nsno,.typename)="" Goto Exit
	
	Kill proplist
	Do reader.FindProperties(cls,,.proplist)

	Set pindex="",num=0
	For {
		Set pindex=$order(proplist(pindex))
		If pindex="" Quit
		
		Set prop=proplist(pindex)
		Set pcls=$list(prop,1)
		Set pno=$list(prop,2)
		Set pname=$list(prop,3)
		If ('$zname(pname,6)) Quit

		Set xmlname=$get($$$ClassTree(pcls,"Property",pno,"Parameter","XMLNAME"))
		if xmlname="" Set xmlname=pname
		
		Set xmlprojection=$zcvt($get($$$ClassTree(pcls,"Property",pno,"Parameter","XMLPROJECTION")),"U")

		Set ptype=$get($$$ClassTree(pcls,"Property",pno,"Type"))
		Set pkey=$select(ptype'="":$get(reader.TypeIndex(ptype)),1:"")
		Set typeref=$select(pkey'="":..GetTypeRef(nsno,pkey,.pnsno,.ptypename),1:"")
		
		Set wrap=""
		If xmlprojection["ATTRIBUTE" {
			Set kind="A"
			Set typeref=""
		} ElseIf (xmlprojection="ELEMENT") || (xmlprojection="") {
			Set kind="E"
		} ElseIf xmlprojection="COLLECTION" {
			Set kind="E"
			Set wrap=xmlname
			Set xmlname=$get($$$ClassTree(pcls,"Property",pno,"Parameter","XMLITEMNAME"))
			if xmlname="" Set xmlname=wrap_"Item"
			Set wrap=wrap_"/#"
		} Else {
			Set kind=""
		}

		// Remember the property element
		If kind="" Continue
		
		If typeref="" {
			Set valuelist=$get($$$ClassTree(pcls,"Property",pno,"Parameter","VALUELIST"))
			If (valuelist="") && (pkey'="") Set valuelist=$get($$$ClassTree(pkey,"Parameter","VALUELIST"))
			If valuelist'="" Set typeref="@enum:!"_valuelist
		}

		Set ^||%xmlXSchema(nsno,typename,$i(num),kind,wrap_xmlname)=typeref
	}
	
Exit
	Quit sc
}

Method GetTypeRef(ns As %Integer, key As %Integer, ByRef nsno As %Integer, ByRef localname As %String) As %String
{
	Set reader=..Reader
	Set typeref=""
	
	Set type=$get($$$ClassTree(key,"Type"))
	// Check for datatype class
	If (type '[ "^") Goto Exit
	
	// find the namespace and local name for this type
	If $extract(type,1,2)="^^" {
		Set uri=$get($$$ClassTree(key,"Parameter","NAMESPACE"))
		Set nsno=$select(uri="":0,1:reader.NSIndex(uri))
		Set localname=$get($$$ClassTree(key,"Parameter","XMLTYPE"))
		If localname="" Set localname=$get($$$ClassTree(key,"Parameter","XMLNAME"))
		If localname="" Set localname=$$$ClassShortName(classname)
	} Else {
		Set nsno = $piece(type,"^",1)
		If nsno="" Set nsno=0
		Set localname = $piece(type,"^",2)
		If localname="" Goto Exit
	
		Set uri = $get(reader.NSInfo(nsno,"uri"))
	}
	Set prefix=$get(reader.NSInfo(nsno,"Prefix"))

	// Skip built in XML types	
	If (##class(%XML.Utils.SchemaReader).IsXMLSchemaNS(uri)) Goto Exit
	
	// If no prefix defined, define it now
	While prefix="" {
		Set ..PrefixIndex=..PrefixIndex+1
		Set prefix="s"_..PrefixIndex
		Set nsindex=$order(reader.NSInfo(""))
		While nsindex'="" {
			If $get(reader.NSInfo(nsindex,"Prefix"))=prefix Set prefix="" Quit
			Set nsindex=$order(reader.NSInfo(nsindex))
		}
		If (prefix'="") && reader.MultipleTargetNS {
			Set reader.NSInfo(nsno,"Prefix")=prefix
		}
	}
	
	If $get($$$ClassTree(key,"ClassType"))'="datatype" {
		If ns=nsno {
			Set typeref="="_localname
		} Else {
			If prefix'="" Set prefix=prefix_":"
			Set typeref="="_prefix_localname
		}
	}

Exit
	Quit typeref
}

/// Output the XSchema data structure to a file
Method OutputXSchema(nsno As %Integer)
{
	Set reader=..Reader

	// Output namespace header
	Write "["_$get(reader.NSInfo(nsno,"Prefix"))_":"_$get(reader.NSInfo(nsno,"uri"))_"]",!
	
	// Output top level elements
	Set index=$order(^||%xmlXSchema(nsno,"<>",""))
	While index'="" {
		Set ename=$order(^||%xmlXSchema(nsno,"<>",index,"E",""))
		Write "/#"_ename_^||%xmlXSchema(nsno,"<>",index,"E",ename),!
		Set index=$order(^||%xmlXSchema(nsno,"<>",index))
	}
	
	// Output types
	Set typename=""
	For {
		Set typename=$order(^||%xmlXSchema(nsno,typename))
		If typename="" Quit
		If typename="<>" Continue

		// Output elements in type
		Set index=$order(^||%xmlXSchema(nsno,typename,""))
		While index'="" {
			If $order(^||%xmlXSchema(nsno,typename,index,""))="E" {
				Set xmlname=$order(^||%xmlXSchema(nsno,typename,index,"E",""))
				Set ref=$select(xmlname["/":"",1:"#")
				Write typename_"/"_ref_xmlname_^||%xmlXSchema(nsno,typename,index,"E",xmlname),!
			}
			Set index=$order(^||%xmlXSchema(nsno,typename,index))
		}

		// Output Sttributes in type
		Set index=$order(^||%xmlXSchema(nsno,typename,""))
		While index'="" {
			If $order(^||%xmlXSchema(nsno,typename,index,""))="A" {
				Set xmlname=$order(^||%xmlXSchema(nsno,typename,index,"A",""))
				Write typename_"|"_xmlname_^||%xmlXSchema(nsno,typename,index,"A",xmlname),!
			}
			Set index=$order(^||%xmlXSchema(nsno,typename,index))
		}
	}
}

}
