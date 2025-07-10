/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator (Ensemble, %occInclude, EnsSearchTableErrors)

/// Base class for all SearchTable classes. Users wishing to create
/// their own SearchTable classes should <b>NOT</b> extend this class. User
/// SearchTable classes must extend one of two kinds of base classes. In most cases, users
/// intending to index Virtual Documents should extend one of the 
/// document-specific subclasses of <class>Ens.VDoc.SearchTable</class>, such as 
/// <class>EnsLib.HL7.SearchTable</class> or <class>EnsLib.EDI.X12.SearchTable</class>.
/// These VDoc SearchTables provide a simple and easy to use way of specifying properties
/// to index in virtual documents moving through InterSystems IRIS.
/// In more complex situations where alternative indexing strategies are needed and users
/// are willing to perform more custom development work, users can extend <class>Ens.CustomSearchTable</class>.
Class Ens.SearchTableBase [ Abstract, ClassType = "", ProcedureBlock, System = 3 ]
{

/// The class of Document object for which this SearchTable subclass is designed.
Parameter DOCCLASS As %String;

/// The ID of the document / message body object this row is associated with.
/// Depending on the class specified in <parameter>DOCCLASS</parameter>, this value
/// may not be numeric, so it is defined as a string with EXACT collation to ensure that
/// any matches on this property are based on the original value.
Property DocId As %String(COLLATION = "EXACT", MAXLEN = "");

/// Method which actually performs indexing of the message / document 
/// supplied in the <var>pDocObj</var> argument. This method should be overridden 
/// in subclasses.
ClassMethod IndexDoc(pDocObj As %Persistent) As %Status
{
	Quit $$$ERROR($$$EnsErrGeneral,"Subclass Responsibility")
}

/// Utility method used in the Message Viewer UI to check whether the class specified in <var>pClass</var>
/// extends the base class supplied in <var>pSuper</var>. The method returns true if <var>pClass</var> = <var>pSuper</var>.
ClassMethod IsASub(pClass As %String, pSuper As %String) As %Boolean [ CodeMode = expression, SqlName = IsASub, SqlProc ]
{
$S(pClass=pSuper: 1,##class(%Dictionary.CompiledClass).%ExistsId(pClass):$classmethod(pClass,"%IsA",pSuper),1:0)
}

/// Build output array of all headers that refer to the given doc ID for this class
/// Output array is subscripted as pOutput(tSessionId,tHeaderId,pDocId)=$LB(tTimeCreated,tSourceConfigName,tTargetConfigName)")
ClassMethod SearchHeader(pOutput, pDocId) [ CodeMode = objectgenerator ]
{
	If $Case(%class.Name, "Ens.SearchTableBase":1, "Ens.VDoc.SearchTable":1, "Ens.VDoc.XMLSearchTable":1, "Ens.CustomSearchTable":1, :0) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	Set tDocClass=##class(Ens.VDoc.SearchTableGenerator).FindClassDefParameterVal(%compiledclass,"DOCCLASS")
	If tDocClass = "" Quit $$$ERROR($$$EnsSearchTableDocClassRequired)
	Do %code.WriteLine(" &sql(DECLARE sql2 CURSOR FOR")
	Do %code.WriteLine("  Select %ID, SessionId, TimeCreated, SourceConfigName, TargetConfigName into :tHeaderId, :tSessionId, :tTimeCreated, :tSourceConfigName, :tTargetConfigName from Ens.MessageHeader")
	Do %code.WriteLine("  Where MessageBodyId =:pDocId And 0<>Ens.IsASub(MessageBodyClassName,'"_tDocClass_"'))")
	Do %code.WriteLine(" &sql(OPEN sql2)  For { &sql(FETCH sql2)  Quit:SQLCODE")
	Do %code.WriteLine("   If tSessionId'="",tHeaderId'="" set pOutput(tSessionId,tHeaderId,pDocId)=$LB(tTimeCreated,tSourceConfigName,tTargetConfigName)")
	Do %code.WriteLine(" } &sql(CLOSE sql2)")
	Do %code.WriteLine(" Quit $$$OK")
}

/// Code generated method to index documents of the type specified in <parameter>DOCCLASS</parameter> with
/// IDs between <var>pStartId</var> and <var>pEndId</var>. The default value of -1 for <var>pEndId</var> 
/// indicates that all IDs after <var>pStartId</var> should be indexed.
ClassMethod BuildIndex(pStartId As %Integer = 0, pEndId As %Integer = -1) As %Status [ CodeMode = objectgenerator ]
{
	If $Case(%class.Name, "Ens.SearchTableBase":1, "Ens.VDoc.SearchTable":1, "Ens.VDoc.XMLSearchTable":1, "Ens.CustomSearchTable":1, :0) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	Do %code.WriteLine(" #; Delete DocId's in the range of rebuilding")
	Do %code.WriteLine(" Set tSC=..RemoveIndex(pStartId,pEndId)  Quit:$$$ISERR(tSC) tSC")
	Do %code.WriteLine(" #; Build DocId's in the range of rebuilding")
	Set tDocClass=##class(Ens.VDoc.SearchTableGenerator).FindClassDefParameterVal(%compiledclass,"DOCCLASS")
	If tDocClass = "" Quit $$$ERROR($$$EnsSearchTableDocClassRequired)
	Set tClassType = $$$comClassKeyGet(tDocClass,$$$cCLASSclasstype)
	If (tClassType '= $$$cCLASSCLASSTYPEPERSISTENT) && '$classmethod(tDocClass,"%IsA","%Stream.Object") {
		Quit $$$ERROR($$$EnsErrGeneral,"DOCCLASS '"_tDocClass_"' is not a persistent class or a stream class")
	}
	If tClassType = $$$cCLASSCLASSTYPESTREAM {
		Do %code.WriteLine(" Quit $$$ERROR($$$EnsErrGeneral,""Stream properties are not stored using sequential ID values"")")
	}
	Else {
		Set tDocClassTable=$$$comClassKeyGet(tDocClass,$$$cCLASSsqlschemaname)_"."_$$$comClassKeyGet(tDocClass,$$$cCLASSsqltablename)
		Do %code.WriteLine(" If pEndId < 0 {")
		Do %code.WriteLine("   If pStartId>0 {")
		Do %code.WriteLine("     &sql(DECLARE C1 CURSOR FOR")
		Do %code.WriteLine("      Select ID into :tDocId from "_tDocClassTable)
		Do %code.WriteLine("      Where ID>=:pStartId)")
		Do %code.WriteLine("     &sql(OPEN C1)  For { &sql(FETCH C1)  Quit:SQLCODE")
		Do %code.WriteLine("       Set tDoc=##class("_tDocClass_").%OpenId(tDocId)   Do ..IndexDoc(tDoc)  Kill tDoc")
		Do %code.WriteLine("     } &sql(CLOSE C1)")
		Do %code.WriteLine("   } Else {")
		Do %code.WriteLine("     &sql(DECLARE C2 CURSOR FOR")
		Do %code.WriteLine("      Select ID into :tDocId from "_tDocClassTable_")")
		Do %code.WriteLine("     &sql(OPEN C2)  For { &sql(FETCH C2)  Quit:SQLCODE")
		Do %code.WriteLine("       Set tDoc=##class("_tDocClass_").%OpenId(tDocId)   Do ..IndexDoc(tDoc)  Kill tDoc")
		Do %code.WriteLine("     } &sql(CLOSE C2)")
		Do %code.WriteLine("   }")
		Do %code.WriteLine(" } Else {")
		Do %code.WriteLine("   If pStartId>0 {")
		Do %code.WriteLine("     &sql(DECLARE C3 CURSOR FOR")
		Do %code.WriteLine("      Select ID into :tDocId from "_tDocClassTable)
		Do %code.WriteLine("      Where ID>=:pStartId And ID<=:pEndId)")
		Do %code.WriteLine("     &sql(OPEN C3)  For { &sql(FETCH C3)  Quit:SQLCODE")
		Do %code.WriteLine("       Set tDoc=##class("_tDocClass_").%OpenId(tDocId)   Do ..IndexDoc(tDoc)  Kill tDoc")
		Do %code.WriteLine("     } &sql(CLOSE C3)")
		Do %code.WriteLine("   } Else {")
		Do %code.WriteLine("     &sql(DECLARE C4 CURSOR FOR")
		Do %code.WriteLine("      Select ID into :tDocId from "_tDocClassTable)
		Do %code.WriteLine("      Where ID<=:pEndId)")
		Do %code.WriteLine("     &sql(OPEN C4)  For { &sql(FETCH C4)  Quit:SQLCODE")
		Do %code.WriteLine("       Set tDoc=##class("_tDocClass_").%OpenId(tDocId)   Do ..IndexDoc(tDoc)  Kill tDoc")
		Do %code.WriteLine("     } &sql(CLOSE C4)")
		Do %code.WriteLine("   }")
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Quit $$$OK")
	}
	Quit $$$OK
}

/// Code generated method to remove index values for all documents of the type specified in <parameter>DOCCLASS</parameter>
/// with IDs between <var>pStartId</var> and <var>pEndId</var>. The default value of -1 for <var>pEndId</var> 
/// indicates that all IDs after <var>pStartId</var> should be indexed.
/// The <var>pNoLock</var> argument controls whether the delete operation should use the %NOLOCK SQL keyword which controls
/// whether locks should be taken out during the delete operation. By default locks are used but there are situations,
/// especially when handling OnDelete triggers, where the extra locks could have a serious impact on performance.
ClassMethod RemoveIndex(pStartId As %Integer = 0, pEndId As %Integer = -1, pNoLock As %Boolean = 0) As %Status [ CodeMode = objectgenerator ]
{
	If $Case(%class.Name, "Ens.SearchTableBase":1, "Ens.VDoc.SearchTable":1, "Ens.VDoc.XMLSearchTable":1, "Ens.CustomSearchTable":1, :0) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	Do %code.WriteLine(" If pNoLock {")
	Do %code.WriteLine("  If pStartId'=0 && (pStartId = pEndId) {")
	Do %code.WriteLine("   &sql(Delete %NOLOCK From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId=:pStartId)")
	Do %code.WriteLine("  } ElseIf pEndId < 0 {")
	Do %code.WriteLine("   If pStartId>0 { &sql(Delete %NOLOCK From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId>=:pStartId) }")
	Do %code.WriteLine("   Else {          &sql(Delete %NOLOCK From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_") }")
	Do %code.WriteLine("  } Else {")
	Do %code.WriteLine("   If pStartId>0 { &sql(Delete %NOLOCK From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId>=:pStartId And DocId<=:pEndId) }")
	Do %code.WriteLine("   Else {          &sql(Delete %NOLOCK From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId<=:pEndId) }")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" } Else {")
	Do %code.WriteLine("  If pStartId'=0 && (pStartId = pEndId) {")
	Do %code.WriteLine("   &sql(Delete From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId=:pStartId)")
	Do %code.WriteLine("  } ElseIf pEndId < 0 {")
	Do %code.WriteLine("   If pStartId>0 { &sql(Delete From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId>=:pStartId) }")
	Do %code.WriteLine("   Else {          &sql(Delete From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_") }")
	Do %code.WriteLine("  } Else {")
	Do %code.WriteLine("   If pStartId>0 { &sql(Delete From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId>=:pStartId And DocId<=:pEndId) }")
	Do %code.WriteLine("   Else {          &sql(Delete From "_%compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName_" Where DocId<=:pEndId) }")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,""RemoveIndex failed with SQLCODE=""_SQLCODE)")
	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

