/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Models.Group.Utils Extends %RegisteredObject [ Deprecated, System = 4 ]
{

ClassMethod %GenerateReportFromXMLFile(filename As %String)
{
	set model=##class(%ZEN.Report.Models.Group.Report).ImportFile(filename)
	set tSC=##class(%ZEN.Report.Models.Group.Utils).%GenerateReport(model)
	quit tSC
}

/// Given a report model (typically supplied
/// by the report designer) create a class that implements the report.
ClassMethod %GenerateReport(pModel As %ZEN.Report.Models.Group.Report) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {

		// determine the class name to use for the report
		Set tClassName = pModel.className

		// open the class definition
		If (##class(%Dictionary.ClassDefinition).%ExistsId(tClassName)) {
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName)
			#; delete the old XDATA block named ReportModel
			Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||GroupModel")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = tClassName
			Set tClassDefinition.Super = "%ZEN.Report.reportPage"
			Set tClassDefinition.ProcedureBlock = 1
		}

		// sequence number controls the order in which class members are displayed
		Set tSeqNo = 0

		// report class parameters
		Set tIndex = tClassDefinition.Parameters.FindObjectId(tClassName_"||APPLICATION")
		If tIndex'="" Do tClassDefinition.Parameters.RemoveAt(tIndex)
		Set tParm = ##class(%Dictionary.ParameterDefinition).%New()
		Set tParm.Name = "APPLICATION"
		Set tParm.SequenceNumber = $I(tSeqNo)
		Set tParm.Description = "Class name of the application this report belongs to."
		Set tParm.parent = tClassDefinition

		Set tIndex = tClassDefinition.Parameters.FindObjectId(tClassName_"||DEFAULTMODE")
		If tIndex'="" Do tClassDefinition.Parameters.RemoveAt(tIndex)
		Set tParm = ##class(%Dictionary.ParameterDefinition).%New()
		Set tParm.Name = "DEFAULTMODE"
		Set tParm.SequenceNumber = $I(tSeqNo)
		Set tParm.Default = "html"
		Set tParm.Description = "This is the default display mode for this report."
		Set tParm.parent = tClassDefinition

		// add report parameters (properties)

		// create XData block to hold the Report Model
		Set tModelXData = ##class(%Dictionary.XDataDefinition).%New()
		
		Set tModelXData.SequenceNumber = $I(tSeqNo)
		Set tModelXData.Description = "Group Model information supplied from Report Builder."
		Set tModelXData.XMLNamespace = ""

		Set tModelXData.Name = "GroupModel"
		Set tModelXData.parent = tClassDefinition

		// contents of xdata block is the xml for the model
		Set tSC = pModel.XMLExportToStream(tModelXData.Data)
		If $$$ISERR(tSC) Quit
	
		// description
		Set tClassDefinition.Description = "This is a generated class."

		// create the ReportDefinition XData block
		Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||ReportDefinition")
		If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)

		Set tRDefXData = ##class(%Dictionary.XDataDefinition).%New()
		Set tRDefXData.Name = "ReportDefinition"
		Set tRDefXData.SequenceNumber = $I(tSeqNo)
		Set tRDefXData.Description = "This XML defines the logical contents of this report."
		Set tRDefXData.XMLNamespace = "http://www.intersystems.com/zen/report/definition"
		Set tRDefXData.parent = tClassDefinition

		Set tSC = ..%ModelToReportDefinition(pModel,tRDefXData.Data)
		If $$$ISERR(tSC) Quit

		// create the ReportDisplay XData block
		Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||ReportDisplay")
		If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)

		Set tRDspXData = ##class(%Dictionary.XDataDefinition).%New()
		Set tRDspXData.Name = "ReportDisplay"
		Set tRDspXData.SequenceNumber = $I(tSeqNo)
		Set tRDspXData.Description = "This XML defines the display for this report."
		Set tRDspXData.XMLNamespace = "http://www.intersystems.com/zen/report/display"
		Set tRDspXData.parent = tClassDefinition

		Set tSC = ..%ModelToReportDisplay(pModel,tRDspXData.Data)
		If $$$ISERR(tSC) Quit

		// save and compile the report class
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit

		// if error occurs, remove the reportDefinition and reportDisplay blocks
		// and save the model only
		Set tSC = $System.OBJ.Compile(tClassDefinition.Name,"-d")
		If $$$ISERR(tSC) Quit

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a report model to a report definition (as a stream in XML format).
ClassMethod %ModelToReportDefinition(pModel As %ZEN.Report.Models.Group.Report, pOutput As %Stream.GlobalCharacter) As %Status [ Internal ]
{
	#define ESCAPEXML(%x) $ZCVT(%x,"O","XML")
	Set tSC=$$$OK
	try {
		Set tSQL=pModel.sql
		if $$$ISERR(tSC) quit
		Do pOutput.WriteLine("<report xmlns=""http://www.intersystems.com/zen/report/definition""")
		Do pOutput.WriteLine("name="""_pModel.name_"""")
		if pModel.sql'="" {
			Do pOutput.WriteLine("sql="""_$$$ESCAPEXML(tSQL)_"""")
		} else {
			Do pOutput.WriteLine("queryClass="_pModel.queryClass)
			Do pOutput.WriteLine("queryName="_pModel.queryName)
		}
		Do pOutput.WriteLine(">")
		Set tSC=..ProcessGroupsDef(pModel,pModel.groups,pOutput)
		if $$$ISERR(tSC) quit
		Do pOutput.WriteLine("</report>")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a report model to a report definition (as a stream in XML format).
ClassMethod %ModelToReportDisplay(pModel As %ZEN.Report.Models.Group.Report, pOutput As %Stream.GlobalCharacter) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Do pOutput.WriteLine("<report xmlns=""http://www.intersystems.com/zen/report/display""")
		Do pOutput.WriteLine("name="""_pModel.name_"""")
		Do pOutput.WriteLine(">")
		Do pOutput.Write("<document")
		Do pOutput.Write(" height='"_pModel.document.height_"' width='"_pModel.document.width_"'")
		Do pOutput.Write(" marginLeft='"_pModel.document.marginLeft_"' marginRight='"_pModel.document.marginRight_"'")
		Do pOutput.Write(" marginTop='"_pModel.document.marginTop_"' marginBottom='"_pModel.document.marginBottom_"'")
		Do pOutput.Write(" footerHeight='"_pModel.document.footerHeight_"' headerHeight='"_pModel.document.headerHeight_"'")
		Do pOutput.WriteLine(">")
		Do pOutput.WriteLine("</document>")
		Set tSC=..ProcessGroupsDisplay(pModel,pModel.groups,pOutput)
		Do pOutput.WriteLine("</report>")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Process Groups for Report Definition
ClassMethod ProcessGroupsDef(parent As %ZEN.Report.Models.Group.Report, list, pOutput As %Stream.GlobalCharacter)
{
	try {
		Set tSC=$$$OK	
		// Begin Groups
	
		For g = 1:1:list.Count() {
			Do pOutput.WriteLine("<group name='GroupBy"_g_"' breakOnField='"_list.GetAt(g).field_"'>")
			Do pOutput.WriteLine("<attribute name='group' field='"_list.GetAt(g).field_"'/>") 
		}
		// Detail records
		Do pOutput.WriteLine("<group name='Detail'>")
		if (parent.sql '= "") {
			Set tSC=..GetColumnNamesSQL(parent.sql,.cols)
		} else {
			Set tSC=..GetColumnNamesQuery(parent.queryClass,parent.queryName,.cols)
		}
		set colnum=""
		set colnum=$o(cols(colnum))
		while (colnum'="") {
			Set field=cols(colnum)
			Do pOutput.WriteLine("<attribute name='"_field_"' field='"_field_"'/>")
			set colnum=$o(cols(colnum))
		}
		Do pOutput.WriteLine("</group>")
		// End Groups
		For g = 1:1:list.Count() {
			Do pOutput.WriteLine("</group>")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	quit tSC
}

/// Process Groups for Report Definition
ClassMethod ProcessGroupsDisplay(parent As %ZEN.Report.Models.Group.Report, list, pOutput As %Stream.GlobalCharacter)
{
	try {
		Set tSC=$$$OK	
		// Begin Groups
	
		For g = 1:1:list.Count() {
			Do pOutput.WriteLine("<group name='GroupBy"_g_"'>")
			Do pOutput.WriteLine("<table orient='row'>")
			Do pOutput.WriteLine("<item field='@group' />") 
			Do pOutput.WriteLine("</table>")
		}
		// Detail records
		Do pOutput.WriteLine("<table group='Detail' class='table2'>")
		if (parent.sql '= "") {
			Set tSC=..GetColumnNamesSQL(parent.sql,.cols)
		} else {
			Set tSC=..GetColumnNamesQuery(parent.queryClass,parent.queryName,.cols)
		}
		set colnum=""
		set colnum=$o(cols(colnum))
		while (colnum'="") {
			Set field=cols(colnum)
			set cond=""
			set sep=""
			for g=1:1:list.Count() if +(list.GetAt(g).inTable)=0 set cond=cond_sep_"($zcvt("""_list.GetAt(g).field_""",""u"")="""_$zcvt(cols(colnum),"u")_""")" set sep="||"
			Do pOutput.WriteLine("<item field='@"_field_"' "_$s((cond'=""):" includeColUnlessExpression='"_cond_"'",1:"")_">")
			Do pOutput.WriteLine("<caption value='"_field_"' "_$s((cond'=""):" includeColUnlessExpression='"_cond_"'",1:"")_"/>")
			Do pOutput.WriteLine("</item>")
			set colnum=$o(cols(colnum))
		}
		Do pOutput.WriteLine("</table>")
		// End Groups
		For g = 1:1:list.Count() {
			Do pOutput.WriteLine("</group>")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	quit tSC
}

ClassMethod GetColumnNamesSQL(sql As %String, ByRef cols As %String)
{
	// Get column names for SQL statement
	try {
		Set sc=$$$OK			
		Set rset = ##class(%ResultSet).%New()
		Do rset.Prepare(sql)
	    Set columns = rset.GetColumnCount()
		// Execute the query
		Set sc = rset.Execute()
		// Now fetch the results
	    For col = 1:1:columns {
	        Set colname=rset.GetColumnName(col)
	        Set cols(col)=colname
	    }
	
		Do rset.Close()
	}
	Catch(ex) {
		Set sc= ex.AsStatus()
	}

	quit sc
}

ClassMethod GetColumnNamesQuery(queryClass As %String, queryName As %String, ByRef cols As %String)
{
	// Get column names for query
	try {
		Set Status=$ZObjClassMethod(queryClass,queryName_"GetInfo",.colinfo,.paraminfo,.idinfo,.qHandle)
		If $$$ISERR(Status) Quit 
		
		For i=1:1:$LL(colinfo) {
			Set colname=$LI($LI(colinfo,i),1)
			Set cols(i)=colname
		}
	}
	Catch(ex) {
		Set Status= ex.AsStatus()
	}
	quit Status
}

}
