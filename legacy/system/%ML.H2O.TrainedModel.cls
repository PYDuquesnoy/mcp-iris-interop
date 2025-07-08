/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ML.H2O.TrainedModel Extends %ML.TrainedModel [ ClassType = persistent ]
{

Property h2oProvider As %ML.H2O.Provider [ Transient ];

Property ByteStream As %Stream.GlobalBinary;

/// Cached info
Property withcolumnnames As %List [ Internal, Transient ];

/// Cached info
Property withcolumntypes As %List [ Internal, Transient ];

/// 
/// Begin trained model operations
/// 
Method %Begin() As %Status
{
	#dim status As %Status = $$$OK
	Try {
		#dim provider As %ML.H2O.Provider
		#dim model, col

		If '$IsObject(..h2oProvider) {
		   // Set status = ##class(%ML.Provider).%GetProvider("%ML.H2O.Provider",.provider)
		   set ..h2oProvider = ##class(%ML.H2O.Provider).%New()
		   set status = ..h2oProvider.%OnInit()
		   Quit:$$$ISERR(status)
		}

		If (..withcolumnnames="") || (..withcolumntypes="") {
			// Set up the cached metadata
			For col = 1:1:..Model.WithColumnNames.Count() {
				Set ..withcolumnnames = ..withcolumnnames _ $LB(..Model.WithColumnNames.GetAt(col))
				Set ..withcolumntypes = ..withcolumntypes _ $LB(..Model.WithColumnTypes.GetAt(col))
			}
		}

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// End trained model operations
/// 
Method %End() As %Status
{
	// We leave stuff around to be cached for more prediction runs, in the event of a
	// re-train, then a new instance of this class will be created.

	Quit $$$OK
}

/// 
/// Bulk Predict
/// 
/// arguments:
/// 	tfn		 - tempfile index
/// 	argspos		 - Positions of the WithColumns in the temp rows, $list(column-positions)
/// 	predpos		 - Position of the predicted value, $list(result-column-positions)
/// 	probpos		 - Position of the probability value, $list(result-column-positions)
/// 	expr		 - expression for probability
/// returns:
/// 	$$$OK on success, otherwise a $$$ERROR(...)
/// 
Method %PredictAll(tfn As %Integer, argspos As %List, predpos As %List = "", probpos As %List = "", expr As %String = "") As %Status
{
	#dim status As %Library.Status
	#dim classname,predictingcolumn,select,selectcnt,tablename As %String
	#dim ex As %Exception.SystemException
	#dim predict,realtfn As %Integer
	#dim results As %List
	try {
		do ..%Begin()
		set predict=(predpos'="")	// if predict=1, this is predict, otherwise, probability
		// Build a table that maps to the SQL temp file
		// returns tablename, classname, ans a select query
		set status=$$MLDefinePredictTempTable^%apiDDL(tfn,argspos,$s(predict:predpos,1:probpos),$THIS.Model,.tablename,.classname,.select, .selectcnt,,predict)
		Quit:$$$ISERR(status)

		Set predictingcolumn = ..Model.PredictingColumnNames.GetAt(1)
		Set:predictingcolumn["." predictingcolumn=$p(predictingcolumn,".",2)	// If qualified, just get the name
		
		If (predict) {
			set status = ..PredictAllH2O(select, selectcnt, predictingcolumn, classname)
		} else {
			set status = ..ProbAllH2O(select, selectcnt, predictingcolumn, classname, expr)
		}	
	} catch (ex) {
		Set status = ex.AsStatus()
	}
	if $g(classname)'="" { set sc=$SYSTEM.OBJ.Delete(classname,"/displaylog=0/deleteextent=0")  } // delete tempfile class if it was created, report error if it fails to delete???
	if $g(realtfn)'="" { kill ^IRIS.Temp.Sql(realtfn) }
	RETURN status
}

Method %Predict(data As %List, ByRef results As %List) As %Status
{
#;	#dim status As %Status = $$$OK
#;	#dim tfn As %Integer = $INCREMENT(^||%t)
#;	Try {
#;		#dim dl As %Integer = $LL(data)
#;		#dim i As %Integer
#;		#dim argspos As %List
#;		#dim predpos As %List
#;		#dim rpos As %Integer = ..Model.WithColumnNames.Count()+1
#;
#;		For i = 1:1:rpos-1 { Set $LI(argspos,i)=i }
#;		Set predpos = $LB(rpos)
#;		Set ^||%t(tfn,1) = data
#;
#;		Set status = $THIS.%PredictAll(tfn, argspos, predpos)
#;		Quit:$$$ISERR(status)
#;
#;		Set results = $LB($LI(^||%t(tfn,1),rpos))
#;
#;	} Catch (ex) {
#;		set status = ex.AsStatus()
#;	}
#;
#;	Kill ^||%t(tfn)
#;
#;	Quit status
	Quit ..predictORprobability(1, data, .results, 1)
}

/// 
/// Predict probability on an ML model
/// Arguments:
/// 	expr:     The argument of PROBABILITY's FOR clause, defaults to 1
/// 	data:     $List of WITH clause values
/// 	results:  PBR, return value
Method %Probability(expr As %String = 1, data As %List, ByRef results As %List) As %Status
{
	Quit ..predictORprobability(expr, data, .results, 0)
}

Method predictORprobability(expr As %String, data As %List, ByRef results As %List, predict As %Boolean) As %Status [ Internal ]
{
	#dim sc As %Status = $$$OK
	Try {
		for i=1:1:$LL(data){
			if ($LG(..withcolumntypes, i) = 9){
				set $LIST(data, i) = $ZDATE($LG(data, i))
			}
			elseif ($LG(..withcolumntypes, i) = 10){
				set $LIST(data, i) = $ZTIME($LG(data, i))
			}
		}
		
		// Convert the row data into a dataframe
		set results = ""
		Set predictingcolumn = ..Model.PredictingColumnNames.GetAt(1)
		Set:predictingcolumn["." predictingcolumn=$p(predictingcolumn,".",2)	// If qualified, just get the name
		// Do the prediction!
		If predict {
			Set results = ..h2oProvider.h2o.predict(..%Id(), data, ..withcolumnnames, ..withcolumntypes, predictingcolumn)
		} Else {
			// expr needs to be sent over
			Set results = ..h2oProvider.h2o.probability(..%Id(), data, ..withcolumnnames, ..withcolumntypes, predictingcolumn, expr)
			if (results = -1){
				set sc = $$$ERROR($$$MLGeneralError,"Probability(): ","Specified positive label value not found in the dataset.")			
			}
		}

	} Catch (ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

Method PredictAllH2O(select As %String, selectcnt As %String, predictingcolumn As %String, classname As %String) As %Status [ Internal ]
{
	set status = $$$OK
	try {
		Set results = ..h2oProvider.h2o.predict(..%Id(), select, selectcnt, predictingcolumn, 0)
		if ($LISTGET(results,1) = "error"){
			set status = $$$ERROR($$$MLGeneralError,"Predict()","failed to predict. Please check the prediction dataset.")
		}
		Quit:$$$ISERR(status)
		do $classmethod(classname, "UpdateResult", results)
	}
	catch (ex) {
		set status = ex.AsStatus()
	}
	quit status
}

Method ProbAllH2O(select As %String, selectcnt As %String, predictingcolumn As %String, classname As %String, expr As %String) As %Status [ Internal ]
{
	set status = $$$OK
	try {
		Set results = ..h2oProvider.h2o.probability(..%Id(), select, selectcnt, predictingcolumn, 0, expr)
		if ($LISTGET(results,1) = "error"){
			set status = $$$ERROR($$$MLGeneralError,"Probability()","failed to import dataset.")
		}
		elseif ($LISTGET(results,1) = "label"){
			set status = $$$ERROR($$$MLGeneralError,"Probability():","Specified positive label value not found in the dataset.")
		}
		Quit:$$$ISERR(status)
		do $classmethod(classname, "UpdateResult", results)
	}
	catch (ex) {
		set status = ex.AsStatus()
	}
	quit status
}

Storage Default
{
<Data name="TrainedModelDefaultData1">
<Subscript>"TrainedModel"</Subscript>
<Value name="1">
<Value>ByteStream</Value>
</Value>
</Data>
<DefaultData>TrainedModelDefaultData1</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
