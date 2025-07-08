/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

Class %DeepSee.SQL.CatalogQueries [ Owner = {_PUBLIC}, System = 4 ]
{

/// Retrieves a list of all cubes accessible through SQL, along with relevant metadata,
/// including whether the cube has any features not supported through direct SQL access.
/// These cubes can be excluded from the result through the <var>pIncludeUnsupported</var>
/// parameter, which defaults to "warning", meaning only cubes that will definitely
/// not work are excluded from the result.
Query GetCubes(pIncludeUnsupported As %String(VALUELIST=",none,warning,error") = "none") As %Query(ROWSPEC = "ClassName:%String,CubeName:%String,DisplayName:%String,Type:%String,PackageName:%String,UnsupportedFeatures:%String") [ SqlName = GetCubes ]
{
}

ClassMethod GetCubesExecute(ByRef qHandle As %Binary, pIncludeUnsupported As %String(VALUELIST=",none,warning,error") = "warning") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill qHandle
		
		set tSC = ##class(%DeepSee.Utils).%GetCubeList(.tList,,1)
		quit:$$$ISERR(tSC)
		
		set i="", qHandle=0
		for {
			set i = $order(tList(i),1,tCubeData)
			quit:i=""
			
			set tCubeName = $lg(tCubeData,1), 
				tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeName)
			
			// check if versioned
			/*if 'pIncludeVersions {
				continue:##class(%DeepSee.CubeVersion.Utils).%IsVersion(tCubeName)
			}*/
			
			// retrieve main package
			set tFactTable = ##class(%DeepSee.Utils).%GetCubeFactTable(tCubeName)
			
			set tUnsupportedLevel = ""
			if ..HasUnsupportedFeatures(tCubeName, .tUnsupportedFeatures) {
				continue:pIncludeUnsupported="none"
				set tUnsupportedLevel = $lg($g(tUnsupportedFeatures(1)),1)
				for j = 2:1:tUnsupportedFeatures {
					set tUnsupportedLevel = $lg(tUnsupportedFeatures(j),1)
					quit:tUnsupportedLevel="error" // can't get any worse!
				}
				if pIncludeUnsupported="warning" {
					continue:tUnsupportedLevel="error"
				}
			}
			
			set qHandle($i(qHandle)) = $lb(tCubeClass, tCubeName, $lg(tCubeData,2), $lg(tCubeData,4), $piece(tFactTable,".",1), tUnsupportedLevel)
		}
		
		// init counter
		set qHandle=0
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetCubesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetCubesExecute ]
{
	quit ..Close(.qHandle)
}

ClassMethod GetCubesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetCubesExecute ]
{
	quit ..Fetch(.qHandle, .Row, .AtEnd)
}

/// Checks if a cube or subject area uses features that are not supported by default
/// through the SQL projections. For example, the presence of an %OnGetFilterSpec()
/// method on the cube class may indicate certain runtime code is expected that cannot
/// be guaranteed to run by direct SQL access.
ClassMethod HasUnsupportedFeatures(pCubeName As %String, Output pUnsupportedFeatures, Output pSC As %Status = {$$$OK}) As %Boolean [ SqlName = HasUnsupportedFeatures, SqlProc ]
{
	set pSC = $$$OK
	try {
		kill pUnsupportedFeatures
		set pUnsupportedFeatures = 0
		
		set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(pCubeName)
		
		// check for compound cubes
		if ##class(%DeepSee.Utils).%IsCubeCompound(pCubeName) {
			set pUnsupportedFeatures($i(pUnsupportedFeatures)) = $lb("error", "Compound cubes are not supported")
		}
		
		// check subject areas
		if '##class(%DeepSee.Utils).%IsBaseCube(pCubeName) {
			
			set pUnsupportedFeatures($i(pUnsupportedFeatures)) = $lb("warning", "Subject Areas are not supported.")
			
			#dim tSAModel as %DeepSee.Model.SubjectArea.subjectArea
			set tSAModel = ##class(%DeepSee.Utils).%GetSubjectAreaModel(pCubeName)
			if tSAModel.filterSpec'="" {
				set pUnsupportedFeatures($i(pUnsupportedFeatures)) = $lb("warning", "Subject Area has a filter spec")
			}
		}
		
		if ##class(%Dictionary.MethodDefinition).%OpenId(tCubeClass_"||%OnGetFilterSpec") {
			set pUnsupportedFeatures($i(pUnsupportedFeatures)) = $lb("warning","Cube class has an %OnGetFilterSpec() method")
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit ''pUnsupportedFeatures
}

