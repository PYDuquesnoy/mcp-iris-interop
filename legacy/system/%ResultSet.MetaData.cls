/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// 	<b>This class has been superseded.</b> It will remain for compatibility with existing code and samples.
/// 	We recommend using <class>%SQL.Statement</class>.
/// </p>
/// 	<p>
/// 	</p>
Class %ResultSet.MetaData Extends %RegisteredObject [ System = 2 ]
{

/// The number of columns defined as SQLRESULTCOL that are returned by executing this statement.
/// This is the same as columns.Count().
Property columnCount As %Integer;

Property columns As list Of %ResultSet.MD.Column;

Property columnIndex As %String(MAXLEN = "") [ MultiDimensional ];

Property parameters As list Of %ResultSet.MD.Parameter;

Property objects As list Of %ResultSet.MD.ObjectId;

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// 
/// %ResultSet.MetaData is a metadata class for result set metadata. The initial value is the metadata from a result set object
/// or it is the result set object itself.
Method %OnNew(initvalue As %RawString = "", pParameters As %RawString = "", pObjects As %RawString = "") As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if initvalue '= "" {
		if $Isobject(initvalue) { set tMetadata = initvalue.%Metadata, tObjects = initvalue.%Objects } else { set tMetadata = initvalue, tObjects = pObjects }
		set tCount = $ListGet(tMetadata), tElements = $Select($Get(%protocol,41)>39:10,1:9), columncount=0
		for tPtr = 2:tElements:(tCount*tElements + 1) {
			set tSerial = $List(tMetadata,tPtr,tPtr + 8)
			if tElements > 9 {
				set tBstr = $List(tMetadata,tPtr + 9)
				for tPtr2 = 1:1:$Length(tBstr) {
					set tSerial = tSerial _ $ListBuild($Ascii(tBstr,tPtr2))
				}
			}
			set tColumn = $List(tSerial), i%columnIndex($$$ucase(tColumn)) = $ListBuild($Increment(tColumnNbr),tColumn)
			do ..columns.InsertObject($$$oidForm(tSerial))
			Set columncount=columncount+1
		}
		set i%columnCount = columncount
		Set ptr=0
		While $listnext(tObjects,ptr,id) {
			do ..objects.InsertObject($$$oidForm(id))
		}
	}
	Quit $$$OK
}

Method print() As %Status
{
	set tCount = ..columns.Count()
	for i=1:1:tCount {
		set tColumn = ..columns.GetAt(i)
		write tColumn.colName,$Char(9)
		write tColumn.ODBCType,$Char(9)
		write tColumn.precision,$Char(9)
		write tColumn.scale,$Char(9)
		write tColumn.isNullable,$Char(9)
		write tColumn.label,$Char(9)
		write tColumn.tableName,$Char(9)
		write tColumn.schemaName,$Char(9)
		write tColumn.qualifier,$Char(9)
		write tColumn.isAutoIncrement,$Char(9)
		write tColumn.isCaseSensitive,$Char(9)
		write tColumn.isCurrency,$Char(9)
		write tColumn.isReadOnly,$Char(9)
		write tColumn.isRowVersion,$Char(9)
		write tColumn.isUnique,$Char(9)
		write tColumn.isAliased,$Char(9)
		write tColumn.isExpression,$Char(9)
		write tColumn.isHidden,$Char(9)
		write tColumn.isIdentity,$Char(9)
		write tColumn.isKeyColumn,$Char(9)
		write tColumn.isRowId,$Char(9)
		write tColumn.propertyId,$Char(9)
		write tColumn.clientType,!
	}
	set tCount = ..parameters.Count()
	for i=1:1:tCount {
		set tParameter = ..parameters.GetAt(i)
		write tParameter.ODBCType,$Char(9)
		write tParameter.precision,$Char(9)
		write tParameter.scale,$Char(9)
		write tParameter.isNullable,$Char(9)
		write tParameter.label,$Char(9)
		write tParameter.clientType,!
	}
	write !!,"Objects: ",!!
	write "Column Name",$Char(9),"Extent",$Char(9),"ExportCall",!
	write "-----------",$Char(9),"------",$Char(9),"----------",!
	set tCount = ..objects.Count()
	#DIM tObject as %ResultSet.MD.ObjectId
	for i=1:1:tCount {
		set tObject = ..objects.GetAt(i)
		write tObject.columnName,?12,$Char(9)
		write tObject.extentName,$Char(9)
		write tObject.exportCall,!
	}
	quit $$$OK
}

Method printMetaData(pMetadata As %RawString) As %Status
{
	set tCount = $List(pMetadata), tElements = $Select($Get(%protocol,41)>39:10,1:9)
	for tPtr = 2:tElements:(tCount*tElements + 1) {
		for tPtr2 = tPtr:1:tPtr + 8 { write $List(pMetadata,tPtr2),$Char(9) }
		if tElements > 9 { set tBstr = $List(pMetadata,tPtr + 9) for tPtr2 = 1:1:$Length(tBstr)-1 { write $Ascii(tBstr,tPtr2),$Char(9) } write $Ascii(tBstr,$Length(tBstr)),! }
	}
	quit $$$OK
}

