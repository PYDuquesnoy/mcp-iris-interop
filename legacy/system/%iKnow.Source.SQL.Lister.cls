/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Lister implementation for retrieving sources corresponding to records in a query result.</p>
/// 
/// <p><b>Lister Parameters</b> to be supplied to <method>AddListToBatch</method> and
/// 	<method>ProcessList</method> calls:</p>
/// <ol>
///     <li><b>query</b> As <class>%String</class> - the query to fetch the data from, wherein each returned row corresponds to an individual source to be indexed.</li>
/// 	<li><b>idField</b> As <class>%String</class> - the column retrieved by the query that contains the identifier we can use as the LocalReference for the source to be stored. Values for this column should not contain colon characters.</li>
/// 	<li><b>groupField</b> As <class>%String</class> - the column retrieved by the query that contains the group name to use as for the source to be stored.</li>
/// 	<li><b>dataFields</b> As <class>%List</class> - the columns retrieved by the query that contain the data to be indexed (currently %String only).</li>
/// 	<li><b>metaFields</b> As <class>%List</class> - the columns retrieved by the query that contain the metadata attributes to set for this source.</li>
/// 	<li><b>metaKeys</b> As <class>%List</class> - the metadata field names, corresponding to the entries in metaFields (if left blank, we assume the column names correspond to the metadata field names).</li>
/// 	<li><b>multiDataFieldMode</b> As <class>%Integer</class> - 0 = concatenate dataFields (default), 1 = store as separate sources (colon+dataField pos is postfixed to idField value).</li>
/// 	<li><b>concatSeparator</b> As <class>%String</class> - separator to use for concatenating multiple fields (default " ").</li>
/// </ol>
/// 
/// <p><b>External ID structure:</b> [GroupName]:[LocalRef]</p>
/// 	<ul>
/// 		<li>GroupName = either retrieved as a column in the query results or, if none specified, the full query string.</li>
/// 	<li>LocalRef = a unique (within the group) identifier retrieved as one of the query result columns. This should not contain colon characters!</li>
/// </ul>
/// 
/// <p><b>Lister alias:</b> "SQL"</p>
/// <p><b>Default Processor:</b> <class>%iKnow.Source.Temp.Processor</class></p>
Class %iKnow.Source.SQL.Lister Extends %iKnow.Source.Lister [ Deprecated, System = 4 ]
{

/// <p>Triggers the query and loops through the results, listing each row as a separate source
/// (exception: when multiDataFieldMode = 1). Metadata is retrieved and stored as specified by
/// the metaFields and metaKeys parameters.</p>
/// <p>In the current implementation, the data columns are also fetched and stored locally using
/// <method>StoreTemp</method>.</p>
Method ExpandList(listparams As %List) As %Status
{
    set query = $lg(listparams)
    set idField = $lg(listparams,2)
    set groupField = $lg(listparams,3)
    set dataFields = $lg(listparams,4)
    $$$IKENSURELISTSTR(dataFields)
    set metaFields = $lg(listparams,5)
    Set metaKeys = $lg(listparams,6)
    set multiDataFieldMode = $s($ll(dataFields)>1:$lg(listparams,7,0), 1:0)
    set concatSep = $lg(listparams,8," ")
    
    // Save the metadata keys
    Do ..RegisterMetadataKeys($s(metaKeys="":metaFields,1:metaKeys))
    
    set statement=##class(%SQL.Statement).%New()
    set sc=statement.%Prepare(query)
    do:$$$ISERR(sc) ..ReportError("",sc)
    quit:$$$ISERR(sc) sc
    
    set statementResult=statement.%Execute()
    
    set:groupField="" groupId=..AddGroup(query)
    
    // get info about columns of the query
    kill dataFieldTypes
    set objmeta=statementResult.%GetMetadata()
    set count=objmeta.columns.Count()
    for i=1:1:count {
    	set objcol=objmeta.columns.GetAt(i)
    	set dataFieldTypes($$$UPPER(objcol.colName))=objcol.clientType
    	set objcol=""
    }
    set objmeta=""
    
    set prevGroupName="", dataFieldCount=$listlength(dataFields)
    while (statementResult.%Next()) {
        set id=$property(statementResult,idField)
        
        // build reference
        if (groupField'="") {
            Set groupName = $property(statementResult,groupField)
            Set:groupName'=prevGroupName groupId = ..AddGroup(groupName),prevGroupName=groupName
        }
        Set ref=$lb(i%ListerClassId,groupId,id)
        
        // build md field values
        set md=""
        for i=1:1:$listlength(metaFields) {
            set md=md_$lb($property(statementResult,$list(metaFields,i)))
        }
        
        // assemble and store data
        for i=1:1:dataFieldCount {
	        set colName = $list(dataFields,i)
		    set data=$property(statementResult,colName)
	        if (multiDataFieldMode=0) {
		        if (dataFieldTypes($$$UPPER(colName))=13) {
			        set:i>1 sc=..StoreTemp(ref, concatSep)
			        do:$$$ISERR(sc) ..ReportError(ref,sc)
				    set sc=..StoreTempStream(ref, data)
		        } else {
			        set:i>1 data=concatSep_data
				    set sc=..StoreTemp(ref, data)
		        }
	            do:$$$ISERR(sc) ..ReportError(ref,sc)
	        } elseif (multiDataFieldMode=1) {
		        set ref = $lb(i%ListerClassId,groupId,id_"#"_i)
		        if (dataFieldTypes($$$UPPER(colName))=13) {
				    set sc=..StoreTempStream(ref, data)
		        } else {
				    set sc=..StoreTemp(ref, data)
		        }
	            do:$$$ISERR(sc) ..ReportError(ref,sc)
		        set:md'="" sc=..SetMetadataValues(ref,md)
	            do:$$$ISERR(sc) ..ReportError(ref,sc)
	        }
        }
        
        // store metadata
        if (md'="") && (multiDataFieldMode=0) {
		    set sc=..SetMetadataValues(ref,md)
    	    do:$$$ISERR(sc) ..ReportError(ref,sc)
        }
    }
    
    Quit $$$OK
}

/// <p>Splits the full reference in group name and ID by finding the last colon, which by definition
/// should separate the local reference (which cannot contain colons) from the group name.</p>
/// <p>See also <method class="%iKnow.Source.Lister">SplitFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod SplitFullRef(domainId As %Integer, fullRef As %String, Output groupName As %String, Output localRef As %String) As %Status [ Private ]
{
    Set len=$l(fullRef,":")
    set localRef=$p(fullRef,":",len),groupName=$e(fullRef,1,*-$l(localRef)-1)
    Quit $$$OK
}

/// <p>Builds the full reference by appending the local reference to the group name, adding a colon
/// as a separator in between.</p>
/// <p>See also <method class="%iKnow.Source.Lister">BuildFullRef</method> in <class>%iKnow.Source.Lister</class>.</p>
ClassMethod BuildFullRef(domainId As %Integer, groupName As %String, localRef As %String) As %String [ Private ]
{
	quit groupName _ ":" _ localRef
}

/// <p>Lister alias: "SQL"</p>
ClassMethod GetAlias() As %String
{
    Quit "SQL"
}

/// <p>Default Processor: <class>%iKnow.Source.Temp.Processor</class></p>
ClassMethod DefaultProcessor() As %String
{
    Quit "%iKnow.Source.Temp.Processor"
}

ClassMethod FormatParams(listerParams As %List) As %String
{
	quit "query:" _ $lg(listerParams,1) _ ";idField:" _ $lg(listerParams,2) _ ";groupName:" _ $lg(listerParams,3) _ ";dataFields:[" _ $lts($lg(listerParams,4)) _ "];metaFields:[" _ $lts($lg(listerParams,5)) _ "];metaKeys:[" _ $lts($lg(listerParams,6)) _ "]"
}

/// <p>Tests performed by this Lister:</p>
/// <ol>
/// 		<li>query: checks whether this is a valid SQL statement (type SELECT or CALL)</li>
/// 		<li>idField: checks whether this is a valid column, returned by the above query</li>
/// 		<li>groupField: checks whether this is a valid column, returned by the above query</li>
/// 		<li>dataFields: checks whether these are valid columns, returned by the above query</li>
/// 		<li>metaFields: checks whether these are valid columns, returned by the above query</li>
/// 		<li>metaKeys: checks whether these are existing metadata fields</li>
/// 		<li>multiDataFieldMode: no checks</li>
/// 		<li>concatSeparator: no checks</li>
/// </ol>
Method TestParams(listerParams...) As %Status
{
    set query = $g(listerParams(1))
    quit:(query="") $$$ERROR($$$IKMissingListerParam, 1, "query")
    
    set idField = $g(listerParams(2))
    quit:(idField="") $$$ERROR($$$IKMissingListerParam, 2, "ID field")
    
    set groupField = $g(listerParams(3))
    quit:(groupField="") $$$ERROR($$$IKMissingListerParam, 3, "group field")
    
    set dataFields = $g(listerParams(4))
    quit:(dataFields="") $$$ERROR($$$IKMissingListerParam, 4, "data fields")
    $$$IKENSURELISTSTR(dataFields)
    
    set metaFields = $g(listerParams(5))
    set metaKeys = $g(listerParams(6))
    set multiDataFieldMode = $s($ll(dataFields)>1:$g(listerParams(7),0), 1:0)
    set concatSep = $g(listerParams(8)," ")
    
    // validate SQL query
	set tStatement = ##class(%SQL.Statement).%New()
	try {
		set tSC = tStatement.%Prepare(query)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit:$$$ISERR(tSC) $$$ERROR($$$IKListerParamError, 1, "query", "Error testing query: "_$$GetErrorText^%apiOBJ(tSC))
	
	// test whether a valid sql statement type
	if (tStatement.%Metadata.statementType'=1) && (tStatement.%Metadata.statementType'=45) {
		quit $$$ERROR($$$IKListerParamError, 1, "query", "The supplied query is not a valid SELECT or CALL statement")
	}
	
	// test whether all supplied fields are present (only available for SELECT statements)
	if (tStatement.%Metadata.statementType = 1) {
		quit:'$d(tStatement.%Metadata.columnIndex($$$UPPER(idField))) $$$ERROR($$$IKListerParamError, 2, "ID field", "Query result columns don't include ID field column """_idField_"""")
		quit:'$d(tStatement.%Metadata.columnIndex($$$UPPER(groupField))) $$$ERROR($$$IKListerParamError, 3, "group field", "Query result columns don't include group field column """_groupField_"""")
	
		set allFound=1
		for i = 1:1:$ll(dataFields) {
			set field = $lg(dataFields,i)
			set allFound = $d(tStatement.%Metadata.columnIndex($$$UPPER(field)))
			quit:'allFound
		}
		quit:'allFound $$$ERROR($$$IKListerParamError, 4, "data fields", "Query result columns don't include data field column """_field_"""")
	
		if (metaFields '= "") {
			set allFound=1
			for i = 1:1:$ll(metaFields) {
				set field = $lg(metaFields,i)
				set allFound = $d(tStatement.%Metadata.columnIndex($$$UPPER(field)))
				quit:'allFound
			}
			quit:'allFound $$$ERROR($$$IKListerParamError, 5, "meta fields", "Query result columns don't include metadata field column """_field_"""")
		}
	
		if (metaKeys '= "") {
			set allFound = 1
			for i = 1:1:$ll(metaKeys) {
				set field = $lg(metaKeys,i)
				set allFound = (##class(%iKnow.Queries.MetadataAPI).GetFieldId(i%DomainId, field)>0)
				quit:'allFound
			}
			quit:'allFound $$$ERROR($$$IKListerParamError, 6, "meta keys", "Metadata field name """_field_""" does not exist in this domain")
		}
		// BDB458 - if metaKeys="", check metaFields
		elseif (metaFields'="") {
			set allFound = 1
			for i = 1:1:$ll(metaFields) {
				set field = $lg(metaFields,i)
				set allFound = (##class(%iKnow.Queries.MetadataAPI).GetFieldId(i%DomainId, field)>0)
				quit:'allFound
			}
			quit:'allFound $$$ERROR($$$IKListerParamError, 6, "meta fields", "Metadata field name """_field_""" does not exist in this domain")
		}
	}
	
	set tStatement = ""
	
	quit $$$OK
}

}
