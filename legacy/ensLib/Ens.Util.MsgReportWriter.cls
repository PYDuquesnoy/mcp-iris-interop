/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to write message reports given the session ID
Class Ens.Util.MsgReportWriter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Writes the report into a (local) file
/// <var>filePath</var> is the path to add log to. We assume path ends in a slash!
/// By default the file is named &lt;sessionId&gt;.log in this path
/// <var>filePath</var> is the path to add log to. We assume path ends in a slash!
ClassMethod WriteXMLReportToFile(pSessionId As %String, pFileDir As %String, pFileSpec As %String = "%f.log") As %Status
{
	Set tFilename=##class(Ens.Util.File).CreateTimestamp(pSessionId,pFileSpec,,pFileDir)
	Set tFile=##Class(%IO.FileStream).%New()  Quit:'$IsObject(tFile) %objlasterror
	Do tFile.Open(tFilename,"NEW",5,"UTF-8",.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit ..WriteFullReport(tFile,pSessionId)
}

/// Write an XML version of the trace
ClassMethod WriteFullReport(pStream As %IO.I.Stream = {$$$NULLOREF}, pSessionId As %String, pStartTime As %String = "", pEndTime As %String = "", pStartId As %Integer = "", pEndId As %Integer = "") As %Status
{
	If $IsObject(pStream) {
		Set:pStream.%Extends("%Stream.Object") pStream=##Class(%IO.MetaCharacterStream).%New(pStream)
	} Else {
		If ""=pStream { Set pStream=##Class(%IO.DeviceStream).AttachNew() }
		Else {
			Set tFilename=pStream
			Set pStream=##Class(%IO.FileStream).%New()  Quit:'$IsObject(pStream) %objlasterror
			Do pStream.Open(tFilename,"NEW",5,"UTF-8",.tSC)  Quit:$$$ISERR(tSC) tSC
		}
	}
	Do pStream.WriteLine("<?xml version=""1.0"" ?>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Do pStream.WriteLine("<EnsMsgReport SessionId="""_pSessionId_""">",,.tSC)  Quit:$$$ISERR(tSC) tSC

	Do ..WriteMsgReport(pStream,pSessionId,pStartTime,pEndTime,pStartId,pEndId)
	Do ..WriteEventReport(pStream,pSessionId)
	Do ..WriteRuleLogReport(pStream,pSessionId)

	Do pStream.WriteLine("</EnsMsgReport>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit tSC
}

ClassMethod WriteMsgReport(pStream As %IO.I.Stream, pSessionId As %String, pStartTime As %String = "", pEndTime As %String = "", pStartId As %Integer = "", pEndId As %Integer = "") As %Status
{
	Set query = "select ID from Ens.MessageHeader where SessionId = ? order by %ID"
	Set tRS = ##class(%ResultSet).%New()
	Set tSC = tRS.Prepare(query)
	Do tRS.Execute(pSessionId)

	Do pStream.WriteLine("<EnsMsgLog>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	While (tRS.Next()) {
		Do ..RenderTraceEntryAsXML(pStream,tRS.ID)
	}  Do tRS.Close()

	Do pStream.WriteLine("</EnsMsgLog>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit tSC
}

ClassMethod WriteEventReport(pStream As %IO.I.Stream, pSessionId As %String) As %Status
{
	// Event log information
	Set query = "SELECT ID,{fn RIGHT(%EXTERNAL(TimeLogged),999 )} As TimeLogged,Type,Job, "
	Set query = query _ "SessionId As Session,ConfigName As Source,(SourceClass || '.' || SourceMethod || '()') "
	Set query = query _ "As Method,Text FROM Ens_Util.Log "
	Set query = query _ "WHERE Type IN ('Assert','Error','Warning','Info','Trace','Alert') AND SessionId = ? "
	Set query = query _ "ORDER BY %ID Desc"

	Set tRS = ##class(%ResultSet).%New()
	Set tSC = tRS.Prepare(query)
	Set tRS.RuntimeMode = 2

	Do tRS.Execute(pSessionId)

	Do pStream.WriteLine("<EnsEventLog>",,.tSC)  Quit:$$$ISERR(tSC) tSC

	While (tRS.Next()) {
		Do ..renderEventAsXML(pStream,tRS)
	}  Do tRS.Close()

	Do pStream.WriteLine("</EnsEventLog>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit tSC
}

ClassMethod WriteRuleLogReport(pStream As %IO.I.Stream, pSessionId As %String) As %Status
{
	Set query = "SELECT ID,SessionId As Session,ExecutionId,{fn RIGHT(%EXTERNAL(TimeExecuted),12)} As TimeExecuted,"
	Set query = query _ "HostClass,ActivityName As Activity,RuleName As Rule,RuleVersion,Reason,ReturnValue As Return,IsError,ErrorMsg,RuleId,RoutineName "
	Set query = query _ "FROM Ens_Rule.RuleLog WHERE SessionId = ? "
	Set query = query _ "ORDER BY SessionId Desc, ExecutionId Desc"

	Set tRS = ##class(%ResultSet).%New()
	Set tSC = tRS.Prepare(query)
	Set tRS.RuntimeMode = 2

	Do tRS.Execute(pSessionId)

	Do pStream.WriteLine("<EnsRuleLog>",,.tSC)  Quit:$$$ISERR(tSC) tSC

	While (tRS.Next()) {
		Do ..renderRuleLogAsXML(pStream,tRS)
	}  Do tRS.Close()

	Do pStream.WriteLine("</EnsRuleLog>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit tSC
}

ClassMethod RenderTraceEntryAsXML(pStream As %IO.I.Stream, pId As %String) As %Status
{
	Set hdr = ##class(Ens.MessageHeader).%OpenId(pId,0)

	If $IsObject(hdr) {
		// Write out the header
		Do pStream.Write("    <EnsMsgEntry Id="""_pId_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		// Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 ","CallType="""_hdr.SourceConfigName_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"DestType="""_hdr.TargetBusinessType_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"MsgClass="""_hdr.MessageBodyClassName_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"MsgType="""_hdr.Type_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		// Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"OrType="""_hdr.OrT_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"SourceClass="""_hdr.SourceConfigName_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"Status="""_hdr.Status_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"TargetClass="""_hdr.TargetConfigName_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                 "_"Time="""_hdr.TimeCreated_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC
		Do pStream.WriteLine(">",,.tSC)  Quit:$$$ISERR(tSC) tSC

		// Dump out the message object
		Set tBodyClass = hdr.MessageBodyClassName
		If tBodyClass'="" {
			Set msg = $classmethod(tBodyClass,"%OpenId",hdr.MessageBodyId)

			Do pStream.WriteLine("<!-- Message: type: "_tBodyClass_"  body-id: "_hdr.MessageBodyId_" -->",,.tSC)  Quit:$$$ISERR(tSC) tSC

			If msg.%Extends("%XML.Adaptor") {
				Set tLibStream=##Class(%IO.LibraryStream).%New(pStream)  Quit:'$IsObject(tLibStream) %objlasterror
				Set tSC = msg.XMLExportToStream(tLibStream)  Quit:$$$ISERR(tSC) tSC
			} ElseIf msg.%Extends("%Stream.Object") {
				Do pStream.Write("<![CDATA[",,.tSC)  Quit:$$$ISERR(tSC) tSC
				Do pStream.CopyFrom(msg,,,.tSC)  Quit:$$$ISERR(tSC) tSC
				Do pStream.WriteLine("]]>",,.tSC)  Quit:$$$ISERR(tSC) tSC
			} ElseIf msg.%Extends("Ens.VDoc.Interface") {
				Do pStream.Write("<![CDATA[",,.tSC)  Quit:$$$ISERR(tSC) tSC
				Set tSC = msg.OutputToIOStream(pStream)  Quit:$$$ISERR(tSC) tSC
				Do pStream.WriteLine("]]>",,.tSC)  Quit:$$$ISERR(tSC) tSC
			} ElseIf msg.%Extends("Ens.Util.MessageBodyMethods") {
				Do pStream.Write("<![CDATA[",,.tSC)  Quit:$$$ISERR(tSC) tSC
				Set tIO="" If pStream.%Extends("%IO.DeviceStream") Set tIO=$IO  Use pStream.Name  Quit:'$Test $$$ERROR($$$EnsErrGeneral,"Could not select device "_pStream.Name)
				Do msg.%ShowContents()
				Do pStream.WriteLine("]]>",,.tSC)
				Use:""'=tIO tIO  Quit:$$$ISERR(tSC) tSC
			} Else {
				Do pStream.Write("<![CDATA[",,.tSC)  Quit:$$$ISERR(tSC) tSC
				Do pStream.Write($$$FormatMsg("There is no output method defined for message type %1"),tBodyClass)
				Do pStream.WriteLine("]]>",,.tSC)  Quit:$$$ISERR(tSC) tSC
			}
			Do pStream.WriteLine("<!-- Message: ends -->",,.tSC)  Quit:$$$ISERR(tSC) tSC
		}
	}
	Do pStream.WriteLine("    </EnsMsgEntry>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit tSC
}

ClassMethod renderEventAsXML(pStream As %IO.I.Stream, pRS As %ResultSet) As %Status [ Internal ]
{
	Do pStream.Write("    <EnsEventEntry Id="""_pRS.Data("ID")_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC

	For i=1:1:pRS.GetColumnCount() { Set tag = pRS.GetColumnHeader(i)  Continue:(tag="ID")||(tag="Text")
		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                   ",,.tSC)  Quit:$$$ISERR(tSC)
		Do pStream.Write(tag_"="""_$ZCVT(pRS.GetData(i),"O","XML")_"""",,.tSC)  Quit:$$$ISERR(tSC)
	}  Quit:$$$ISERR(tSC) tSC
	Do pStream.WriteLine(">")
	Do pStream.Write("<![CDATA[",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Do pStream.Write(pRS.Data("Text"),,.tSC)  Quit:$$$ISERR(tSC) tSC
	Do pStream.WriteLine("]]>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Do pStream.WriteLine("    </EnsEventEntry>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit tSC
}

ClassMethod renderRuleLogAsXML(pStream As %IO.I.Stream, pRS As %ResultSet) As %Status [ Internal ]
{
	Do pStream.Write("    <EnsRuleLogEntry Id="""_pRS.Data("ID")_"""",,.tSC)  Quit:$$$ISERR(tSC) tSC

	For i=1:1:pRS.GetColumnCount() {
		Set tag = pRS.GetColumnHeader(i)
		If (tag = "ID") Continue

		Do pStream.WriteLine("",,.tSC)  Do:$$$ISOK(tSC) pStream.Write("                   ",,.tSC)  Quit:$$$ISERR(tSC)
		Do pStream.Write(tag_"="""_$ZCVT(pRS.GetData(i),"O","XML")_"""",,.tSC)  Quit:$$$ISERR(tSC)
	}  Quit:$$$ISERR(tSC) tSC
	Do pStream.WriteLine("/>",,.tSC)  Quit:$$$ISERR(tSC) tSC
	Quit tSC
}

}