/// Display metadata on the current device.
Method %Display() As %Status
{
	write !!,"Columns (SQLRESULTCOL, property 'columns'): ",!!
	write "Column Name",?13,"Type",?18,"Prec",?23,"Scale",?29,"Null",?34,"Label",?47,"Table",?60,"Schema",?73,"CType",!
	write "-----------",?13,"----",?18,"----",?23,"-----",?29,"----",?34,"------------",?47,"------------",?60,"------------",?73,"-----",!
	set tCount = ..columns.Count()
	for i=1:1:tCount {
		set tColumn = ..columns.GetAt(i)
		write $Extract(tColumn.colName,1,12)
		write ?13,$Justify(tColumn.ODBCType,4,0)
		write ?18,$Justify(tColumn.precision,4,0)
		write ?23,$Justify(tColumn.scale,5,0)
		write ?29,$Justify(tColumn.isNullable,4,0)
		write ?34,$Extract(tColumn.label,1,12)
		write ?47,$Extract(tColumn.tableName,1,12)
		write ?60,$Extract(tColumn.schemaName,1,12)
		write ?75,$Justify(tColumn.clientType,2)
		write !
	}
	write !!,"Extended Column Info (SQLRESULTCOL) ",!
	write ?5,"Flags: 1:AutoIncrement,2:CaseSensitive,3:Currency,4:ReadOnly,5:RowVersion,",!
	write ?5,"       6:Unique,7:Aliased,8:Expression,9:Hidden,10:Identity,11:KeyColumn,",!
	write ?5,"       12:RowId",!!
	write "Column Name",?13,"Linked Prop",?35,"Type Class",?57,"Flags",!
	write "------------",?13,"---------------------",?35,"---------------------",?57,"-----------------------",!
	set tCount = ..columns.Count()
	for i=1:1:tCount {
		set tColumn = ..columns.GetAt(i)
		write tColumn.colName
		if $Length(tColumn.colName) > 12 { write ! }
		set tColumnProperty = tColumn.propertyId
		write:tColumnProperty'="" ?13,tColumnProperty
		if $Length(tColumnProperty) > 20 { write ! }
		write ?57,$Select(tColumn.isAutoIncrement:"Y",1:"N"),","
		write $Select(tColumn.isCaseSensitive:"Y",1:"N"),","
		write $Select(tColumn.isCurrency:"Y",1:"N"),","
		write $Select(tColumn.isReadOnly:"Y",1:"N"),","
		write $Select(tColumn.isRowVersion:"Y",1:"N"),","
		write $Select(tColumn.isUnique:"Y",1:"N"),","
		write $Select(tColumn.isAliased:"Y",1:"N"),","
		write $Select(tColumn.isExpression:"Y",1:"N"),","
		write $Select(tColumn.isHidden:"Y",1:"N"),","
		write $Select(tColumn.isIdentity:"Y",1:"N"),","
		write $Select(tColumn.isKeyColumn:"Y",1:"N"),","
		write $Select(tColumn.isRowId:"Y",1:"N"),!
	}

	write !!,"Statement Parameters (property 'parameters'): ",!!
	write "Nbr. Type precision scale nullable colName      columntype",!
	write "---- ---- --------- ----- -------- ------------ ----------",!
	set tCount = ..parameters.Count()
	for tPtr = 1:1:tCount {
		set tParameter = ..parameters.GetAt(tPtr)
		write ?1,$Justify(tPtr,3)
		write ?5,$Justify(tParameter.ODBCType,4)
		write ?10,$Justify(tParameter.precision,6)
		write ?20,$Justify(tParameter.scale,5)
		write ?30,tParameter.isNullable
		write ?35,$Extract(tParameter.colName,1,15)
		write ?51,tParameter.columnType,!
	}
	write !!,"Objects: ",!!
	write "Col",?4,"Column Name",?16,"Extent",?34,"ExportCall",!
	write "---",?4,"-----------",?16,"-----------------",?34,"-----------------------------",!
	set tCount = ..objects.Count()
	#DIM tObject as %SQL.StatementObject
	for i=1:1:tCount {
		set tObject = ..objects.GetAt(i)
		write $Justify(i,3)
		write ?4,tObject.columnName
		if $Length(tObject.columnName) > 12 { write ! }
		write ?16,tObject.extentName
		if $Length(tObject.extentName) > 18 { write ! }
		set tExportCall = $Piece(tObject.exportCall,"(",1)
		write ?34,$Extract(tExportCall,1,42),$Select($Length(tExportCall)>42:"...",1:""),!
	}
	quit $$$OK
}

Method GenerateRowType() As %Library.String(MAXLEN="") [ Internal, ServerOnly = 1 ]
{
	set tCount = ..columns.Count()
	if tCount {
		set tColumn = ..columns.GetAt(1)
		set tRowType = "ROW(" _ tColumn.colName _ " " _ $$GetODBCTypeString^%ourODBC(tColumn.ODBCType,tColumn.precision,tColumn.precision,tColumn.scale)
		for tPtr = 2:1:tCount {
			set tColumn = ..columns.GetAt(tPtr)
			set tRowType = tRowType _ "," _ tColumn.colName _ " " _ $$GetODBCTypeString^%ourODBC(tColumn.ODBCType,tColumn.precision,tColumn.precision,tColumn.scale)
		}
		set tRowType = tRowType _ ")"
	}
	else { set tRowType = "" }
	quit tRowType
}

}