Query GetUnsupportedFeatures(pCubeName As %String) As %Query(ROWSPEC = "Severity:%String,Message:%String") [ SqlName = GetUnsupportedFeatures ]
{
}

ClassMethod GetUnsupportedFeaturesExecute(ByRef qHandle As %Binary, pCubeName As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill qHandle
		
		do ..HasUnsupportedFeatures(pCubeName, .qHandle, .tSC)
		
		// init counter
		set qHandle=0
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetUnsupportedFeaturesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetUnsupportedFeaturesExecute ]
{
	quit ..Close(.qHandle)
}

ClassMethod GetUnsupportedFeaturesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetUnsupportedFeaturesExecute ]
{
	quit ..Fetch(.qHandle, .Row, .AtEnd)
}

Query GetDimensionTables(pCubeName As %String) As %Query(ROWSPEC = "TableName:%String,DisplayName:%String") [ SqlName = GetDimensionTables ]
{
}

ClassMethod GetDimensionTablesExecute(ByRef qHandle As %Binary, pCubeName As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill qHandle
		set tFactTable = ##class(%DeepSee.Utils).%GetCubeFactTable(pCubeName)
		set tPackageName = $piece(tFactTable,".",1)_"."
		set qHandle($i(qHandle)) = $lb(tFactTable, "Fact: "_##class(%DeepSee.Utils).%GetCubeCaption(pCubeName))
		
		kill tMetadata
		merge tMetadata = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCubeName))
		
		set tClassName = ""
		for {
			set tClassName = $order(tMetadata("star",tClassName))
			quit:tClassName=""
			
			set tTableName = ##class(%DeepSee.Utils).%GetSQLTableName(tClassName)
			
			// skip fodder
			continue:'$find(tTableName,tPackageName)
			
			// TODO: what if there are multiple primaries?
			set tPrimary = $piece(tMetadata("star",tClassName,"primary"),",",*)
			set tPrimaryFact = tMetadata("star",tClassName,"prop",tPrimary,"fact")
			
			kill tFactInfo
			merge tFactInfo = tMetadata("fact", "prop",tPrimaryFact)
			if '$d(tFactInfo) {
				set qHandle($i(qHandle)) = $lb(tTableName,"NO FACT METADATA: "_tPrimary)
				continue
			}
			do ##class(%DeepSee.Utils).%GetDimensionCaption(pCubeName, tFactInfo("dimNo"), tFactInfo("hierNo"), tFactInfo("levelNo"),.tCaption)
			
			set qHandle($i(qHandle)) = $lb(tTableName, "Dimension: "_tCaption)
		}
		
		// init counter
		set qHandle=0
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetDimensionTablesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetDimensionTablesExecute ]
{
	quit ..Close(.qHandle)
}

ClassMethod GetDimensionTablesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetDimensionTablesExecute ]
{
	quit ..Fetch(.qHandle, .Row, .AtEnd)
}

/// Retrieves a list of measures, dimensions, and relationships in a cube's fact table which are accessible through SQL.
Query GetDimensionColumns(pTableName As %String) As %Query(ROWSPEC = "ColumnName:%String,DisplayName:%String,Usage:%String,References:%String") [ SqlName = GetDimensionColumns ]
{
}

