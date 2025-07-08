/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.modelling.TableGenerator Extends Base [ System = 4 ]
{

Property config As %DeepSee.extensions.modelling.conf.Table;

Property AttrRS As %IResultSet;

Property AttrValueList As %List;

Property AttrDisplayList As %List;

Property AttrTypeList As %List;

Property AttrArray [ MultiDimensional ];

Method setConfig(conf As %DeepSee.extensions.modelling.conf.Table) As %Status
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

Method setAttrResultSet(rs As %IResultSet) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..AttrRS = rs
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method setAttrList(valueList As %List, displayList As %List = "") As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set ..AttrValueList = valueList
		set ..AttrDisplayList = displayList
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method setAttrListFromConfig() As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim vList, dList As %String
	#dim i, n1, n2, n3
	
	Try {
		set vList = $zstrip(..config.Attributes.ValueList,"<>W")
		set vList = $zstrip(vList,"*C")
		if ($match(vList,"[0-9]+:[0-9]+:[0-9]+")) {
			set n1 = $p(vList,":",1)
			set n2 = $p(vList,":",2)
			set n3 = $p(vList,":",3)
			set vList = ""
			for i = n1:n2:n3 {
				set vList = vList_$lb(i)
			}
			set sc = ..setAttrList(vList)
			Quit
		}
		
		set dList = $zstrip(..config.Attributes.DisplayList,"<>W")
		set dList = $zstrip(dList,"*C")
		set sc = ..setAttrList($lfs(vList),$lfs(dList))
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method setAttrArray(ByRef array) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		k ..AttrArray
		m ..AttrArray = array
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method apply() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set sc = ..genClassifierTable()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method genClassifierTable() As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim classDef As %Dictionary.ClassDefinition
	
	#dim className, tableName As %String;
	
	#dim dim As %Integer
	
	Try {
		set className = ..config.ClassName

		set sc = ..createNewClass(className, .classDef)
		Quit:$$$ISERR(sc)

		set sc = ..genAttributes(classDef, .dim)
		Quit:$$$ISERR(sc)

		set sc = ..genClassifierTableBody(classDef, dim)
		Quit:$$$ISERR(sc)

		set sc = ##class(%iKnow.Objects.dd.Builder).TableName(className, .tableName)
		Quit:$$$ISERR(sc)
		
		if (##class(%DeepSee.extensions.components.PCA).%ExistsId(tableName)) {
			set sc = ##class(%DeepSee.extensions.components.PCA).%DeleteId(tableName)
			Quit:$$$ISERR(sc)
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method genAttributes(classDef As %Dictionary.ClassDefinition, Output dim As %Integer) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim keywords, sql, sortColumn As %String;
	#dim i, count As %Integer
	#dim attr As %DeepSee.extensions.modelling.conf.Attributes
	
	#dim key, v As %String
	#dim sortValue

	Try {
		set sortColumn = ""
		set sortValue  = ""
		set attr = ..config.Attributes
		if (attr.input = "$list") {
			if (..AttrValueList = "") {
				set sc = ..setAttrListFromConfig()
				Quit:$$$ISERR(sc)
			}
			if (..AttrValueList = "") {
				set sc = $$$ERROR($$$GeneralError,"Attribute Value List is undefined")
				Quit
			}
			set dim = $ll(..AttrValueList)
		} elseif (attr.input = "array") {
			if ($d(..AttrArray) < 10) {
				set sc = $$$ERROR($$$GeneralError,"Attribute Value Array is undefined")
				Quit
			}
			set ..AttrValueList = ""
			set ..AttrDisplayList = ""
			set key = $o(..AttrArray(""),1,v)
			set i = 0
			While (key '= "") {
				set ..AttrValueList = ..AttrValueList_$lb(key)
				set ..AttrDisplayList = ..AttrDisplayList_$lb($g(v))
				if ($g(v) '= "") {
					set i = $i(i)
				}
				set key = $o(..AttrArray(key),1,v)
			}
			if (i = 0) {
				set ..AttrDisplayList = ""
			}
			set dim = $ll(..AttrValueList)
		} else {
			set sortColumn = attr.Sort.column
			set dim = attr.dim
			if (attr.input = "ResultSet") {
				if (..AttrRS = "") {
					set sc = $$$ERROR($$$GeneralError,"Attribute Result Set is undefined")
					Quit
				}
			} else {
				if (attr.input = "table") {
					set sql = "select top "_dim_" "_attr.IdColumn
					if (attr.ValueColumn '= "") {
						set sql = sql_", "_attr.ValueColumn
					}
					if (attr.TypeColumn '= "") {
						set sql = sql_", "_attr.TypeColumn
					}
					if (sortColumn '= "") {
						set sql = sql_", "_sortColumn
					}
					set sql = sql_" from "_attr.InputTable
					set sql = sql_" order by "_attr.Sort.toSQL()
				} elseif (attr.input = "sql") {
					set sql = attr.SQL
				} else {
					break
					set sc = $$$ERROR($$$GeneralError,"Unrecognized Attribute Input Type: "_attr.input)
					Quit
				}
				
				w sql, !
				set stmt = ##class(%SQL.Statement).%New()
				set sc = stmt.%Prepare(sql)
				Quit:$$$ISERR(sc)
				
				set ..AttrRS = stmt.%Execute()
			}
			
			set ..AttrValueList = ""
			set ..AttrDisplayList = ""
			set i = 0
			While (..AttrRS.%Next()) {
				set key = ..AttrRS.%Get(attr.IdColumn)
				set ..AttrValueList = ..AttrValueList_$lb(key)
				if (attr.ValueColumn '= "") {
					set v = ..AttrRS.%Get(attr.ValueColumn)
					set ..AttrDisplayList = ..AttrDisplayList_$lb($g(v))
				}
				if (attr.TypeColumn '= "") {
					set v = ..AttrRS.%Get(attr.TypeColumn)
					set ..AttrTypeList = ..AttrTypeList_$lb($g(v))
				}
				if (sortColumn '= "") {
					set sortValue = ..AttrRS.%Get(sortColumn)
				}
				
				set i = $i(i)
				if (i >= dim) {
					Quit
				}
			}
			
			d ..AttrRS.%Close()
		}

		if ('$ISVALIDNUM(dim)) {
			set sc = $$$ERROR($$$GeneralError,"Invalid attributes dimension: """_dim_"""; must be an %Integer")
			Quit
		}

		set keywords = $lts(..AttrValueList)		
		set count = $l(keywords,",")

		set sc = ..addParameter(classDef, "Attributes", "STRING", keywords)
		Quit:$$$ISERR(sc)
		
		if (..AttrDisplayList '= "") {
			set keywords = $lts(..AttrDisplayList)		
			set sc = ..addParameter(classDef, "AttributeValues", "STRING", keywords)
			Quit:$$$ISERR(sc)
		}

		set sc = ..addParameter(classDef, "Dim1", "STRING", count)
		Quit:$$$ISERR(sc)

		w "Using "_count_" keywords out of "_dim_" possible."
		if (sortColumn '= "") {
			w " The boundary "_sortColumn_" is: "_sortValue
		}
		w !
		set dim = count

		set sc = ..addParameter(classDef, "Dim", "INTEGER", dim)
		Quit:$$$ISERR(sc)

		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method genClassifierTableBody(classDef As %Dictionary.ClassDefinition, dim As %Integer) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim tableName As %String;
	
	#dim i As %Integer
	#dim type As %String
	
	Try {
		
		set sc = ..addXData(classDef, "Table", ..config)
		Quit:$$$ISERR(sc)

		set sc = ..addProperty(classDef, "Total", "%Integer")
		Quit:$$$ISERR(sc)

		set sc = ..addProperty(classDef, "Instance", ..config.InstanceType)
		Quit:$$$ISERR(sc)
		
		set sc = ..addIndex(classDef, "InstanceIdx", "Instance", 1, 1, 0)
		Quit:$$$ISERR(sc)
		
		set type = ..config.OutcomeType
		if (..config.hasOutcome) {
			set sc = ..addProperty(classDef, ..config.OutcomeColumn, type,,,,1)
			Quit:$$$ISERR(sc)
			if (type = "%Double")  {
				set sc = ..addIndex(classDef, "OutcomeIdx", "Outcome", 0, 0, 0)
			} else {
				set sc = ..addIndex(classDef, "OutcomeIdx", "Outcome", 0, 0, 1)
			}
			Quit:$$$ISERR(sc)
			
			// BDB473 - update PMML definition
			do ..AddPMMLDataField("Outcome", type, $s(type="%String":"categorical", 1:"continuous"))
		}
		
		//set sc = ..addParameter(classDef, "MDKey", "STRING", model.MDField)
		Quit:$$$ISERR(sc)

		set tDefaultType = ..config.Attributes.Type
		for i=1:1:dim {
			set tType = $lg(..AttrTypeList,i)
			set:tType="" tType = tDefaultType
			set sc = ..addProperty(classDef, ..ClassifierPropName(i), tType,,,,,, $case(tType, "%Integer":0, "%Double":0, :""))
			Quit:$$$ISERR(sc)
			
			// BDB473 - update PMML definition
			do ..AddPMMLDataField(..ClassifierPropName(i), tType, "continuous", $lg(..AttrDisplayList,i))
		}
		Quit:$$$ISERR(sc)
		
		for i=1:1:..config.MaxPC {
			set sc = ..addProperty(classDef, ..ClassifierPCName(i), "%Double")
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
		
		set sc = ..compile(classDef, .tableName)
		Quit:$$$ISERR(sc)

		//set classifier.ClassifierTable = tableName
		
		// BDB473 - append DataSource element
		set tDataSource = ##class(%DeepSee.PMML.Definition.Extension.SQLDataSource).%New()
		set tDataSource.name = "Full dataset"
		set tDataSource.description = "Automatically generated by "_$classname()
		set tDataSource.SQL = "SELECT * FROM "_tableName
		set tExtension = ##class(%DeepSee.PMML.Definition.Extension).%New()
		set tExtension.name = "isc:datasource"
		do tExtension.iscExtensions.Insert(tDataSource)
		do ..PMML.DataDictionary.Extension.Insert(tExtension)
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

Method AddPMMLDataField(pName As %String, pDataType As %String, pOptype As %String = "continuous", pDisplayName As %String = "") As %Status
{
	set tDataField = ##class(%DeepSee.PMML.Definition.DataField).%New()
	set tDataField.name = pName
	set tDataField.dataType = $case(pDataType, :$$$LOWER($translate(pDataType,"%","")))
	set tDataField.optype = pOptype
	set:pDisplayName'="" tDataField.displayName = pDisplayName
	do ..PMML.DataDictionary.AddField(tDataField)
	quit $$$OK
}

ClassMethod createNewClass(className As %String, Output classDef As %Dictionary.ClassDefinition) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = ..deleteIfExists(className)
		Quit:$$$ISERR(sc)

		set classDef = ##class(%Dictionary.ClassDefinition).%New()
		set classDef.Name = className
		set classDef.Super = "%Persistent"

	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod deleteIfExists(className As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		if (##class(%Dictionary.ClassDefinition).%ExistsId(className)) {
			if (##class(%Dictionary.CompiledClass).%ExistsId(className)) {
				Try {
					set cDef = ##class(%Dictionary.CompiledClass).%OpenId(className,,.sc)
					Quit:$$$ISERR(sc)
					
					if ($zcvt(cDef.ClassType,"l") [ "persistent") {
						set sc = $classmethod(className,"%KillExtent")
					}
				} Catch(ex) {
					set sc = ex.AsStatus()
				}
				if ($$$ISERR(sc)) {
					if ($system.Status.GetErrorCodes(sc) = 5002) {
						d $system.OBJ.DisplayError(sc)
						set sc = $$$OK
					} else {
						Quit
					}
				}
			}
			set sc = $system.OBJ.Delete(className)
			Quit:$$$ISERR(sc)
			w !
		}
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod relate(parent As %String, child As %String, pProp As %String, cProp As %String, idx As %Boolean) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set pDef = ##class(%Dictionary.ClassDefinition).%OpenId(parent)
		set cDef = ##class(%Dictionary.ClassDefinition).%OpenId(child)
		
		set propDef = ##class(%Dictionary.PropertyDefinition).%New()
		set propDef.parent = pDef
		set propDef.Name = pProp
		set propDef.Type = child
		set propDef.Relationship = 1
		set propDef.Cardinality = "many"
		set propDef.Inverse = cProp
		
		set sc = propDef.%Save()
		Quit:$$$ISERR(sc)
		
		set propDef = ##class(%Dictionary.PropertyDefinition).%New()
		set propDef.parent = cDef
		set propDef.Name = cProp
		set propDef.Type = parent
		set propDef.Relationship = 1
		set propDef.Cardinality = "one"
		set propDef.Inverse = pProp
		
		set sc = propDef.%Save()
		Quit:$$$ISERR(sc)

		if (idx) {
			set sc = ..addIndex(cDef, cProp_"Idx", cProp)
			Quit:$$$ISERR(sc)
		}

		set sc = $system.OBJ.Compile(parent_","_child)
		Quit:$$$ISERR(sc)
	}Catch(ex){
		set sc = ex.AsStatus()
	}
	
	//break:$$$ISERR(sc)
	
	Quit sc
}

ClassMethod addProperty(classDef As %Dictionary.ClassDefinition, name As %String, type As %String, maxlen As %Integer = 0, collation As %String = "", valuelist As %String = "", isRequired As %Boolean = 0, Output propDef As %Dictionary.PropertyDefinition, pDefaultValue As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set propDef = ##class(%Dictionary.PropertyDefinition).%New()
		set propDef.parent = classDef
		set propDef.Name = name
		set propDef.Type = type
		
		if (maxlen > 0) {
			d propDef.Parameters.SetAt(maxlen,"MAXLEN")
		}
		if (maxlen < 0) {
			set maxlen = -maxlen
			d propDef.Parameters.SetAt(maxlen,"MAXLEN")
			d propDef.Parameters.SetAt(1,"TRUNCATE")
		}
		if (collation '= "") {
			d propDef.Parameters.SetAt(collation,"COLLATION")
		}
		if (valuelist '= "") {
			d propDef.Parameters.SetAt(valuelist,"VALUELIST")
		}
		
		if (isRequired) {
			set propDef.Required = isRequired
		}
		
		if (pDefaultValue'="") {
			set propDef.InitialExpression = pDefaultValue
		}
			
		set sc = propDef.%Save()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod addCollection(classDef As %Dictionary.ClassDefinition, name As %String, type As %String, ctype As %String, storage As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set propDef = ##class(%Dictionary.PropertyDefinition).%New()
		set propDef.parent = classDef
		set propDef.Name = name
		set propDef.Type = type
		set propDef.Collection = ctype

		if (storage '= "") {
			d propDef.Parameters.SetAt(storage,"STORAGEDEFAULT")
		}
		
		set sc = propDef.%Save()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod addMethod(classDef As %Dictionary.ClassDefinition, name As %String, type As %String, plist As %String, code As %List, static As %Boolean = 0) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim i, n As %Integer
	//#dim line As %String

	Try {
		set mDef = ##class(%Dictionary.MethodDefinition).%New()
		set mDef.parent = classDef
		set mDef.Name = name
		set mDef.ReturnType = type
		set mDef.ClassMethod = static
		
		set n = $ll(code)
		for i = 1:1:n {
			set sc = mDef.Implementation.WriteLine($li(code,i))
			Quit:$$$ISERR(sc)
		}
		Quit:$$$ISERR(sc)
		set mDef.FormalSpec = plist
			
		set sc = mDef.%Save()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod addCompProperty(classDef As %Dictionary.ClassDefinition, name As %String, type As %String, code As %String, collation As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set propDef = ##class(%Dictionary.PropertyDefinition).%New()
		set propDef.parent = classDef
		set propDef.Name = name
		set propDef.Type = type
		set propDef.Calculated = 1
		set propDef.SqlComputed = 1
		set propDef.SqlComputeCode = code
		
		if (name [ "_") {
			set propDef.Name = $tr(name,"_")
			set propDef.SqlFieldName = name
		}
		
		if (collation '= "") {
			d propDef.Parameters.SetAt(collation,"COLLATION")
		}
			
		set sc = propDef.%Save()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod addXData(classDef As %Dictionary.ClassDefinition, name As %String, content As %XML.Adaptor) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim stream As %Stream.TmpCharacter

	Try {
		set xData = ##class(%Dictionary.XDataDefinition).%New()
		set xData.parent = classDef
		set xData.Name = name
		
		set stream = xData.Data
		set sc = content.XMLExportToStream(.stream)
		Quit:$$$ISERR(sc)	
		
		set sc = xData.%Save()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod addParameter(classDef As %Dictionary.ClassDefinition, name As %String, type As %String, value As %String) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set propDef = ##class(%Dictionary.ParameterDefinition).%New()
		set propDef.parent = classDef
		set propDef.Name = name
		set propDef.Type = type
		set propDef.Default = value
			
		set sc = propDef.%Save()
		Quit:$$$ISERR(sc)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod addIndex(classDef As %Dictionary.ClassDefinition, name As %String, properties As %String, isUnique As %Boolean = 0, isPK As %Boolean = 0, isBitmap As %Boolean = 0) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set indexDef = ##class(%Dictionary.IndexDefinition).%New()
		set indexDef.Name = name
		set indexDef.PrimaryKey = isPK
		set indexDef.Unique = isUnique
		if (isBitmap) {
			set indexDef.Type = "bitmap"
		}
		set indexDef.Properties = properties
		set indexDef.parent = classDef
		
		set sc = indexDef.%Save()
		Quit:$$$ISERR(sc)
			
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod addIDKey(classDef As %Dictionary.ClassDefinition, name As %String, properties As %String) As %Status
{
	#dim sc As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set indexDef = ##class(%Dictionary.IndexDefinition).%New()
		set indexDef.Name = name
		set indexDef.IdKey = 1
		set indexDef.Unique = 1
		set indexDef.Properties = properties
		set indexDef.parent = classDef
		
		set sc = indexDef.%Save()
		Quit:$$$ISERR(sc)
			
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod compile(classDef As %Dictionary.ClassDefinition, Output tableName As %String, flags As %String = "") As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		set sc = classDef.%Save()
		Quit:$$$ISERR(sc)

		if (flags '= "") {
			set sc = $system.OBJ.Compile(classDef.Name, flags)
		} else {
			set sc = $system.OBJ.Compile(classDef.Name)
		}
		Quit:$$$ISERR(sc)
		
		set cDef = ##class(%Dictionary.CompiledClass).%OpenId(classDef.Name)
		set tableName = cDef.SqlSchemaName_"."_cDef.SqlTableName
		
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod dts(ts1 As %TimeStamp, ts2 As %TimeStamp) As %Double
{
	Quit ($p(ts2,",",2) - $p(ts1,",",2)) + (86400*($p(ts2,",",1) - $p(ts1,",",1)))
}

ClassMethod TableName(className As %String, Output tableName As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		set clsDef = ##class(%Dictionary.CompiledClass).%OpenId(className,,.sc)
		Quit:$$$ISERR(sc)
		
		set tableName = clsDef.SqlSchemaName_"."_clsDef.SqlTableName
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod getType(class As %String, column As %String, Output type As %String)
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	#dim i, n As %Integer
	#dim p, t As %String

	Try {
		set type = ""
		if (##class(%Dictionary.CompiledProperty).%ExistsId(class_"||"_column)) {
			set rpDef = ##class(%Dictionary.CompiledProperty).%OpenId(class_"||"_column,,.sc)
			Quit:$$$ISERR(sc)
			set type = rpDef.Type
			Quit
		} 
		
		set n = $l(column,"_")
		if (n <2) {
			set type = "%String"
			Quit
		}
		
		for i = 1:1:n {
			set p = $p(column,"_",i)
			if ('##class(%Dictionary.CompiledProperty).%ExistsId(class_"||"_p)) {
				Quit
			}
			
			set rpDef = ##class(%Dictionary.CompiledProperty).%OpenId(class_"||"_p,,.sc)
			Quit:$$$ISERR(sc)
			
			if (i < n) {
				set class = rpDef.Type
			} else {
				set type = rpDef.Type
			}
		}
		Quit:$$$ISERR(sc)
		
		if (type = "") {
			set type = "%String"
		}
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
		
	Quit sc
}

ClassMethod idColumn(class As %String, Output sc As %Status) As %String
{
	#dim ex As %Exception.AbstractException
	#dim id As %String = ""

	set sc = $$$OK
	Try {
		d ##class(%Dictionary.ClassDefinition).%OpenId(class,,.sc)
		Quit:$$$ISERR(sc)
	
		set id = $$$EXTPROPsqlcolumnname($$$pEXT,class,"%%ID")
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
		
	Quit id
}

ClassMethod propertyName(name As %String) As %String
{
	if ($zname(name,6)) {
		Quit name
	}
	
	set name = $zstrip(name,"*PC")
	
	Quit name
}

ClassMethod bestKey(class As %String, Output column As %String, Output id1 As %String) As %Status
{
	#dim sc 	As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim i, n As %Integer
	#dim iDef As %Dictionary.CompiledIndex

	Try {
		set column = ""
		
		set cDef = ##class(%Dictionary.CompiledClass).%OpenId(class,,.sc)
		Quit:$$$ISERR(sc)
		
		set n = cDef.Indices.Count()
		for i = 1:1:n {
			set iDef = cDef.Indices.GetAt(i)
			if (iDef.IdKey || iDef.PrimaryKey) {
				if (iDef.Properties = "") {
					Continue
				}
				if ($l(iDef.Properties,",") > 1) {
					Continue
				}
				set column = iDef.Properties
				Quit
			}
		}
		
		set id1 = ..idColumn(class)
	} Catch(ex) {
		set sc = ex.AsStatus()
	}
		
	Quit sc
}

}
