/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This class is used to generate and manage SQL projections of iKnow data structures for a
/// particular domain. The easiest way to generate these SQL projections is by setting the objectsPackage
/// attribute on the &lt;domain&gt; element in a Domain Definition. <br/>
/// These projections can be customized in any of the following ways:</p>
/// <ol>
/// <li>New properties for metadata can be added to any table. they can be either writeable properties (such as source-level metadata) or computed/calculated fields to denormalize the schema. Non-computed fields should be set using regular UPDATE calls in SQL or set commands in COS. Computed fields (with the SqlComputed flag on) will be populated automatically when either of the following conditions is met:
///   <ol>
/// 		<li>The computed property has the SqlComputeOnChange attribute set to one or more custom fields: the value is updated when one of those is updated</li>
/// 		<li>The computed property is based on built-in fields (for example to denormalize the schema, such as adding a SourceId property to the Parts table): the value is updated (set) automatically when the domain is being built. Note that computed fields are built in a specific order and particular dependencies may not be satisfied, in which case the condition below applies. The build order is Sources, [EntityUnique, StemUnique, CrcUnique, CcUniqe], Sentence, Path, Part, CrcOccurrence, with the [] indicating that these are built in parallel.</li>
/// 		<li>The table's %BuildCustomFields() method is called. Note that this is called automatically as part of loading / updating a domain. Iow, this method only needs to be called explicitly when a computed property depends on a custom field and its SqlComputeOnChange is not set appropriately, or when it has non-trivial dependencies on other tables and the automated call to %BuildCustomFields() does not cover them.</li>
///   </ol></li>
/// 	<li>Existing properties (created as part of the default mapping) that are marked as Calculated and SqlComputed can be marked SqlComputed only (not Calculated). These properties' values will then be persisted rather than calculated on-the-fly, which may benefit query performance. See above for the policy on when computed fields' values are updated.</li>
/// <li>New indices can be added on existing or custom properties, regardless of whether their values are simply persisted, computed-persisted or calculated. These indices will be updated automatically when loading/updating a domain or when updating writeable fields as added in option 1.</li>
/// <li>Custom methods, optionally serving to populate indices (like *BuildValueArray()) can be added to the existing tables.</li>
/// </ol>
/// <p>The CustomAnnotations table is special in the sense that it's the only table that can be written to directly. It allows users to specify custom annotations for specific sentence parts (Part table), which will be available through the Annotations property of that Part table, next to attributes and matching results.</p>
/// <p>The following modifications are NOT supported:
/// <ul>
/// <li>modifying the definition of any property marked as ReadOnly, other than turning calculated fields into computed ones as described above. </li>
/// <li>modifying the definition of any index or foreign key whose name starts with a % sign</li>
/// <li>modifying or overriding any *Get() or *BuildValueArray() method for a ReadOnly property provided in the generated classes or its superclasses</li>
/// <li>dropping any of the generated tables</li>
/// <li>INSERT and DELETE operations on any of the generated tables, except CustomAnnotations. Note that there are triggers that should prevent this.</li>
/// <li>UPDATE operations on any non-custom fields. Note that this should be prevented by the ReadOnly attributes of those fields.</li>
/// </ul>
/// <p>These table projections and any associated data will be dropped when dropping the domain. </p>
/// <p>It is important to note that the generated projections include a number of denormalizations, such as calculated fields providing convenience access to data stored in another table. For example, the EntityValue property of the Part table is a calculated field based on the string value of the corresponding EntityUnique record. This means filtering or grouping by such denormalized columns directly may lead to valid but not necessarily efficient SQL. Therefore, it is recommend to check query plans and, when adopting the queries for production use (or when implementing a query generation utility), ensure appropriate indices will be used, either custom (as explained earlier) or default ones by adding a query subclause.</p>
/// <p>When generating these tables, the actual classes, properties and indices generated will be based on the Build Flag settings and some domain parameters (most importantly $$$IKPSTEMMING). If these would change (which already assumes the domain is empty), the GenerateDomainTables() method should be re-invoked.</p>
Class %iKnow.Tables.Utils [ Deprecated, System = 4 ]
{

/// <p>Creates a set of tables representing the data in domain <var>pDomainId</var> in package 
/// <var>pPackageName</var>. If <var>pOverWrite</var>=1, existing table definitions will be overwritten,
/// which may therefore no longer preserve non-calculated custom field values.</p>
/// <p>If <var>pRefClass</var> is non-null, a "Ref" property of that type will be added to the Source class, 
/// initialized with the value of its LocalReference property (ie, the ID field used when loading
/// from a SQL table).</p>
/// <p>Any metadata fields referenced in <var>pMetadata</var> will be added to the Source class as
/// calculated fields, along with indices mapping the corresponding iKnow data structures where possible.</p>
/// <p>A list of additional indices to be created can be supplied through <var>pIndices</var> in the
/// following format: 
///  <blockquote><tt>pIndices("<i>TableName</i>", "idx", "<i>IndexName</i>") = $lb("<i>Properties</i>", "<i>IndexType</i>")</tt></blockquote>
/// For the Source table, these can be references to <var>pRefClass</var> columns by using arrow syntax.</p>
ClassMethod CreateDomainTables(pDomainId As %Integer, pPackageName As %String, pRefClass As %String = "", pMetadata As %List = "", ByRef pAdditionalIndices, pGlobalPrefix As %String = "", pOverWrite As %Boolean = 0, pQueue As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		$$$IKCHECKDOMMGRX(pDomainId,tSC) // BDB732
		
		set tDomain = ##class(%iKnow.Domain).%OpenId(pDomainId,, .tSC)
		quit:$$$ISERR(tSC)
		
		// check if there already is a set of tables registered for this domain
		set tOldPackage = tDomain.GetParameter($$$IKPPACKAGE)
		if (tOldPackage'="") && (tOldPackage'=pPackageName) {
			if (pOverWrite) {
				set tSC = ..DropDomainTables(tOldPackage)
				quit:$$$ISERR(tSC)
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Domain already has a set of table projections ('"_tOldPackage_"'). Use pOverwrite=1 to replace them")
				quit
			}
		}
		
		// fetch build flags
		new %IKBuildFlags
		set %IKBuildFlags = tDomain.BuildFlags
		set tUseStemming = ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)'=0)
		
		// preset some property params
		set tIDProps("MINVAL")=1
		set tPosIntProps("MINVAL")=0
		set tStrProps("MAXLEN")=150
		set tMediumStrProps("MAXLEN")=1000
		set tLongStrProps("MAXLEN")=""
		
		
		// SOURCE table
		set tSC = ..CreateClass(.tSrcClass, pPackageName_".Source", $$DataLocation("SrcId"), $$DataLocation("Idx.Src"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tSrcClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tSrcClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "SourceId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "ListerId", "%Integer", .tPosIntProps, 1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "ListerClass", "%String", .tStrProps, 0, 1, 1, "set {*} = $g(^IRIS.IK.Sys.ListerD({ListerId}))")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "GroupId", "%Integer", .tPosIntProps, 2, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "GroupName", "%String", .tStrProps, 0, 1, 1, "set {*} = $g("_$$DataLocation("Ext.Group",0)_"{ListerId},{GroupId}))")
		quit:$$$ISERR(tSC)
		set tLocalRefProps("MAXLEN")=$$$IKHASHSIZE, tLocalRefProps("COLLATION")="EXACT"
		set tSC = ..AddProperty(tSrcClass, "LocalReference", "%String", .tLocalRefProps, 3, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "FirstSentenceId", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),1)+1")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "SentenceCount", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),2)")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "FirstPartId", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),3)+1")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "PartCount", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),4)")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "FirstCrcOccurrenceId", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),5)+1")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "CrcOccurrenceCount", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),6)")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "FirstPathId", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),7)+1")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "PathCount", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),8)")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "ExternalId", "%String", .tMediumStrProps, 0, 1, 1, "set {*} = ##class(%iKnow.Queries.SourceAPI).GetExternalId("_pDomainId_", {SourceId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "FullText", "%String", .tLongStrProps, 0, 1, 1, "new tTxt,tFrom,tTo,tSentId,tOut,tMore  s tTxt = """", tFrom=$lg($g("_$$DataLocation("SrcDetails",0)_"{SourceId})),1)+1, tTo=tFrom-1+$lg($g(^({SourceId})),2) for tSentId = tFrom:1:tTo { k tOut  set tMore = ##class(%iKnow.Queries.SentenceAPI).GetValue("_pDomainId_",tSentId,.tOut)  set tOut="""" for { set tOut = $order(tOut(tOut),1,tMore) q:tOut=""""  set tTxt = tTxt _ tMore _ "" "" } }  set {*} = $e(tTxt,1,*-1)")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSrcClass, "EntityOccurrenceCount", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountBySource("_pDomainId_", {SourceId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tSrcClass, "%ExtIdComp", "ListerId,GroupId,LocalReference", 1, "key", $$DataLocation("Ext.LocalRef"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tSrcClass, "%SrcExists",,, "bitmapextent", $$DataLocation("SrcExistsBit"))
		quit:$$$ISERR(tSC)
		
		if (pRefClass'="") {
			set tSC = ..AddProperty(tSrcClass, "Ref", pRefClass,, 0, 1, 1, "set {*} = {LocalReference}")
			quit:$$$ISERR(tSC)
		}
		
		// metadata
		for i = 1:1:$ll(pMetadata) {
			set tMetadataField = $lg(pMetadata,i), tFieldName = $zstrip(tMetadataField,"*P")
			set tSqlFieldName = $translate(tMetadataField,".- [](),;:{}""'","")
			set:tSqlFieldName=tFieldName tSqlFieldName = ""
			set tFieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(pDomainId, tMetadataField, .tSC)
			quit:$$$ISERR(tSC)
			do ##class(%iKnow.Queries.MetadataAPI).GetFieldInfoById(pDomainId, tFieldId, .tFieldInfo)
			set tFieldType = $case(tFieldInfo("DataType"), $$$MDDTSTRING:"%String", $$$MDDTDATE:"%Date", $$$MDDTNUMBER:"%Numeric")
			
			set tSC = ..AddProperty(tSrcClass, tFieldName, tFieldType,, 0, 1, 1, "set {*} = ##class(%iKnow.Queries.MetadataAPI).GetValueById({DomainId},"_tFieldId_",{SourceId})",, tSqlFieldName)
			quit:$$$ISERR(tSC)
			
			// now add index
			if ((tFieldInfo("StorageType")'=$$$MDSTNORMAL) && (tFieldInfo("StorageType")'=$$$MDSTBITMAP)) {
				
				// compressed storage cannot be mapped
				
				
			} elseif (tFieldInfo("DataType")=$$$MDDTDATE) {
				
				// date indices cannot be mapped currently
				
			} else  {
				
				// add truncation indicator
				set tSC = ..AddProperty(tSrcClass, tFieldName_"IsTruncated", "%Boolean",, 0, 1, 1, "set {*} = ($length({"_tFieldName_"})>"_$$$IKHASHSIZE_")", 1)
				quit:$$$ISERR(tSC)
				
				if (tFieldInfo("StorageType")=$$$MDSTNORMAL) {
					set tDataLocation = $$DataLocation("Mdt.ValueToSrc",0)_tFieldId_")"
				} else {
					set tDataLocation = $$DataLocation("Mdt.ValueToSrcBit",0)_tFieldId_")"
				}
				set tSC = ..AddIndex(tSrcClass, "%Mdt"_tFieldName, tFieldName_","_tFieldName_"IsTruncated",, $s(tFieldInfo("StorageType")=$$$MDSTBITMAP:"bitmap", 1:""), tDataLocation)	
				quit:$$$ISERR(tSC)
			}
		}
		quit:$$$ISERR(tSC)
		
		if '##class(%Dictionary.MethodDefinition).%ExistsId(tSrcClass.Name_"||SyncCustomizations") {
			set tMethodDef = ##class(%Dictionary.MethodDefinition).%New()
			set tMethodDef.parent = tSrcClass
			set tMethodDef.Name = "SyncCustomizations"
			set tMethodDef.FormalSpec = "pAutoPurge:%Boolean=1,pStartSrcId:%Integer="""",pEndSrcId:%Integer="""""
			set tMethodDef.ReturnType = "%Status"
			set tMethodDef.SqlProc = 1
			set tMethodDef.SqlName = "SyncCustomizations"
			set tMethodDef.ClassMethod = 1
			do tMethodDef.Implementation.WriteLine("	quit ##class(%iKnow.Tables.Utils).SyncCustomizations(..#DOMAINID,"""_pPackageName_""",pAutoPurge,pStartSrcId,pEndSrcId)")
		}

		set tSC = tSrcClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tSrcClass.Name) = tSrcClass
		
		
		
		// SENTENCE table
		set tSC = ..CreateClass(.tSentClass, pPackageName_".Sentence", $$DataLocation("SentDetails"), $$DataLocation("Idx.Sent"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tSentClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tSentClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "SentenceId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "LanguageId", "%Integer", .tIDProps, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "LanguageConfidence", "%Numeric",, 2)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "SummaryRelevance", "%Numeric",, 3)
		quit:$$$ISERR(tSC)
		k tTheseProps
		merge tTheseProps = tLongStrProps
		set tTheseProps("COLLATION") = "SQLUPPER(150)"
		set tSC = ..AddProperty(tSentClass, "SentenceValue", "%String", .tTheseProps, 0, 1, 1, "set {*} = ##class(%iKnow.Queries.SentenceAPI).GetValue("_pDomainId_",{SentenceId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "Position", "%Integer", .tIDProps, 0, 1, 1, "set {*} = ##class(%iKnow.Queries.SentenceAPI).GetPosition("_pDomainId_",{SentenceId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "SourceId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = ##class(%iKnow.Queries.SentenceAPI).GetSourceId("_pDomainId_",{SentenceId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "Source", "Source",, 0, 1, 1, "set {*} = {SourceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "Entities", "%List",, 0, 1, 1, "new tEntOccData,tEntOcc,tMaxEntOcc,tEntity,tList  set tList="""", tEntOccData = $g("_$$DataLocation("SentDetails",0)_"{SentenceId})),tEntOcc=$lg(tEntOccData,4),tMaxEntOcc=tEntOcc+$lg(tEntOccData,5),tEntOccData=""""  for { set tEntOcc=$o("_$$DataLocation("EntOccId",0)_"tEntOcc),1,tEntOccData)  quit:tEntOcc=""""  quit:tEntOcc>tMaxEntOcc  set tEntity=$lg(tEntOccData,1)  set:tEntity tList=tList_$lb(tEntity) }  set {*} = tList")
		quit:$$$ISERR(tSC)
		set tSC = ..AddBVA(tSentClass, "Entities", "$g("_$$DataLocation("EntUniId",0)_"tElement))", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tSentClass, "Parts", "%List",, 0, 1, 1, "new tSentData,tPartId,tMinPartId,tMaxPartId,tList  set tList="""", tSentData = $g("_$$DataLocation("SentDetails",0)_"{SentenceId})),tMinPartId=$lg(tSentData,4)+1,tMaxPartId=tMinPartId+$lg(tSentData,5)-1,tSentData=""""  for tPartId=tMinPartId:1:tMaxPartId { set tList=tList_$lb(tPartId) }  set {*} = tList")
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBENTUNIBIT) {
			set tSC = ..AddIndex(tSentClass, "%EntUniToSent", "Entities(KEYS)",, "bitmap", $$DataLocation("EntUniToSentBit"))
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddIndex(tSentClass, "SentExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tSentClass, "%SourceFK", "SourceId", tSrcClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = tSentClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tSentClass.Name) = tSentClass
		
		
		
		// PATH table
		set tSC = ..CreateClass(.tPathClass, pPackageName_".Path", $$DataLocation("PathToEntOcc"), $$DataLocation("Idx.Path"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tPathClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tPathClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "PathId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "EntityOccurrences", "%List",, -2)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "Entities", "%List",, 0,, 1, "set {*} = ##class(%iKnow.Queries.PathAPI).GetEntIds("_pDomainId_",{PathId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddBVA(tPathClass, "Entities", "$g("_$$DataLocation("EntUniId",0)_"tElement))", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "SentenceId", "%Integer", .tIDProps, 0,, 1, "set {*} = ##class(%iKnow.Queries.PathAPI).GetSentenceId("_pDomainId_",{PathId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "Sentence", "Sentence",, 0,, 1, "set {*} = {SentenceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "SourceId", "%Integer", .tIDProps, 0,, 1, "set {*} = ##class(%iKnow.Queries.PathAPI).GetSourceId("_pDomainId_",{PathId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "Source", "Source",, 0,, 1, "set {*} = {SourceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPathClass, "Value", "%String",, 0,, 1, "new tEntity,tEntList,tValue,tPointer  set tEntList = {Entities}, tPointer=0, tValue=""""  while $listnext(tEntList,tPointer,tEntity) { set tValue = tValue _ $s(tValue="""":"""", 1:"" ~ "") _ ##class(%iKnow.Queries.EntityAPI).GetValueInternal("_pDomainId_",tEntity) }  set {*} = tValue")
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBENTUNIBIT) {
			set tSC = ..AddIndex(tPathClass, "%EntUniToPath", "Entities(KEYS)",, "bitmap", $$DataLocation("EntUniToPathBit"))
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddIndex(tPathClass, "PathExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tPathClass, "%SentenceFK", "SentenceId", tSentClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tPathClass, "%SourceFK", "SourceId", tSrcClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = tPathClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tPathClass.Name) = tPathClass
		
		
		
		
		// ENTITYUNIQUE table
		set tSC = ..CreateClass(.tEUClass, pPackageName_".EntityUnique", $$DataLocation("EntUniId"), $$DataLocation("Idx.EU"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tEUClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tEUClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEUClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEUClass, "EntUniId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tEntValueProps("MAXLEN")="", tEntValueProps("COLLATION")="SQLSTRING"
		set tSC = ..AddProperty(tEUClass, "EntityValue", "%String", .tEntValueProps, -2)
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBENTUNIDET) {
			set tSC = ..AddProperty(tEUClass, "CorpusFrequencyAsConcept", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("EntUniDetails",0)_"{EntUniId})),1)")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddProperty(tEUClass, "CorpusFrequencyAsRelation", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("EntUniDetails",0)_"{EntUniId})),2)")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddProperty(tEUClass, "CorpusFrequency", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = {CorpusFrequencyAsConcept} + {CorpusFrequencyAsRelation}")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddProperty(tEUClass, "CorpusSpreadAsConcept", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("EntUniDetails",0)_"{EntUniId})),4)")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddProperty(tEUClass, "CorpusSpreadAsRelation", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("EntUniDetails",0)_"{EntUniId})),5)")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddProperty(tEUClass, "CorpusSpread", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("EntUniDetails",0)_"{EntUniId})),3)")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddProperty(tEUClass, "CorpusDominanceAsConcept", "%Numeric",, 0, 1, 1, "set {*} = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue("_pDomainId_",{EntUniId},$$$SDCONCEPT)")
			quit:$$$ISERR(tSC)
			set tSC = ..AddProperty(tEUClass, "CorpusDominanceAsRelation", "%Numeric",, 0, 1, 1, "set {*} = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue("_pDomainId_",{EntUniId},$$$SDRELATION)")
			quit:$$$ISERR(tSC)
		} else {
			// TODO: what if EntUniDetails is not generated?
		}
		set tSC = ..AddIndex(tEUClass, "%EntUni", "EntityValue", 1, "collatedkey", $$DataLocation("EntUni"))
		quit:$$$ISERR(tSC)	// TODO: EntUniHash?
		if $$$IKBUILD($$$IKBENTUNIFREQ) {
			set tSC = ..AddIndex(tEUClass, "%EntUniFreqCon", "CorpusFrequencyAsConcept:Minus",,, $$DataLocation("EntUniIdFreq",0)_"0)")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddIndex(tEUClass, "%EntUniFreqRel", "CorpusFrequencyAsRelation:Minus",,, $$DataLocation("EntUniIdFreq",0)_"1)")
			quit:$$$ISERR(tSC) 
		}
		if $$$IKBUILD($$$IKBENTUNISPREAD) {
			set tSC = ..AddIndex(tEUClass, "%EntUniSpreadCon", "CorpusSpreadAsConcept:Minus",,, $$DataLocation("EntUniIdSpread",0)_"0)")
			quit:$$$ISERR(tSC) 
			set tSC = ..AddIndex(tEUClass, "%EntUniSpreadRel", "CorpusSpreadAsRelation:Minus",,, $$DataLocation("EntUniIdSpread",0)_"1)")
			quit:$$$ISERR(tSC) 
		}
		set tSC = ..AddIndex(tEUClass, "%EntUniExists",,, "bitmapextent", $$DataLocation("EntUniExistsBit"))
		quit:$$$ISERR(tSC)
		set tSC = tEUClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tEUClass.Name) = tEUClass
		
		if (tUseStemming) {
			// STEMS table
			set tSC = ..CreateClass(.tStemClass, pPackageName_".StemUnique", $$DataLocation("StemUniId"), $$DataLocation("Idx.StU"), pOverWrite)
			quit:$$$ISERR(tSC)
			set tSC = ..AddParameter(tStemClass, "DOMAINID", pDomainId)
			quit:$$$ISERR(tSC)
			set tSC = ..AddParameter(tStemClass, "MANAGEDEXTENT", 0)
			quit:$$$ISERR(tSC)
			set tSC = ..AddProperty(tStemClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
			quit:$$$ISERR(tSC)
			set tSC = ..AddProperty(tStemClass, "StemUniId", "%Integer", .tIDProps, -1)
			quit:$$$ISERR(tSC)
			set tEntValueProps("MAXLEN")="", tEntValueProps("COLLATION")="SQLSTRING"
			set tSC = ..AddProperty(tStemClass, "StemValue", "%String", .tEntValueProps, -2)
			quit:$$$ISERR(tSC)
			if $$$IKBUILD($$$IKBSTEMUNIDET) {
				set tSC = ..AddProperty(tStemClass, "CorpusFrequencyAsConcept", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("StemUniDetails",0)_"{StemUniId})),1)")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddProperty(tStemClass, "CorpusFrequencyAsRelation", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("StemUniDetails",0)_"{StemUniId})),2)")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddProperty(tStemClass, "CorpusFrequency", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = {CorpusFrequencyAsConcept} + {CorpusFrequencyAsRelation}")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddProperty(tStemClass, "CorpusSpreadAsConcept", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("StemUniDetails",0)_"{StemUniId})),4)")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddProperty(tStemClass, "CorpusSpreadAsRelation", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("StemUniDetails",0)_"{StemUniId})),5)")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddProperty(tStemClass, "CorpusSpread", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("StemUniDetails",0)_"{StemUniId})),3)")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddProperty(tStemClass, "CorpusDominanceAsConcept", "%Numeric",, 0, 1, 1, "set {*} = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue("_pDomainId_",{StemUniId},$$$SDSTEMCONCEPT)")
				quit:$$$ISERR(tSC)
				set tSC = ..AddProperty(tStemClass, "CorpusDominanceAsRelation", "%Numeric",, 0, 1, 1, "set {*} = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue("_pDomainId_",{StemUniId},$$$SDSTEMRELATION)")
				quit:$$$ISERR(tSC)
			} else {
				// TODO: what if StemUniDetails is not generated?
			}
			set tSC = ..AddIndex(tStemClass, "%StemUni", "StemValue", 1, "collatedkey", $$DataLocation("StemUni"))
			quit:$$$ISERR(tSC)	// TODO: StemUniHash?
			if $$$IKBUILD($$$IKBSTEMUNIFREQ) {
				set tSC = ..AddIndex(tStemClass, "%StemUniFreqCon", "CorpusFrequencyAsConcept:Minus",,, $$DataLocation("StemUniIdFreq",0)_"0)")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddIndex(tStemClass, "%StemUniFreqRel", "CorpusFrequencyAsRelation:Minus",,, $$DataLocation("StemUniIdFreq",0)_"1)")
				quit:$$$ISERR(tSC) 
			}
			if $$$IKBUILD($$$IKBSTEMUNISPREAD) {
				set tSC = ..AddIndex(tStemClass, "%StemUniSpreadCon", "CorpusSpreadAsConcept:Minus",,, $$DataLocation("StemUniIdSpread",0)_"0)")
				quit:$$$ISERR(tSC) 
				set tSC = ..AddIndex(tStemClass, "%StemUniSpreadRel", "CorpusSpreadAsRelation:Minus",,, $$DataLocation("StemUniIdSpread",0)_"1)")
				quit:$$$ISERR(tSC) 
			}
			set tSC = ..AddIndex(tStemClass, "%StemUniExists",,, "bitmapextent", $$DataLocation("StemUniExistsBit"))
			quit:$$$ISERR(tSC)
			set tSC = tStemClass.%Save()
			quit:$$$ISERR(tSC)
			set tClasses(tStemClass.Name) = tStemClass
		}
		
		// PARTS table
		set tSC = ..CreateClass(.tPartsClass, pPackageName_".Part", $$DataLocation("EntOccId"), $$DataLocation("Idx.EO"), pOverWrite, "AbstractPart")
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tPartsClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tPartsClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set:pGlobalPrefix'="" tSC = ..AddParameter(tPartsClass, "GLOBALPREFIX", pDomainId, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "PartId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "EntUniId", "%Integer", .tIDProps, 1)
		quit:$$$ISERR(tSC)
		set tRoleProps("VALUELIST")=($$$ENTTYPECONCEPT_","_$$$ENTTYPERELATION_","_$$$ENTTYPENONREL_","_$$$ENTTYPEPATHREL)
		set tSC = ..AddProperty(tPartsClass, "EntTypeId", "%Integer", .tRoleProps, 2)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "EntityType", "%String",, 0, 1, 1, "set {*} = $case({EntTypeId}, $$$ENTTYPECONCEPT:""concept"", $$$ENTTYPERELATION:""relation"", $$$ENTTYPENONREL:""non-relevant"", $$$ENTTYPEPATHREL:""path-relevant"", :""unknown"")")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "SentenceId", "%Integer", .tIDProps, 3)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "PosInSentence", "%Integer", .tIDProps, 4)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "CrcOccurrenceIdM", "%Integer", .tPosIntProps, 5)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "CrcOccurrenceIdR", "%Integer", .tPosIntProps, 6)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "CrcOccurrenceIdS", "%Integer", .tPosIntProps, 7)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "PathId", "%Integer", .tIDProps, 8)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "PosInPath", "%Integer", .tPosIntProps, 9)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "Entity", "EntityUnique",, 0,, 1, "set {*} = {EntUniId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "EntityValue", "%String", .tLongStrProps, 0,, 1, "new tObj  if '{EntUniId} { set {*} = """" } else { set tObj = ##class(EntityUnique).%OpenId({EntUniId},0), {*} = $s($isobject(tObj):tObj.EntityValue, 1:"""") }")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "Sentence", "Sentence",, 0,, 1, "set {*} = {SentenceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "Path", "Path",, 0,, 1, "set {*} = {PathId}")
		quit:$$$ISERR(tSC)
		k tTheseProps
		merge tTheseProps = tLongStrProps
		set tTheseProps("COLLATION") = "EXACT"
		set tSC = ..AddProperty(tPartsClass, "Literal", "%String", .tLongStrProps, 0,, 1, "set {*} = ##class(%iKnow.Queries.EntityAPI).GetLiteral("_pDomainId_",{PartId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "SourceId", "%Integer", .tIDProps, 0,, 1, "set {*} = ##class(%iKnow.Queries.SentenceAPI).GetSourceId("_pDomainId_",{SentenceId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "Source", "Source",, 0,, 1, "set {*} = {SourceId}")
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBENTUNIBIT) {
			set tSC = ..AddIndex(tPartsClass, "%EntUniToOccBit", "EntUniId",, "bitmap", $$DataLocation("EntUniToOccBit"))
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddIndex(tPartsClass, "PartExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tPartsClass, "%EntTypeToOccBit", "EntTypeId",, "bitslice", $$DataLocation("EntTypeToOccBit"))
		quit:$$$ISERR(tSC) // mapping not picked up by optimizer?? --> may need bitmap extent index!
		set tSC = ..AddFK(tPartsClass, "%EntUniFK", "EntUniId", tEUClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tPartsClass, "%SentenceFK", "SentenceId", tSentClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tPartsClass, "%SourceFK", "SourceId", tSrcClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tPartsClass, "%PathFK", "PathId", tPathClass.Name)
		quit:$$$ISERR(tSC)
		if tUseStemming {
			set tSC = ..AddProperty(tPartsClass, "StemUniId", "%Integer", .tIDProps, 10)
			quit:$$$ISERR(tSC)
			set tSC = ..AddProperty(tPartsClass, "Stem", "StemUnique",, 0,, 1, "set {*} = {StemUniId}")
			quit:$$$ISERR(tSC)
			if $$$IKBUILD($$$IKBSTEMUNIBIT) {
				set tSC = ..AddIndex(tPartsClass, "%StemUniToOccBit", "StemUniId",, "bitmap", $$DataLocation("StemUniToOccBit"))
				quit:$$$ISERR(tSC)
			}
			set tSC = ..AddFK(tPartsClass, "%StemUniFK", "StemUniId", tStemClass.Name)
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddProperty(tPartsClass, "Attributes", "%ArrayOfObjects",, 0, 1, 1, "set {*} = ##class("_tPartsClass.Name_").GetAttributes({PartId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "DictionaryMatches", "%ArrayOfObjects",, 0, 1, 1, "set {*} = ##class("_tPartsClass.Name_").GetDictionaryMatches({PartId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tPartsClass, "Annotations", "%ArrayOfObjects",, 0, 1, 1, "set {*} = ##class("_tPartsClass.Name_").GetAnnotations({PartId})")
		quit:$$$ISERR(tSC)
		set tSC = tPartsClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tPartsClass.Name) = tPartsClass
		
		
		// Entity Occurrence table
		if '##class(%Dictionary.ClassDefinition).%ExistsId(pPackageName_".EntityOccurrence") {
			set tEOClass = ##class(%Dictionary.ClassDefinition).%New()
			set tEOClass.Name = pPackageName_".EntityOccurrence"
			set tEOClass.ClassType = "view"
			set tEOClass.CompileAfter = tPartsClass.Name
			set tEOClass.ViewQuery = "SELECT * FROM "_$replace(pPackageName,".","_")_".Part WHERE EntTypeId IN (0,1)"
			set tSC = tEOClass.%Save()
			quit:$$$ISERR(tSC)
			set tClasses(tEOClass.Name) = tEOClass
		}
		
		
		// ENTITYINSOURCE table
		set tSC = ..CreateClass(.tEntSrcClass, pPackageName_".EntityInSource", $$DataLocation("EntSrcDetails"), $$DataLocation("Idx.ESD"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tEntSrcClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tEntSrcClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEntSrcClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEntSrcClass, "SourceId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEntSrcClass, "EntUniId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEntSrcClass, "Source", "Source",, 0, 1, 1, "set {*} = {SourceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEntSrcClass, "Entity", "EntityUnique",, 0, 1, 1, "set {*} = {EntUniId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEntSrcClass, "FrequencyAsConcept", "%Integer", .tPosIntProps, 1)
		quit:$$$ISERR(tSC) 
		set tSC = ..AddProperty(tEntSrcClass, "FrequencyAsRelation", "%Integer", .tPosIntProps, 2)
		quit:$$$ISERR(tSC) 
		set tSC = ..AddProperty(tEntSrcClass, "Frequency", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = {FrequencyAsConcept} + {FrequencyAsRelation}")
		quit:$$$ISERR(tSC) 
		set tSC = ..AddProperty(tEntSrcClass, "DominanceAsConcept", "%Numeric",, 3)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tEntSrcClass, "DominanceAsRelation", "%Numeric",, 4)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tEntSrcClass, "%SourceFK", "SourceId", "Source")
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tEntSrcClass, "%EntUniFK", "EntUniId", "EntityUnique")
		quit:$$$ISERR(tSC)
		set tSC = tEntSrcClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tEntSrcClass.Name) = tEntSrcClass
		
		
		// CRCUNIQUE table
		set tSC = ..CreateClass(.tCRCUClass, pPackageName_".CrcUnique", $$DataLocation("CrcUniId"), $$DataLocation("Idx.CRCU"), pOverWrite)
		quit:$$$ISERR(tSC)
		
		// BDB879 - if classes with the old terminology already exist, we should not attempt
		// to add the new properties as they will be appended as custom props rather than
		// update the storage definition. For any indices or other artefacts that haven't changed
		// names, this doesn't need to be verified beyond existing checks in the ..Add*() methods
		set tPreBDB879ClassExists = ##class(%Dictionary.PropertyDefinition).%ExistsId(pPackageName_".CrcUnique||MasterId")
		
		set tSC = ..AddParameter(tCRCUClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tCRCUClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCUClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCUClass, "CrcUniId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddProperty(tCRCUClass, "HeadId", "%Integer", .tPosIntProps, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCUClass, "RelationId", "%Integer", .tPosIntProps, 2)
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddProperty(tCRCUClass, "TailId", "%Integer", .tPosIntProps, 3)
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBCRCUNIDET) {
			set tSC = ..AddProperty(tCRCUClass, "CorpusFrequency", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("CrcUniDetails",0)_"{CrcUniId})),1)")
			quit:$$$ISERR(tSC)
			set tSC = ..AddProperty(tCRCUClass, "CorpusSpread", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("CrcUniDetails",0)_"{CrcUniId})),2)")
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddProperty(tCRCUClass, "CorpusDominance", "%Numeric",, 0, 1, 1, "set {*} = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue("_pDomainId_",{CrcUniId},$$$SDCRC)")
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddProperty(tCRCUClass, "Head", "EntityUnique",, 0, 1, 1, "set {*} = {HeadId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCUClass, "Relation", "EntityUnique",, 0, 1, 1, "set {*} = {RelationId}")
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddProperty(tCRCUClass, "Tail", "EntityUnique",, 0, 1, 1, "set {*} = {TailId}")
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBCCUNIALL) {
			set tSC = ..AddProperty(tCRCUClass, "CcUniId", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $g("_$$DataLocation("CcUni",0)_"+{HeadId},+{TailId}))")
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddProperty(tCRCUClass, "Value", "%String", .tLongStrProps, 0, 1, 1, "set {*} = $s({HeadId}:##class(EntityUnique).%OpenId({HeadId},0).EntityValue, 1:"""") _ "" ~ "" _ $s({RelationId}:##class(EntityUnique).%OpenId({RelationId},0).EntityValue, 1:"""") _ "" ~ "" _ $s({TailId}:##class(EntityUnique).%OpenId({TailId},0).EntityValue, 1:"""")")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCUClass, "Entities", "%List",, 0, 1, 1, "set {*} = $g("_$$DataLocation("CrcUniId",0)_"{CrcUniId}))")
		quit:$$$ISERR(tSC)
		set tSC = ..AddBVA(tCRCUClass, "Entities", "$g("_$$DataLocation("EntUniId",0)_"tElement))", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tCRCUClass, "%CrcUni", "HeadId,RelationId,TailId", 1, "key", $$DataLocation("CrcUni"))
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBCRCUNIFREQ) {
			set tSC = ..AddIndex(tCRCUClass, "%CrcUniIdFreq", "CorpusFrequency:Minus,CrcUniId",,, $$DataLocation("CrcUniIdFreq"))
			quit:$$$ISERR(tSC)
		}
		if $$$IKBUILD($$$IKBCRCUNISPREAD) {
			set tSC = ..AddIndex(tCRCUClass, "%CrcUniIdSpread", "CorpusSpread:Minus,CrcUniId",,, $$DataLocation("CrcUniIdSpread"))
			quit:$$$ISERR(tSC)
		}
		if $$$IKBUILD($$$IKBCRCUNIMAP) {
			set tSC = ..AddIndex(tCRCUClass, "%EntUniMToCrcUniBit", "HeadId",, "bitmap", $$DataLocation("EntUniMToCrcUniBit"))
			quit:$$$ISERR(tSC)
			set tSC = ..AddIndex(tCRCUClass, "%EntUniRToCrcUniBit", "RelationId",, "bitmap", $$DataLocation("EntUniRToCrcUniBit"))
			quit:$$$ISERR(tSC)
			set tSC = ..AddIndex(tCRCUClass, "%EntUniSToCrcUniBit", "TailId",, "bitmap", $$DataLocation("EntUniSToCrcUniBit"))
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddIndex(tCRCUClass, "%CrcUniExists",,, "bitmapextent", $$DataLocation("CrcUniExistsBit"))
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddFK(tCRCUClass, "%HeadFK", "HeadId", "EntityUnique")
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tCRCUClass, "%RelationFK", "RelationId", "EntityUnique")
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddFK(tCRCUClass, "%TailFK", "TailId", "EntityUnique")
		quit:$$$ISERR(tSC)
		set tSC = tCRCUClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tCRCUClass.Name) = tCRCUClass
		
		
		
		// CRCOCCURRENCE table
		set tSC = ..CreateClass(.tCRCOClass, pPackageName_".CrcOccurrence", $$DataLocation("CrcOccId"), $$DataLocation("Idx.CRCO"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tCRCOClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tCRCOClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "CrcOccId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "CrcUniId", "%Integer", .tIDProps, 1)
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddProperty(tCRCOClass, "HeadOccId", "%Integer", .tIDProps, 2)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "RelationOccId", "%Integer", .tIDProps, 3)
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddProperty(tCRCOClass, "TailOccId", "%Integer", .tIDProps, 4)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "SentenceId", "%Integer", .tIDProps, 5)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "PosInSentence", "%Integer", .tIDProps, 6)
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBCCUNIALL) {
			set tSC = ..AddProperty(tCRCOClass, "CcUniId", "%Integer", .tIDProps, 0,, 1, "n crc  set crc = $g("_$$DataLocation("CrcUniId",0)_"{CrcUniId})), {*} = $g("_$$DataLocation("CcUni",0)_"+$lg(crc,1),+$lg(crc,3)))")
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddProperty(tCRCOClass, "CrcUnique", "CrcUnique",, 0,, 1, "set {*} = {CrcUniId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "Sentence", "Sentence",, 0,, 1, "set {*} = {SentenceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "SourceId", "%Integer", .tIDProps, 0,, 1, "set {*} = ##class(%iKnow.Queries.SentenceAPI).GetSourceId("_pDomainId_",{SentenceId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCOClass, "Source", "Source",, 0,, 1, "set {*} = {SourceId}")
		quit:$$$ISERR(tSC)
		if $$$IKBUILD($$$IKBCRCUNIBIT) {
			set tSC = ..AddIndex(tCRCOClass, "%CrcUniToOccBit", "CrcUniId",, "bitmap", $$DataLocation("CrcUniToOccBit"))
			quit:$$$ISERR(tSC)
		}
		if $$$IKBUILD($$$IKBCCUNIBIT) {
			set tSC = ..AddIndex(tCRCOClass, "%CcUniToOccBit", "CcUniId",, "bitmap", $$DataLocation("CcUniToOccBit"))
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddIndex(tCRCOClass, "CrcOccExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tCRCOClass, "%CrcUniFK", "CrcUniId", "CrcUnique")
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddFK(tCRCOClass, "%EntOccHFK", "HeadOccId", tPartsClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tCRCOClass, "%EntOccRFK", "RelationOccId", tPartsClass.Name)
		quit:$$$ISERR(tSC)
		set:'tPreBDB879ClassExists tSC = ..AddFK(tCRCOClass, "%EntOccTFK", "TailOccId", tPartsClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tCRCOClass, "%SentenceFK", "SentenceId", "Sentence")
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tCRCOClass, "%SourceFK", "SourceId", "Source")
		quit:$$$ISERR(tSC)
		set tSC = tCRCOClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tCRCOClass.Name) = tCRCOClass
		
		
		
		
		// CRCINSOURCE table
		set tSC = ..CreateClass(.tCRCSrcClass, pPackageName_".CrcInSource", $$DataLocation("CrcSrcDetails"), $$DataLocation("Idx.CSD"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tCRCSrcClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tCRCSrcClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCSrcClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCSrcClass, "SourceId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCSrcClass, "CrcUniId", "%Integer", .tIDProps, -1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCSrcClass, "Source", "Source",, 0, 1, 1, "set {*} = {SourceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCSrcClass, "CrcUnique", "CrcUnique",, 0, 1, 1, "set {*} = {CrcUniId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tCRCSrcClass, "Frequency", "%Integer", .tPosIntProps, 1)
		quit:$$$ISERR(tSC) 
		set tSC = ..AddProperty(tCRCSrcClass, "Dominance", "%Numeric",, 2)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tCRCSrcClass, "%SourceFK", "SourceId", "Source")
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tCRCSrcClass, "%CrcUniFK", "CrcUniId", "CrcUnique")
		quit:$$$ISERR(tSC)
		set tSC = tCRCSrcClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tCRCSrcClass.Name) = tCRCSrcClass
		
		
		
		// CCUNIQUE table
		if $$$IKBUILD($$$IKBCCUNIALL) {
			set tSC = ..CreateClass(.tCCClass, pPackageName_".CcUnique", $$DataLocation("CcUniId"), $$DataLocation("Idx.CCU"), pOverWrite)
			quit:$$$ISERR(tSC)
			set tSC = ..AddParameter(tCCClass, "DOMAINID", pDomainId)
			quit:$$$ISERR(tSC)
			set tSC = ..AddParameter(tCCClass, "MANAGEDEXTENT", 0)
			quit:$$$ISERR(tSC)
			set tSC = ..AddProperty(tCCClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
			quit:$$$ISERR(tSC)
			set tSC = ..AddProperty(tCCClass, "CcUniId", "%Integer", .tIDProps, -1)
			quit:$$$ISERR(tSC)
			set:'tPreBDB879ClassExists tSC = ..AddProperty(tCCClass, "HeadId", "%Integer", .tPosIntProps, 1)
			quit:$$$ISERR(tSC)
			set:'tPreBDB879ClassExists tSC = ..AddProperty(tCCClass, "TailId", "%Integer", .tPosIntProps, 2)
			quit:$$$ISERR(tSC)
			if $$$IKBUILD($$$IKBCCUNIDET) {
				set tSC = ..AddProperty(tCCClass, "CorpusFrequency", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("CcUniDet",0)_"{CcUniId})),1)")
				quit:$$$ISERR(tSC)
				set tSC = ..AddProperty(tCCClass, "CorpusSpread", "%Integer", .tPosIntProps, 0, 1, 1, "set {*} = $lg($g("_$$DataLocation("CcUniDet",0)_"{CcUniId})),2)")
				quit:$$$ISERR(tSC)
			}
			set:'tPreBDB879ClassExists tSC = ..AddProperty(tCCClass, "Head", "EntityUnique",, 0, 1, 1, "set {*} = {HeadId}")
			quit:$$$ISERR(tSC)
			set:'tPreBDB879ClassExists tSC = ..AddProperty(tCCClass, "Tail", "EntityUnique",, 0, 1, 1, "set {*} = {TailId}")
			quit:$$$ISERR(tSC)
			set tSC = ..AddIndex(tCCClass, "%CcUni", "HeadId,TailId", 1, "key", $$DataLocation("CcUni"))
			quit:$$$ISERR(tSC)
			if $$$IKBUILD($$$IKBCCUNIFREQ) {
				set tSC = ..AddIndex(tCCClass, "%CcUniIdFreq", "CorpusFrequency:Minus,CcUniId",,, $$DataLocation("CcUniIdFreq"))
				quit:$$$ISERR(tSC)
			}
			if $$$IKBUILD($$$IKBCCUNISPREAD) {
				set tSC = ..AddIndex(tCCClass, "%CcUniIdSpread", "CorpusSpread:Minus,CcUniId",,, $$DataLocation("CcUniIdSpread"))
				quit:$$$ISERR(tSC)
			}
			if $$$IKBUILD($$$IKBCCUNIMAP) {
				set tSC = ..AddIndex(tCCClass, "%EntUniMToCcUniBit", "HeadId",, "bitmap", $$DataLocation("EntUniMToCcUniBit"))
				quit:$$$ISERR(tSC)
				set tSC = ..AddIndex(tCCClass, "%EntUniSToCcUniBit", "TailId",, "bitmap", $$DataLocation("EntUniSToCcUniBit"))
				quit:$$$ISERR(tSC)
			}
			set tSC = ..AddIndex(tCCClass, "%CcUniExists",,, "bitmapextent", $$DataLocation("CcUniExistsBit"))
			quit:$$$ISERR(tSC)
			set:'tPreBDB879ClassExists tSC = ..AddFK(tCCClass, "%HeadFK", "HeadId", "EntityUnique")
			quit:$$$ISERR(tSC)
			set:'tPreBDB879ClassExists tSC = ..AddFK(tCCClass, "%TailFK", "TailId", "EntityUnique")
			set tSC = tCCClass.%Save()
			quit:$$$ISERR(tSC)
			set tClasses(tCCClass.Name) = tCCClass
		}
		
		
		// attributes
		set tSC = ..CreateClass(.tAttPClass, pPackageName_".PathAttribute", $$DataLocation("Att.Path"), $$DataLocation("Idx.ATP"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tAttPClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tAttPClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttPClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttPClass, "PathId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttPClass, "AttributeTypeId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttPClass, "StartPosInPath", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttPClass, "SpanInPath", "%Integer", .tIDProps, 1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttPClass, "Path", "Path",, 0,, 1, "set {*} = {PathId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttPClass, "Parts", "%List",, 0, 1, 1, "set {*} = $li($g("_$$DataLocation("PathToEntOcc",0)_"{PathId})),{StartPosInPath},{StartPosInPath}+{SpanInPath}-1)")
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tAttPClass, "%PathFK", "PathId", "Path")
		quit:$$$ISERR(tSC)
		set tSC = tAttPClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tAttPClass.Name) = tAttPClass
		
		set tSC = ..CreateClass(.tAttSClass, pPackageName_".SentenceAttribute", $$DataLocation("Att.Sent"), $$DataLocation("Idx.ATS"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tAttSClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tAttSClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttSClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttSClass, "SentenceId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttSClass, "AttributeTypeId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttSClass, "StartPosInSent", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttSClass, "SpanInSent", "%Integer", .tIDProps, 1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttSClass, "Sentence", "Sentence",, 0,, 1, "set {*} = {SentenceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tAttSClass, "Parts", "%List",, 0, 1, 1, "new tPartBase,tSentPos,tList,tAttData  set tPartBase = $lg($g("_$$DataLocation("SentDetails",0)_"{SentenceId})),4),tList="""",tAttData=$g("_$$DataLocation("Att.Sent",0)_"{SentenceId},{AttributeTypeId},{StartPosInSent})) for tSentPos=0:1:{SpanInSent}-1 { set:$ld(tAttData,tSentPos+2) tList=tList_$lb(tPartBase+{StartPosInSent}+tSentPos) }  set {*} = tList")
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tAttSClass, "%SentenceFK", "SentenceId", "Sentence")
		quit:$$$ISERR(tSC)
		set tSC = tAttSClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tAttSClass.Name) = tAttSClass
		
		
		// custom annotations
		if '$$$defClassDefined(pPackageName_".CustomAnnotation") {
			set tCustomClass = ##class(%Dictionary.ClassDefinition).%New(pPackageName_".CustomAnnotation")
			set tCustomClass.Super = "%iKnow.Tables.AbstractCustomAnnotation"
			set tCustomClass.ProcedureBlock = 1
			set tSC = tCustomClass.%Save()
			quit:$$$ISERR(tSC)
			set tClasses(tCustomClass.Name) = tCustomClass
		}
		
		
		// dictionary & matching results
		set tSC = ..CreateClass(.tDictClass, pPackageName_".Dictionary", $$DataLocation("Mat.DictId"), $$DataLocation("Idx.MD"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictClass, "DictionaryId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		//set tDictNameProps("MAXLEN")=$$$IKHASHSIZE, tDictNameProps("COLLATION")="SQLUPPER"
		set tSC = ..AddProperty(tDictClass, "Name", "%String", .tMediumStrProps, 1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictClass, "Description", "%String", .tLongStrProps, 2, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictClass, "DefaultLanguage", "%String", .tStrProps, 3, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictClass, "%DictName", "Name", 1, "key", $$DataLocation("Mat.Dict"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictClass, "DictExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = tDictClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tDictClass.Name) = tDictClass
		
		set tSC = ..CreateClass(.tDictItemClass, pPackageName_".DictionaryItem", $$DataLocation("Mat.DictItemId"), $$DataLocation("Idx.MDI"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictItemClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictItemClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictItemClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictItemClass, "DictionaryItemId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictItemClass, "DictionaryId", "%Integer", .tIDProps, 1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictItemClass, "Dictionary", "Dictionary",, 0, 1, 1, "set {*} = {DictionaryId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictItemClass, "Name", "%String", .tMediumStrProps, 2, 1)
		quit:$$$ISERR(tSC)
		set tURIProps("MAXLEN")=$$$IKHASHSIZE, tURIProps("COLLATION")="EXACT"
		set tSC = ..AddProperty(tDictItemClass, "URI", "%String", .tURIProps, 3, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictItemClass, "DefaultLanguage", "%String", .tStrProps, 4, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictItemClass, "Terms", "%List",, 0, 1, 1, "set {*} = $g(^IRIS.IK.Mat.DictItemTerms(193,{DictionaryItemId}))")
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictItemClass, "%DictItemURI", "URI", 1, "key", $$DataLocation("Mat.DictItemURI"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictItemClass, "%DictToItem", "DictionaryId",,, $$DataLocation("Mat.DictToItem"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictItemClass, "DictItemExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = tDictItemClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tDictItemClass.Name) = tDictItemClass
		
		set tSC = ..CreateClass(.tDictTermClass, pPackageName_".DictionaryTerm", $$DataLocation("Mat.DictTermId"), $$DataLocation("Idx.MDT"), pOverWrite)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictTermClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictTermClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "DictionaryTermId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "DictionaryId", "%Integer", .tIDProps, 1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "Dictionary", "Dictionary",, 0, 1, 1, "set {*} = {DictionaryId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "DictionaryItemId", "%Integer", .tIDProps, 2, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "DictionaryItem", "DictionaryItem",, 0, 1, 1, "set {*} = {DictionaryItemId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "StringValue", "%String", .tLongStrProps, 3, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictTermClass, "DefaultLanguage", "%String", .tStrProps, 4, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictTermClass, "DictTermExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = tDictTermClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tDictTermClass.Name) = tDictTermClass
		
		/*
		set tSC = ..AddProperty(tDictElemClass, "StringId", "%Integer",, 3, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictElemClass, "StringValue", "%String", .tLongStrProps, 0, 1, 1, "set {*} = $s({StringId}>0:"_$$DataLocation("EntUniId",0)_"{StringId}, 1:"_$$DataLocation("Mat.DictElemStringId",0)_"-{StringId})")
		quit:$$$ISERR(tSC)
		*/
		
		set tSC = ..CreateClass(.tDictMatchClass, pPackageName_".DictionaryMatch", $$DataLocation("Mat.MatchId"), $$DataLocation("Idx.MM"), pOverWrite, "AbstractDictionaryMatch")
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictMatchClass, "DOMAINID", pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddParameter(tDictMatchClass, "MANAGEDEXTENT", 0)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "DomainId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = "_pDomainId)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "MatchId", "%Integer", .tIDProps, -1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "DictionaryId", "%Integer", .tIDProps, 1, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "Dictionary", "Dictionary",, 0, 1, 1, "set {*} = {DictionaryId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "DictionaryItemId", "%Integer", .tIDProps, 2, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "DictionaryItem", "DictionaryItem",, 0, 1, 1, "set {*} = {DictionaryItemId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "DictionaryTermId", "%Integer", .tIDProps, 3, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "DictionaryTerm", "DictionaryTerm",, 0, 1, 1, "set {*} = {DictionaryTermId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "TargetType", "%Integer", .tIDProps, 4, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "TargetId", "%Integer", .tIDProps, 5, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "Score", "%Numeric", .tIDProps, 6, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "MatchedConceptCount", "%Integer", .tPosIntProps, 7, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "MatchedRelationCount", "%Integer", .tPosIntProps, 8, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "PartialMatchCount", "%Integer", .tPosIntProps, 9, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "FirstPosInPath", "%Integer", .tIDProps, 10, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "LastPosInPath", "%Integer", .tIDProps, 11, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "IsInOrder", "%Boolean", .tIDProps, 12, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "NegatedEntityCount", "%Integer", .tPosIntProps, 13, 1)
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "SentenceId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = ##class(%iKnow.Matching.MatchingAPI).GetSentenceIdForMatchTarget("_pDomainId_",{TargetType},{TargetId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "Sentence", "Sentence",, 0, 1, 1, "set {*} = {SentenceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "SourceId", "%Integer", .tIDProps, 0, 1, 1, "set {*} = ##class(%iKnow.Matching.MatchingAPI).GetSourceIdForMatchTarget("_pDomainId_",{TargetType},{TargetId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "Source", "Source",, 0, 1, 1, "set {*} = {SourceId}")
		quit:$$$ISERR(tSC)
		set tSC = ..AddProperty(tDictMatchClass, "Parts", "%List",, 0, 1, 1, "set {*} = ##class("_tDictMatchClass.Name_").GetParts({MatchId})")
		quit:$$$ISERR(tSC)
		set tSC = ..AddBVA(tDictMatchClass, "Parts")
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictMatchClass, "%EntOccToMatch", "Parts(ELEMENTS)", 0,, $$DataLocation("Mat.EntOccToMatch"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictMatchClass, "%ItemToMatch", "DictionaryItemId",,, $$DataLocation("Mat.DictItemToMatch"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictMatchClass, "%DictToMatch", "DictionaryId",, "bitmap", $$DataLocation("Mat.DictToMatchBit"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictMatchClass, "%SourceToMatch", "SourceId",,, $$DataLocation("Mat.SrcToMatch"))
		quit:$$$ISERR(tSC)
		set tSC = ..AddIndex(tDictMatchClass, "DictMatchExtent", "",, "bitmapextent") // BDB624
		quit:$$$ISERR(tSC)
		set tSC = tDictMatchClass.%Save()
		quit:$$$ISERR(tSC)
		set tClasses(tDictMatchClass.Name) = tDictMatchClass
		
		
		// add remaining pointers and FKs
		if $$$IKBUILD($$$IKBCCUNIALL) {
			set tSC = ..AddProperty(tCRCUClass, "CcUnique", "CcUnique",, 0, 1, 1, "set {*} = {CcUniId}")
			quit:$$$ISERR(tSC)
			set tSC = ..AddFK(tCRCUClass, "%CcUniqueFK", "CcUniId", tCCClass.Name)
			quit:$$$ISERR(tSC)
			set tSC = tCRCUClass.%Save()
			
			set tSC = ..AddProperty(tCRCOClass, "CcUnique", "CcUnique",, 0, 1, 1, "set {*} = {CcUniId}")
			quit:$$$ISERR(tSC)
			set tSC = tCRCOClass.%Save()
			quit:$$$ISERR(tSC)
		}
		set tSC = ..AddFK(tPartsClass, "%CrcOccMFK", "CrcOccurrenceIdM", tCRCOClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tPartsClass, "%CrcOccRFK", "CrcOccurrenceIdR", tCRCOClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = ..AddFK(tPartsClass, "%CrcOccSFK", "CrcOccurrenceIdS", tCRCOClass.Name)
		quit:$$$ISERR(tSC)
		set tSC = tPartsClass.%Save()
		quit:$$$ISERR(tSC)
		
		
		// add custom indices
		set tSC = ..CustomizeTables(pDomainId, pPackageName, .pAdditionalIndices, 0)
		quit:$$$ISERR(tSC)
		
		
		// compile all
		if pQueue {
			set tClass = ""
			for {
				set tClass = $order(tClasses(tClass))
				quit:tClass=""
				
				do QueueClass^%occCompile(tClass)
			}
		} else {
			set tSC = $system.OBJ.Compile(.tClasses, "c-d")
			quit:$$$ISERR(tSC)
		}
		
		
		// register package name
		set ^IRIS.IK.Sys.Params(pDomainId, $$$IKPPACKAGE) = pPackageName
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
	
DataLocation(name,close=1)
	quit $$$IKTablesDataLocation(pGlobalPrefix,pDomainId,name,close)
}

ClassMethod CustomizeTables(pDomainId As %Integer = "", pPackageName As %String, ByRef pCustomziations, pCompile As %Boolean = 1) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		for tTableName = "Source", "Sentence", "Path", "EntityUnique", "EntityOccurrence", "StemUnique", "CrcUnique", "CcUnique", "CrcOccurrence", "Part", "Dictionary", "DictionaryItem", "DictionaryTerm", "DictionaryMatch" {
			continue:'$d(pCustomziations(tTableName))
			
			set tClass = ##class(%Dictionary.ClassDefinition).%OpenId(pPackageName_"."_tTableName)
			if '$isobject(tClass) {
				set tSC = $$$ERROR($$$ClassDoesNotExist, pPackageName_"."_tTableName)
				quit
			}
			
			/// PARAMETERS
			set tParamName = ""
			for {
				set tParamName = $order(pCustomziations(tTableName, "param", tParamName), 1, tParamDetails)
				quit:tParamName=""
				
				set tSC = ..AddParameter(tClass, tParamName, $lg(tParamDetails,1))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
			
			/// PROPERTIES
			set tPropName = ""
			for {
				// tPropDetails = $lb(type, calculated, computecode)
				set tPropName = $order(pCustomziations(tTableName, "prop", tPropName), 1, tPropDetails)
				quit:tPropName=""
				
				set:pDomainId'="" tCode = $replace($lg(tPropDetails,3),"{DomainId}",pDomainId)
				set tCode = $replace(tCode, "{ClassName}", tClass.Name)
				set tCode = $replace(tCode, "{PackageName}", $piece(tClass.Name, ".", 1, *-1))
				set tSC = ..AddProperty(tClass, tPropName, $lg(tPropDetails,1),, 0, $ld(tPropDetails,3), +$lg(tPropDetails,2), tCode)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
			
			
			/// METHODS
			set tMethodName=""
			for {
				// tMethodDetails = $lb(formalspec, returntype, classmethod)
				set tMethodName = $order(pCustomziations(tTableName, "method", tMethodName), 1, tMethodDetails)
				quit:tMethodName=""
				
				set tMethod = ##class(%Dictionary.MethodDefinition).%New()
				set tMethod.parent = tClass
				set tMethod.Name = tMethodName
				set tMethod.FormalSpec = $lg(tMethodDetails,1)
				set tMethod.ReturnType = $lg(tMethodDetails,2)
				set tMethod.ClassMethod = +$lg(tMethodDetails,3)
				
				set i=""
				for {
					set i = $order(pCustomziations(tTableName, "method", tMethodName, i), 1, tCode)
					quit:i=""
					do tMethod.Implementation.WriteLine(tCode)
				}
			}
			
			
			/// INDICES
			set tIndexName = ""
			for {
				set tIndexName = $order(pCustomziations(tTableName, "idx", tIndexName), 1, tIndexDetails)
				quit:tIndexName=""
				
				set tProps = $lg(tIndexDetails,1)
				
				// add calculated property for arrow syntax
				if $f(tProps,"->") {
					
					// find property types
					set tPropClass = tClass, tChainLength = $l(tProps,"->")
					for i = 1:1:tChainLength {
						set tPropType = "", tPropNames(i) = $piece(tProps,"->",i)
						for j = 1:1:tPropClass.Properties.Count() {
							continue:tPropClass.Properties.GetAt(j).Name'=tPropNames(i)
							set tPropType = tPropClass.Properties.GetAt(j).Type
							quit
						}
						if tPropType="" {
							set tSC = $$$ERROR($$$NoSuchMethodorProp,tPropNames(i))
							quit
						}
						set tPropType = $s($f(tPropType,"."):tPropType, $e(tPropType)="%":tPropType, 1:pPackageName_"."_tPropType)
						set tPropClass = ##class(%Dictionary.ClassDefinition).%OpenId(tPropType)
						set tPropTypes(i) = tPropType
					}
					quit:$$$ISERR(tSC)
					
					set tSC = ..AddProperty(tClass, tIndexName_"IDXValue", tPropType,, 0, 1, 1, "new tObj if '{"_tPropNames(1)_"} { set {*} = """" } else { set tObj = ##class("_tPropTypes(1)_").%OpenId({"_tPropNames(1)_"},0), {*} = $s($isobject(tObj):tObj."_$replace($piece(tProps,"->",2,*),"->",".")_", 1:"""") }", 1)
					quit:$$$ISERR(tSC)
					set tProps = tIndexName_"IDXValue"
				}
				set tIndexType = $lg(tIndexDetails,2), tUnique = 0
				set:$$$LOWER(tIndexType)="unique" tIndexType="", tUnique = 1
				set tSC = ..AddIndex(tClass, tIndexName, tProps, tUnique, tIndexType)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
			set tSC = tClass.%Save()
			quit:$$$ISERR(tSC)
			
			set tClasses(tClass.Name)=""
		}
		quit:$$$ISERR(tSC)
		
		
		// compile all
		if pCompile {
			set tSC = $system.OBJ.Compile(.tClasses, "c-d")
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Drops any classes generated by <method>CreateDomainTables</method> in package <var>pPackageName</var>
/// and associated customization data (field values & indices)
ClassMethod DropDomainTables(pPackageName As %String) As %Status
{
	set tSC = $$$OK
	try {
		// BDB732 - retrieve domain ID for any of the tables still around
		set tDomainId = -1
		for tTable = "Source", "EntityUnique", "StemUnique", "CrcUnique", "CcUnique", "Sentence", "Path", "Part", "CrcOccurrence", "EntityInSource", "CrcInSource", "PathAttribute", "SentenceAttribute", "Dictionary", "DictionaryItem", "DictionaryTerm", "DictionaryMatch" {
			continue:'$$$defClassDefined(pPackageName_"."_tTable)
			set tDomainId = $parameter(pPackageName_"."_tTable, "DOMAINID")
			quit:tDomainId>0
		}
		// if there are none left, there's nothing to drop either
		quit:tDomainId<0
		// verify if this domain isn't managed by someone else
		$$$IKCHECKDOMMGRX(tDomainId,tSC) 
		
		
		// first make sure the annotation table is emptied
		if $$$defClassDefined(pPackageName_".CustomAnnotation") {
			do $classmethod(pPackageName_".CustomAnnotation", "%KillExtent")
			set tClasses(pPackageName_".CustomAnnotation")=""
		}
		
		// BDB625 - now get rid of custom field data (in async jobs) and purge custom indices
		#dim tWorkMgr As %SYSTEM.WorkMgr
		set tWorkMgr = $system.WorkMgr.Initialize("", .tSC)
		quit:$$$ISERR(tSC)
		
		for tTable = "Source", "EntityUnique", "StemUnique", "CrcUnique", "CcUnique", "Sentence", "Path", "Part", "CrcOccurrence", "EntityInSource", "CrcInSource", "PathAttribute", "SentenceAttribute", "Dictionary", "DictionaryItem", "DictionaryTerm", "DictionaryMatch" {
			set tClassName = pPackageName_"."_tTable
			set:$$$defClassDefined(tClassName) tClasses(tClassName)=""
			continue:'##class(%Dictionary.CompiledClass).%ExistsId(tClassName)
			
			if $classmethod(tClassName,"%HasCustomFields") {
				set tSC = tWorkMgr.Queue("##class("_tClassName_").%PurgeCustomFields")
				quit:$$$ISERR(tSC)
			}
			
			set tSC = $classmethod(tClassName, "%PurgeCustomIndices")
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// add EO view
		set:$$$defClassDefined(pPackageName_".EntityOccurrence") tClasses(pPackageName_".EntityOccurrence")=""
		
		set tSC = tWorkMgr.Sync()
		quit:$$$ISERR(tSC)
		
		set:$d(tClasses) tSC = $$Delete^%apiOBJ(.tClasses, "c-d-e")
		quit:$$$ISERR(tSC)
		
		// TODO: why do we need to do this explicitly??
		for tTable = "Source", "EntityUnique", "StemUnique", "CrcUnique", "CcUnique", "Sentence", "Path", "Part", "CrcOccurrence", "EntityInSource", "CrcInSource", "PathAttribute", "SentenceAttribute", "CustomAnnotation", "Dictionary", "DictionaryItem", "DictionaryTerm", "DictionaryMatch" {
			set tClassName = pPackageName_"."_tTable
			do ##class(%ExtentMgr.Util).DeleteExtentDefinitionIfExists(tClassName)
		}
		
		// BDB732
		k ^IRIS.IK.Sys.Params(tDomainId,$$$IKPPACKAGE)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod SyncDictionaryMatchCustomizations(pDomainId As %Integer = "", pPackageName As %String = "", pAutoPurge As %Boolean = 1, pStartSrcId As %Integer = "", pEndSrcId As %Integer = "", pFilter As %iKnow.Filters.Filter = "") As %Status
{
	set tSC = $$$OK
	try {
		if (pPackageName="") {
			set tDomain = ##class(%iKnow.Domain).%OpenId(pDomainId)
			set pPackageName = tDomain.GetParameter($$$IKPPACKAGE)
			if (pPackageName="") {
				set tSC = $$$ERROR($$$GeneralError, "No package name registered for domain "_pDomainId)
				quit
			}
		}
		set tClassName = pPackageName_".DictionaryMatch"
		
		// quit if nothing to do
		quit:$d(^IRIS.IK.Mat.MatchId(pDomainId))<10
		quit:'$classmethod(tClassName,"%HasCustomizations")
		 
		if (pStartSrcId+pEndSrcId) || $isobject(pFilter) {
			set:'pDomainId pDomainId = $parameter(tClassName,"DOMAINID")
			
			if $isobject(pFilter) {
				set tSrcId=""
				for {
					set tSrcId = pFilter.GetNextSrcId(tSrcId)
					quit:tSrcId=""
					merge tMatchIds = ^IRIS.IK.Mat.SrcToMatch(pDomainId,tSrcId)
				}
			} else {
				set tSrcId = pStartSrcId-1
				for {
					set tSrcId = $order(^IRIS.IK.Mat.SrcToMatch(pDomainId,tSrcId))
					quit:tSrcId=""
					merge tMatchIds = ^IRIS.IK.Mat.SrcToMatch(pDomainId,tSrcId)
					quit:tSrcId=pEndSrcId
				}
			}
			
			set tMatchId=""
			for {
				set tMatchId = $order(tMatchIds(tMatchId))
				quit:tMatchId=""
				$$$IKBITOFFPOS(tMatchId,tOffset,tPos)
				set $bit(tMatchIdsBit(tOffset),tPos)=1
			}
			
			set tOffset=""
			for {
				set tOffset = $order(tMatchIdsBit(tOffset),1,tBits)
				quit:tOffset=""
				
				set tEndPos = 0
				for {
					set tPos = $bitfind(tBits,1,tEndPos+1)
					quit:'tPos // no more 1s
					
					// find first non-1
					set tEndPos = $bitfind(tBits,0,tPos)
					set:'tEndPos tEndPos = $bitcount(tBits)+1 // 1s all the way to the end!
					$$$IKGETIDOFFPOS(tMatchIdFrom,tOffset,tPos)
					$$$IKGETIDOFFPOS(tMatchIdTo,tOffset,(tEndPos-1))
					
					set tSC = $classmethod(tClassName, "%BuildCustomFields", tMatchIdFrom, tMatchIdTo)
					quit:$$$ISERR(tSC)
					set tSC = $classmethod(tClassName, "%BuildCustomIndices", pAutoPurge, tMatchIdFrom, tMatchIdTo)
					quit:$$$ISERR(tSC)
				}
			}
			
		} else {
			set tSC = $classmethod(tClassName,"%BuildCustomFields")
			quit:$$$ISERR(tSC)
			set tSC = $classmethod(tClassName,"%BuildCustomIndices", pAutoPurge)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Either pDomainId or pPackageName has to be passed in, or both if they are known
ClassMethod SyncCustomizations(pDomainId As %Integer = "", pPackageName As %String = "", pAutoPurge As %Boolean = 1, pStartSrcId As %Integer = "", pEndSrcId As %Integer = "", ByRef pRanges) As %Status
{
	set tSC = $$$OK
	try {
		#define Class(%t) pPackageName_"."_%t
		
		if (pPackageName="") {
			set tDomain = ##class(%iKnow.Domain).%OpenId(pDomainId)
			set pPackageName = tDomain.GetParameter($$$IKPPACKAGE)
			if (pPackageName="") {
				set tSC = $$$ERROR($$$GeneralError, "No package name registered for domain "_pDomainId)
				quit
			}
		}
		
		write:$g(%IKVerbose) !,$zt($p($h,",",2)),": Synchronizing custom fields..."
		
		#dim tWorkMgr As %SYSTEM.WorkMgr
		set tWorkMgr = $system.WorkMgr.Initialize("", .tSC)
		quit:$$$ISERR(tSC)
		
		set tSC = tWorkMgr.Queue("##class("_$$$Class("Source")_").%BuildCustomFields", pStartSrcId, pEndSrcId)
		quit:$$$ISERR(tSC)
		
		// these will have to run for all values!
		for tTable = "EntityUnique", "StemUnique", "CrcUnique", "CcUnique" {
			continue:'$$$defClassDefined($$$Class(tTable))
			set tSC = tWorkMgr.Queue("##class("_$$$Class(tTable)_").%BuildCustomFields")
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// while the above are running, find the ID ranges for occurrence-based entries
		if $d(pRanges) {
			// get them from BuildGlobals!
			merge tRanges = pRanges
		} elseif (pStartSrcId+pEndSrcId) {
			
			// fetch domain ID if it wasn't known
			set:'pDomainId pDomainId = $parameter($$$Class("Source"),"DOMAINID")
			
			set tSrcId = pStartSrcId-1
			while 1 {
				set tSrcId = $order(^IRIS.IK.SrcDetails(pDomainId, tSrcId), 1, tSrcDetails)
				quit:tSrcId=""
				quit:pEndSrcId&&(tSrcId>pEndSrcId)
				
				// FUTURE OPTIMIZATION: refine code to collapse these into fewer entries
				set tRanges("Sentence", $lg(tSrcDetails,1)+1) = $lg(tSrcDetails,1)+$lg(tSrcDetails,2)
				set tRanges("Part", $lg(tSrcDetails,3)+1) = $lg(tSrcDetails,3)+$lg(tSrcDetails,4)
				set tRanges("CrcOccurrence", $lg(tSrcDetails,5)+1) = $lg(tSrcDetails,5)+$lg(tSrcDetails,6)
				set tRanges("Path", $lg(tSrcDetails,7)+1) = $lg(tSrcDetails,7)+$lg(tSrcDetails,8)
			}
		} else {
			set tRanges("Sentence", 0) = ""
			set tRanges("Path", 0) = ""
			set tRanges("Part", 0) = ""
			set tRanges("CrcOccurrence", 0) = ""
		}
		
		// wait for the others to complete before doing occurrences, as those are the obvious dependencies
		set tSC = tWorkMgr.Sync()
		quit:$$$ISERR(tSC)
		
		
		// now build fields for the occurrence-based ones
		for tTable =  "Sentence", "Path", "Part", "CrcOccurrence" {
			continue:'$$$defClassDefined($$$Class(tTable))
			set tStart = ""
			for {
				set tStart = $order(tRanges(tTable, tStart), 1, tEnd)
				quit:tStart=""
				set tSC = tWorkMgr.Queue("##class("_$$$Class(tTable)_").%BuildCustomFields", tStart, tEnd)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set tSC = tWorkMgr.Sync()
		quit:$$$ISERR(tSC)
		
		
		// BDB778
		for tTable =  "Dictionary", "DictionaryItem", "DictionaryTerm", "DictionaryMatch" {
			continue:'$$$defClassDefined($$$Class(tTable))
			set tSC = $classmethod($$$Class(tTable),"%BuildCustomFields")
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set tSC = tWorkMgr.Sync()
		quit:$$$ISERR(tSC)
		
		write:$g(%IKVerbose) !,$zt($p($h,",",2)),": Synchronizing custom indices..."
		
		// start full index building
		set tSC = $classmethod($$$Class("Source"), "%BuildCustomIndices", pAutoPurge, pStartSrcId, pEndSrcId)
		quit:$$$ISERR(tSC)
		
		// these will have to run for all values!
		for tTable = "EntityUnique", "StemUnique", "CrcUnique", "CcUnique" {
			continue:'$$$defClassDefined($$$Class(tTable))
			set tSC = $classmethod($$$Class(tTable), "%BuildCustomIndices", pAutoPurge)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// wait for complete before building indices
		for tTable =  "Sentence", "Path", "Part", "CrcOccurrence" {
			continue:'$$$defClassDefined($$$Class(tTable))
			set tStart = ""
			for {
				set tStart = $order(tRanges(tTable, tStart), 1, tEnd)
				quit:tStart=""
				set tSC = $classmethod($$$Class(tTable), "%BuildCustomIndices", pAutoPurge, tStart, tEnd)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// BDB778 - dictionary-related tabels
		for tTable =  "Dictionary", "DictionaryItem", "DictionaryTerm" {
			continue:'$$$defClassDefined($$$Class(tTable))
			set tSC = $classmethod($$$Class(tTable), "%BuildCustomIndices", pAutoPurge)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set tSC = ..SyncDictionaryMatchCustomizations(pDomainId, pPackageName, pAutoPurge, pStartSrcId, pEndSrcId)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod CreateClass(Output pClassDef As %Dictionary.ClassDefinition, pFQName As %String, pDataLocation As %String, pIndexLocation As %String, pOverWrite As %Boolean, pSuper As %String = "AbstractTable") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		
		if $$$defClassDefined(pFQName) {
			if pOverWrite {
				set tSC = $$Delete^%apiOBJ(pFQName, "-d")
				quit:$$$ISERR(tSC)
			} else {
				set pClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(pFQName,, .tSC)
				quit
			}
		}
		
		//set tShortName = $piece(pFQName,".",*)
		// BDB732 - avoid automatically setting GeneratedBy
		set:$d(%classname) tTemp = %classname, %classname = ""
		set pClassDef = ##class(%Dictionary.ClassDefinition).%New()
		set:$d(tTemp) %classname = tTemp
			
		set pClassDef.Name = pFQName
		set pClassDef.ProcedureBlock = 1
		set pClassDef.Super = "%Persistent"_$s(pSuper="":"", $f(pSuper,"."):","_pSuper, 1:",%iKnow.Tables."_pSuper)
		
		// mark as final so %%CLASSNAME is not required
		set pClassDef.Final = 1
		
		
		set tStorage = ##class(%Dictionary.StorageDefinition).%New()
		set tStorage.Name = "iKnowStorage"
		set tStorage.DataLocation = pDataLocation
		set tStorage.IndexLocation = pIndexLocation
		set tStorage.IdLocation = pDataLocation
		set tStorage.Type = "%Storage.Persistent"
		set tStorage.parent = pClassDef
		set pClassDef.StorageStrategy = "iKnowStorage"
		
		// add data definition for system-managed data
		set tSystemData = ##class(%Dictionary.StorageDataDefinition).%New()
		set tSystemData.Name = "iKnowSystemData"
		set tSystemData.parent = tStorage
		
		// add data definition for custom fields
		if (pSuper'="") {
			set tCustomData = ##class(%Dictionary.StorageDataDefinition).%New()
			set tCustomData.Name = "CustomData"
			set tCustomData.Subscript = """c"""
			set tCustomData.parent = tStorage
			set tStorage.DefaultData = "CustomData"
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod AddProperty(pClassDef As %Dictionary.ClassDefinition, pName As %String, pType As %String, ByRef pParams, pStoragePos As %Integer = 0, pReadOnly As %Boolean = 1, pCalculated As %Boolean = 0, pComputeCode As %String = "", pInternal As %Boolean = 0, pSqlFieldName As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		// skip if it already exists
		quit:##class(%Dictionary.PropertyDefinition).%ExistsId(pClassDef.Name_"||"_$piece(pName,":",1))
		
		set tPropDef = ##class(%Dictionary.PropertyDefinition).%New()
		set tPropDef.Name = $piece(pName,":",1)
		set:pSqlFieldName'="" tPropDef.SqlFieldName = pSqlFieldName
		if $find(pType,":") {
			set tPropDef.Collection = $piece(pType,":",1)
			set tPropDef.Type = $piece(pType,":",2)
		} else {
			set tPropDef.Type = pType
		}
		set tPropDef.ReadOnly = pReadOnly
		set tPropDef.Internal = pInternal
		set tPropDef.Calculated = pCalculated
		set tPropDef.SqlComputed = pCalculated
		set:pComputeCode'="" tPropDef.SqlComputeCode = pComputeCode
		set tPropDef.parent = pClassDef
		
		set tParam = ""
		for {
			set tParam = $order(pParams(tParam), 1, tParamValue)
			quit:tParam=""
			
			do tPropDef.Parameters.SetAt(tParamValue, tParam)
		}
		
		// add storage spec to system data def
		if pStoragePos > 0 {
			
			set tDataValue = ##class(%Dictionary.StorageDataValueDefinition).%New()
			set tDataValue.Name = pStoragePos
			set tDataValue.Value = pName
			set tDataValue.parent = pClassDef.Storages.GetAt(1).Data.GetAt(1)
			
		} elseif (pStoragePos = -1) { // IdKey!
		
			// first try to find existing index def to append to
			for i = 1:1:pClassDef.Indices.Count() {
				continue:'(pClassDef.Indices.GetAt(i).IdKey)
				set tIndexDef = pClassDef.Indices.GetAt(i)
				set tIndexDef.Name = "%"_$piece(pClassDef.Name,".",*)
				set tIndexDef.Properties = tIndexDef.Properties_","_pName
				quit
			}
			
			// if none found, create new IdKey
			if $g(tIndexDef)="" {
				set tIndexDef = ##class(%Dictionary.IndexDefinition).%New()
				set tIndexDef.Name = "%"_pName
				set tIndexDef.Properties = pName
				set tIndexDef.Unique = 1
				set tIndexDef.IdKey = 1
				set tIndexDef.PrimaryKey = 1
				set tIndexDef.parent = pClassDef
				set tIndexDef.Description = "This index is maintained automatically by iKnow. DO NOT MODIFY"
			}
			
		} elseif (pStoragePos = -2) { // whole value node
			
			set tDataDef = pClassDef.Storages.GetAt(1).Data.GetAt(1)
			set tDataDef.Attribute = pName
			set tDataDef.Structure = "node"
			
		}
			
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod AddParameter(pClassDef As %Dictionary.ClassDefinition, pName As %String, pValue As %String = "", pInternal As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		// skip if it already exists
		quit:##class(%Dictionary.ParameterDefinition).%ExistsId(pClassDef.Name_"||"_pName)
		
		set tParamDef = ##class(%Dictionary.ParameterDefinition).%New()
		set tParamDef.Name = pName
		set tParamDef.Default = pValue
		set tParamDef.Internal = pInternal
		set tParamDef.parent = pClassDef
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod AddIndex(pClassDef As %Dictionary.ClassDefinition, pName As %String, pProperties As %String = "", pUnique As %Boolean = 0, pType As %String = "", pGlobal As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		// skip if it already exists
		quit:##class(%Dictionary.IndexDefinition).%ExistsId(pClassDef.Name_"||"_pName)
		
		set tIndexDef = ##class(%Dictionary.IndexDefinition).%New()
		set tIndexDef.Name = pName
		set tIndexDef.Properties = pProperties
		set:pType["extent" tIndexDef.Extent = 1, pType = $replace(pType,"extent","")
		set tIndexDef.Type = pType
		set tIndexDef.Unique = ''pUnique
		set:pUnique=2 tIndexDef.PrimaryKey = 1, tIndexDef.IdKey = 1
		set tIndexDef.parent = pClassDef
		set:$e(pName)="%" tIndexDef.Description = "This index is maintained automatically by iKnow. DO NOT MODIFY"
		
		if (pGlobal'="") {
			set tStorageDef = ##class(%Dictionary.StorageIndexDefinition).%New()
			set tStorageDef.Name = pName
			set tStorageDef.Location = pGlobal
			set tStorageDef.parent = pClassDef.Storages.GetAt(1)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod AddFK(pClassDef As %Dictionary.ClassDefinition, pName As %String, pProperties As %String, pTarget As %String, pTargetKey As %String = "", pNoCheck As %Boolean = 1) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		// skip if it already exists
		quit:##class(%Dictionary.ForeignKeyDefinition).%ExistsId(pClassDef.Name_"||"_pName)

		set tFKDef = ##class(%Dictionary.ForeignKeyDefinition).%New()
		set tFKDef.Name = pName
		set tFKDef.Properties = pProperties
		set tFKDef.ReferencedClass = pTarget
		set tFKDef.ReferencedKey = pTargetKey
		set tFKDef.parent = pClassDef
		set tFKDef.NoCheck = pNoCheck
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod AddBVA(pClassDef As %Dictionary.ClassDefinition, pPropName As %String, pValueCode As %String = "", pAcceptZero As %Boolean = 1) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		// skip if it already exists
		quit:##class(%Dictionary.MethodDefinition).%ExistsId(pClassDef.Name_"||"_pPropName_"BuildValueArray")

		set tMethodDef = ##class(%Dictionary.MethodDefinition).%New()
		set tMethodDef.Name = pPropName_"BuildValueArray"
		set tMethodDef.FormalSpec = "pEntities:%List,*pArray:%String"
		set tMethodDef.ReturnType = "%Status"
		set tMethodDef.ClassMethod = 1
		set tMethodDef.parent = pClassDef
		
		do tMethodDef.Implementation.WriteLine("	set tSC = $$$OK")
		do tMethodDef.Implementation.WriteLine("	try {")
		do tMethodDef.Implementation.WriteLine("		kill pArray")
		do tMethodDef.Implementation.WriteLine("		set ptr = 0")
		do tMethodDef.Implementation.WriteLine("		while $listnext(pEntities,ptr,tElement) {")
		do:'pAcceptZero tMethodDef.Implementation.WriteLine("			continue:'tElement")
		do tMethodDef.Implementation.WriteLine("			set pArray(tElement) = "_$s(pValueCode="":"""""", 1:pValueCode))
		do tMethodDef.Implementation.WriteLine("		}")
		do tMethodDef.Implementation.WriteLine("	} catch (ex) {")
		do tMethodDef.Implementation.WriteLine("		set tSC = ex.AsStatus()")
		do tMethodDef.Implementation.WriteLine("	}")
		do tMethodDef.Implementation.WriteLine("	quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
