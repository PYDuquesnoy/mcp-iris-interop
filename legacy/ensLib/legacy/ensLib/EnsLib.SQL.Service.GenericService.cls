/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.SQL.Service.GenericService Extends Ens.BusinessService [ Language = objectscript ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter ADAPTER = "EnsLib.SQL.InboundAdapter";

Parameter SETTINGS = {"MessageClass:Data:selector?context={Ens.ContextSearch/MessageClasses?mode=request},TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},AllowTruncating:Data,OnlyWarnOnce:Alerting"};

/// Configuration items to which to send Documents
Property TargetConfigNames As %String(MAXLEN = 2000);

/// Message class to use in generating the request message. If this is set and the query returns a result set, query results will be set into the corresponding properties of the request message.
/// If no <property>MessageClass</property> is specified, then the request message will take the form of an Ens.StreamContainer message with the Stream property
/// containing a json string (eg. {"ID":"1","Name":"John Smith"})
Property MessageClass As %String(MAXLEN = 1000);

/// If the incoming data is longer than the MAXLEN of the property into which it is being set, truncate it to the MAXLEN.
/// If set to false, an error will be thrown when the incoming data exceeds the MAXLEN of its associated property. </br>
/// This is only relevant when <property>MessageClass</property> is set because json streams do  
Property AllowTruncating As %Boolean [ InitialExpression = 0 ];

/// Limit warnings about truncated data.</br>
/// Give a warning the first time the value for a property must be truncated, but do not repeat the warning if any subsequent messages also have that same property to be truncated.
/// This is only relevant when <property>AllowTruncating</property> is true and <property>ResponseClass</property> is set.
Property OnlyWarnOnce As %Boolean [ InitialExpression = 1 ];

Property %WarningsArray As %ArrayOfDataTypes [ Internal, Private, Transient ];

Method OnInit() As %Status
{
	#dim tSC as %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
	
		Set tSC=##super()
		Quit:$$$ISERR(tSC)
		
		// Target must be configured
		If ..TargetConfigNames="" {
			$$$LOGWARNING($$$Text("No Target Config Name configured"))
		}
		
		If ""=..MessageClass {
			$$$LOGINFO($$$Text("No Message Class set.  Using a dynamic object instead."))
		} ElseIf '##class(%Dictionary.CompiledClass).%ExistsId(..MessageClass)||'$classmethod(..MessageClass,"%Extends","%Library.Persistent") {
			$$$LOGWARNING($$$FormatText($$$Text("No persistent class '%1' defined.  Using a dynamic object instead."),..MessageClass))
			Set ..MessageClass = ""
		}
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
		
	Quit tSC
}

/// pInput is an EnsLib.SQL.Snapshot
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	Try {
		#dim tColCount As %Integer = $Select($IsObject(pInput)&&pInput.RowCount:pInput.ColCount,1:0)
		#dim tColumn,tMaxLen As %Integer
		#dim tColName,tVal As %String = ""
		#dim msg As %Library.Persistent
		#dim tIsFuncProc As %Boolean = 0
		
		If ..Adapter.%Extends("EnsLib.SQL.InboundProcAdapter") && $IsObject(..Adapter.%CurrParams) && ..Adapter.%CurrParams.Size {
			#; SQL Procedure - %CurrParams is a %ListOfDataTypes containing function parameters
			#dim tCount As %Integer
			#dim tParamName As %String = ""
			#dim tOutputParmsNames As %String = ..Adapter.OutputParamNames
			Set tIsFuncProc = 1
		}
		
		If (..MessageClass="") {
			#dim tObj As %DynamicObject = ##class(%DynamicObject).%New()
			#dim tStream As %Stream.GlobalBinary = ##class(%Stream.GlobalBinary).%New()
		
			For tColumn=1:1:tColCount {
				Set tColName = pInput.GetColumnName(tColumn)
				If pInput.GetColumnIsLOB(tColumn) {
					Set tStreamData = ##class(%Stream.GlobalBinary).%New()
					Do pInput.GetStream(tColName,.tStreamData)
					If tStreamData.Size > 0 {
						Do tObj.%Set(tColName,tStreamData,"stream")
					}
				} Else {
					Set tVal = pInput.GetData(tColumn)
					Do tObj.%Set(tColName,tVal)
				}
			}
			
			If tIsFuncProc {
				#; Add output parameters
				For tCount=1:1:..Adapter.%CurrParams.Size {
					Set tParamName = $S(""=tOutputParmsNames:"Parameter_"_tCount,1:$P(tOutputParmsNames,",",tCount))
					Continue:(""=tParamName)
					Set tVal = ..Adapter.%CurrParams.GetAt(tCount)
					If ($IsObject(tVal) && tVal.%Extends("%Stream.Object")) {
						#; Skip any empty streams
						Continue:('tVal.Size)
						Do tObj.%Set(tParamName,tVal,"stream")
					} Else {
						#; Skip any parameters for which return "value" is null character
						Continue:(""=$zstrip(tVal,"*C"))
						Do tObj.%Set(tParamName,tVal)
					}
				}
			}
			
			Do tObj.%ToJSON(.tStream)
			
			Set msg = ##class(Ens.StreamContainer).%New()
			Set msg.Stream = tStream
		} Else {
			Set msg = $classmethod(..MessageClass,"%New")
			For tColumn=1:1:tColCount {
				Set tColName = pInput.GetColumnName(tColumn)
				If $$$defMemberDefined(..MessageClass,$$$cCLASSproperty,tColName) {
					Try {
						Set tDataType = $$$defMemberKeyGet(..MessageClass,$$$cCLASSproperty,tColName,$$$cPROPtype)
						Set:(""=tDataType) tDataType = "%String"
						If $classmethod(tDataType,"%Extends","%Stream.Object") {
							If pInput.GetColumnIsLOB(tColumn) {
								Set tStreamData = ##class(%Stream.GlobalBinary).%New()
								Do pInput.GetStream(tColName,.tStreamData)
								Continue:('tStreamData.Size)
								Set tSC = $method($Property(msg,tColName),"CopyFrom",.tStreamData)
								Quit:$$$ISERR(tSC)
							} Else {
								Set tVal = pInput.GetData(tColumn)
								Do $method($Property(msg,tColName),"Write",tVal)
							}
						} Else {
							If pInput.GetColumnIsLOB(tColumn) {
								Set tStreamData = ##class(%Stream.GlobalBinary).%New()
								Do pInput.GetStream(tColName,.tStreamData)
								Continue:('tStreamData.Size)
								Set tVal = tStreamData.Read()
							} Else {
								Set tVal = pInput.GetData(tColumn)
							}
							#; Convert value from ODBC representation to logical if relevant
							If ($E(tDataType)="%") && '##class(%Dictionary.ClassDefinition).%ExistsId(tDataType) {
								Set tDataType = "%Library."_$E(tDataType,2,*)
							}
							If $$$defMemberDefined(tDataType,$$$cCLASSmethod,"OdbcToLogical") {
								Set tVal = $classmethod(tDataType,"OdbcToLogical",tVal)
							}
							#; Make sure that the value conforms to property's MAXLEN restriction - mostly important when original data was a stream
							Set tMaxLen = $$$comMemberArrayGet(..MessageClass,$$$cCLASSproperty,tColName,$$$cPROPparameter,"MAXLEN")
							If (+tMaxLen > 0) && ($L(tVal) > tMaxLen) {
								If ..AllowTruncating {
									If '..%WarningsArray.IsDefined(tColName) {
										$$$LOGWARNING($$$FormatText($$$Text("Truncating the value from column '%1' to meet the MAXLEN restriction of the message property."),tColName))
										Do:..OnlyWarnOnce ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
									}
									Set tVal = $E(tVal,1,tMaxLen)
								} Else {
									Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("The value in selected column '%1' exceeds the MAXLEN restriction of the message property."),tColName))
									Quit
								}
							}
							Set $Property(msg,tColName) = tVal
						}
					} Catch exSet {
						If exSet.Name = "<CANNOT SET THIS PROPERTY>" {
							If '..%WarningsArray.IsDefined(tColName) {
								$$$LOGWARNING($$$FormatText($$$Text("Unable to assign selected column '%1' to a property in the message because this property cannot be set."),tColName))
								Do ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
							}
						} Else {
							Set tSC = exSet.AsStatus()
						}
					}
					Quit:$$$ISERR(tSC)
				} Else {
					If '..%WarningsArray.IsDefined(tColName) {
						$$$LOGWARNING($$$FormatText($$$Text("Unable to assign selected column '%1' to a property in message because this is not a defined property in class '%2'."),tColName,..MessageClass)) 
						Do ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
					}
				}
			}
			Quit:$$$ISERR(tSC)
			
			If tIsFuncProc && (""'=tOutputParmsNames) {
				For tCount=1:1:..Adapter.%CurrParams.Size {
					Set tParamName = $P(tOutputParmsNames,",",tCount)
					Continue:(""=tParamName)
					If $$$defMemberDefined(..MessageClass,$$$cCLASSproperty,tParamName) {
						Try {
							Set tVal = ..Adapter.%CurrParams.GetAt(tCount)
							Set tDataType = $$$defMemberKeyGet(..MessageClass,$$$cCLASSproperty,tParamName,$$$cPROPtype)
							Set:(""=tDataType) tDataType = "%String"
							If $classmethod(tDataType,"%Extends","%Stream.Object") {
								If $IsObject(tVal) && tVal.%Extends("%Stream.Object") {
									#; Property and value are both streams - copy value to the property
									#; Skip empty stream
									Continue:('tVal.Size)
									Set tSC = $method($Property(msg,tParamName),"CopyFrom",.tVal)
								} Else {
									#; The property is a stream, but the value is just a string - write the value to the property
									#; Skip any parameters for which return "value" is a null character
									Continue:(""=$zstrip(tVal,"*C"))
									Do $method($Property(msg,tParamName),"Write",tVal)
								}
							} Else {
								#; The property isn't a stream.  If the output parameter was a stream, get a string value from it
								If $IsObject(tVal) && tVal.%Extends("%Stream.Object") {
									#; Skip empty stream
									Continue:('tVal.Size)
									Set tVal = tVal.Read()
								}
								#; Skip any parameters for which return "value" is null character
								Continue:(""=$zstrip(tVal,"*C"))
								#; Convert value from ODBC representation to logical if relevant
								If ($E(tDataType)="%") && '##class(%Dictionary.ClassDefinition).%ExistsId(tDataType) {
									Set tDataType = "%Library."_$E(tDataType,2,*)
								}
								If $$$defMemberDefined(tDataType,$$$cCLASSmethod,"OdbcToLogical") {
									Set tVal = $classmethod(tDataType,"OdbcToLogical",tVal)
								}
								#; Make sure that the value conforms to property's MAXLEN restriction - mostly important when original data was a stream
								Set tMaxLen = $$$comMemberArrayGet(..MessageClass,$$$cCLASSproperty,tParamName,$$$cPROPparameter,"MAXLEN")
								If (+tMaxLen > 0) && ($L(tVal) > tMaxLen) {
									If ..AllowTruncating {
										If '..%WarningsArray.IsDefined(tParamName) {
											$$$LOGWARNING($$$FormatText($$$Text("Truncating the value from output parameter '%1' to meet the MAXLEN restriction of the message property."),tParamName))
											Do ..%WarningsArray.SetAt(1,tParamName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
										}
										Set tVal = $E(tVal,1,tMaxLen)
									} Else {
										Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("The value in output parameter '%1' exceeds the MAXLEN restriction of the message property."),tParamName))
										Quit
									}
								}
								Set $Property(msg,tParamName) = tVal
							}
						} Catch exSet {
							If exSet.Name = "<CANNOT SET THIS PROPERTY>" {
								If '..%WarningsArray.IsDefined(tParamName) {
									$$$LOGWARNING($$$FormatText($$$Text("Unable to assign output parameter '%1' to a property in the message because this property cannot be set."),tParamName))
									Do ..%WarningsArray.SetAt(1,tParamName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
								}
							} Else {
								Set tSC = exSet.AsStatus()
							}
						}
						Quit:$$$ISERR(tSC)
					} Else {
						If '..%WarningsArray.IsDefined(tParamName) {
							$$$LOGWARNING($$$FormatText($$$Text("Unable to assign output parameter '%1' to a property in the message because this is not a defined property in class '%2'."),tParamName,..MessageClass)) 
							Do ..%WarningsArray.SetAt(1,tParamName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
						}
					}
				}
			}
			Quit:$$$ISERR(tSC)
		}
		Set tSC = msg.%Save()
		Quit:$$$ISERR(tSC)

		For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
			Set tSC1=..SendRequestAsync(tOneTarget,msg)
			If $$$ISERR(tSC1) Set tSC=$$$ADDSC(tSC,tSC1)
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

}
