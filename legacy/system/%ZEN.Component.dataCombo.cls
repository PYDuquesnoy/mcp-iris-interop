/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  A <class>dataCombo</class> is a specialized type of <class>abstractComboBox</class> that
///  presents the user with a set of options that are provided by querying the database.<br>
///  <br>
///  <div style="font-weight: bold;">Contents of the dataCombo Dropdown</div>
///  The contents of the <class>dataCombo</class> dropdown are provided by 
///  creating, executing, and fetching from a <class>%ResultSet</class> object on the server.<br/>
///  Initially the contents of the dropdown are empty until the user
///  causes the dropdown to appear at which point a call to the server is made to fetch the dropdown contents.
///  You can change this behavior by setting the <property>cached</property> property.<br/>
///  You can specify how this <class>%ResultSet</class> object is created using the properties
///  inherited from the <class>querySource</class> class.<br>
///  The number of columns returned by the <class>%ResultSet</class> determines
///  what is displayed within the dropdown list in the following way:
///  <ul>
///  <li>If the <class>%ResultSet</class> has one column, then the contents of this
///  column are used as both the logical and display values within the dropdown.</li>
///  <li>If the <class>%ResultSet</class> has two (or more) columns, then the contents of the
///  first column supply the logical value and the contents of the second
///  column supply the display values.
///  You can change which columns are used to provide the logical and display values
///  using the <property>valueColumn</property> and <property>choiceColumn</property> properties.</li>
///  <li>If the <class>%ResultSet</class> has more than two columns, then you can use
///  the <property>displayColumns</property> and <property>columnHeaders</property> 
///  properties to specify that the dropdown should display multiple columns (only one column will
///  be used for a display value).</li>
///  </ul>
///  <br>
///  <div style="font-weight: bold;">Logical and Display Values</div>
///  A combobox has two current values: a logical value (its internal value returned by the <method>getValue</method> method), and a display value (the value displayed to the user). (In some cases, the logical and display values may be the same).<br>
///  Unlike a traditional HTML select control, the ZEN dataCombo does not contain every possible logical/display value within its dropdown list. Instead it constructs the contents of its dropdown list on demand.
///  This behavior makes it much better suited for database applications (where the set of possible values can be long and unwieldy).<br>
///  When an application sets the value of a dataCombo control, it sets the 
///  <em>logical</em> value of the control. Internally, the dataCombo tries to find the display value that best matches this logical value. On the server, this works by executing the SQL statement defined
///  by the <property>sqlLookup</property> property of the dataCombo.<br>
///  On the client, the dataCombo first looks for a match for a given logical value within 
///  its dropdown cache. If it does not find a match, then it executes a server method to execute the <property>sqlLookup</property> query.<br>
///  For example: suppose we want to define a dataCombo to show a set of Customer names; the display value will be Name while the logical value is the ID of the Customer.
///  To do this we define a dataCombo using 2 SQL statements:
///  <example language="html">
///  <dataCombo id="MyCombo"
///  		sql="SELECT ID,Name FROM MyApp.Customer WHERE Name %STARTSWITH ? ORDER BY Name"
///  		sqlLookup="SELECT Name FROM MyApp.Customer WHERE ID = ?"
///  		editable="true"
///  		searchKeyLen="10"
///  	/>
///  </example>
///  This does the following:
///  <ol>
///  <li>The query defined by <property>sql</property> is called when the dropDown list is displayed. It provides a set of logical (ID) and display (Name) values. The ? parameter is supplied by the contents of the combobox text area at the time the dropdown appears (up to the first 10 characters are used, as specified by <property>searchKeyLen</property>). The dataCombo remembers the results of the last query it ran in a local cache.</li>
///  <li>The query defined by <property>sqlLookup</property> is used to find a specific display value for a specific logical value. The ? in this case is a logical value. This query should only return one row.</li>
///  </ol>
///  If, at run-time, the application tries to set the logical value of this combobox, then (if the answer is not in the cache) the <property>sqlLookup</property> query will be executed.<br>
///  <br>
///  <div style="font-weight: bold;">Query Parameters</div>
///  The query used to provide the contents of the dropdown list may contain
///  one or more run-time ? parameters (e.g., WHERE Name %STARTSWITH ?). If this 
///  is the case, the values for query parameters are provided as follows:
///  <ol>
///  <li>The <class>dataCombo</class> can define a <property>parameters</property> list.
///  The values of these parameters are used as query parameters when 
///  executing the query to fill the dropdown list. The parameter values will replace
///  ? parameters in the order in which they appear in the SQL query.<br/>
///  It is possible to modify the values of these parameters
///  within client code, if desired. The application should call the dataCombo's
///  <method>clearCache</method> in this case to make sure that the dropdown query
///  is re-executed with the new values.</li>
///  <li>If the <property>searchKeyLen</property> property is set to a non-zero value,
///  <em>and</em> the dataCombo is editable, then the current contents (the first 
///  <property>searchKeyLen</property> characters) of the combo
///  input box are used as the value for the first query parameter. (first
///  ? appearing within the query).
///  In this case, additional members of the <property>parameters</property> list are treated
///  as if they start from the second position within the list (the first being the search key).
///  Any additional ? parameters within the SQL are provided from the <property>parameters</property>
///  list, with one exception: if any parameter value is equal to "?", then the
///  current search key value (i.e., the value used for the first parameter) will
///  also be used for this query parameter.
///  </li>
///  </ol>
Class %ZEN.Component.dataCombo Extends (abstractComboBox, querySource) [ Deprecated, Inheritance = right, System = 3 ]
{

Parameter DOMAIN = "%ZEN";

///  Indicates that this combobox should cache its dropdown contents.
Parameter USECACHEDIV = 1;

///  If true (the default), then display multiple columns in the drop
///  down box if the result set contains more than 2 columns.
Property multiColumn As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  If there are multiple data columns displayed within the dropdown list
///  this is the column number (1-based) of the column that will provide the display
///  value for this control.<br>
///  If this value is greater than the number of columns in the query
///  then the second column will be used.
Property choiceColumn As %ZEN.Datatype.integer(MINVAL = 1, ZENSETTING = 0) [ InitialExpression = 2 ];

///  If there are multiple data columns displayed in the dropdown list
///  this is the column number (1-based) of the column that will provide the logical
///  value for this control.<br>
///  If this value is greater than the number of columns in the query
///  then the first column will be used.
Property valueColumn As %ZEN.Datatype.integer(MINVAL = 1, ZENSETTING = 0) [ InitialExpression = 1 ];

///  If there are multiple data columns displayed in the dropdown list,
///  this optional property defines a comma-delimited list of the column numbers
///  of the column that should be displayed.
Property displayColumns As %ZEN.Datatype.csv(ZENSETTING = 0);

///  If defined, this is a comma-delimited list of column
///  headers displayed in the dropdown list.
Property columnHeaders As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

///  Indicates how display values should be rendered:<br>
///  If <property>contentType</property> is "text" (the default) then the display values
///  will be HTML-escaped before being rendered.<br>
///  If <property>contentType</property> is "html" then the display values
///  will not be HTML-escaped before being rendered. 
///  Use this when your display values contain HTML markup that you do not want escaped.<br>
Property contentType As %ZEN.Datatype.string(VALUELIST = ",text,html") [ InitialExpression = "text" ];

///  Optional.
///  If there are multiple data columns displayed in the dropdown list
///  this is the comma-delimited (1-based) list of the column numbers that will provide additional auxiliary
///  values for this control.<br>
///  This provides a way to supply an additional value that is not
///  the display or logical value.<br>
///  If this value is not a valid column number, then no auxiliary data will be provided.
Property auxColumn As %ZEN.Datatype.string [ InitialExpression = "1" ];

///  If non-zero, this is the maximum number of search characters
///  taken from the combo input box and passed as a parameter to 
///  the query (defined by <property>sql</property> that provides the contents of the dropdown box.<br>
///  If zero, then the contents of the input box are not used as a parameter.
Property searchKeyLen As %ZEN.Datatype.integer(MINVAL = 0) [ InitialExpression = 0 ];

///  (optional) SQL statement that, given a value, finds a display
///  value to show in the combo box. If present, this is used
///  to find a display value for a given logical value.<br>
///  The value of this property should be an SQL statement that
///  returns a single row containing a display value for a given logical value.
///  When this query is executed, a logical value is provided as a query
///  input parameter (i.e., as a ? within the SQL statement.<br>
///  For example:<br>
///  <example language="html">
///  sqlLookup="SELECT Name FROM MyApp.MyTable WHERE ID = ?" 
///  </example>
Property sqlLookup As %ZEN.Datatype.sql(ZENSETTING = 0);

///  Server-side diagnostic flag. If true, display the query used
///  to get data for the dropdown.<br/>
///  This is an encrypted value and cannot be set on the client.
Property showQuery As %ZEN.Datatype.boolean(ZENENCRYPT = 1, ZENEXPRESSION = 1) [ InitialExpression = 0 ];

///  If true (the default), insert an extra row with the value of <property>emptyText</property>
///  at the top of the dropdown, unless <property>required</property> is true.
Property showEmpty As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  The text to be displayed in the "empty" item displayed if 
///  <property>showEmpty</property> is true. The default is "".
Property emptyText As %ZEN.Datatype.caption;

///  If true (the default is false) then the following behavior occurs:
///  <ol>
///  <li>When the page is first displayed, a query is executed to fetch the initial contents of the dropdown. The <property>itemCount</property> property
///  will be set to the number of items within the dropdown.</li>
///  <li>The client will use these results instead of going back to the server to fetch the contents of the dropdown.</li>
///  </ol>
///  The <method>clearCache</method will clear the dropdown cache, so will
///  modifying the search parameters for the query.
Property cached As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If this is set true and this dataCombo is bound to a data controller,
///  then the contents of this combo box will be cleared whenever a new
///  instance is loaded into the controller.
Property clearOnLoad As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  Internal property<br> 
///  client flag used to track if data for the
///  dropdown has been loaded.
Property dataLoaded As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

///  User-defined list of query parameters.<br>
///  These values are passed on
///  to the user callback function that provides the query for this component
///  in order to provide values for any run-time query parameters.
Property parameters As list Of %ZEN.Auxiliary.parameter(XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

///  A list of conditions. These are special expression objects that
///  are evaluated to add data-dependent styles to the dataCombo.
Property conditions As list Of %ZEN.Auxiliary.condition(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE");

///  Localized "loading" message displayed by control.<br>
///  This message is temporarily displayed while a server-side query is running.
Property loadingMessage As %ZEN.Datatype.caption;

///  Internal property.<br> 
///  Used for bound dataCombo controls.
Property modelClass As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

///  onshowDropdown event handler:
///  This event is fired just before the dropdown is displayed.
///  If the event handler returns a value, then this value is used as
///  the filter value for the dropdown query instead of the value typed into
///  the input box.
Property onshowDropdown As %ZEN.Datatype.eventHandler;

///  Number of items in the drop down.<br>
///  Note that this value is set as a side effect of populating the
///  dropdown list. When a dataCombo is first displayed, it typically
///  has no entries in its dropdown list until the user causes the dropdown
///  to appear. After this, <property>itemCount</property> will be set to the
///  current number of items in the dropdown.<br>
///  If you set the <property>cached</property> to true, then the dropdown
///  list will be populated when the control is initially displayed and <property>itemCount</property>
///  will be set. Note that in this case, the value is set <i>after</i> the page's %OnAfterCreatePage
///  callback method is invoked.
Property itemCount As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

Method %DrawHTML()
{
	Do ##super()
	If (..loadingMessage="") {
		Set ..loadingMessage = $$$Text("Loading...","%ZEN")
	}
}

///  This method fills in reasonable default values for
///  this control. Used by tools (such as Control Tester) to
///  dynamically create controls.
Method %SetDefaultValues()
{
	#; default query for testing
	Set ..queryClass = "%ZEN.Utils"
	Set ..queryName = "EnumerateComponents"
	Set ..multiColumn = 0
	Set ..editable = 1
}

///  Lookup up the display value for the combobox given
///  a logical value.<br>
///  This is called when the control is initially drawn.
Method %GetDisplayValue(pValue As %String) As %String
{
	Set tDisplay = pValue
	If (pValue="")&&(..showEmpty)&&('..required)&&(..emptyText'="") {
		Set tDisplay=..emptyText
	}
	Do {
		Set tModelClass = ..modelClass
		#; if we are not linked to the model, get it via the form
		If ((..dataBinding'="")&&(..modelClass="")) {
			Set tForm = ..%GetForm()
			If ($IsObject(tForm)&&$IsObject(tForm.%controller)) {
				Set tModelClass = tForm.%controller.modelClass
			}
		}
		Set tModelClass = $$$ZENVAL(tModelClass)
		Set tLookup = ..sqlLookup
		
		If ((tLookup="")&&(..dataBinding'="")&&(tModelClass'="")) {
			#; find query from model
			Set tSC = $zobjclassmethod(tModelClass,"%GetLookupSQL",..dataBinding,.sql,.tLookup)
			
		}
		
		#; if sqlLookup is defined, use it
		If ((pValue '= "") && (tLookup '= "")) {
			Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
			Set tSC = tStatement.%Prepare(tLookup)
			If ($$$ISERR(tSC)) {
				Quit
			}
			Set tRS = tStatement.%Execute(pValue)
			If tRS.%SQLCODE {
				Quit
			}
			#; assume one result
			If (tRS.%Next()) {				
				Set tDisplay = tRS.%GetData(1)
			}
			Else {
				#; no result
				Set tDisplay = ""
			}
		}		
		#; if sql is defined use that
		#; as we can't make any assumption over the semantic of the used query
		#; loop over it and compare pValue to ..valueColumn
		elseIf ((pValue'="") && (..sql'="") && (..valueColumn'="")) {
			Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
			Set tSC = tStatement.%Prepare(..sql)
			If ($$$ISERR(tSC)) {
				Quit
			}
			Set tRS = tStatement.%Execute()
		   
			If tRS.%SQLCODE {
				Quit
			}
			
			Set colCount=tRS.%ResultColumnCount 
            Set ..choiceColumn=$S(colCount=1:1,..choiceColumn>colCount:2,1:..choiceColumn) 
         
			while (tRS.%Next()) {				
				if (pValue=tRS.%GetData(..valueColumn)){
					Set tDisplay = tRS.%GetData($S(..choiceColumn'="":..choiceColumn,1:1))
					Quit					
				}
			}
		}
		
	} While(0)
	Quit $S(..contentType="text":tDisplay,1:$ZCVT(tDisplay,"I","HTML"))
}

///  If implemented, allow control to provide initial contents of cache div.
Method %OnDrawCacheDiv() As %Boolean [ Internal ]
{
	If ..cached {
		Set searchParm = ""
		Set tSC = ..%DrawDropDownContents(searchParm,.tCount)
		Set ..itemCount = tCount
		Set ..dataLoaded = 1
	}
	Else {
		Set ..dataLoaded = 0
		Set ..itemCount = 0
	}
	Quit 1
}

///  Internal method.<br>
///  Server-side method to provide contents of the list box.
///  This is called from the client.
Method %DrawDropDownContents(searchParm As %String, Output pCount As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set $ZT="Trap"
	Set tRS = ""
	Set tHasDisplay = 0
	Set tMaxRows = ..maxRows
	Set tCount = 0

	#; create result set
	#; For query parameters use the values that come from 
	#; the *parameters* property.
	#; If searchKeyLen is non-zero, then ignore parameter(1)
	#; and use the searchParm instead.
	#; Special case: if you set a parameter (other than parameter(1))
	#; to "?", then searchParm will be used for this parameter as well.
	#; This is for special cases where the searchParm needs to occur multiple
	#; times within a query 

	#; create QueryInfo object to hold query info
	Set tInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()

	#; additional query parms
	Set tInfo.tableName = $$$ZENVAL(..tableName)
	Set tInfo.columnName = $$$ZENVAL(..columnName)
	Set tInfo.whereClause = $$$ZENVAL(..whereClause)
	Set tInfo.orderByClause = $$$ZENVAL(..orderByClause)
	Set tInfo.groupByClause = $$$ZENVAL(..groupByClause)

	#; do we have a searchParm
	Set adj = 0
	If (..editable && (..searchKeyLen > 0)) {
		Set tInfo.parms(1) = searchParm
		Set adj = 1 // skip first parameter
	}

	#; look at parameters to get values for additional ? parms
	Set tParmCount = ..parameters.Count()
	For n=1:1:tParmCount {
		Set tParam = ..parameters.GetAt(n)
		Set tVal = $$$ZENVAL(tParam.value)
		Set tInfo.parms(n+adj) = $S(tVal="?":searchParm,1:tVal)
	}

	Set tModelClass = $$$ZENVAL(..modelClass)

	#; if we are not linked to the model, get it via the form
	If ((..dataBinding'="")&&(tModelClass="")) {
		Set tForm = ..%GetForm()
		If ($IsObject(tForm)&&$IsObject(tForm.%controller)) {
			Set tModelClass = $$$ZENVAL(tForm.%controller.modelClass)
		}
	}

	#; remember original query, so we can restore it
	Set tSQL = ..sql
	If ((tSQL="")&&(..queryClass="")&&(..queryName="")&&(..dataBinding'="")&&(tModelClass'="")) {
		#; find query from model
		Set tSC = $zobjclassmethod(tModelClass,"%GetLookupSQL",..dataBinding,.sql,.sqllk)
		If $$$ISERR(tSC) Quit tSC
		Set ..sql = $G(sql)
	}

	Set tRS = ..%CreateResultSet(.tSC,tInfo)

	Set ..sql = tSQL  // restore original SQL
	If $$$ISERR(tSC) Quit tSC
	If (..showQuery) {
		#; show query and parm values as a diagnostic aid
		&html<query:<br/><pre class='debugsqlquerypre'>#(tInfo.queryText)#</pre>>
		Set p = $O(tInfo.parms(""))
		While (p '= "") {
			Write "P",p," = '",$ZCVT(tInfo.parms(p),"O","HTML"),"'&nbsp;"
			Set p = $O(tInfo.parms(p))
		}
		&html<<hr/>>
	}

	Set tInfo = ""

	If ($IsObject(tRS)) {
		Set tStyle=""
		Set tColCount = tRS.%ResultColumnCount
		Set tColCount = $S(..multiColumn:tColCount,tColCount=1:1,1:2)
		Set tValueCol = +$S(tColCount=1:1,..valueColumn<=tColCount:..valueColumn,1:1)
		Set tChoiceCol = +$S(tColCount=1:1,..choiceColumn<=tColCount:..choiceColumn,1:2)		
		#; leaving in as default		
		Set tAuxCol = +$S((..auxColumn>0)&&(..auxColumn<=tColCount):..auxColumn,1:0)
		
		If (tColCount >= 1) {			
			#; check indices of columns to use as auxValue
			If (..auxColumn '= "") {
				For n = 1:1:$L(..auxColumn,",") {
					Set tColIdx(n) = +$P(..auxColumn,",",n)
					If (tColIdx(n)=0) {
						Set tSC = $$$ERROR($$$GeneralError,"auxColumn must contain integer values")
						Quit
					}
					if (n>tColCount){
						#; Oh srsly? (more auxcolumns than columns??)
						Set tSC = $$$ERROR($$$GeneralError,"auxColumn must have fewer values than we have columns")
						Quit						
					}
				}
				#; now that we know ..auxColumn values are sane, set them up for usage
				Set:$$$ISOK(tSC) tAuxCol=..auxColumn				
			}
			If (..displayColumns '= "") {
				For n = 1:1:$L(..displayColumns,",") {
					Set tColIdx(n) = +$P(..displayColumns,",",n)
					If (tColIdx(n)<=0) {
						Set tSC = $$$ERROR($$$GeneralError,"displayColumns must contain integer values  >0")
						Quit
					}
				}
				Set tColCount = n
			}
			Else {
				Set n = 1
				For c=1:1:tColCount {
					If (c '= tValueCol) {
						Set tColIdx(n) = c
						Set n = n + 1
					}
				}
			}
		}
		If $$$ISERR(tSC) Quit tSC
		
		

		#; build list of conditions for the table
		#; organized by column name
		For i=1:1:..conditions.Count() {
			Set tCondition = ..conditions.GetAt(i)
			If $IsObject(tCondition) {
				Set tColName = $$$ZENVAL(tCondition.colName)
				If (tColName '="") {
					Set tCellStyle = $$$ZENVALHTML(tCondition.cellStyle)
					Set tRowStyle = $$$ZENVALHTML(tCondition.rowStyle)
					If (tCellStyle '= "") {
						#; cell condition
						Set tTargetCol = $$$ZENVAL(tCondition.targetCol)
						Set tTarg = $S(tTargetCol'="":tTargetCol,1:tColName)
						Set idx = 1 + $G(tCellCondition(tTarg))
						Set tCellCondition(tTarg) = idx
						Set tCellCondition(tTarg,idx) = tCondition
					}
					If (tRowStyle '= "") {
						#; row condition
						Set idx = 1 + $G(tRowCondition)
						Set tRowCondition = idx
						Set tRowCondition(idx) = tCondition
					}
				}
			}
		}
		
		#; build DHTML table to show results
		&html<<table class="comboboxTable" width="100%" border="0" cellpadding="0" cellspacing="0">>

		If ((..columnHeaders '= "") && (..columnHeaders '= $C(0))) {
			#; column headers
			&html<<tr>>
			If (tColCount = 1) {
				Set tHeader = $P(..columnHeaders,",",1)
				&html<<th>#($ZCVT(tHeader,"O","HTML"))#&nbsp;</th>>
			}
			Else {
				Set n = 1
				Set c = $O(tColIdx(""))
				While (c '= "") {
					Set tHeader = $P(..columnHeaders,",",n)
					&html<<th>#($ZCVT(tHeader,"O","HTML"))#&nbsp;</th>>
					Set n = n + 1
					Set c = $O(tColIdx(c))
				}
			}
			&html<</tr>>
		}
		if '(tRS.%IsA("%Library.ResultSet")) {
			set tMetadata = tRS.%GetMetadata()
			set tColumn = $Order(tMetadata.columnIndex(""))
			while tColumn '= "" {
				set tColumnNbr = $List(tMetadata.columnIndex(tColumn),1)
				set tColumns(tColumnNbr) = $List(tMetadata.columnIndex(tColumn),2)
				set tColumn = $Order(tMetadata.columnIndex(tColumn))
			}
		}
		#; insert blank value at the top
		If (('..required) && (..showEmpty)) {
			Set tAuxAttr = "zenAux="""""""
			Set tValAttr = "zenValue="""""""
			Set tTextAttr = "zenText="""""""
			Set tCls = "comboboxItem"
			Set tData = ""
			Set tText = $S(..contentType="text":$ZCVT(..emptyText,"O","HTML"),1:..emptyText)
			Set tTextAttr = "zenText="""_tText_""""
			Do DrawRow()
			Set tCount = 1
		}

		#; iterate over rows
		Set tSC = $$$OK
		While (tRS.%Next(.tSC) && ((tMaxRows = 0) || (tCount < tMaxRows))) {
			If $$$ISERR(tSC) Quit
			Set tValue = $S(+tValueCol:tRS.%GetData(tValueCol),1:"")
			Set:tValue=$C(0) tValue=""
			Set tText = $S(+tChoiceCol:tRS.%GetData(tChoiceCol),1:"")			
			Set:tText=$C(0) tText=""

			#; at this point tAuxCol has a comma-separated list of columns to use as values
			If (tAuxCol'=""){				
				If ($L(tAuxCol,",")=1){					
					#; old behaviour of 1 defined auxColumn
					Set tAuxValue = $S(+tAuxCol:tRS.%GetData(+tAuxCol),1:"")
					Set:tAuxValue=$C(0) tAuxValue=""
					Set tAuxValue = $ZCVT(tAuxValue,"O","HTML")
					Set tAuxAttr = "zenAux="""_tAuxValue_""""
				} else {
					Set values=""
					#; multiple auxColumns -> create an array
					Set temp=##class(%GlobalCharacterStream).%New()
					Do temp.Write("{")					
					for i=1:1:$L(tAuxCol,",") {
						#; we need a comma after the x-th entry (for x>1)
						Do:i>1 temp.Write(",") 
						#; note that this will fail as soon as it hits ~32K (when converting back to string)
						#; you really should rethink your application design if you hit ~32K on each row of a datacombo!						
						set val=tRS.%GetData(+$P(tAuxCol,",",i))
						Set:val=$C(0) val=""						
						#; add to string, escaping '"' and '''						
						d temp.Write("""val"_i_""":"""_$ZCVT($REPLACE(val,"""","\"""),"O","HTML")_"""")
					}
					Do temp.Write("}")
					Do temp.Rewind()
					set tAuxAttr="zenAux='"_temp.Read(32000)_"'"
					Do temp.Clear()
					k temp
				}
			}			

			Set tValue = $ZCVT(tValue,"O","HTML")
			Set tText = $S(..contentType="text":$ZCVT(tText,"O","HTML"),1:tText)
			Set tValAttr = "zenValue="""_tValue_""""
			Set tTextAttr = "zenText="""_tText_""""
			Set tCls = "comboboxItem"
			Do DrawRow()
			Set tCount = tCount + 1
		}
	
		If $$$ISOK(tSC) {
			If (tCount > 0 && tRS.%Next()) {
				#; more rows
				Set tColSpan = $S(tColCount>1:tColCount-1,1:1)
				&html<<tr onmousedown="zenPage.endModal();"><td colspan="#(tColSpan)#"><i>#("...")#</i></td></tr>>
			}

			If (tCount = 0) {
				// endModal
				Set tNoMatches = $$$TextHTML("No matches")
				&html<<tr><td onmousedown="zenPage.endModal();"><i>#(tNoMatches)#</i></td></tr>>
			}
		}

		&html<</table>>
	}

	Set pCount = tCount
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,"Error running query: " _ $ZE)
	Goto Done

	#; common code to draw row of the dropdown
DrawRow() 
		

	#; see if there are any row conditions
	set tRowStyle = ""
	Set tName = $O(tRowCondition(""))
	if tRS.%IsA("%Library.ResultSet") {
		merge q = tRS.Data
	}
	else {
		set tColumn = $Order(tMetadata.columnIndex(""))
		while tColumn '= "" {
			set tColumnName = $List(tMetadata.columnIndex(tColumn),2)
			set q(tColumnName) = tRS.%Get(tColumnName)
			set tColumn = $Order(tMetadata.columnIndex(tColumn))
		}
	}
	While (tName '= "") {
		#; evaluate condition
		Set tCondition = tRowCondition(tName)
		Set tEval = tCondition.Eval(.q)
		If (tEval) {
			Set tRowStyle = tRowStyle _ $$$ZENVALHTML(tCondition.rowStyle)
		}
		Set tName = $O(tRowCondition(tName))
	}
	Set:tRowStyle'="" tRowStyle=" style="""_tRowStyle_""""
	
	#; TSL, 7/1/2011: Modified end of tag to insert tRowStyle for this row.
	&html<<tr id="#(..%MakeId("item_"_tCount))#" class="#(tCls)#" onmousedown="zenPage.getComponent(#(..index)#).itemMouseDown(event,#(tCount)#);" onmouseup="this.style.color='';zenPage.getComponent(#(..index)#).itemMouseUp(event,#(tCount)#);" #(tValAttr)# #(tTextAttr)# #($G(tAuxAttr))# #(tRowStyle)# >>
	If (tColCount = 1) {
		&html<<td><a href="#">#($S(tText="":"&nbsp;",1:tText))#</a></td>>
	}
	Else {
		Set c = $O(tColIdx(""))
		While (c '= "") {
			Set tCellStyle = ""
			Set tData = tRS.%GetData(tColIdx(c))
			Set:tData=$C(0) tData=""		
		    #; handle cell condition styles
		    if tRS.%IsA("%Library.ResultSet") {
			    set tColumnName = tRS.GetColumnName(tColIdx(c))
		    }
		    else {
			    set tColumnName = tColumns(tColIdx(c))
		    }
			Set idx = $O(tCellCondition(tColumnName,""))
			While (idx '= "") {
				#; evaluate condition
				Set tCondition = tCellCondition(tColumnName,idx)
				Set tEval = tCondition.Eval(.q)
				If (tEval) {
					Set tCellStyle = tCellStyle _ $$$ZENVALHTML(tCondition.cellStyle)
				}
				Set idx = $O(tCellCondition(tColumnName,idx))
			}
			Set:tCellStyle'="" tCellStyle=" style="""_tCellStyle_""""
		
			if (..multiColumn) {
				&html<<td #(tCellStyle)#><a #(tCellStyle)# href="#">#($S(tData="":"&nbsp;",..contentType="text":$ZCVT(tData,"O","HTML"),1:tData))#</a></td>>
			} else {
			    &html<<td #(tCellStyle)#><a #(tCellStyle)# href="#">#($S(tText'="":tText,1:"&nbsp;"))#</a></td>>
			}
			Set c = $O(tColIdx(c))
		}
	}
	&html<</tr>>
	Quit
}

///  Internal method.<br>
///  Server-side method to load contents of the drop down box
///  by executing query associated with this control.
///  If <var>cached</var>, load contents into cache div
Method LoadDropDownContents(searchParm As %String, cached As %Boolean = 0) [ Internal, ZenMethod ]
{
	#; stop progress bar
	&js<zenPage.getComponent(#(..index)#).stopProgressBar();>

	#; invoke method to draw dropdown contents
	#; find div to hold content
	If ('cached) {
		&js<var div = zenPage.getComponent(#(..index)#).getDropDownDiv();>
	}
	Else {
		&js<var div = zenPage.getComponent(#(..index)#).getCacheDiv();>
	}
	&js<zenASSERT(div,"Unable to find drop down div element.",arguments);>

	#; execute our %DrawDropDownContents method and capture it as JavaScript
	Write "var html = '"

	#; use JS output to properly escape HTML for JS
	Set io = ##class(%ZEN.Controller).%BeginJSTranslation()
	Set tSC = ..%DrawDropDownContents(searchParm,.tCount)
	Do ##class(%ZEN.Controller).%EndJSTranslation(io)
	Write "';",!

	Write "div.innerHTML = html;",!
	Write "html=null;",!

	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorJS($this,tSC)
		&js<zenPage.endModal();>
		Quit
	}

	#; update client focus, flags, & item count
	&js<
		var xcb = zenPage.getComponent(#(..index)#);
		xcb.selectedIndex = -1;
		xcb.dataLoaded = true;
		xcb.itemCount = #(tCount)#;
		zenPage.correctIELayering(xcb.getDropDownDiv());
	>
	If ('cached) {
		&js<
			var input = xcb.findElement('input');
			if (input) {
				input.focus();
			}
			xcb.isDropdownVisible = (div.style.display != 'none');
			xcb.findSelectedItem();
		>
	}
	Else {
		&js<
			xcb._hasCache = true;
		>
	}
}

///  Execute the server-side associated with this dataCombo
///  using <var>param</var> as an input parameter.<br>
///  Note: the results of running this query are not displayed,
///  instead the results are written to the cache div element maintained
///  by the dataCombo.<br>
///  The searchKeyLen property is used to truncate the
///  value of <var>param</var>.<br>
///  The query is executed asynchronously, so results may not be available 
///  immediately.
ClientMethod executeQuery(param) [ Language = javascript ]
{
	this.loadDropdown(param,false);
}

///  Internal method.<br>
///  Create contents of drop down box using DHTML.
///  If <var>loadOnly</var> is defined and true, then
///  load the contents into the cached div, but do not show.
ClientMethod renderDropdown() [ Internal, Language = javascript ]
{
	// get search value from input box
	var input = this.findElement('input');
	zenASSERT(input,'Unable to find input element',arguments);
	var value = input.value;
	this.loadDropdown(value,true);
}

///  Internal method.<br>
///  Create contents of drop down box using DHTML.
///  <var>value</var> is used as search filter.
///  If <var>show</var> is false, then
///  load the contents into the cached div, but do not show.
ClientMethod loadDropdown(value, show) [ Internal, Language = javascript ]
{
	value = (null == value) ? '' : value;

	// invoke callback
	if (show) {
		ret = zenInvokeCallbackMethod(this.onshowDropdown,this,'onshowDropdown');
		if (null != ret) {
			value = ret;
		}
	}

	// trim value
	if (this.searchKeyLen >= 0) {
		value = value.substr(0,this.searchKeyLen);
	}

	// if we have a local cache, show it
	var cache = this.getCacheDiv();
	if (this.cached && cache.innerHTML != '') {
		this._hasCache = true;
		if (null == this.lastValue && value == '') {
			this.lastValue = '';
		}
	}
	else this._hasCache = false;

	if (cache) {
		if ((this._hasCache) && this.dataLoaded && (this.lastValue == value)) {
			if (show) { 
				// no need to reload dropdown; copy from cache
				var div = this.getDropDownDiv();
				div.innerHTML = cache.innerHTML;
				cache.innerHTML = '';
				delete this._hasCache;
		
				// give focus to input box
				var input = this.findElement('input');
				if (input) {
					input.focus();
				}
				this.isDropdownVisible = true;
				this.findSelectedItem();
			}
			return;
		}
		else {
			cache.innerHTML = '';
			delete this._hasCache;
		}
	}


	this.dataLoaded = false;
	this.lastValue = value;

	if (show) { 
		// register that we used the modal div!
		zenPage.lastModalIndex = this.index;
	
		var div = this.getDropDownDiv();
		// display progress bar, if needed
		this.startProgressBar(div);

		div.innerHTML = '<span class="comboboxLoading">' + this.loadingMessage + '</span>';
	}

	// if we are bound to a dataController, get additional info
	// to pass to the server.
	this.modelClass = '';
	var form = this.getForm();
	if (form) {
		var controller = form.getController();
		if (controller) {
			this.modelClass = controller.getProperty('modelClass');
		}
	}

	// call server method
	this.LoadDropDownContents(value,show?0:1);
}

///  Clears any cached data held by this control.
///  This will force the dropdown to re-execute its query the next time
///  the dropdown is displayed.
ClientMethod clearCache() [ Language = javascript ]
{
	this.dataLoaded = false;
	delete this._hasCache;
	var cache = this.getCacheDiv();
	if (cache) {
		cache.innerHTML = '';
	}
}

///  Return the current number of items within in the dropdown list.<br>
ClientMethod getOptionCount() [ Language = javascript ]
{
	return (this.itemCount!=null) ? this.itemCount : 0;
}

///  Return the logical value of the given item (0-based) in the dropdown list.<br>
ClientMethod getOptionValue(idx) [ Language = javascript ]
{
	// find matching row
	var value = '';
	var tr = self.document.getElementById('item_' + idx + '_' + this.index);
	if (tr) {
		value = tr.getAttribute('zenValue');
	}
	return value;
}

///  Return the display value for the given item (0-based) in the dropdown list.<br>
ClientMethod getOptionText(idx) [ Language = javascript ]
{
	// find matching row
	var value = '';
	var tr = self.document.getElementById('item_' + idx + '_' + this.index);
	if (tr) {
		value = tr.getAttribute('zenText');
	}
	return value;
}

///  Return the auxiliary value for the given item (0-based) in the dropdown list.<br>
ClientMethod getOptionAux(idx) [ Language = javascript ]
{
	// find matching row
	var value = '';
	var tr = self.document.getElementById('item_' + idx + '_' + this.index);
	if (tr) {
		value = tr.getAttribute('zenAux');
	
	}
	return value;
}

///  Return the current auxiliary value (if any) for the dropdown list.<br>
ClientMethod getAuxValue() [ Language = javascript ]
{
	if (this.selectedIndex < 0) return '';
	var value = this.getOptionAux(this.selectedIndex);
	return (null==value) ? '' : value;
}

///  Given a logical value, lookup the display value within the current set of
///  options. Returns null if no match is found.<br>
///  Subclasses may override this to add additional lookup behavior.
ClientMethod findDisplayValue(value) [ Language = javascript ]
{
	// first try to find value in current set
	var text = this.invokeSuper('findDisplayValue',arguments);

	// if not found *and* we have an sqlLookup defined, call server to
	// find the value
	if (null == text && ('' != this.sqlLookup)) {
		// make sure we pass the model to the server
		var form = this.getForm();
		if (form) {
			var controller = form.getController();
			if (controller) {
				this.modelClass = controller.getProperty('modelClass');
			}
		}
		text = this.LookupDisplayValue(value);
	}

	return text;
}

///  Internal method.<br>
///  Server-side method to find a display value for a logical value
///  by executing the sqlLookup query associated with this control.
Method LookupDisplayValue(value As %String) As %String [ Internal, ZenMethod ]
{
	Quit ..%GetDisplayValue(value)
}

///  User has selected an item in the DropDown box.
///  If <var>show</var> is true, make item visible.
///  If <var>update</var> is true, update value of control.
ClientMethod selectItem(idx, show, update) [ Language = javascript ]
{
	var out = zenPage.getComponentById('events');

	// update value of main controls
	var input = this.findElement('input');
	var hidden = this.findElement('hidden');
	zenASSERT(input,'Unable to find input element',arguments);
	zenASSERT(hidden,'Unable to find hidden element',arguments);

	var value,text;
	
	// unhighlight old select
	if (parseInt(this.selectedIndex,10) >= 0) {
		var el = this.getItemEl(parseInt(this.selectedIndex,10));
		if (el) {
			el.className = 'comboboxItem';
			
			//revert to old style for deselected row.
			this.restoreConditionalStyle(el);
		}
	}

	// find number of items in dropdown list
	var size = this.getOptionCount();

	if (idx < 0 || idx > size) {
		this.selectedIndex = -1;
		value = '';
		text = '';
	}
	else {
		idx = parseInt(idx,10);
		this.selectedIndex = idx;
		value = this.getOptionValue(idx);
		text = this.getOptionText(idx);

		var el = this.getItemEl(this.selectedIndex);
		if (el) {
			el.className = 'comboboxItemSelected';
			
			// save style and clear for the selected row.
			this.storeConditionalStyle(el);
			
			if (show && this.scrollIntoView) {
				if (this.selectedIndex == 0) {
					this.getDropDownDiv().scrollTop = 0;
				}
				else {
					zenScrollIntoView(this.getDropDownDiv(),el,!this.hzScroll);
				}
			}
		}
	}
	
	if (update) {
		this.value = value;
		this.text = text;
		hidden.value = value;
		input.value = text;

		// notify
		this.onchangeHandler();
	}
}

///  Stores the style for trEl, a row in the dropdown table.
///  This is used to handle selected-row style.
ClientMethod storeConditionalStyle(trEl) [ Language = javascript ]
{
	trEl.oldStyle = trEl.getAttribute("style");
	trEl.setAttribute("style","");
	for (var i = 0; i < trEl.children.length; i++) {
		this.storeConditionalStyle(trEl.children[i]);
	}
}

///  Retores the conditional style for trEl, a row in the dropdown table.
///  This is used to handle selected-row style.
ClientMethod restoreConditionalStyle(trEl) [ Language = javascript ]
{
	trEl.setAttribute("style",zenGet(trEl.oldStyle));
	for (var i = 0; i < trEl.children.length; i++) {
		this.restoreConditionalStyle(trEl.children[i]);
	}
}

///  Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'itemCount':
		break;
	case 'parameters':
		// set value of parameter: note that value will
		// be 1-based, so we have to convert it.
		// changing parameter always forces a query execution,
		// even in snapshot mode.
		if ('' != value) {
			value = value - 1;
			if (this.parameters[value]) {
				if (this.parameters[value].value != value2) {
					this.parameters[value].value = value2;
					this.clearCache();
				}
			}
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
		break;
	}

	return true;
}

}
