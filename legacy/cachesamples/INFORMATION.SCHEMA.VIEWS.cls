/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each view in the current namespace for which the current user has privileges
Class INFORMATION.SCHEMA.VIEWS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = VIEWS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, TableExact) [ IdKey, Internal, Unique ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 20 ];

Property TableExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 21 ];

/// Is the table a system table (1 or 0)
Property SystemView As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 22, SqlComputeCode = { set {*}=$s($e({TABLE_SCHEMA})="%"||({TABLE_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// Table qualifier - always NULL in InterSystems IRIS.
Property TABLECATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = TABLE_CATALOG ];

/// Name of schema that contains the table.
Property TABLESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = TABLE_SCHEMA ];

/// Name of the view.
Property TABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = TABLE_NAME ];

/// The view's query expression.  If longer than 1048576 characters, only the first 1048573 characters of the query are returned followed by "...".
Property VIEWDEFINITION As %String(MAXLEN = 1048576) [ SqlColumnNumber = 5, SqlFieldName = VIEW_DEFINITION ];

/// The view's check option setting.
/// <br>Values of CHECK_OPTION have the following meanings:
/// <br><ul>
/// 	<li>CASCADED - The view has the CASCADED check option specified.</li>
/// 	<li>LOCAL - The view has the LOCAL check option specified.</li>
/// 	<li>NONE - The view has no check option specified.</li>
/// </ul>
Property CHECKOPTION As %String(MAXLEN = 8, VALUELIST = ",CASCADED,LOCAL,NONE") [ Calculated, SqlColumnNumber = 6, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHECK_OPTION ];

/// Returns YES if the view is updatable, otherwise NO.
Property ISUPDATABLE As %String(MAXLEN = 3) [ SqlColumnNumber = 7, SqlFieldName = IS_UPDATABLE ];

/// Reserved for future use.  For InterSystems IRIS, IS_TRIGGER_UPDATABLE is always NULL.
Property ISTRIGGERUPDATABLE As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 8, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IS_TRIGGER_UPDATABLE ];

/// Reserved for future use.  For InterSystems IRIS, IS_TRIGGER_DELETABLE is always NULL.
Property ISTRIGGERDELETABLE As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 9, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IS_TRIGGER_DELETABLE ];

/// Reserved for future use.  For InterSystems IRIS, IS_TRIGGER_INSERTABLE_INTO is always NULL.
Property ISTRIGGERINSERTABLEINTO As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 10, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IS_TRIGGER_INSERTABLE_INTO ];

/// Description for the class that projects the view definition, or if the view is projected from a class query, the class query description.
Property DESCRIPTION As %String(MAXLEN = 1024) [ Calculated, SqlColumnNumber = 11, SqlComputeCode = { 
	set {*}=""
	new tClassname
	set tClassname=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),1) QUIT:tClassname=""
	if $$$comClassKeyGet(tClassname,$$$cCLASSviewquery)'="" {	// view is a class view
		set {*}=$$$defClassKeyGet(tClassname,$$$cCLASSdescription)
	}
	else {	// view is projected from a class query
		new tQuery
		set tQuery=""
		for  {	// See if any class query is a view with this SqlViewName
			set tQuery=$$$defMemberNext(tClassname,$$$cCLASSquery,tQuery) quit:tQuery=""
			continue:'$$$comMemberKeyGet(tClassname,$$$cCLASSquery,tQuery,$$$cQUERYsqlview)	// Query is not a view
			quit:$$$comMemberKeyGet(tClassname,$$$cCLASSquery,tQuery,$$$cQUERYsqlviewname)={TableExact}	// Found a match on SqlViewName
		}
		if tQuery="" {	// No SqlViewName match, look for query name match
			for  {	// See if any class query is a view with this SqlViewName
				set tQuery=$$$defMemberNext(tClassname,$$$cCLASSquery,tQuery) quit:tQuery=""
				continue:'$$$comMemberKeyGet(tClassname,$$$cCLASSquery,tQuery,$$$cQUERYsqlview)	// Query is not a view
				quit:tQuery={TableExact}	// Found a match on query name
			}
		}
		set:tQuery'="" {*}=$$$comMemberKeyGet(tClassname,$$$cCLASSquery,tQuery,$$$cQUERYdescription)
	}
	}, SqlComputed, SqlFieldName = DESCRIPTION ];

/// Timestamp for when the class projecting the view definition was created.
Property DATECREATED As %TimeStamp [ Calculated, SqlColumnNumber = 12, SqlComputeCode = { 
	set {*}=""
	new tClassname
	set tClassname=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),1) QUIT:tClassname=""
	set {*}=$$$defClassKeyGet(tClassname,$$$cCLASStimecreated)
	set:{*} {*}=$zdt({*},3,,$l($p({*},".",2)))
	}, SqlComputed, SqlFieldName = DATE_CREATED ];

