/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occODBC, %soap)

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25SQL.StatementMetadata">SQL Metadata</a>.</p>
/// Metadata describes the statement interface. The statement metadata contains the type of statement, the number of
/// columns defined by the statement and the metadata for each column. Statement columns are of three primary types:
/// result columns, parameters, and the return value. There is also a distinction between the metadata available for a
/// prepared statement and for a statement that has been executed since not all statement results are known at prepare
/// time. For all statement types except CALL, the statement metadata is all available at prepare time. CALL statement metadata
/// that is available at prepare time includes the metadata from the statement itself and that metadata is not to be confused
/// with the metadata defined by the SQL routine that is called. Each routine defines a formal interface that consists of an
/// optional return value and option input, input-output and output parameters. An SQL routine might also return a single
/// preplanned result set. That metadata is available at prepare time and it consists of some number of columns of type
/// SQLRESULTCOL. An SQL routine might also declare that it returns some dynamic result sets, the metadata for which is not
/// available until after the statement is executed and the result sets bound dynamic cursors.
Class %SQL.StatementMetadata Extends %RegisteredObject [ System = 4 ]
{

/// <p>Integer value indicating the type of statement.</p>
/// <table>
/// 	<tr><td>1</td><td>SELECT</td></tr>
/// 	<tr><td>2</td><td>INSERT (also 'INSERT OR UPDATE')</td></tr>
/// 	<tr><td>3</td><td>UPDATE</td></tr>
/// 	<tr><td>4</td><td>DELETE</td></tr>
/// 	<tr><td>5</td><td>COMMIT</td></tr>
/// 	<tr><td>6</td><td>ROLLBACK</td></tr>
/// 	<tr><td>7</td><td>GRANT</td></tr>
/// 	<tr><td>8</td><td>REVOKE</td></tr>
/// 	<tr><td>9</td><td>CREATE TABLE</td></tr>
/// 	<tr><td>10</td><td>ALTER TABLE</td></tr>
/// 	<tr><td>11</td><td>DROP TABLE</td></tr>
/// 	<tr><td>12</td><td>CREATE VIEW</td></tr>
/// 	<tr><td>13</td><td>ALTER VIEW</td></tr>
/// 	<tr><td>14</td><td>DROP VIEW</td></tr>
/// 	<tr><td>15</td><td>CREATE INDEX</td></tr>
/// 	<tr><td>16</td><td>ALTER INDEX (Not supported)</td></tr>
/// 	<tr><td>17</td><td>DROP INDEX</td></tr>
/// 	<tr><td>18</td><td>CREATE ROLE</td></tr>
/// 	<tr><td>19</td><td>DROP ROLE</td></tr>
/// 	<tr><td>20</td><td>SET TRANSACTION</td></tr>
/// 	<tr><td>21</td><td>START TRANSACTION</td></tr>
/// 	<tr><td>22</td><td>%INTRANSACTION</td></tr>
/// 	<tr><td>23</td><td>%BEGTRANS (Alias for START TRANSACTION)</td></tr>
/// 	<tr><td>24</td><td>%INTRANS (Alias for %INTRANSACTION)</td></tr>
/// 	<tr><td>25</td><td>GET (Not supported)</td></tr>
/// 	<tr><td>26</td><td>SET OPTION</td></tr>
/// 	<tr><td>27</td><td>STATISTICS (UPDATE STATISTICS, not supported))</td></tr>
/// 	<tr><td>28</td><td>%CHECKPRIV</td></tr>
/// 	<tr><td>29</td><td>CREATE USER</td></tr>
/// 	<tr><td>30</td><td>ALTER USER</td></tr>
/// 	<tr><td>31</td><td>DROP USER</td></tr>
/// 	<tr><td>32</td><td>%CHECKPRIV (SQL Admin Privilege)</td></tr>
/// 	<tr><td>33</td><td>GRANT (SQL Admin Privilege)</td></tr>
/// 	<tr><td>34</td><td>REVOKE (SQL Admin Privilege)</td></tr>
/// 	<tr><td>35</td><td>CREATE FUNCTION</td></tr>
/// 	<tr><td>36</td><td>CREATE METHOD</td></tr>
/// 	<tr><td>37</td><td>CREATE PROCEDURE</td></tr>
/// 	<tr><td>38</td><td>CREATE QUERY</td></tr>
/// 	<tr><td>39</td><td>DROP FUNCTION</td></tr>
/// 	<tr><td>40</td><td>DROP METHOD</td></tr>
/// 	<tr><td>41</td><td>DROP PROCEDURE</td></tr>
/// 	<tr><td>42</td><td>DROP QUERY</td></tr>
/// 	<tr><td>43</td><td>CREATE TRIGGER</td></tr>
/// 	<tr><td>44</td><td>DROP TRIGGER</td></tr>
/// 	<tr><td>45</td><td>CALL</td></tr>
/// 	<tr><td>46</td><td>SAVEPOINT</td></tr>
/// 	<tr><td>47</td><td>LOCK TABLE</td></tr>
/// 	<tr><td>48</td><td>UNLOCK TABLE</td></tr>
/// 	<tr><td>49</td><td>CREATE DATABASE</td></tr>
/// 	<tr><td>50</td><td>DROP DATABASE</td></tr>
/// 	<tr><td>51</td><td>USE DATABASE</td></tr>
/// 	<tr><td>52</td><td>TUNE TABLE</td></tr>
/// 	<tr><td>53</td><td>DECLARE</td></tr>
/// 	<tr><td>54</td><td>CREATE MODEL</td></tr>
/// 	<tr><td>55</td><td>DROP MODEL</td></tr>
/// 	<tr><td>56</td><td>TRAIN MODEL</td></tr>
/// 	<tr><td>57</td><td>ALTER MODEL</td></tr>
/// 	<tr><td>58</td><td>VALIDATE MODEL</td></tr>
/// 	<tr><td>59</td><td>SET ML CONFIGURATION</td></tr>
/// 	<tr><td>60</td><td>CREATE ML CONFIGURATION</td></tr>
/// 	<tr><td>61</td><td>ALTER ML CONFIGURATION</td></tr>
/// 	<tr><td>62</td><td>DROP ML CONFIGURATION</td></tr>
/// 	<tr><td>63</td><td>FREEZE PLANS</td></tr>
/// 	<tr><td>64</td><td>UNFREEZE PLANS</td></tr>
/// 	<tr><td>65</td><td>PURGE</td></tr>
/// 	<tr><td>66</td><td>BUILD INDEX</td></tr>
/// 	<tr><td>67</td><td>CREATE AGGREGATE</td></tr>
/// 	<tr><td>68</td><td>DROP AGGREGATE</td></tr>
/// 	<tr><td>69</td><td>LOAD</td></tr>
/// 	<tr><td>70</td><td>CREATE SCHEMA</td></tr>
/// 	<tr><td>71</td><td>DROP SCHEMA</td></tr>
/// 	<tr><td>72</td><td>CREATE SERVER</td></tr>
/// 	<tr><td>73</td><td>ALTER SERVER</td></tr>
/// 	<tr><td>74</td><td>DROP SERVER</td></tr>
/// 	<tr><td>75</td><td>CREATE FOREIGN TABLE</td></tr>
/// 	<tr><td>76</td><td>ALTER FOREIGN TABLE</td></tr>
/// 	<tr><td>77</td><td>DROP FOREIGN TABLE</td></tr>
/// 	<tr><td>78</td><td>CANCEL QUERY</td></tr>
/// 	<tr><td>79</td><td>EXPLAIN</td></tr>
/// 	<tr><td>80</td><td>THROUGH</td></tr>
/// 	<tr><td>99</td><td>Anything not list above</td></tr>
/// </table>
Property statementType As %Integer;

/// interface is an integer value indicating the routine interface:
/// -2	-	Return value, dynamic cursors returned (zero, one or more)
/// -1	-	No return value, dynamic cursors returned (RETURNRESULTSETS, zero one or more)
///  0	-	No return value, no dynamic cursors (NOT RETURNRESULTSETS, aka "function" procedure although a function should return a value (interface = 2))
///  1	-	No return value, one pre-planned result set (AKA "query" procedure)
///  2	-	Return value, no dynamic cursors (NOT RETURNRESULTSETS)
Property interface As %Integer;

/// The number of columns defined as SQLRESULTCOL that are returned by executing this statement.
/// This is the same as columns.Count().
Property columnCount As %Integer;

/// columns is a collection of StatementColumn objects. Each StatementColumn object
/// contains the metadata a column defined by the statement as an SQLRESULTCOL column type.
Property columns As list Of %SQL.StatementColumn;

/// Index on column names and column number.
Property columnIndex As %String(MAXLEN = "") [ MultiDimensional ];

/// formalParameters is a collection of '?' parameters found in the prepared statement.
/// It may differ from the parameters collection if literal replacement occurred. This
/// property is mainly for internal use and metadata reporting. It is not meant to be used
/// for the statement descriptor.
Property formalParameters As list Of %SQL.StatementParameter;

/// The number of parameters defined in this statement. This is the same as
/// parameters.Count().
Property parameterCount As %Integer;

/// The parameters collection contains the metadata for each actual parameter
/// contained in the source statement. ..parameters.Count() is equivalent to the
/// number of '?' parameters found in the source statement and the list position
/// corresponds to the ordinal position of the '?' in the source statement.
Property parameters As list Of %SQL.StatementParameter;

/// A collection of StatementObject objects representing the columns that are object values.
Property objects As list Of %SQL.StatementObject;

/// GenerateMetadata constructs the serialized metadata from the query processor's info array.
/// 
/// IF %protocol 41 and higher:
///  metadata = $lb()
/// 		1 - # of SELECT columns
/// 		2 - i:  <For each SELECT column>
/// 			1) Name
/// 			2) ODBC Type
/// 			3) Precision
/// 			4) Scale
/// 			5) NULLABLE (integer)
/// 			6) Column Label (same as Name)
/// 			7) Column Table Name
/// 			8) Column Schema Name
/// 			9) Column Qualifier Name - NULL
/// 			10) $Char(1)/$Char(0) string / $Extract position:
/// 				1)  isAutoIncrement
/// 				2)  isCaseSensitive
/// 				3)  isCurrency
/// 				4)  IsReadOnly
/// 				5)  IsRowVersion
/// 				6)  IsUnique
/// 				7)  IsAliased
/// 				8)  IsExpression
/// 				9)  IsHidden
/// 				10) IsIdentity
/// 				11) IsKeyColumn
/// 				12) IsRowid
/// 				13) IsList
/// 		j - # of Parameters
/// 		j+1 - k:  <For each Parameter>
/// 			1) ODBC Type
/// 			2) Precision
/// 			3) Scale
/// 			4) NULLABLE
/// 				5) colName
/// 				6) colType
/// IF %protocol less than 41:
///  metadata = $lb()
/// 		1 - # of SELECT columns
/// 		2 - i:  <For each SELECT column>
/// 			1) Name
/// 			2) ODBC Type
/// 			3) Precision
/// 			4) Scale
/// 			5) NULLABLE
/// 			6) Column Label (same as Name)
/// 			7) Column Table Name
/// 			8) Column Schema Name
/// 			9) Column Qualifier Name - NULL
/// 		j - # of Parameters
/// 		j+1 - k:  <For each Parameter>
/// 			1) ODBC Type
/// 			2) Precision
/// 			3) Scale
/// 			4) NULLABLE
/// 
ClassMethod %GenerateMetadata(ByRef pInfo As %Binary, pStatementType As %Integer = 0, ByRef pMetadata As %Binary, ByRef pParameters As %Binary = "", ByRef pObjects As %Binary, ByRef pActual As %List = "", ByRef pDynamic As %List = "") As %Status
{
	kill pMetadata
	set tPtr = 0, pMetadata(0) = "", pObjects = ""
	if ",1,80,"[(","_pStatementType_",") {
			#; Column count is first
		set pMetadata(tPtr) = $listbuild(+$get(pInfo("select")))
		for tPtr2=1:1:+$get(pInfo("select")) {
			set info=$get(pInfo("select",tPtr2,1))
			set tColumnName = $Piece(info,$Char(1),1)
			set tColumnODBCType = +$piece(info,$char(1),2)
			set tColumnDataType = $piece(info,$char(1),13)
			if (tColumnDataType '= "") { set tClientTypeEnum = $$$comClassKeyGet(tColumnDataType,$$$cCLASSclientdatatypeenum) }
			else { set tClientTypeEnum=+$Piece("12|0|1|7|0|0|14|0|5|5|0|0|3|2|8|9|10","|",tColumnODBCType+5) }
			set tColumnProperty = $piece(info,$char(1),14)
			if (tColumnProperty  '= "") && ($piece(pInfo("select",tPtr2),$char(1),8) '= "") {
				set tColumnExtent = $piece(info,$char(1),15), tColumnContainer = $Piece(info,$Char(1),26)
				if tColumnContainer = "" {
					if tColumnProperty '= "%%ID" { set tColumnDataType = $get($$$EXTPROPtype($$$pEXT,tColumnExtent,tColumnProperty),tColumnDataType),rowid=0, pDynamic = pDynamic _$ListBuild($ListBuild(tColumnExtent _ "||" _ tColumnProperty,tColumnDataType,tClientTypeEnum)) }
					else { set tColumnDataType = tColumnExtent, rowid=1, pDynamic = pDynamic _ $ListBuild($ListBuild("",tColumnDataType,tClientTypeEnum)) }
				}
				else {
					set tContainerProp=$$$SQLLocColPropertyName($$$EXTSQLCOLsqlinfo($$$rEXT,tColumnExtent,tColumnContainer))
					set tContainerExtent = $get($$$EXTPROPtype($$$pEXT,tColumnExtent,tContainerProp),tColumnExtent)
					if tColumnProperty '= "%%ID" {
						set tColumnDataType = $get($$$EXTPROPtype($$$pEXT,tColumnExtent,tColumnContainer_"."_tColumnProperty),tColumnDataType),rowid=0
						set pDynamic = pDynamic _$ListBuild($ListBuild(tContainerExtent _ "||" _ tColumnProperty,tColumnDataType,tClientTypeEnum))
					}
					else { set tColumnDataType = tContainerExtent, rowid=1, pDynamic = pDynamic _ $ListBuild($ListBuild("",tColumnDataType,tClientTypeEnum)) }
				}
					#; This is an object - add to the list
				if '$$$classIsDataType(tColumnDataType) {
					$$$comClassKeyGetLvar(tSchema,tColumnDataType,$$$cCLASSsqlschemaname)
					$$$comClassKeyGetLvar(tTable,tColumnDataType,$$$cCLASSsqltablename)
					if (tSchema '= "") && (tTable '= "") { set tQuickQuery = $Get(^oddSQL(tSchema,tTable,"QQ")) set:tQuickQuery'="" tQuickQuery="##class("_$lg(tQuickQuery)_")."_$lg(tQuickQuery,2)_"(%rowid,%nolock,0,1)" } else { set tQuickQuery = "" }
					set pObjects = pObjects _ $lb($lb(tColumnName,tColumnDataType,tQuickQuery,tPtr2))
				}
			}
			else { set pDynamic = pDynamic _ $ListBuild($ListBuild("",tColumnDataType,tClientTypeEnum)) }
			set pMetadata(tPtr)=pMetadata(tPtr)_$listbuild(tColumnName,tColumnODBCType,+$piece(info,$char(1),4),$case($piece(info,$char(1),5),"":"",:$piece(info,$char(1),5)),+$piece(info,$char(1),6),$piece(info,$char(1),8),$piece(info,$char(1),11),$piece(info,$char(1),9),+$piece(info,$char(1),10))
			if $get(%SQLCompileMode)="RUNTIME" {	// DPV3072=
				if $zutil(115,5)=0 {	// Logical mode
					#;  Convert DATE, TIME, BIT to INTEGER
					set:$case(+$piece(info,$char(1),2),-7:1,9:1,10:1,:0) $piece(info,$char(1),2,5)=4_$char(1)_4_$char(1)_10_$char(1)_0
				}
				elseif $zutil(115,5)=2 {	// Display mode, report all as string
					set:+$piece(info,$char(1),2)'=12 $piece(info,$char(1),2)=12
				}
			}
			set cstr=$char(+$piece(info,$char(1),18),
					$select($piece(info,$char(1),2)'=12:0,1:$case($piece(info,$char(1),12),"":1,"%EXACT":1,"%STRING":1,"%SQLSTRING":1,:0)),
					($piece(info,$char(1),13)="%Library.Currency"),
					+$piece(info,$char(1),7),
					+$piece(info,$char(1),19),
					+$piece(info,$char(1),20),
					(($piece(info,$char(1),17)'=""&&($piece(info,$char(1),8)'=$piece(info,$char(1),17)))||($piece(info,$char(1),17)="")),
					+$piece(info,$char(1),21),
					+$piece(info,$char(1),22),
					+$piece(info,$char(1),23),
					+$piece(info,$char(1),24),
					+$piece(info,$char(1),25),
					+$piece(info,$char(1),29))
			set pMetadata(tPtr)=pMetadata(tPtr)_$listbuild(cstr)
			set:$length(pMetadata(tPtr))>32000 tPtr = tPtr+1,pMetadata(tPtr)=""
		}
			#; The ROWTYPE metadata is completely and solely contained in pMetadata. Parameter and object metadata is contained in pParameters and pObjects
		set pParameters = pParameters_$listbuild(+$get(pInfo("parameter")))
		for tPtr2 = 1:1:+$get(pInfo("parameter")) {
			set info = $get(pInfo("parameter",tPtr2,1))
			set pParameters = pParameters_$listbuild(+$piece(info,$char(1),2),+$piece(info,$char(1),4),+$piece(info,$char(1),5),+$piece(info,$char(1),6),$piece(pInfo("parameter",tPtr2),$char(1),1),$$$SQLPARAMINPUT)
		}
	}
	elseif pStatementType '= 45 {
			#; This is not a SELECT and not a CALL
		set pMetadata(tPtr)=pMetadata(tPtr)_$listbuild(+$get(pInfo("parameter")))
		for tPtr2=1:1:+$get(pInfo("parameter")) {
			set info=$get(pInfo("parameter",tPtr2,1))
			set pMetadata(tPtr)=pMetadata(tPtr)_$listbuild(+$piece(info,$char(1),2),+$piece(info,$char(1),4),+$piece(info,$char(1),5),+$piece(info,$char(1),6),$piece(pInfo("parameter",tPtr2),$char(1),1),1)
			set:$length(pMetadata(tPtr))>32000 tPtr=tPtr+1,pMetadata(tPtr)=""
		}
	}
	else {
			#; This is a CALL statement
		set tSchemaName = pInfo("call","schema"), tProcedureName = pInfo("call","proc")
			#; SQL-invoked routine metadata is $lb(interface,colcount,columns...,parmcount,parms...,objectcount,objects...)
			#; What we stored in the CachedStatement library is the routine metadata (the ODBCInfo property from the routine definition) and the
			#; parameters from the prepared statement. 
		set tRoutine = ##class(%SQL.DICT.Routine).idkOpen(tSchemaName,tProcedureName)
		if $IsObject(tRoutine) {
			#dim tRoutine as %SQL.DICT.Routine
			#dim tColumn as %SQL.DICT.RoutineColumn
			set pMetadata(0) = tRoutine.ODBCinfo
			if tRoutine.interface = 1 {
				set tColumnKey = "", pDynamic = "", tResultColCount = 0
				set tColumn = tRoutine.columns.GetNext(.tColumnKey)
				while tColumnKey '= "" {
					if tColumn.type = $$$SQLRESULTCOL {
						set tResultColCount = tResultColCount + 1, tColumnDataType = ""
						if (tColumn.attribute '= "") && (tColumn.attribute '= "%%ID") {
							$$$comMemberKeyGetLvar(tColumnDataType,tColumn.class,$$$cCLASSproperty,tColumn.attribute,$$$cPROPtype)
							set pDynamic = pDynamic _$ListBuild($ListBuild(tColumn.class _ "||" _ tColumn.attribute, tColumn.datatype, tColumn.clientdatatypeenum))
						}
						elseif tColumn.attribute = "%%ID" { set pDynamic = pDynamic _$ListBuild($ListBuild("", tColumn.class, tColumn.clientdatatypeenum)) }
						else { set pDynamic = pDynamic _$ListBuild($ListBuild("", tColumn.datatype, tColumn.clientdatatypeenum)) }
						if tResultColCount = tRoutine.idcolumn {
							$$$comClassKeyGetLvar(tSchema,tRoutine.idextent,$$$cCLASSsqlschemaname)
							$$$comClassKeyGetLvar(tTable,tRoutine.idextent,$$$cCLASSsqltablename)
							if (tSchema '= "") && (tTable '= "") { set tQuickQuery = $Get(^oddSQL(tSchema,tTable,"QQ")) set:tQuickQuery'="" tQuickQuery="##class("_$lg(tQuickQuery)_")."_$lg(tQuickQuery,2)_"(%rowid,%nolock,0,1)" } else { set tQuickQuery = "" }
							set pObjects = pObjects _ $lb($lb(tColumn.name,tRoutine.idextent,tQuickQuery,tResultColCount))
						}
						elseif (tColumnDataType '= "") && ('$$$classIsDataType(tColumnDataType)) {
							$$$comClassKeyGetLvar(tSchema,tColumn.class,$$$cCLASSsqlschemaname)
							$$$comClassKeyGetLvar(tTable,tColumn.class,$$$cCLASSsqltablename)
							if (tSchema '= "") && (tTable '= "") { set tQuickQuery = $Get(^oddSQL(tSchema,tTable,"QQ")) set:tQuickQuery'="" tQuickQuery="##class("_$lg(tQuickQuery)_")."_$lg(tQuickQuery,2)_"(%rowid,%nolock,0,1)" } else { set tQuickQuery = "" }
							set pObjects = pObjects _ $lb($lb(tColumn.name,tColumn.class,tQuickQuery,tResultColCount))
						}
					}
					set tColumn = tRoutine.columns.GetNext(.tColumnKey)
				}
				if tRoutine.idcolumn > 0 {
				}
			}
		}
			#; The ROWTYPE metadata is completely and solely contained in pMetadata. Parameter and object metadata is contained in pParameters and pObjects
	#; TODO: routine parameters (formal args) are in pMetadata(0) at this point, as are objects. Maybe we need to extract?
		set pParameters = pParameters_$listbuild(+$get(pInfo("parameter")))
		for tPtr2 = 1:1:+$get(pInfo("parameter")) {
			set info = $get(pInfo("parameter",tPtr2,1))
			set pParameters = pParameters_$listbuild(+$piece(info,$char(1),2),+$piece(info,$char(1),4),+$piece(info,$char(1),5),+$piece(info,$char(1),6),$piece(pInfo("parameter",tPtr2),$char(1),1),$$$SQLPARAMINPUT)
		}
			#; There is always supposed to be a ("call","param",0) entry even if the called routine does not define a return value.
			#; If the statement contains a "? = call" then this array value is non-null, otherwise it is null.
			#; The intent is to provide a statement arg to routine arg binding list that is zero-relative, the first entry always corresponds to
			#; the return value.
		set tReturnValue = $Select($Data(pInfo("call","param",0)):1,1:0)
		set tPtr2 = $order(pInfo("call","param",""))
		while tPtr2 '= "" {
			if pInfo("call","param",tPtr2) '= "" {
				set tArg = $listget(pInfo("call","param",tPtr2),2)
					#; tParmBinding is an array subscripted by the statement parameter position and is equal to the
					#; corresponding routine parameter's position. If there is a return value then this is a "zero relative list"
					#; to allow for a return value (parm #0)
				if tArg { set $List(pActual,tPtr2+tReturnValue) = tArg }
			}
			set tPtr2 = $order(pInfo("call","param",tPtr2))
		}
		
	}
	kill:pMetadata(tPtr)="" pMetadata(tPtr)
	quit $$$OK
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
/// 
/// %SQL.StatementMetadata is a metadata class for dynamic statement metadata. The initial value is the metadata from a StatementCache object.
/// or it is the result set object itself.
/// 
/// pMetadata describes only the ROWTYPE metadata for a result set. Additional metadata is contained in pParameters and pObjects.
/// The non-ROWTYPE metadata is a single node for non-result columns (in pParameters) and a single node for object metadata (in pObjects).
Method %OnNew(pStatementType As %Integer = 0, ByRef pMetadata As %Binary = "", pParameters As %Binary = "", pObjects As %Binary = "", pArguments As %Binary = "", pActualBinding As %List = "", pDynamic As %List = "") As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	try {
		if pArguments '= "" { for tPtr = 1:2:$ListLength(pArguments) { if $List(pArguments,tPtr) = "?" { set tActualParameter(tPtr\2+1) = 1 } } }
		set ..statementType = pStatementType
		if $Data(pMetadata) > 2 { set tMetadata = pMetadata(0) }
		else { set tMetadata = pMetadata }
		set tSub = 0, tEndPtr = $ListLength(tMetadata)
		if pStatementType = 45 {
			set ..interface = $ListGet(tMetadata)
			if ..interface = 1 {
				set tColumns = $ListGet(tMetadata,2)
				set tElementPtr = 3
			}
			else { set tColumns = 0, tElementPtr = 2 }
				#; If the called routine does not define a return value, then remove the return value place holder
				#; from the argument binding.
			if $zabs(..interface) '= 2 { set pActualBinding = $List(pActualBinding,2,*) }
		}
		elseif ",1,80,"[(","_pStatementType_",") { set tColumns = $ListGet(tMetadata,1), tElementPtr = 2 } // SELECT or THROUGH
		else { set tColumns = 0, tElementPtr = 1 }
			#; first, get the column count
		set tElements = 10
		for tPtr = 1:1:tColumns {
			if tElementPtr > tEndPtr { set tMetadata = $Get(pMetadata($Increment(tSub))), tElementPtr = 1, tEndPtr = $ListLength(tMetadata)
				if tElementPtr > tEndPtr { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"SQL statement Metadata incomplete")) }
			}
			set tSerial = $List(tMetadata,tElementPtr,tElementPtr + 8)
			set tBstr = $List(tMetadata,tElementPtr + 9)
			for tPtr2 = 1:1:$Length(tBstr)-1 { set tSerial = tSerial _ $ListBuild($Ascii(tBstr,tPtr2)) }
			set tColumn = $List(tSerial), ..columnIndex($$$ucase(tColumn)) = $ListBuild($Increment(tColumnNbr),tColumn)
				//     property              typeclass              clienttype
			set tDynamic=$lg(pDynamic,tPtr) if tDynamic'="" set $list(tSerial,22,25)=$list(tDynamic,1,3)_$lb($ascii(tBstr,13))  // piece 25 is 'isList'
			do ..columns.InsertObject($$$oidForm(tSerial))
			set tElementPtr = tElementPtr + tElements
		}
		set i%columnCount = tColumns
		set tParameters = $ListGet(tMetadata,tElementPtr)
		if tParameters {
			set tElementPtr = tElementPtr + 1
		}
		else {
			set tMetadata = pParameters
			set tParameters = $ListGet(tMetadata,1)
			set tElementPtr = 2, tEndPtr = $ListLength(tMetadata)
		}
		set tElements = 6
		for tPtr = 1:1:tParameters {
			if tElementPtr > tEndPtr { set tMetadata = $Get(pMetadata($Increment(tSub))), tElementPtr = 1, tEndPtr = $ListLength(tMetadata)
				if tElementPtr > tEndPtr { throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"SQL statement Metadata incomplete")) }
			}
			set tSerial = $List(tMetadata,tElementPtr,tElementPtr + tElements)
			do ..formalParameters.InsertObject($$$oidForm(tSerial))
				#; If this formal argument appears in the statement as an actual argument then insert this parameter definition in
				#; the actual parameters (statement parameters). For CALL, the statement doesn't define the formal arguments, the definition
				#; of the SQL routine has that definition. The statement specification can ignore a formal parameter (missing parameters) so a
				#; binding map is needed to match statement parameters with formal parameters. For non-CALL statements, there can only be a
				#; bound statement parameter or a literal (we don't support host vars).
			if (pStatementType '= 45) { if $Get(tActualParameter(tPtr)) { do ..parameters.InsertObject($$$oidForm(tSerial)) } }
			elseif ($ListGet(pActualBinding,tPtr)) && ($Get(tActualParameter($List(pActualBinding,tPtr)))) { do ..parameters.InsertObject($$$oidForm(tSerial)) }
			set tElementPtr = tElementPtr + tElements
		}
		set i%parameterCount = ..parameters.Count()
		set tCount = $ListLength(pObjects)
		for tPtr = 1:1:tCount { do ..objects.InsertObject($$$oidForm($List(pObjects,tPtr))) }
		set tStatus = $$$OK
	}
	catch tException {
		set tStatus = tException.AsStatus()
	}
	Quit tStatus
}

