/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.SQL.Operation.GenericOperation Extends Ens.BusinessOperation [ Language = objectscript ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter ADAPTER = "EnsLib.SQL.OutboundAdapter";

Property Adapter As EnsLib.SQL.OutboundAdapter;

Parameter INVOCATION = "Queue";

Parameter UIWIZARDREQUESTSETTING = "RequestClass";

Parameter UIWIZARDRESPONSESETTING = "ResponseClass";

/// The Base query string that will be executed when a new message is received
Property Query As %String(MAXLEN = "") [ Required ];

/// A comma-separated list of input parameter value specifiers, if any. These correspond to any replaceable ? parameters in the query string.</br>
/// *<varname> refers to message properties from the request message;</br>
/// %<varname> refers to Adapter properties such as %LastKey;</br>
/// $<varname> refers to Service class properties;
Property InputParameters As %String(MAXLEN = "");

/// A comma-separated list of the SQL data types of each parameter used in the query (eg. SQL_CHAR,SQL_INTEGER).
/// This may be required for the query to execute successfully if the datatypes are not SQL_VARCHAR (the default used when unspecified)
Property ParamSQLTypes As %String(MAXLEN = "");

/// This is optional and is used by the BPL Editor UI call wizard
/// and the input parameter popup helper dialog.
Property RequestClass As %String(MAXLEN = 1000);

/// Message class to use in generating the response object. If this is set and the query returns a result set, a response object of this class will be
/// created and the values from the top row of query results will be set into the corresponding properties of the response object.
/// If no <parameter>ResponseClass</parameter> is specified, then the response object will take the form of an Ens.StreamContainer message with the Stream property
/// containing a json string which lists each row as a separate object. (eg. {"1":{"ID":"1","Name":"John Smith"},"2":{"ID":"2","Name":"Jane Doe"}}) </br>
/// Note, if a query returns multiple rows of results and a <property>ResponseClass</property> is specified, a message will be logged in the Event Log
/// stating that there were multiple rows, but only one response message is generated. If no value is specified, all results will be included in the 
/// json response message.
Property ResponseClass As %String(MAXLEN = 1000);

/// If the returned data is longer than the MAXLEN of the property into which it is being set, issue a warning, but truncate it to the MAXLEN.
/// If set to false, an error will be thrown when the returned data exceeds the MAXLEN of its associated property. </br>
/// This is only relevant when <property>ResponseClass</property> is set because no truncating is required for json response messages..
Property AllowTruncating As %Boolean [ InitialExpression = 0 ];

/// Limit warnings about multiple returned rows and truncated data.</br>
/// Give a warning the first time that a call to this Operation returns multiple rows, but do not repeat the warning if any subsequent calls also return multiple rows.
/// Likewise, give one warning per column if <property>AllowTruncating</property> is true and returned values must be truncated. </br>
/// This is only relevant when <property>ResponseClass</property> is set because these warning are not issued for json response messages.
Property OnlyWarnOnce As %Boolean [ InitialExpression = 1 ];

Property %WarningsArray As %ArrayOfDataTypes [ Internal, Private, Transient ];

Parameter SETTINGS = {"Query:Data,InputParameters:Data:sqlParametersTable?querySetting=HostQuery&classSettingName=HostRequestClass&prependAsterix=1,ParamSQLTypes:Data,RequestClass:Data:selector?context={Ens.ContextSearch/MessageClasses?mode=request},ResponseClass:Data:selector?context={Ens.ContextSearch/MessageClasses?mode=response},AllowTruncating:Data,OnlyWarnOnce:Alerting"};

Method OnMessage(pRequest As Ens.Request, Output pResponse As Ens.Response) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tRequest As %RegisteredObject
	#dim tJSON, tParamArray, tCommand As %String = ""
	#dim nRows As %Integer
	#dim tResultSet As EnsLib.SQL.GatewayResultSet
	#dim tSnapshots As %ListOfObjects
	#dim tOutputParms As %ListOfDataTypes
	#dim ex As %Exception.AbstractException
	
	Try {
		
		If ..Query'="" {

			Set tSC = ..getObjectFromRequest(pRequest,.tRequest)
			Quit:$$$ISERR(tSC)

			If (..InputParameters'="") {
				Set tSC = ..getParms(.tParamArray,.tRequest,,..ParamSQLTypes)
				Quit:$$$ISERR(tSC)
			}

			Set tCommand = $zcvt($P(..Query," "),"l")
			If tCommand = "select" {
				Set tSC = ..Adapter.ExecuteQueryParmArray(.tResultSet,..Query,.tParamArray)
				Quit:$$$ISERR(tSC)
				Set tSC = ..ProcessQueryResponse(tResultSet,.pResponse)
			} ElseIf $Case(tCommand,"update":1,"insert":1,"delete":1,:0) {
				Set tSC = ..Adapter.ExecuteUpdateParmArray(.nRows,..Query,.tParamArray)
				Quit:$$$ISERR(tSC)
				Set tSC = ..CreateUpdateResponse(nRows,.pResponse)
			} Else {
				Set tSC = ..Adapter.ExecuteProcedureParmArray(.tSnapshots,.tOutputParms,..Query,,.tParamArray)
				Quit:$$$ISERR(tSC)
				Set tSC = ..ProcessProcedureResponse(tSnapshots,tOutputParms,,.pResponse)
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Parse out parameters by comma-separators, honoring single and double quotes, escaped by doubling
/// Borrowed from EnsLib.SQL.InboundAdapter, but modified to allow for *<varname>
Method getParms(Output pArray, pMessage As %Library.Persistent, pIO As %String = "", pSQLType As %String = "") As %Status [ Private ]
{
	Set tSC = $$$OK
	Try {
		Set pIO = $zcvt(pIO,"l")
		Kill pArray  Set pArray=0, tParm="", tParms=..InputParameters_",", tLen=$L(tParms), qq1=0, qq2=0, lq=0, inq(lq)=0
		For i=1:1:tLen { Set c=$E(tParms,i)
			If ","=c&&('lq||(lq=1&&$Case(inq(1),1:qq1,2:qq2,:0))) {
				Quit:i=tLen&&(""=tParm) ; skip the trailing parm if blank
				Set tParm=$ZStrip(tParm,"<>W"), c1=$E(tParm), tParm=$E(tParm,2,*)
				If ("*"=c1) {
					Set tPropName = tParm
				} Else {
					Set tPropName = ""
				}
				Set tParm=$Case(c1, "*": $Property(pMessage,tParm), "%":$Property(..Adapter,"%"_tParm), "$":$Property($this,tParm), "&":$G($$$EnsStaticAppData(..%ConfigName,"adapter.sqlparam",tParm)), :c1_tParm)
				Set tIOChar = "", tSQLType = ""
				If ""'=$E(pIO,pArray+1) {
					For {
						Set tIOChar = $E(pIO,pArray+1)	Quit:""=tIOChar
						Set pArray(pArray+1,"IOType") = $Case(tIOChar,"i":1,"o":4,"b":2,:"")
						Set tSQLType = $P(pSQLType,",",pArray+1)
						If (""'=tSQLType) {
							Set tSQLType = ##class(EnsLib.SQL.Common).ConvertSQLTypeToInt(tSQLType)
							Set pArray(pArray+1,"SqlType") = tSQLType
						}
						If $Case(tIOChar,"i":1,"b":1,:0) {
							Quit
						} Else {
							Set pArray = pArray+1
						}
					}
				}
				If (""=tIOChar)&&(""'=$P(pSQLType,",",pArray+1)) {
					Set tSQLType = ##class(EnsLib.SQL.Common).ConvertSQLTypeToInt($P(pSQLType,",",pArray+1))
					Set pArray(pArray+1,"SqlType") = tSQLType
				}
				If (""'=tPropName) {
					#; Convert from logical value to ODBC representation if relevant
					Set tDataType = $$$defMemberKeyGet(pMessage.%ClassName(1),$$$cCLASSproperty,tPropName,$$$cPROPtype)
					If (""'=tDataType) {
						If ($E(tDataType)="%") && '##class(%Dictionary.ClassDefinition).%ExistsId(tDataType) {
							Set tDataType = "%Library."_$E(tDataType,2,*)
						}
						If $$$defMemberDefined(tDataType,$$$cCLASSmethod,"LogicalToOdbc") {
							Set tParm = $classmethod(tDataType,"LogicalToOdbc",tParm)
						}
					}
				}
				Set pArray=pArray+1, pArray(pArray)=tParm, tParm="", lq=0, qq1=0, qq2=0
			} Else {
				If "'"=c { Set:inq(lq)=2&&qq2 lq=lq-1  Set qq2=0
					If inq(lq)=1 { If qq1 { Set qq1=0 } Else { Set qq1=1 } }
					Else { Set lq=lq+1, inq(lq)=1 }
				}
				ElseIf """"=c { Set:inq(lq)=1&&qq1 lq=lq-1  Set qq1=0
					If inq(lq)=2 { If qq2 { Set qq2=0 } Else { Set qq2=1 } }
					Else { Set lq=lq+1, inq(lq)=2 }
				} Else {
					Set:qq1||qq2 lq=lq-1, qq1=0, qq2=0
				}
				Set tParm=tParm_c
			}
		}
		If ""'=tParm {
			#; remove artificial comma, match unbalanced quotes
			Set tParm=$E(tParm,1,*-1)
			For lq=lq:-1:1 Set tParm=tParm_$Case(inq(lq),1:"'",2:"""",:"")
			Set pArray=pArray+1
			Set pArray(pArray)=tParm
		}
	} Catch ex {
		/* possible thrown errors are wrong request object e.g. not the required property */
		If (ex.Name="<INVALID OREF>")||(ex.Name="<PROPERTY DOES NOT EXIST>") {
			Set tSC = $$$ERROR($$$GeneralError,"Incorrect request object provided for parameter retrieval")
		} Else {
			Set tSC = ex.AsStatus()
		}
	}
	Quit tSC
}

Method ProcessQueryResponse(pResult As EnsLib.SQL.GatewayResultSet, Output pOutput As %RegisteredObject) As %Status
{
	#dim tSC As %Status = $$$OK
	
	Try {
		#dim tColCount,tRowCount As %Integer
		#dim tColumn,tMaxLen As %Integer
		#dim tColName,tVal,tParamName As %String = ""
		
		If (..ResponseClass="") {
			#; No ResponseClass set - return results in a json string wrapped in a stream container
			#dim tObj As %DynamicObject = ##class(%DynamicObject).%New()
			#dim tStream As %Stream.GlobalBinary = ##class(%Stream.GlobalBinary).%New()
		
			If $IsObject(pResult) && pResult.Next(.tSC) {
				Quit:$$$ISERR(tSC)
				Set tColCount = pResult.ColCount
				For {
					Set tResultObj = ##class(%DynamicObject).%New()
					For tColumn=1:1:tColCount {
						Set tColName = pResult.GetColumnName(tColumn)
						If pResult.GetColumnIsLOB(tColumn) {
							Set tStreamData = ##class(%Stream.GlobalCharacter).%New()
							Do pResult.GetStream(tColName,.tStreamData)
							If tStreamData.Size > 0 {
								Do tResultObj.%Set(tColName,tStreamData,"stream")
							}
						} Else {
							Set tVal = pResult.GetData(tColumn)
							Do tResultObj.%Set(tColName,tVal)
						}
					}
					Do tObj.%Set($I(tRowCount),tResultObj)
					Quit:('pResult.Next(tSC) || $$$ISERR(tSC))
				}
				
				Do tObj.%ToJSON(.tStream)
				
				Set pOutput = ##class(Ens.StreamContainer).%New()
				Set pOutput.Stream = tStream
				Set tSC = pOutput.%Save()
			}
		} Else {
			#; A response class was specified, create an object of that type into which we will insert the results
			Set pOutput = $classmethod(..ResponseClass,"%New")
			
			#; Start with the SQL snapshot, but only the first row
			If $IsObject(pResult)&& (pResult.Next(.tSC)) {
				Quit:$$$ISERR(tSC)
				Set tColCount = pResult.ColCount
				For tColumn=1:1:tColCount {
					Set tColName = pResult.GetColumnName(tColumn)
					If $$$defMemberDefined(..ResponseClass,$$$cCLASSproperty,tColName) {
						Try {
							Set tDataType = $$$defMemberKeyGet(..ResponseClass,$$$cCLASSproperty,tColName,$$$cPROPtype)
							Set:(""=tDataType) tDataType = "%String"
							If $classmethod(tDataType,"%Extends","%Stream.Object") {
								If pResult.GetColumnIsLOB(tColumn) {
									Set tStreamData = ##class(%Stream.GlobalBinary).%New()
									Do pResult.GetStream(tColName,.tStreamData)
									Continue:('tStreamData.Size)
									Set tSC = $method($Property(pOutput,tColName),"CopyFrom",.tStreamData)
									Quit:$$$ISERR(tSC)
								} Else {
									Set tVal = pResult.GetData(tColumn)
									Do $method($Property(pOutput,tColName),"Write",tVal)
								}
							}
							Else {
								If pResult.GetColumnIsLOB(tColumn) {
									Set tStreamData = ##class(%Stream.GlobalCharacter).%New()
									Do pResult.GetStream(tColName,.tStreamData)
									Continue:('tStreamData.Size)
									Set tVal = tStreamData.Read()
								} Else {
									Set tVal = pResult.GetData(tColumn)
								}
								#; Convert value from ODBC representation to logical if relevant
								If ($E(tDataType)="%") && '##class(%Dictionary.ClassDefinition).%ExistsId(tDataType) {
									Set tDataType = "%Library."_$E(tDataType,2,*)
								}
								If $$$defMemberDefined(tDataType,$$$cCLASSmethod,"OdbcToLogical") {
									Set tVal = $classmethod(tDataType,"OdbcToLogical",tVal)
								}
								#; Make sure that the value conforms to property's MAXLEN restriction - mostly important when original data was a stream
								Set tMaxLen = $$$comMemberArrayGet(..ResponseClass,$$$cCLASSproperty,tColName,$$$cPROPparameter,"MAXLEN")
								If (+tMaxLen > 0) &&($L(tVal) > tMaxLen) {
									If ..AllowTruncating {
										If '..%WarningsArray.IsDefined(tColName) {
											$$$LOGWARNING($$$FormatText($$$Text("Truncating the value from column '%1' to meet the MAXLEN restriction of the response message property."),tColName))
											Do:..OnlyWarnOnce ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
										}
										Set tVal = $E(tVal,1,tMaxLen)
									} Else {
										Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("The value in selected column '%1' exceeds the MAXLEN restriction of the response message property."),tColName))
										Quit
									}
								}
								Set $Property(pOutput,tColName) = tVal
							}
						} Catch exSet {
							If exSet.Name = "<CANNOT SET THIS PROPERTY>" {
								If '..%WarningsArray.IsDefined(tColName) {
									$$$LOGWARNING($$$FormatText($$$Text("Unable to assign selected column '%1' to a property in the response message because this property cannot be set."),tColName))
									Do ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
								}
							} Else {
								Set tSC = exSet.AsStatus()
							}
						}
						Quit:$$$ISERR(tSC)
					} Else {
						If '..%WarningsArray.IsDefined(tColName) {
							$$$LOGWARNING($$$FormatText($$$Text("Unable to assign selected column '%1' to a property in the response message because this is not a defined property in class '%2'."),tColName,..ResponseClass)) 
							Do ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
						}
					}
				}
				Quit:$$$ISERR(tSC)
				
				Set tSC = pOutput.%Save()
				
				#; Add note in the Event Log that there were more results
				If pResult.Next() {
					#; Using non-printable characters as the key so that it can't be the same as the name of some column or parameter
					If '..%WarningsArray.IsDefined($C(0)_"AdditionalRows"_$C(0)) {
						$$$LOGWARNING($$$Text("Additional rows have been returned by the query, but not recorded in the response message."))
						Do:..OnlyWarnOnce ..%WarningsArray.SetAt(1,$C(0)_"AdditionalRows"_$C(0))
					}
				}
			}
			
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

Method CreateUpdateResponse(pNumRowsAffected As %Integer, Output pOutput As %RegisteredObject) As %Status
{
	#dim tSC As %Status = $$$OK
	
	Try {		
		If (..ResponseClass="") {
			#; No ResponseClass set - return results in a json string wrapped in a stream container
			#dim tObj As %DynamicObject = ##class(%DynamicObject).%New()
			#dim tStream As %Stream.GlobalBinary = ##class(%Stream.GlobalBinary).%New()
		
			Do tObj.%Set("NumRowsAffected",pNumRowsAffected)				
			Do tObj.%ToJSON(.tStream)
				
			Set pOutput = ##class(Ens.StreamContainer).%New()
			Set pOutput.Stream = tStream
			Set tSC = pOutput.%Save()
		} Else {
			#; A response class was specified, create an object of that type into which we will insert the result if it happens to have a property names "NumRowsAffected"
			If $$$defMemberDefined(..ResponseClass,$$$cCLASSproperty,"NumRowsAffected") {
				Set pOutput = $classmethod(..ResponseClass,"%New")
				Set pOutput.NumRowsAffected = pNumRowsAffected
				Set tSC = pOutput.%Save()
			} Else {
				If '..%WarningsArray.IsDefined("NumRowsAffected") {
					$$$LOGWARNING($$$FormatText($$$Text("Unable to create a response message because '%1' is not a defined property in response class '%2'."),"NumRowsAffected",..ResponseClass)) 
					Do ..%WarningsArray.SetAt(1,"NumRowsAffected") ; doesn't actually matter what we call this or what we set it to, as long as it's consistent with the IsDefined() check above
				}
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

Method ProcessProcedureResponse(pResults As %ListOfObjects = {$$$NULLOREF}, pOutputParms As %ListOfDataTypes = {$$$NULLOREF}, pOutputParmsNames As %String = "", Output pOutput As %RegisteredObject) As %Status
{
	#dim tSC As %Status = $$$OK
	
	Try {
		#dim tColCount,tResultsCount,tRowCount,tCount,tParmCount As %Integer = 0
		#dim tColumn,tMaxLen As %Integer
		#dim tColName,tVal,tParamName As %String = ""
		#dim tSnapshot As EnsLib.SQL.Snapshot
		#dim tSnapshotAsParms As %Boolean = 0
		
		If (..ResponseClass="") {
			#; No ResponseClass set - return results in a json string wrapped in a stream container
			#dim tObj As %DynamicObject = ##class(%DynamicObject).%New()
			#dim tStream As %Stream.GlobalBinary = ##class(%Stream.GlobalBinary).%New()
			
			#; Start with output parameters
			If $IsObject(pOutputParms) && pOutputParms.Count() {
				For tCount=1:1:pOutputParms.Count() {
					Set tParamName = $S(""=pOutputParmsNames:"Parameter_"_tCount,1:$P(pOutputParmsNames,",",tCount))
					Continue:(""=tParamName)
					Set tVal = pOutputParms.GetAt(tCount)
					If $IsObject(tVal) && tVal.%Extends("%Stream.Object") {
						#; Skip any empty streams
						Continue:('tVal.Size)
						Do tObj.%Set(tParamName,tVal,"stream")
					} Else {
						#; Skip any return values that are just a control character
						Continue:(""=$zstrip(tVal,"*C"))
						Do tObj.%Set(tParamName,tVal)
					}
					Set tParmCount = $I(tParmCount)
				}
			}
			
			#; Check if we were expecting parameters, but didn't get any.
			#; If so we will set the column values directly into the json stream instead of setting the results as an array of objects
			If ..%Extends("EnsLib.SQL.Operation.ProcOperation")&&'tParmCount&&(pOutputParmsNames'="") {
				Set tSnapshotAsParms = 1
				$$$LOGWARNING($$$Text("No output parameter values were returned by the SQL procedure. Returning first row of query results instead."))
			}
		
			#; Add any SQL snapshot data
			If $IsObject(pResults) && pResults.Count() {
				Set tSnapshot = pResults.GetAt($I(tResultsCount))
				Set tColCount = tSnapshot.ColCount
				While tResultsCount <= pResults.Count() {
					While tSnapshot.Next() {
						Set tResultObj = ##class(%DynamicObject).%New()
						For tColumn=1:1:tColCount {
							Set tColName = tSnapshot.GetColumnName(tColumn)
							If tSnapshot.GetColumnIsLOB(tColumn) {
								Set tStreamData = ##class(%Stream.GlobalBinary).%New()
								Do tSnapshot.GetStream(tColName,.tStreamData)
								If tStreamData.Size > 0 {
									Do tResultObj.%Set(tColName,tStreamData,"stream")
								}
							} Else {
								Set tVal = tSnapshot.GetData(tColumn)
								Do tResultObj.%Set(tColName,tVal)
							}
						}
						If tSnapshotAsParms {
							Set tObj = tResultObj
							Quit
						}
						Do tObj.%Set($I(tRowCount),tResultObj)
					}
					Quit:tSnapshotAsParms
					Set tSnapshot = pResults.GetAt($I(tResultsCount))
				}
			}
			
			Do tObj.%ToJSON(.tStream)
			
			Set pOutput = ##class(Ens.StreamContainer).%New()
			Set pOutput.Stream = tStream
		} Else {
			#; A response class was specified, create an object of that type into which we will insert the results
			Set pOutput = $classmethod(..ResponseClass,"%New")
			
			#; Start with the SQL snapshot, but only the first row
			If $IsObject(pResults)&& (pResults.Count() >= 1) {
				Set tSnapshot = pResults.GetAt(1)
				Set tColCount = tSnapshot.ColCount
				If tSnapshot.Next() {
					For tColumn=1:1:tColCount {
						Set tColName = tSnapshot.GetColumnName(tColumn)
						If $$$defMemberDefined(..ResponseClass,$$$cCLASSproperty,tColName) {
							Try {
								Set tDataType = $$$defMemberKeyGet(..ResponseClass,$$$cCLASSproperty,tColName,$$$cPROPtype)
								Set:(""=tDataType) tDataType = "%String"
								If $classmethod(tDataType,"%Extends","%Stream.Object") {
									If tSnapshot.GetColumnIsLOB(tColumn) {
										Set tStreamData = ##class(%Stream.GlobalBinary).%New()
										Do tSnapshot.GetStream(tColName,.tStreamData)
										Continue:('tStreamData.Size)
										Set tSC = $method($Property(pOutput,tColName),"CopyFrom",.tStreamData)
										Quit:$$$ISERR(tSC)
									} Else {
										Set tVal = tSnapshot.GetData(tColumn)
										Do $method($Property(pOutput,tColName),"Write",tVal)
									}
								} Else {
									If tSnapshot.GetColumnIsLOB(tColumn) {
										Set tStreamData = ##class(%Stream.GlobalBinary).%New()
										Do tSnapshot.GetStream(tColName,.tStreamData)
										#; Skip empty stream
										Continue:('tStreamData.Size)
										Set tVal = tStreamData.Read()
									} Else {
										Set tVal = tSnapshot.GetData(tColumn)
									}
									#; Convert value from ODBC representation to logical if relevant
									If ($E(tDataType)="%") && '##class(%Dictionary.ClassDefinition).%ExistsId(tDataType) {
										Set tDataType = "%Library."_$E(tDataType,2,*)
									}
									If $$$defMemberDefined(tDataType,$$$cCLASSmethod,"OdbcToLogical") {
										Set tVal = $classmethod(tDataType,"OdbcToLogical",tVal)
									}
									#; Make sure that the value conforms to property's MAXLEN restriction - mostly important when original data was a stream
									Set tMaxLen = $$$comMemberArrayGet(..ResponseClass,$$$cCLASSproperty,tColName,$$$cPROPparameter,"MAXLEN")
									If (+tMaxLen > 0) && ($L(tVal) > tMaxLen) {
										If ..AllowTruncating {
											If '..%WarningsArray.IsDefined(tColName) {
												$$$LOGWARNING($$$FormatText($$$Text("Truncating the value from column '%1' to meet the MAXLEN restriction of the response message property."),tColName))
												Do:..OnlyWarnOnce ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
											}
											Set tVal = $E(tVal,1,tMaxLen)
										} Else {
											Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("The value in selected column '%1' exceeds the MAXLEN restriction of the response message property."),tColName))
											Quit
										}
									}
									Set $Property(pOutput,tColName) = tVal
								}
							} Catch exSet {
								If exSet.Name = "<CANNOT SET THIS PROPERTY>" {
									If '..%WarningsArray.IsDefined(tColName) {
										$$$LOGWARNING($$$FormatText($$$Text("Unable to assign selected column '%1' to a property in the response message because this property cannot be set."),tColName))
										Do ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
									}
								} Else {
									Set tSC = exSet.AsStatus()
								}
							}
							Quit:$$$ISERR(tSC)
						} Else {
							If '..%WarningsArray.IsDefined(tColName) {
								$$$LOGWARNING($$$FormatText($$$Text("Unable to assign selected column '%1' to a property in the response message because this is not a defined property in class '%2'."),tColName,..ResponseClass)) 
								Do ..%WarningsArray.SetAt(1,tColName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
							}
						}
					}
					Quit:$$$ISERR(tSC)
					
					#; Add note in the Event Log that there were more results
					If tSnapshot.Next() {
						#; Using non-printable characters as the key so that it can't be the same as the name of some column or parameter
						If '..%WarningsArray.IsDefined($C(0)_"AdditionalRows"_$C(0)) {
							$$$LOGWARNING($$$Text("Additional rows have been returned by the query, but not recorded in the response message."))
							Do:..OnlyWarnOnce ..%WarningsArray.SetAt(1,$C(0)_"AdditionalRows"_$C(0))
						}
					}
				}
			}
			
			#; Add any output parameters
			If $IsObject(pOutputParms) && pOutputParms.Count() && (""'=pOutputParmsNames) {
				For tCount=1:1:pOutputParms.Count() {
					Set tParamName = $P(pOutputParmsNames,",",tCount)
					Continue:(""=tParamName)
					If $$$defMemberDefined(..ResponseClass,$$$cCLASSproperty,tParamName) {
						Try {
							Set tVal = pOutputParms.GetAt(tCount)
							Set tDataType = $$$defMemberKeyGet(..ResponseClass,$$$cCLASSproperty,tParamName,$$$cPROPtype)
							Set:(""=tDataType) tDataType = "%String"
							If $classmethod(tDataType,"%Extends","%Stream.Object") {
								If $IsObject(tVal) && tVal.%Extends("%Stream.Object") {
									#; Skip empty stream
									Continue:('tVal.Size)
									Set tSC = $method($Property(pOutput,tParamName),"CopyFrom",.tVal)
								} Else {
									#; Skip any return values that are just a control character
									Continue:(""=$zstrip(tVal,"*C"))
									Do $method($Property(pOutput,tParamName),"Write",tVal)
								}
							} Else {
								#; Class property isn't a stream.  If the output parameter was a stream, get a string value from it
								If $IsObject(tVal) && tVal.%Extends("%Stream.Object") {
									#; Skip empty stream
									Continue:('tVal.Size)
									Set tVal = tVal.Read()
								}
								#; Skip any return values that are just a control character
								Continue:(""=$zstrip(tVal,"*C"))
								#; Convert value from ODBC representation to logical if relevant
								If ($E(tDataType)="%") && '##class(%Dictionary.ClassDefinition).%ExistsId(tDataType) {
									Set tDataType = "%Library."_$E(tDataType,2,*)
								}
								If $$$defMemberDefined(tDataType,$$$cCLASSmethod,"OdbcToLogical") {
									Set tVal = $classmethod(tDataType,"OdbcToLogical",tVal)
								}
								#; Make sure that the value conforms to property's MAXLEN restriction - mostly important when original data was a stream
								Set tMaxLen = $$$comMemberArrayGet(..ResponseClass,$$$cCLASSproperty,tParamName,$$$cPROPparameter,"MAXLEN")
								If (+tMaxLen > 0) && ($L(tVal) > tMaxLen) {
									If ..AllowTruncating {
										If '..%WarningsArray.IsDefined(tParamName) {
											$$$LOGWARNING($$$FormatText($$$Text("Truncating the value from output parameter '%1' to meet the MAXLEN restriction of the response message property."),tParamName))
											Do:..OnlyWarnOnce ..%WarningsArray.SetAt(1,tParamName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
										}
										Set tVal = $E(tVal,1,tMaxLen)
									} Else {
										Set tSC = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("The value in output parameter '%1' exceeds the MAXLEN restriction of the response message property."),tParamName))
										Quit
									}
								}
								Set $Property(pOutput,tParamName) = tVal
							}
						} Catch exSet {
							If exSet.Name = "<CANNOT SET THIS PROPERTY>" {
								If '..%WarningsArray.IsDefined(tParamName) {
									$$$LOGWARNING($$$FormatText($$$Text("Unable to assign output parameter '%1' to a property in the response message because this property cannot be set."),tParamName))
									Do ..%WarningsArray.SetAt(1,tParamName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
								}
							} Else {
								Set tSC = exSet.AsStatus()
							}
						}
						Quit:$$$ISERR(tSC)
					} Else {
						If '..%WarningsArray.IsDefined(tParamName) {
							$$$LOGWARNING($$$FormatText($$$Text("Unable to assign output parameter '%1' to a property in the response message because this is not a defined property in class '%2'."),tParamName,..ResponseClass)) 
							Do ..%WarningsArray.SetAt(1,tParamName) ; doesn't matter what we set this to because only possible for any particular property to encounter one warning type
						}
					}
				}
				Quit:$$$ISERR(tSC)
			}

		}
		Set tSC =pOutput.%Save()
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Internal shared method to convert a property of certain types of request objects
/// to a dynamic object in order to provide the input parameters. <br>
/// The following request object properties are converted to Dynamic Objects:<br>
/// Ens.StreamContainer: Stream <br>
/// Ens.StringContainer: StringValue <br>
/// Ens.StringRequest:StringValue <br>
Method getObjectFromRequest(pRequest As %RegisteredObject, Output pRequestOrDAO As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		If pRequest.%Extends("Ens.StreamContainer") {
			Set tJSON = pRequest.Stream
			Set pRequestOrDAO = $Select(""=tJSON:$$$NULLOREF,1:##class(%DynamicObject).%FromJSON(tJSON))
		} ElseIf pRequest.%Extends("Ens.StringContainer") {
			Set tJSON = pRequest.StringValue
			Set pRequestOrDAO = $Select(""=tJSON:$$$NULLOREF,1:##class(%DynamicObject).%FromJSON(tJSON))
		} ElseIf pRequest.%Extends("Ens.StringRequest") {
			Set tJSON = pRequest.StringValue
			Set pRequestOrDAO = $Select(""=tJSON:$$$NULLOREF,1:##class(%DynamicObject).%FromJSON(tJSON))
		} Else {
			Set pRequestOrDAO = pRequest
		}
	} Catch ex {
		If $Get(tJSON)'="" {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid JSON content provided for parameter retrieval")
			Set tSC = $SYSTEM.Status.AppendStatus(tSC,ex.AsStatus())
		} Else {
			Set tSC = ex.AsStatus()
		}
		Return tSC
	}
	Return tSC
}

}