ClassMethod GetDimensionColumnsExecute(ByRef qHandle As %Binary, pTableName As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill qHandle
		set qHandle($i(qHandle)) = $lb("ID","ID","ID","")
		quit:'##class(%SYSTEM.SQL.Schema).TableExists(pTableName,.tTableMetadata)
		set tClassName = $lg(tTableMetadata,3)
		set tCubeName = $parameter(tClassName, "CUBENAME")
		set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCubeName)
		
		merge tMetadata = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName))
		
		// keep track of names in use as connector cannot handle duplicate (display) names
		kill tNameIndex
		
		if $piece(tClassName,".",*)="Fact" { // fact table
		
			set tColName = ""
			for {
				set tColName = $order(tMetadata("fact","prop",tColName))
				quit:tColName=""
				
				kill tFactInfo
				merge tFactInfo = tMetadata("fact","prop",tColName)

				// DP-429698 - Check for an alias for common use across all column types
				set tColumnAlias = $s(($g(tFactInfo("alias"))'=""):$g(tFactInfo("alias")),1:tColName)

				if $g(tFactInfo("mbrtype"))="m" {
					
					// DP-422208 - iKnow Measures have no corresponding column in the fact table, so skip
					continue:$p($g(tFactInfo("index")),":",1)="iKnow"

					// DP-418267 - Account for the user-defined SQL alias if it exists
         			do AddColumn(tColumnAlias,tFactInfo("msrname"),"measure","")
					
				} elseif ($g(tFactInfo("mbrtype"))="d") {
					
					if $g(tFactInfo("isTime")) {
						if $g(tFactInfo("functionClass"))="%DeepSee.Time.Year" {
							
							// skip pre-DTB840 case when dim coordinates unavailable
							continue:'$g(tFactInfo("dimNo")) 
							
							do ##class(%DeepSee.Utils).%GetDimensionCaption(tCubeName, tFactInfo("dimNo"), tFactInfo("hierNo"), tFactInfo("levelNo"),.tCaption)
							do AddColumn(tColumnAlias, tCaption, "year",)
							continue
							
						} else {
							// skip other time dim functions as the values make no sense to clients
							continue
						}
					}
					
					// for dimensions, just stick to the column name (or alias)
					do ##class(%DeepSee.Utils).%GetDimensionCaption(tCubeName, tFactInfo("dimNo"), tFactInfo("hierNo"), tFactInfo("levelNo"),.tCaption)
					do AddColumn(tColumnAlias,tCaption_" ID","rollup",tFactInfo("type"))
					
				} elseif ($g(tFactInfo("type"))="%DeepSee.Datatype.dateTime") {
					do ##class(%DeepSee.Utils).%GetDimensionCaption(tCubeName, tFactInfo("dimNo"), tFactInfo("hierNo"), tFactInfo("levelNo"),.tCaption)
					do AddColumn(tColumnAlias,tCaption,"date","")
					
				} elseif ($g(tFactInfo("mbrtype"))="r") && ($g(tFactInfo("type"))'="$none") {
					// DP-418267 - Add Rx* columns for Cube Relationships - their FKs will be picked up
					// DP-429698 - Relationships don't have the dimension reference information in the prop metadata, look up the dimension number
					Set tRelName = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"rel#",+$G(tFactInfo))
					Set tRelLocation = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbrs",$$$UPPER(tRelName)))

					do ##class(%DeepSee.Utils).%GetDimensionCaption(tCubeName, $LG(tRelLocation,1), $LG(tRelLocation,2), $LG(tRelLocation,3),.tCaption)
					do AddColumn(tColumnAlias,tCaption,"rollup",tFactInfo("type"))
				}
			}
		} else { // dim table
		
			// fetch dimension properties, if any
			set tKeyProperty = $parameter(tClassName, "KEYPROPERTY")
			// fetch true fact name in case it's aliased
			set tFactName = $g(tMetadata("star",tClassName,"prop",tKeyProperty,"fact"),tKeyProperty)
			
			kill tFactInfo
			merge tFactInfo = tMetadata("fact", "prop",tFactName)
			merge tLevelInfo = tMetadata("mbr#",tFactInfo("dimNo"),tFactInfo("hierNo"),tFactInfo("levelNo"))
			set tPropName = ""
			for {
				set tPropName = $order(tLevelInfo("prop",tPropName),1,tData)
				quit:tPropName=""
				set tDPropInfo($lg(tData,3)) = $zobjclassmethod(tCubeClass,"%GetMemberCaption",$lg(tLevelInfo,2),$lg(tLevelInfo,3),$lg(tLevelInfo,4),tPropName)
			}
			
			set tColName = ""
			for {
				set tColName = $order(tMetadata("star",tClassName,"prop",tColName))
				quit:tColName=""
				
				set tPropFact = tMetadata("star",tClassName,"prop",tColName,"fact")
				set tPropUse = tMetadata("star",tClassName,"prop",tColName,"use")
				set tPropType = tMetadata("star",tClassName,"prop",tColName,"type")
				
				// for some properties, the column name rather than the fact name is used
				if '$d(tMetadata("fact","prop",tPropFact)) {
					set tPropFact = tColName
				}
				
				kill tFactInfo
				merge tFactInfo = tMetadata("fact", "prop",tPropFact)
				
				
				if $g(tFactInfo("virtual")) {
					
					do AddColumn(tColName,$g(tDPropInfo(tPropFact),"No property metadata: "_tPropFact),tPropUse,"")
					
				} else {
					
					if '$d(tFactInfo("levelNo")) {
						do AddColumn(tColName,"No fact metadata: "_tPropFact,"")
						continue
					}
					do ##class(%DeepSee.Utils).%GetDimensionCaption(tCubeName, tFactInfo("dimNo"), tFactInfo("hierNo"), tFactInfo("levelNo"),.tCaption)
					
					set tReferences = $s($e(tPropType)="%":"", 1:tPropType)
					do AddColumn(tColName, tCaption, tPropUse, tReferences)
				}
			}
		}
		
		// init counter
		set qHandle=0
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
	