/// Timestamp for when the class projecting the view definition was last modified.
Property DATEMODIFIED As %TimeStamp [ Calculated, SqlColumnNumber = 13, SqlComputeCode = { 
	set {*}=""
	new tClassname
	set tClassname=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),1) QUIT:tClassname=""
	set {*}=$$$defClassKeyGet(tClassname,$$$cCLASStimechanged)
	set:{*} {*}=$zdt({*},3,,$l($p({*},".",2)))
	}, SqlComputed, SqlFieldName = DATE_MODIFIED ];

/// Name of the class that projected the view definition
Property Classname As %String(MAXLEN = 254) [ Calculated, SqlColumnNumber = 14, SqlComputeCode = { set {*}=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),1) }, SqlComputed, SqlFieldName = CLASSNAME ];

/// View's owner
Property Owner As %String(MAXLEN = 254) [ Calculated, SqlColumnNumber = 15, SqlComputeCode = { set {*}=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),6) }, SqlComputed, SqlFieldName = OWNER ];

/// If projected from a class query, name of the query
Property Queryname As %String(MAXLEN = 254) [ Calculated, SqlColumnNumber = 16, SqlComputeCode = { 
	set {*}=""
	new tClassname
	set tClassname=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),1) QUIT:tClassname=""
	if $$$comClassKeyGet(tClassname,$$$cCLASSviewquery)'="" {	// view is a class view
	}
	else {	// view is projected from a class query
		new tQuery
		set tQuery=""
		for  {	// See if any class query is a view with this SqlViewName
			set tQuery=$$$defMemberNext(tClassname,$$$cCLASSquery,tQuery) quit:tQuery=""
			continue:'$$$comMemberKeyGet(tClassname,$$$cCLASSquery,tQuery,$$$cQUERYsqlview)	// Query is not a view
			quit:$$$comMemberKeyGet(tClassname,$$$cCLASSquery,tQuery,$$$cQUERYsqlviewname)={TableExact}	// Found a match on SqlViewName
		}
		if tQuery="" {	// No SqlViewName match, look for query name match
			for  {	// See if any class query is a view with this SqlViewName
				set tQuery=$$$defMemberNext(tClassname,$$$cCLASSquery,tQuery) quit:tQuery=""
				continue:'$$$comMemberKeyGet(tClassname,$$$cCLASSquery,tQuery,$$$cQUERYsqlview)	// Query is not a view
				quit:tQuery={TableExact}	// Found a match on query name
			}
		}
		set:tQuery'="" {*}=tQuery
	}
	}, SqlComputed, SqlFieldName = QUERY_NAME ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="CHECK_OPTION">
<RetrievalCode> set {*}=$case($li(^oddEXTR({3D1},91),31),"C":"CASCADED","L":"LOCAL",:"NONE")</RetrievalCode>
</Data>
<Data name="IS_UPDATABLE">
<RetrievalCode> set {*}=$s($li(^oddEXTR({3D1},91),30)=1:"YES",1:"NO")</RetrievalCode>
</Data>
<Data name="TABLE_NAME">
<Piece>3</Piece>
</Data>
<Data name="TABLE_SCHEMA">
<Piece>2</Piece>
</Data>
<Data name="VIEW_DEFINITION">
<RetrievalCode>
<![CDATA[ new i set {*}="" for i=1:1:$g(^oddEXTR({3D1},"spec",94,0)) set {*}={*}_$s(i>1:$c(13,10),1:"")_^(i) if $l({*})>1048576 set {*}=$e({*},1,1048573)_"..." quit  ]]></RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"VIEW"</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SchemaExact}</Expression>
<NextCode>set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""VIEW"")", {L2})</NextCode>
</Subscript>
<Subscript name="3">
<Accessvar name="1">
<Code> set {3D1}=$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),2)</Code>
<Variable>{3D1}</Variable>
</Accessvar>
<Expression>{TableExact}</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("3,"_$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="rxIndex">
<Data name="SchemaExact">
<RetrievalCode>set {*}=$p($lg(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4),".",1,*-1)</RetrievalCode>
</Data>
<Data name="TableExact">
<RetrievalCode>set {*}=$tr($p($lg(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4),".",*),$c(2),".")</RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"rv"</Expression>
</Subscript>
<Subscript name="2">
<Expression>$$UPPER({TABLE_SCHEMA})</Expression>
<NextCode>set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""rv"")", {L2})</NextCode>
</Subscript>
<Subscript name="3">
<Expression>$$UPPER({TABLE_NAME})</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("3,"_$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^INFORMATION.SCHEMA.VIEWSS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

