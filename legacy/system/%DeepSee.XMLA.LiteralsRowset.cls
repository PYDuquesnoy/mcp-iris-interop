/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.LiteralsRowset Extends %Persistent [ System = 4 ]
{

Property LiteralName As String;

Property LiteralValue As String;

Property LiteralInvalidChars As String;

Property LiteralInvalidStartingChars As String;

Property LiteralMaxLength As %Integer;

Property LiteralNameEnumValue As %Integer;

ClassMethod Populate()
{
	do ##class(LiteralsRowset).%KillExtent()
	
	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_CATALOG_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 24
	set row.LiteralNameEnumValue = 2
	do row.%Save()
	
	set row = ##class(LiteralsRowset).%New()	
	set row.LiteralName = "DBLITERAL_CATALOG_SEPARATOR"
	set row.LiteralValue = "."
	set row.LiteralMaxLength = 1
	set row.LiteralNameEnumValue = 3
	do row.%Save()
	
	set row = ##class(LiteralsRowset).%New()	
	set row.LiteralName = "DBLITERAL_COLUMN_ALIAS"
	set row.LiteralInvalidChars = "'""[]"
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 255
	set row.LiteralNameEnumValue = 5
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_COLUMN_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 14
	set row.LiteralNameEnumValue = 6
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_CORRELATION_NAME"
	set row.LiteralInvalidChars = "'""[]"
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 255
	set row.LiteralNameEnumValue = 7
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_PROCEDURE_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 255
	set row.LiteralNameEnumValue = 14
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_TABLE_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 24
	set row.LiteralNameEnumValue = 17
	do row.%Save()
		
	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_TEXT_COMMAND"
	set row.LiteralMaxLength = 0
	set row.LiteralNameEnumValue = 18
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_USER_NAME"
	set row.LiteralMaxLength = 0
	set row.LiteralNameEnumValue = 19
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_QUOTE_PREFIX"
	set row.LiteralValue = "["
	set row.LiteralMaxLength = 1
	set row.LiteralNameEnumValue = 15
	do row.%Save()
	
	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_CUBE_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 24
	set row.LiteralNameEnumValue = 21
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_DIMENSION_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 14
	set row.LiteralNameEnumValue = 22
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_HIERARCHY_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 10
	set row.LiteralNameEnumValue = 23
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_LEVEL_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 255
	set row.LiteralNameEnumValue = 24
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_MEMBER_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 255
	set row.LiteralNameEnumValue = 25
	do row.%Save()
	
	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_PROPERTY_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 255
	set row.LiteralNameEnumValue = 26
	do row.%Save()
	
	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_QUOTE_SUFFIX"
	set row.LiteralValue = "]"
	set row.LiteralMaxLength = 1
	set row.LiteralNameEnumValue = 28
	do row.%Save()

	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_SCHEMA_NAME"
	set row.LiteralInvalidChars = "."
	set row.LiteralInvalidStartingChars = "0123456789 "
	set row.LiteralMaxLength = 24
	set row.LiteralNameEnumValue = 16
	do row.%Save()
	
	set row = ##class(LiteralsRowset).%New()
	set row.LiteralName = "DBLITERAL_SCHEMA_SEPARATOR"
	set row.LiteralValue = "."
	set row.LiteralMaxLength = 1
	set row.LiteralNameEnumValue = 27
	do row.%Save()
}

Storage Default
{
<Data name="LiteralsRowsetDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>LiteralName</Value>
</Value>
<Value name="3">
<Value>LiteralValue</Value>
</Value>
<Value name="4">
<Value>LiteralInvalidChars</Value>
</Value>
<Value name="5">
<Value>LiteralInvalidStartingChars</Value>
</Value>
<Value name="6">
<Value>LiteralMaxLength</Value>
</Value>
<Value name="7">
<Value>LiteralNameEnumValue</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.XMLA.LiteralsRowsetD</DataLocation>
<DefaultData>LiteralsRowsetDefaultData</DefaultData>
<IdLocation>^%DeepSee.XMLA.LiteralsRowsetD</IdLocation>
<IndexLocation>^%DeepSee.XMLA.LiteralsRowsetI</IndexLocation>
<StreamLocation>^%DeepSee.XMLA.LiteralsRowsetS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