AddColumn(pColName, pCaption, pPropUse, pReferences)

	// check if name already exists
	if $d(tNameIndex(pCaption),tPos) {
		
		if $lg(qHandle(tPos),3)="key" {
			
			// if name already exists for a key entry, rename the key one
			set $li(qHandle(tPos),2) = pCaption_" - key"
			set tNameIndex(pCaption_" - key") = tPos
			
		} elseif (pPropUse="key") {
			
			// if this new entry is the key, rename it
			set pCaption = pCaption_" - key"
			
		} else { 
		
			// just add a boring number otherwise
			set tBoringNumber = 2
			while $d(tNameIndex(pCaption_" "_tBoringNumber)) { set tBoringNumber = tBoringNumber+1 }
			set pCaption = pCaption_" "_tBoringNumber
			
		}
	}
	set qHandle = qHandle + 1,
		qHandle(qHandle) = $lb(pColName, pCaption, pPropUse, pReferences),
		tNameIndex(pCaption) = qHandle
}

ClassMethod GetDimensionColumnsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetDimensionColumnsExecute ]
{
	quit ..Close(.qHandle)
}

ClassMethod GetDimensionColumnsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetDimensionColumnsExecute ]
{
	quit ..Fetch(.qHandle, .Row, .AtEnd)
}

ClassMethod Fetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, Private ]
{
	set tNext = $order(qHandle(qHandle),1,tData)
	if tNext="" {
		set AtEnd=1, Row=""
	} else {
		set AtEnd=0, Row=tData, qHandle=tNext
	}
	quit $$$OK
}

ClassMethod Close(ByRef qHandle) As %Status [ Internal, Private ]
{
	kill qHandle
	quit $$$OK
}

}
