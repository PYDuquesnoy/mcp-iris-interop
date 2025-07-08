/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// iKnow utility methods, available through the $system syntax from the command line.
/// For example: "do $system.iKnow.ListDomains()"
Class %SYSTEM.iKnow Extends %SYSTEM.Help [ Abstract, Deprecated, System = 4 ]
{

/// Print a list of all the domains within this namespace.
ClassMethod ListDomains(currentNamespaceOnly As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		set tRS = ##class(%ResultSet).%New()
		set tRS.ClassName = "%iKnow.Domain", tRS.QueryName = "GetAllDomains"
		
		set tSC = tRS.Execute(currentNamespaceOnly)
		quit:$$$ISERR(tSC)
		
		set tCurrentNS = $namespace
		if (currentNamespaceOnly) {
			write !,"Domains for Namespace ",$namespace,":"
		}
		write !," Domain ID : Domain name                              : # of sources : version"
		write !," --------- : ---------------------------------------- : ------------ : -------"
		while tRS.Next() {
			set tDomainId = tRS.GetData(1), tDomainName = tRS.GetData(2), tPart=1
			set tNS = tRS.GetData(3)
			zn tNS
			set tSourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tDomainId)
			zn tCurrentNS
			
			write !,$justify(tDomainId,10)," : ",$e(tDomainName,1,40),$justify(" : ",43-$length(tDomainName)),$justify(tSourceCount,12)," : ",$justify(tRS.GetData(4),7)
			while ($length(tDomainName)>40) {
				set tDomainName = $e(tDomainName,41,*)
				write !,$justify("",13),$e(tDomainName,1,40)
			}
		}
		
		write !
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Print a list of all the configurations within this namespace.
ClassMethod ListConfigurations() As %Status
{
	set tSC = $$$OK
	try {
		set tRS = ##class(%ResultSet).%New()
		set tRS.ClassName = "%iKnow.Configuration", tRS.QueryName = "GetAllConfigurations"
		
		set tSC = tRS.Execute()
		quit:$$$ISERR(tSC)
		
		write !,"Configurations for Namespace ",$namespace,":"
		
		write !," ID  : Configuration name          : ALI : Languages           : UserDict "
		write !," --- : --------------------------- : --- : ------------------- : --------------"
		while tRS.Next() {
			
			set tConfigName = tRS.GetData(2)
			write !,$justify(tRS.GetData(1),4)," : ",$e(tConfigName,1,27),$justify(" : ",30-$length(tConfigName)),"  ",tRS.GetData(3)," : "
			write tRS.GetData(4),$justify(" : ",22-$l(tRS.GetData(4))),tRS.GetData(5)
			while ($length(tConfigName)>27) {
				set tConfigName = $e(tConfigName,28,*)
				write !,"       ",$e(tConfigName,1,27)
			}
		}
		
		write !
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Print a list of all metadata fields for a given namespace.
ClassMethod ListMetadata(pDomainName As %String, pIncludeHidden As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		set tDomainId = ..GetDomainId(pDomainName)
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, tDomainId, pIncludeHidden)
		quit:$$$ISERR(tSC)
		
		write !,"Metadata fields for domain '",pDomainName,"':"
		
		write !," ID : Field name          : Datatype : Operators              : Storage "
		write !,"----:---------------------:----------:------------------------:---------------"
		
		set i = ""
		for {
			set i = $order(tFields(i), 1, tFieldInfo)
			quit:i=""
			
			set tFieldId = $li(tFieldInfo,1)
			set tFieldName = $li(tFieldInfo,2)
			set tOperators = $lts($li(tFieldInfo,3))
			set tDatatype = $li(tFieldInfo,4)
			set tStorage = $case($li(tFieldInfo,5), $$$MDSTNORMAL:"normal", $$$MDSTBITMAP:"bitmap", $$$MDSTCOMPRESS:"compressed", $$$MDSTCOMPRESSBITMAP:"compressed bmp")
			write !,$justify(tFieldId,3)," : "
			write $e(tFieldName,1,18),$justify(" : ",22-$length(tFieldName))
			write tDatatype,$justify(" : ",11-$length(tDatatype))
			write tOperators,$justify(" : ",25-$length(tOperators))
			write tStorage
			
		}
		
		write !
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Prints the first <var>pLimit</var> load errors, failures and warnings for domain <var>pDomainName</var>. 
/// Use <var>pLimit</var>=0 to display all errors.
ClassMethod ListErrors(pDomainName As %String, pLimit As %Integer = 5) As %Status
{
	set tSC = $$$OK
	try {
		set tDomainId = ..GetDomainId(pDomainName)
		if 'tDomainId {
			set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)
			quit
		}
		
		write !,"Error report for domain '",pDomainName,"':"
		set tLoader = ##class(%iKnow.Source.Loader).%New(tDomainId)
		
		// errors first
		set tSC = tLoader.GetErrors(.tErrors, 1)
		quit:$$$ISERR(tSC)
		if $d(tErrors) {
			write !,"The following load errors occurred in this domain:"
			set i = "", tCount = 0
			for { 
				set i = $order(tErrors(i), 1, tData)
				quit:i=""
				quit:pLimit&&($i(tCount)>pLimit)
				write !,$zdt($lg(tData,3)),": ",$lg(tData,1)," (location: ",$lg(tData,2),")"
			}
		} else {
			write !,"No errors"
		}
		write !
		
		// failed sources
		set tSC = tLoader.GetFailed(.tErrors, 1)
		quit:$$$ISERR(tSC)
		if $d(tErrors) {
			write !,"The following sources failed to load in this domain:"
			set i = "", tCount = 0
			for { 
				set i = $order(tErrors(i), 1, tData)
				quit:i=""
				quit:pLimit&&($i(tCount)>pLimit)
				write !,$zdt($lg(tData,6)),": ",$lg(tData,4)," (external ID: ",$lg(tData,2),", location: ",$lg(tData,3),")"
			}
		} else {
			write !,"No failed sources"
		}
		write !
		
		
		// warnings
		set tSC = tLoader.GetWarnings(.tErrors, 1)
		quit:$$$ISERR(tSC)
		if $d(tErrors) {
			write !,"The following warnings were raised while loading sources:"
			set i = "", tCount = 0
			for { 
				set i = $order(tErrors(i), 1, tData)
				quit:i=""
				quit:pLimit&&($i(tCount)>pLimit)
				write !,$zdt($lg(tData,5)),": ",$lg(tData,4)," (external ID: ",$lg(tData,2),", location: ",$lg(tData,3),")"
			}
		} else {
			write !,"No warnings"
		}
		write !
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the ID corresponding to the supplied domain name in <var>pDomainName</var>
/// or "" if none found in this namespace.
ClassMethod GetDomainId(pDomainName As %String = "") As %Integer
{
	set tDomain = ##class(%iKnow.Domain).NameIndexOpen(pDomainName)
	quit:tDomain="" ""
	quit tDomain.Id
}

/// Returns the name corresponding to the supplied domain ID or "" if none found in this namespace.
ClassMethod GetDomainName(pDomainId As %Integer) As %String
{
	set tDomain = ##class(%iKnow.Domain).%OpenId(pDomainId)
	quit:tDomain="" ""
	quit tDomain.Name
}

/// Drops all of a Domain's contents
ClassMethod DropData(pDomainName As %String, pDropMetadataFields As %Boolean = 1, pDropDictionaries As %Boolean = 1) As %Integer
{
	set tSC = $$$OK
	try {
		set tDomain = ##class(%iKnow.Domain).Open(pDomainName, .tSC)
		quit:$$$ISERR(tSC)
		if tDomain="" { set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)  quit }
		
		set tSC = tDomain.DropData(pDropMetadataFields, pDropDictionaries)
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Indexes the supplied file and stores the indexing results in domain <var>pDomainName</var>, 
/// returning the generated source ID as <var>pSrcId</var>.
/// The full path of the files indexed will be used to build the External ID (cf
/// <class>%iKnow.Source.File.Lister</class>)
ClassMethod IndexFile(pDomainName As %String, pPath As %String, pConfig As %String = "", pEncoding As %String = "UTF-8", Output pSrcId As %Integer = 0) As %Status
{
	set tSC = $$$OK, pSrcId = ""
	try {
		if (pDomainName="") {
			set tDomainId = 0
		} else {
			set tDomainId = ..GetDomainId(pDomainName)
			if 'tDomainId { set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)  quit }
		}
		
		set tLoader = ##class(%iKnow.Source.Loader).%New(tDomainId)
		set tLister = ##class(%iKnow.Source.File.Lister).%New(tDomainId)
		
		set:(pConfig'="") tSC = tLister.SetConfig(pConfig)
		quit:$$$ISERR(tSC)
		
		set:(pEncoding'="") tSC = tLister.SetProcessor("%iKnow.Source.File.Processor", $lb(pEncoding))
		quit:$$$ISERR(tSC)
		
		set tSC = tLoader.SetLister(tLister)
		quit:$$$ISERR(tSC)
		
		set tSC = tLoader.ProcessList(pPath,,0)
		quit:$$$ISERR(tSC)
		
		set pSrcId = $lg(tLoader.GetSourceIds(),1)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Indexes the supplied file and stores the indexing results in domain <var>pDomainName</var>.
/// The full path of the files indexed will be used to build the External ID (cf
/// <class>%iKnow.Source.File.Lister</class>)
ClassMethod IndexDirectory(pDomainName As %String, pPath As %String, pRecurse As %Boolean = 0, pConfig As %String = "", pEncoding As %String = "UTF-8", pExtensions As %List = "") As %Status
{
	set tSC = $$$OK
	try {
		if (pDomainName="") {
			set tDomainId = 0
		} else {
			set tDomainId = ..GetDomainId(pDomainName)
			if 'tDomainId { set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)  quit }
		}
		
		set tLoader = ##class(%iKnow.Source.Loader).%New(tDomainId)
		
		set tLister = ##class(%iKnow.Source.File.Lister).%New(tDomainId)
		set:(pConfig'="") tSC = tLister.SetConfig(pConfig)
		quit:$$$ISERR(tSC)
		
		set:(pEncoding'="") tSC = tLister.SetProcessor("%iKnow.Source.File.Processor", $lb(pEncoding))
		quit:$$$ISERR(tSC)
		
		set tSC = tLister.AddListToBatch(pPath, pExtensions, pRecurse)
		quit:$$$ISERR(tSC)
		
		set tSC = tLoader.ProcessBatch()
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Indexes the contents of the <var>pDataField</var> column in table <var>pTableName</var>,
/// using the <var>pIdField</var> and <var>pGroupField</var> columns to build the external
/// ID for this record (cf <class>%iKnow.Source.SQL.Lister</class>).
/// <var>pDomainName</var> can be a (SQL) constant, such as "'MyGroup'".
/// The results are stored in the domain <var>pDomainName</var>.</p>
/// <p>Optionally, specify a <class>%List</class> of table field names through
/// <var>pMetaFields</var> that should be loaded as metadata for the table records.</p>
ClassMethod IndexTable(pDomainName As %String, pTableName As %String, pIdField As %String, pGroupField As %String, pDataField As %String, pMetaFields As %List = "", pWhereClause As %String = "", pConfig As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		if (pDomainName="") {
			set tDomainId = 0
		} else {
			set tDomainId = ..GetDomainId(pDomainName)
			if 'tDomainId { set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)  quit }
		}
		
		if '$system.SQL.TableExists(pTableName) { set tSC = $$$ERROR($$$TableDoesNotExist, pTableName)  quit }
		
		// first ensure metadata fields are all there
		set tRS = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		set tSC = tRS.Prepare("select p.type from %dictionary.compiledproperty p, %dictionary.compiledclass c where p.parent = c.name and UPPER(c.sqlschemaname || '.' || c.sqltablename) = UPPER('"_pTableName_"') and p.sqlfieldname = ?")
		for i = 1:1:$listlength(pMetaFields) {
			set tField = $li(pMetaFields,i)
			set tFieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(tDomainId, tField)
			if (tFieldId<=0) {
				set tSC = tRS.Execute(tField)
				quit:$$$ISERR(tSC)
				if ('tRS.Next()) {
					set tSC = $$$ERROR($$$GeneralError, "Field """_tField_""" not found in table")
				}
				set tType = tRS.GetData(1)
				if $lf($lb("%Library.Numeric","%Library.Integer","%Library.Double"),tType) {
					set tType = $$$MDDTNUMBER
				} else {
					set tType = $$$MDDTSTRING
				}
				set tFieldId = ##class(%iKnow.Queries.MetadataAPI).AddField(tDomainId, tField,, tType,,,,,, .tSC)
				quit:$$$ISERR(tSC)
			}
		}
		quit:$$$ISERR(tSC)
		
		// groupfield cannot have an alias
		set tAliasPos = $find($$$UPPER(pGroupField), " AS ")
		set:tAliasPos pGroupField = $e(pGroupField,1,tAliasPos-5)
		
		// build query
		set tQuery = "SELECT "_pIdField_", "_pGroupField_" As __GroupField, "_pDataField
		set:$listlength(pMetaFields) tQuery = tQuery _ ", " _ $lts(pMetaFields)
		set tQuery = tQuery _ " FROM " _ pTableName
		set:pWhereClause'="" tQuery = tQuery _ " WHERE " _ pWhereClause
		
		// fix aliased columns
		set tAliasPos = $find($$$UPPER(pIdField), " AS ")
		set:tAliasPos pIdField = $e(pIdField, tAliasPos, *)
		set tAliasPos = $find($$$UPPER(pDataField), " AS ")
		set:tAliasPos pDataField = $e(pDataField, tAliasPos, *)
		
		// load data
		set tLoader = ##class(%iKnow.Source.Loader).%New(tDomainId)
		
		set tLister = ##class(%iKnow.Source.SQL.Lister).%New(tDomainId)
		set:(pConfig'="") tSC = tLister.SetConfig(pConfig)
		quit:$$$ISERR(tSC)
		
		set tSC = tLister.AddListToBatch(tQuery, pIdField, "__GroupField", pDataField, pMetaFields)
		quit:$$$ISERR(tSC)
		
		set tSC = tLoader.ProcessBatch()
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Indexes the supplied <var>pString</var> and stores the results into the domain
/// <var>pDomainName</var>, using <var>pIdentifier</var> to construct the External ID
/// (cf <class>%iKnow.Source.Temp.Lister</class>). The generated sources ID will be returned
/// through <var>pSrcId</var>.
ClassMethod IndexString(pDomainName As %String, pIdentifier As %String, pString As %String, pConfig As %String = "", pVirtual As %Boolean = 0, Output pSrcId As %Integer = 0) As %Status
{
	set tSC = $$$OK, pSrcId = ""
	try {
		if (pDomainName="") {
			set tDomainId = 0, pVirtual = 1
		} else {
			set tDomainId = ..GetDomainId(pDomainName)
			if 'tDomainId { set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)  quit }
		}
		
		// load data
		set tLoader = ##class(%iKnow.Source.Loader).%New(tDomainId)
		set tSC = tLoader.BufferSource(pIdentifier, pString)
		quit:$$$ISERR(tSC)
		
		if (pVirtual) {
			set tSC = tLoader.ProcessVirtualBuffer(pConfig)
		} else {
			set tSC = tLoader.ProcessBuffer(pConfig)
		}
		quit:$$$ISERR(tSC)
		
		set pSrcId = $li(tLoader.GetSourceIds(),1)
		set:pVirtual pSrcId = -$zabs(pSrcId)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the Source ID for a given <var>pExternalId</var> in domain <var>pDomainName</var>,
/// or the empty string if no source exists with that External ID.
ClassMethod GetSourceId(pDomainName As %String, pExternalId As %String) As %Integer
{
	set tDomainId = ..GetDomainId(pDomainName)
	quit:'tDomainId ""
	quit ##class(%iKnow.Queries.SourceAPI).GetSourceId(tDomainId, pExternalId)
}

/// Returns the External ID for a given <var>pSourceId</var> in domain <var>pDomainName</var>,
/// or the empty string if no source exists with that Source ID.
ClassMethod GetExternalId(pDomainName As %String, pSourceId As %Integer) As %String
{
	set tDomainId = ..GetDomainId(pDomainName)
	quit:'tDomainId ""
	quit ##class(%iKnow.Queries.SourceAPI).GetExternalId(tDomainId, pSourceId)
}

/// Returns true if the iKnow kernel resource is current held, false otherwise
ClassMethod IsResourceAcquired() As %Boolean [ Internal ]
{
 Quit $SYSTEM.iKnow.IsResourceAcquired()
}

/// <p>Creates an iKnow domain named <var>pDomainName</var> representing the textual contents
/// of column <var>pColumnName</var> in table <var>pTableName</var>, returning the domain
/// ID in <var>pDomainId</var>. If <var>pDomainName</var> is left blank, a default name
/// will be generated as follows: "SQL@<var>pTableName</var>@<var>pColumnName</var>"</p>
/// <p>If <var>pObjectsPackage</var> is non-null, wrapper objects for the generated
/// elements will be generated in that package.</p>
/// <p>This method is deprecated. See <method>CreateDomainTables</method></p>
ClassMethod CreateDomainForTableColumn(pTableName As %String, pColumnName As %String, ByRef pDomainName As %String = "", Output pDomainId As %Integer, pObjectsPackage As %String = "", pDropExisting As %Boolean = 1, ByRef pDomainParams = "", pIdColumn As %String = "ID") As %Status [ Deprecated, Internal ]
{
	set tSC = $$$OK
	try {
		if (pDomainName="") {
			set pDomainName = "SQL@"_pTableName_"@"_pColumnName
		}
		
		// check if the domain exists
		if (##class(%iKnow.Domain).Exists(pDomainName)) {
			if (pDropExisting) {
				set tSC = ##class(%iKnow.Domain).Delete(pDomainName)
			} else {
				set tSC = $$$ERROR($$$IKDomainExists, pDomainName)
			}
			quit:$$$ISERR(tSC)
		}
		
		// create the domain
		set tDomain = ##class(%iKnow.Domain).Create(pDomainName,, .tSC)
		quit:$$$ISERR(tSC)
		set pDomainId = tDomain.Id
		
		// apply any parameters passed in by the user
		set tParam = ""
		for {
			set tParam = $order(pDomainParams(tParam),1,tValue)
			quit:tParam=""
			set tSC = tDomain.SetParameter(tParam,tValue)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// ensure $$$IKPSIMPLEEXTIDS mode so we have the SQL row's %ID = iKNow External ID
		set tSC = tDomain.SetParameter($$$IKPSIMPLEEXTIDS,1)
		quit:$$$ISERR(tSC)
		
		// index column contents
		set tSC = ..IndexTable(pDomainName, pTableName, pIdColumn, "'none'", pColumnName,, pColumnName_" IS NOT NULL")
		quit:$$$ISERR(tSC)
		
		// create wrapper objects
		if (pObjectsPackage'="") {
			set tSC = ##class(%iKnow.Objects.Utils).GenerateAllObjectsForDomain(pDomainId, pObjectsPackage, 1, 0, 0, 0, 0)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the name of the domain parameter whose macro name was passed in.
/// For example, translates $$$IKPDEFAULTCONFIG into "DefaultConfig"
ClassMethod GetDomainParameterName(pMacroName As %String) As %String [ Internal ]
{
	set tSC = $$$OK, tParamName = ""
	try {
		set:$e(pMacroName,1,3)="$$$" pMacroName = $e(pMacroName,4,*)
		quit:$e(pMacroName,1,3)'="IKP"
		set tLookFor = "#DEFINE "_$$$UPPER(pMacroName)_" ", tLength = $length(tLookFor)
		
		for tFile = "%IKPublic", "%IKInclude" {
			set tLineNb=0
			for {
				set tLineNb = $order(^rINC(tFile,0,tLineNb),1,tLine)
				quit:tLineNb=""
				
				if ($e($$$UPPER(tLine),1,tLength)=tLookFor) {
					set tParamName = $piece(tLine,"""",2)
					quit
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tParamName
}

/// For an iTables domain creates UMLS mapping between domain entities, sources and UMLS concepts.
ClassMethod mapToUMLS(domainId As %Integer, sourceMatchLevel As %Integer = 0, buildTfIdfTable As %Boolean = 1) As %Status [ Deprecated, Internal ]
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = ##class(%DeepSee.DomainExpert.utils.UMLSUtils).buildMapping(domainId,"/thoroughness="_sourceMatchLevel)
		Quit:$$$ISERR(sc)

	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

/// <p>Creates an iKnow domain containing the data in the <var>pColumnName</var> column of table
/// <var>pTableName</var> through a domain definition (<class>%iKnow.DomainDefinition</class>)
/// named "Domain" in the same package as <var>pTableName</var>. In addition, customizable table projections
/// for accessing the iKnow domain data through SQL will be generated by invoking <class>%iKnow.Tables.Utils</class>.
/// If an existing domain ID is supplied through <var>pDomainId</var>, no domain definition is
/// generated and only the projection classes will be generated.</p>
/// <p>Depending on the value of <var>createITablesIndices</var>, a number of additional index
/// structures and properties will be created to complement the system-supplied ones on the table
/// projections.</p>
ClassMethod CreateDomainTables(pTableName As %String, pColumnName As %String, ByRef pDomainName As %String = "", ByRef pDomainId As %Integer = "", pIdColumn As %String = "ID", lang As %String = "", silent As %Boolean = 0, turnOffJournal As %Boolean = 1, noindex As %Boolean = 1, createWordContextTable As %List = "", createITablesIndices As %Boolean = 1) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if (pTableName="") && createITablesIndices {
			set tSC = $$$ERROR("iTables indices require a reference table")
			quit
		}
		if (pTableName'="") && '$system.SQL.TableExists(pTableName, .tMetadata) {
			set tSC = $$$ERROR($$$TableDoesNotExist, pTableName)
			quit
		}
		set tRefClass = $lg($g(tMetadata),3)
		set tGlobalPrefix = ""
		
		
		// for an existing domamin
		if $g(pDomainId) {
			set tDomain = ##class(%iKnow.Domain).%OpenId(pDomainId)
			if (tDomain="") {
				set tSC = $$$ERROR($$$IKNoDomainWithId, pDomainId)
				quit
			} elseif (pDomainName'="") && (pDomainName'=tDomain.Name) {
				set tSC = $$$ERROR($$$GeneralError,"Domain Name for id "_pDomainId_" is "_tDomain.Name_", not "_pDomainName)
				quit
			}
			set pDomainName = tDomain.Name
			
			set tPackageName = $replace(pDomainName," ",".")_".tables"
			if '$zname(tPackageName_".Source",4) {
				set tSC = $$$ERROR($$$GeneralError, "Domain name '"_pDomainName_"' cannot be translated into a valid package name")
				quit
			}
			
			if tDomain.GetParameter($$$IKPDISABLEJOURNALLING)'=turnOffJournal {
				set tSC = $$$ERROR($$$GeneralError, "Cannot override journalling behavior for an existing domain")
				quit
			}
		
			// additional iTables indices & props
			if (createITablesIndices) {
				set tSC = ##class(%iKnow.Tables.ITablesDomainDefinition).%GetCustomizations(.tCustomize)
				quit:$$$ISERR(tSC)
			}
		
			set tSC = ##class(%iKnow.Tables.Utils).CreateDomainTables(pDomainId, tPackageName, tRefClass,, .tCustomize,, 1)
			quit
		}
		
		
		// if no domain ID specified, create a new domain definition
		set tPackageName = $replace(pDomainName," ",".")
		if '$zname(tPackageName_".Source",4) {
			set tSC = $$$ERROR($$$GeneralError, "Domain name '"_pDomainName_"' cannot be translated into a valid package name")
			quit
		}
		set tDomainDef = ##class(%iKnow.Model.domain).%New()
		set tDomainDef.name = pDomainName
		set tDomainDef.objectsPackage = tPackageName_".tables"
		if (lang'="en") && (lang'="") {
			set tConfigDef = ##class(%iKnow.Model.configuration).%New()
			set tConfigDef.languages = lang
			set tConfigDef.domain = tDomainDef
			set tConfigDef.name = pDomainName_"Config"
			
			set tParam = ##class(%iKnow.Model.parameter).%New()
			set tParam.name = $$$IKPDEFAULTCONFIG
			set tParam.value = tConfigDef.name
			set tParam.parent = tDomainDef
		}
			
		set tParam = ##class(%iKnow.Model.parameter).%New()
		set tParam.name = $$$IKPDISABLEJOURNALLING
		set tParam.value = turnOffJournal
		set tParam.parent = tDomainDef
		
		set tDomainDef.data = ##class(%iKnow.Model.data).%New()
		set tListDef = ##class(%iKnow.Model.listTable).%New()
		set tListDef.tableName = pTableName
		set tListDef.idField = pIdColumn
		set tListDef.groupField = pIdColumn
		set tListDef.dataFields = pColumnName
		set tListDef.data = tDomainDef.data
		
		set tDomainDefClass = tPackageName_".Domain"
		set tSC = tDomainDef.%SaveToClass(tDomainDefClass, 1, 'silent, 0, $s(createITablesIndices:"%iKnow.Tables.ITablesDomainDefinition", 1:"%iKnow.DomainDefinition"))
		quit:$$$ISERR(tSC)
		
		// override %GetCustomizations() method to ensure metadata fields are indexed
		if (createWordContextTable'="") {
			set:'$lv(createWordContextTable) createWordContextTable = $lfs(createWordContextTable)
			set tMethodDef = ##class(%Dictionary.MethodDefinition).%New()
			set tMethodDef.parent = ##class(%Dictionary.ClassDefinition).%OpenId(tDomainDefClass)
			set tMethodDef.Name = "%GetCustomizations"
			set tMethodDef.ClassMethod = 1
			set tMethodDef.FormalSpec = "*pCustomizations,*pMetadata:%List"
			set tMethodDef.ReturnType = "%Status"
			do tMethodDef.Implementation.WriteLine("	set tSC = ##super(.pCustomizations, .pMetadata)")
			do tMethodDef.Implementation.WriteLine("	quit:$$$ISERR(tSC) tSC")
			
			// default iTables parameters
			do tMethodDef.Implementation.WriteLine("	set pCustomizations(""Source"", ""param"", ""RefTable"") = $lb("""_pTableName_""")")
			do tMethodDef.Implementation.WriteLine("	set pCustomizations(""Source"", ""param"", ""RefIdColumn"") = $lb("""_pIdColumn_""")")
			
			// customizations for word-context table
			set ptr=0
			while $listnext(createWordContextTable,ptr,tFieldDef) {
				//do tMethodDef.Implementation.WriteLine("	set pMetadata = pMetadata _ $lb("""_tFieldDef_""")")
				set tFieldName = $piece(tFieldDef,"->",*)
				//do tMethodDef.Implementation.WriteLine("	set pCustomizations(""Source"", ""prop"", """_tFieldName_""") = $lb(, 1, ""new o set o = ##class("_tPackageName_".Source).%OpenId({SourceId}), {*} = $s($isobject(o):o."_tFieldName_", 1:"""""""")"")")
				do tMethodDef.Implementation.WriteLine("	set pCustomizations(""Source"", ""idx"", """_tFieldName_"Idx"") = $lb(""Ref->"_tFieldName_""")")
				//do tMethodDef.Implementation.WriteLine("	set pCustomizations(""Part"", ""prop"", """_tFieldName_""") = $lb(, 1, ""new o set o = ##class("_tPackageName_".Source).%OpenId({SourceId}), {*} = $s($isobject(o):o."_tFieldName_", 1:"""""""")"")")
				do tMethodDef.Implementation.WriteLine("	set pCustomizations(""Part"", ""idx"", """_tFieldName_"Idx"") = $lb(""Source->"_tFieldName_"IdxIDXValue"")")
			}
			do tMethodDef.Implementation.WriteLine("	quit $$$OK")
			set tSC = tMethodDef.%Save()
			quit:$$$ISERR(tSC)
		}
		
		set tSC = $system.OBJ.Compile(tDomainDefClass, "c"_$s(silent:"-d", 1:"d"))
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if $$$ISERR(tSC) && ($g(tDomainDefClass)'="") && $$$defClassDefined(tDomainDefClass) {
		set tSC2 = $$Delete^%apiOBJ(tDomainDefClass, "-d")
		quit tSC
	}
	
	quit:noindex tSC
	
	// now build if required
	try {
		set pDomainId = $classmethod(tDomainDefClass, "%GetDomainId")
		set tSC = $classmethod(tDomainDefClass, "%Build", 'silent)
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit:$$$ISERR(tSC) tSC
	
	// now recycle generation of word-context table:
	try {
		if (createWordContextTable '= "") {
			w:'silent !,"Generating Entity-Context Table", !
			if ($lv(createWordContextTable)) {
				set tParams = "/fields="_$lts(createWordContextTable)
			} else {
				set tParams = ""
			}
			if ('silent) {
				w "Running:", !
				w "d ##class(%DeepSee.DomainExpert.utils.MetadataBuilder).buildIt("_pDomainId_",""entity"","""_tParams_""")", !
			}
			set tSC = ##class(%DeepSee.DomainExpert.utils.MetadataBuilder).buildIt(pDomainId, "entity", tParams)
			if ($$$ISERR(tSC)) {
				if ('silent) {
					d $system.OBJ.DisplayError(tSC)
					w !, "Generating Entity-Context Table has Failed. "
					w "Please rerun: ", !
					w "d ##class(%DeepSee.DomainExpert.utils.MetadataBuilder).buildIt("_pDomainId_",""entity"","""_tParams_""")", !
					set tSC = $$$OK
				}
			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

/// Run the iKnow shell. See also <class>%iKnow.Shell</class>.
ClassMethod Shell()
{
	set shell=##class(%iKnow.Shell).%New()
	do shell.Run()
	set shell=""
}

/// Highlights the supplied text <var>pText</var> using the highlight information specified through
/// <var>pHighlight</var>. See <method>GetHighlighted</method> in <class>%iKnow.Queries.SentenceAPI</class> 
/// for more details on possible input to <var>pHighlight</var>.
ClassMethod Highlight(pText As %String, ByRef pHighlight, pConfig As %String = {$$$DEFAULTCONFIG}, pEscapeHTML As %Boolean = 1, Output pSC As %Status = {$$$OK}) As %String
{
	set pSC = $$$OK, tHighlighted="", vSrcId=0
	try {
		set pSC = ..IndexString("", "highlight", pText, pConfig, 1, .vSrcId)
		quit:$$$ISERR(pSC)
		
		set tSentCount = ##class(%iKnow.Queries.SentenceAPI).GetCountBySource(0, vSrcId, .pSC)
		quit:$$$ISERR(pSC)
		
		for i = 1:1:tSentCount {
			set:i>1 tHighlighted = tHighlighted_" "
			
			set tHighlighted = tHighlighted _ ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(0, i, .pHighlight, vSrcId,, .pSC, pEscapeHTML)
			quit:$$$ISERR(pSC)
		}
		
		set pSC = ##class(%iKnow.Source.Loader).DeleteVirtualSource(0, vSrcId), vSrcId=0
		quit:$$$ISERR(pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	
	// make sure we try to get rid of the virtual source if an error occurred, but don't
	// overwrite the original error
	if (vSrcId) {
		try {
			do ##class(%iKnow.Source.Loader).DeleteVirtualSource(0, vSrcId)
		} catch (ex) {}
	}
	
	quit tHighlighted
}

/// Deletes the source with internal ID <var>pSrcId</var> from domain <var>pDomainName</var>
ClassMethod DeleteSource(pDomainName As %String, pSrcId As %Integer) As %Status
{
	set tDomainId = $case(pDomainName, "":0, :..GetDomainId(pDomainName))
	if (pSrcId>0) {
		quit ##class(%iKnow.Source.Loader).DeleteSource(tDomainId, pSrcId)
	} else {
		quit ##class(%iKnow.Source.Loader).DeleteVirtualSource(tDomainId, $zabs(pSrcId))
	}
}

/// Deletes the virtual source with ID <var>vSrcId</var> from domain <var>pDomainName</var>
ClassMethod DeleteVirtualSource(pDomainName As %String, vSrcId As %Integer) As %Status
{
	set tDomainId = $case(pDomainName, "":0, :..GetDomainId(pDomainName))
	quit ##class(%iKnow.Source.Loader).DeleteVirtualSource(tDomainId, $zabs(vSrcId))
}

/// <p>Applies relevant iKnow normalization logic. By default, this implies removing whitespace
/// from the front and back of the string, removing duplicate whitespace, and lowercase. 
/// For specific configurations or languages such as Japanese, normalization behaviour is more
/// refined and described in the documentation.</p>
/// <p>If a domain ID is specified through <var>pDomainId</var>, its default configuration will
/// be used (if specified). Otherwise, the configuration named <var>pConfig</var> will be used.</p>
ClassMethod Normalize(pString As %String, pDomainId As %Integer = "", pConfig As %String = "", pLanguage As %String = "", Output pSC As %Status = {$$$OK}, pCleanPunctuation As %Boolean = 1) As %String
{
	set pSC = $$$OK, tNormalized = ""
	try {
		set tNormalized = $zstrip(pString,"<>=W")
		
		// sole optimization: if all characters are simple alfa characters and spaces,
		// we can just lowercase and exit
		if $match(tNormalized,"[ a-zA-Z]+") {
			set tNormalized = $zconvert(tNormalized,"L")
			quit
		}
		
		// retrieve domain-specific configuration, if any
		if ($g(pDomainId)'="") {
			set pConfig = $$$GETPARAM(pDomainId,$$$IKPDEFAULTCONFIG,pConfig)
		}
		
		// use params if nothing specified
		if ($g(pConfig)="") {
			
			set tNormalized = ##class(%iKnow.Configuration).NormalizeWithParams(tNormalized, $case(pLanguage, "":"en", :pLanguage),, .pSC, pCleanPunctuation)
			quit
			
		} else {
		
			// retrieve configuration object
			set tConfigObj = ##class(%iKnow.Configuration).NameIndexOpen(pConfig,, .pSC)
			quit:tConfigObj=""
			
			// normalize
			set tNormalized = tConfigObj.Normalize(tNormalized, pLanguage, .pSC, pCleanPunctuation)
			quit
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tNormalized
}

}