/// This method serializes the parameter collection as a metadata string in xDBC format.
Method getParameterMetadata() As %List [ Internal ]
{
	set tParameterCount = ..parameters.Count()
	set tParameters = $Listbuild(tParameterCount)
	for tPtr = 1:1:tParameterCount { set tParameters = tParameters _ ..parameters.GetObjectIdAt(tPtr) }
	quit tParameters
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
		write ?23,$case(tColumn.scale,"":" null",:$Justify(tColumn.scale,5,0))
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
	write ?5,"       12:RowId,13:isList",!!
	write "Column Name",?23,"Linked Prop",?45,"Type Class",?67,"Flags",!
	write "----------------------",?23,"---------------------",?45,"---------------------",?67,"-------------",!
	set tCount = ..columns.Count()
	for i=1:1:tCount {
		set tColumn = ..columns.GetAt(i)
		write tColumn.colName
		if $Length(tColumn.colName) > 22 { write ! }
		set tColumnProperty = tColumn.propertyGetObjectId()
		write:tColumnProperty'="" ?23,$Piece(tColumnProperty,"||",1),".",$Piece(tColumnProperty,"||",2)
		if $Length(tColumnProperty) > 20 { write ! }
		write ?45,tColumn.typeClassGetObjectId()
		if $Length(tColumn.typeClassGetObjectId()) > 20 { write ! }
		write ?67,$Select(tColumn.isAutoIncrement:"Y",1:"N")
		write $Select(tColumn.isCaseSensitive:"Y",1:"N")
		write $Select(tColumn.isCurrency:"Y",1:"N")
		write $Select(tColumn.isReadOnly:"Y",1:"N")
		write $Select(tColumn.isRowVersion:"Y",1:"N")
		write $Select(tColumn.isUnique:"Y",1:"N")
		write $Select(tColumn.isAliased:"Y",1:"N")
		write $Select(tColumn.isExpression:"Y",1:"N")
		write $Select(tColumn.isHidden:"Y",1:"N")
		write $Select(tColumn.isIdentity:"Y",1:"N")
		write $Select(tColumn.isKeyColumn:"Y",1:"N")
		write $Select(tColumn.isRowId:"Y",1:"N")
		write $Select(tColumn.isList:"Y",1:"N"),!
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
	write !!,"Formal Parameters (property 'formalParameters'): ",!!
	write "Nbr. Type precision scale nullable colName      columntype",!
	write "---- ---- --------- ----- -------- ------------ ----------",!
	set tCount = ..formalParameters.Count()
	for tPtr = 1:1:tCount {
		set tParameter = ..formalParameters.GetAt(tPtr)
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
		write $Justify(tObject.column,3)
		write ?4,tObject.columnName
		if $Length(tObject.columnName) > 12 { write ! }
		write ?16,tObject.extentName
		if $Length(tObject.extentName) > 18 { write ! }
		set tExportCall = $Piece(tObject.exportCall,"(",1,2)
		write ?34,$Extract(tExportCall,1,42),$Select($Length(tExportCall)>42:"...",1:""),!
	}
	quit $$$OK
}

Method printMetadata(pMetadata As %RawString) As %Status
{
	set tCount = $List(pMetadata), tElements = 10
	for tPtr = 2:tElements:(tCount*tElements + 1) {
		for tPtr2 = tPtr:1:tPtr + 8 { write $List(pMetadata,tPtr2),$Char(9) }
		if tElements > 9 { set tBstr = $List(pMetadata,tPtr + 9) for tPtr2 = 1:1:$Length(tBstr)-1 { write $Ascii(tBstr,tPtr2),$Char(9) } write $Ascii(tBstr,$Length(tBstr)),! }
	}
	quit $$$OK
}

Method GenerateRowType() As %Library.String(MAXLEN="") [ Internal, ServerOnly = 1 ]
{
#dim tColumn as %SQL.StatementColumn
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