/// Method to remove all SearchTable entries which appear for a given document class.
/// The method relies on <class>Ens.DocClassMap</class> to maintain a list of SearchTables
/// which have indexed instances of the document class.
ClassMethod RemoveSearchTableEntries(pClass As %String, pId As %String, pNoLock As %Boolean = 0) As %Status [ Final ]
{
	If '$data($$$EnsJobLocal) New $$$EnsJobLocal
	Set tIsStream = 0
	Try { Set tIsStream = $classmethod(pClass,"%IsA","%Stream.Object") }
	Catch { Set tIsStream = 0 }
	Set tClass = $select(tIsStream: "%Stream.Object", 1: pClass)
	If '##class(Ens.DocClassMap).IsCacheCurrent(tClass) {
		Set tSC = ##class(Ens.DocClassMap).UpdateCache(tClass)
		If $$$ISERR(tSC) Quit tSC
	}
	Set tLocalTran = 0
	If ($TLevel = 0) {
		TSTART
		Set tLocalTran = 1
	}
	Set tSC = $$$OK
	Try {
		Set tSearchTable = ""
		For {
			Set tSearchTable = $order($$$EnsJobLocal("EnsDocClassMap",tClass,"st",tSearchTable))
			Quit:(tSearchTable = "")
			Try {
				Set tSC = $classmethod(tSearchTable,"RemoveIndex",pId,pId,pNoLock)
			}
			Catch ex {
				If ex.Name [ "<CLASS DOES NOT EXIST>" {
					$$$LOGWARNING("SearchTable class '"_tSearchTable_"' does not exist; Class will be removed from DocClassMap")
					#; perform removal after exiting local transaction
					Set tStaleTables(tSearchTable) = ""
				}
				Else {
					Set tSC = ex.AsStatus()
				}
			}
			#; Ignore the following errors
			If $$$StatusEquals(tSC,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) { Set tSC = $$$OK }
			ElseIf $$$ISERR(tSC) { Quit }
		}
		If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If tLocalTran {
		If $$$ISOK(tSC) {
			TCOMMIT
		}
		Else {
			TROLLBACK
		}
	}
	// Remove any entries referring to non-existent classes
	If $data(tStaleTables) {
		Set tST = ""
		For {
			Set tST = $order(tStaleTables(tST))
			Quit:(tST = "")
			Do ##class(Ens.DocClassMap).RemoveSearchTable(tST,1)
		}
	}
	Quit tSC
}

/// Generated method to return the name of the class which forms the base extent
/// for the current SearchTable class.
ClassMethod GetExtentSuperclass() As %String [ CodeMode = objectgenerator ]
{
	Do %code.WriteLine(" Quit """_##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(%class.Name)_"""")
	Quit $$$OK
}

}
