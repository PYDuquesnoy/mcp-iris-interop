/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.ReadSequence Extends Base [ System = 4 ]
{

Property config As %DeepSee.extensions.modelling.conf.Sequence;

Property RS As %IResultSet;

Method setConfig(conf As %DeepSee.extensions.modelling.conf.Sequence) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..config = conf
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method setResultSet(rs As %IResultSet) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..RS = rs
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method populate() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim idCol, attrCol, vCol, outColIn, outColOut, table As %String
	#dim attrs As %List
	#dim curId, id, a, v As %String
	
	#dim tIdx, count, count1 As %Integer
	#dim tableConfig As %DeepSee.extensions.modelling.conf.Table
	
	#dim row
	#dim map
	
	Try {
		set map = ""
		set idCol 	= ..config.InstanceIdColumn
		set attrCol = ..config.AttributeValuesColumn
		set vCol 	= ..config.CorrespondenceColumn
		set outColIn= ..config.OutcomeColumn
		set tInsertOnly = ..config.InsertOnly

		// BDB: not in use?
		//set sc = ##class(Processor).readConfig(..config.OutputClass, "Table", "Table", .tableConfig)
		//Quit:$$$ISERR(sc)

		set sc = ..GetAttributeList(..config.OutputClass, .attrs)
		Quit:$$$ISERR(sc)
		
		set sc = ..PrepareRS(attrs, .idCol, .attrCol, .vCol, .outColIn, .outColOut)
		Quit:$$$ISERR(sc)
		
		if (..config.CorrespondenceType = "contrib") {
			if (..config.type = "table") {
				set sc = ..getFk(..config.InputTable, attrCol, attrs, .map)
				Quit:$$$ISERR(sc)
			}
		}
		
		do:tInsertOnly $classmethod(..config.OutputClass, "%SortBegin")

		set curId = ""
		set count = 0
		set count1 = 0
		While(..RS.%Next()) {
			set a = ..RS.%Get(attrCol)
			set tIdx = $lf(attrs, a)
			if (tIdx = 0) {
				if (..config.IgnoreInvalidAttributes) {
					Continue
				}
				set sc = $$$ERROR($$$GeneralError,"Invalid Attribute: "_a)
				Quit
			}
			
			set id = ..RS.%Get(idCol)
			if (curId = "") {
				set curId = id
				set sc = ..newRow(id, .row)
				Quit:$$$ISERR(sc)
			} elseif (id '= curId) {
				set sc = row.%Save()
				Quit:$$$ISERR(sc)
				
				set count = $i(count)
				
				if ((count#100) = 0) {
					w count_" Records Saved. Number of ones: "_count1, !
				}
				
				if (tInsertOnly) {
					set sc = ..newRow(id, .row)
					Quit:$$$ISERR(sc)
				} else {
					set row = $classmethod(..config.OutputClass, "InstanceIdxOpen", id)
					if (row="") {
						set sc = ..newRow(id, .row)
						quit:$$$ISERR(sc)
					}
				}
				set curId = id
			}
			
			if (..config.CorrespondenceType = "spread") {
				set v = 1
			} else {
				set v = ..RS.%Get(vCol)
			}
			if (..config.CorrespondenceType = "frequency") {
				set v = v / ( v + 1)
			} elseif (..config.CorrespondenceType = "contrib") {
				if ($d(map) < 10) {
					set sc = $$$ERROR($$$GeneralError,"Map is undefined for CorrespondenceType = 'contrib'")
					Quit
				}
				//break
				set v = v / $zsqr(map(a))
			} 
			
			set $property(row,..ClassifierPropName(tIdx)) = v

			if (outColOut '= "") {
				set v = ..RS.%Get(outColIn)
				set $property(row,outColOut) = v
			}

			set count1 = $i(count1)
			set row.Total = row.Total + 1
		}
		Quit:$$$ISERR(sc)
		
		if (count = 0) {
			set sc = $$$ERROR($$$GeneralError,"No records have been found")
			Quit
		}
		
		set sc = row.%Save()
		Quit:$$$ISERR(sc)
		set count = $i(count)

		do:tInsertOnly $classmethod(..config.OutputClass, "%SortEnd")
		
		d ..RS.%Close()
		Quit:$$$ISERR(sc)

		W "Total: "_count_" Records Saved. "
		w ". Number of ones: "_count1, !

		set cDef = ##class(%Dictionary.CompiledClass).%OpenId(..config.OutputClass,,.sc)
		Quit:$$$ISERR(sc)
		set table = cDef.SqlSchemaName_"."_cDef.SqlTableName
		d $system.SQL.TuneTable(table,1)

	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method PrepareRS(attrs As %List, Output idCol As %String, Output attrCol As %String, Output vCol As %String, Output outColIn As %String, Output outColOut As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim table, sql, groupBy  As %String
	#dim tableConfig As %DeepSee.extensions.modelling.conf.Table
	
	Try {
		set outColOut = ""
		set sc = ##class(Processor).readConfig(..config.OutputClass, "Table", "Table", .tableConfig)
		if (outColIn '= "") {
			if ($$$ISERR(sc)) {
				set sc = $$$ERROR($$$GeneralError,"Can not determine outcome column in output table: "_$system.Status.GetErrorText(sc))
				Quit
			}
			
			set outColOut = tableConfig.OutcomeColumn
		}

		if (..config.type = "array") {
			set sc = $$$ERROR($$$GeneralError,"Not yet implemented")
			Quit
		} elseif (..config.type = "ResultSet") {
			if (..RS = "") {
				set sc = $$$ERROR($$$GeneralError,"Input Data Result Set is undefined")
				Quit
			}
		} else {
			if (..config.type = "sql") {
				set sql = ..config.SQL
			} elseif (..config.type = "table") {
				set table = ..config.InputTable
				set groupBy = idCol
				if ($zname(idCol,6)) {
					set sql = "select "_idCol_", "_attrCol
				} else {
					set sql = "select "_idCol_" as InstanceId, "_attrCol
					set idCol = "InstanceId"
				}
				if (..config.CorrespondenceType = "spread") {
					set sql = sql_", 1 as "_vCol
				} elseif (..config.CorrespondenceType = "frequency") {
					set sql = sql_", count(%ID) as "_vCol
				} elseif (..config.CorrespondenceType = "contrib") {
					set sql = sql_", count(%ID) as "_vCol
				}
				if (outColIn '= "") {
					set sql = sql_", "_outColIn
				} 
				set sql = sql_" from "_table
				set sql = sql_" where "_attrCol_" %INLIST ?"
				set sql = sql_" group by "_groupBy_", "_attrCol
				set sql = sql_" order by "_idCol
				
			} else {
				set sc = $$$ERROR($$$GeneralError,"Unrecognized Data Input Type: "_..config.type)
				Quit
			}
			
			w "SQL: "_sql, !
			set stmt = ##class(%SQL.Statement).%New()
			set sc = stmt.%Prepare(sql)
			Quit:$$$ISERR(sc)
			
			zw attrs
			w !
			if (stmt.%Metadata.parameterCount > 0) {
				set ..RS = stmt.%Execute(attrs)
			} else {
				set ..RS = stmt.%Execute()
			}
			if (..RS.%SQLCODE '= 0) {
				set sc = $$$ERROR(..RS.%SQLCODE, ..RS.%Message)
				Quit
			}
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method newRow(id As %String, Output row) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim i, n As %Integer
	
	Try {
		set row  = $classmethod(..config.OutputClass,"%New")
		d row.InstanceSetObjectId(id)
		set row.Total = 0
		set n = $parameter(row,"Dim")
		// BDB473: now taken care of by InitialExpressions for the individual attributes
		//for i = 1:1:n {
		//	set $property(row,..ClassifierPropName(i)) = 0
		//}
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method getFk(table As %String, col As %String, attrs As %List, Output map) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim i, n As %Integer
	#dim sql As %String
	#dim rs As %IResultSet
	
	Try {
		set sql = "select "_col_", count(%ID) from "_table
		set sql = sql_" where "_col_" %INLIST ? "
		set sql = sql_" group by "_col

		w "Get Frequencies for contrib: "_sql, !
		set stmt = ##class(%SQL.Statement).%New()
		set sc = stmt.%Prepare(sql)
		Quit:$$$ISERR(sc)
			
		set rs = stmt.%Execute(attrs)
		
		While (rs.%Next()) {
			set map(rs.%GetData(1)) = rs.%GetData(2)
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

}
