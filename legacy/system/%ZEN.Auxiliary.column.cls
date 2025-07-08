/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines column information for a <class>%ZEN.Component.tablePane</class>.<br>
/// This class lets you specify details for how a column should be displayed within
/// a tablePane. These details include:
/// <ul>
/// <li>Whether to hide a column (the <property>hidden</property> property)</li>
/// <li>Whether a column should display a link or action (the <property>link</property> property)</li>
/// <li>What header to use for a column (the <property>header</property> property)</li>
/// <li>Whether to display a search filter for a column along with details of the filter (the <property>filter</property> properties)</li>
/// <li>Additional styles for a column (the <property>style</property> property)</li>
/// </ul>
Class %ZEN.Auxiliary.column Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// If specified, name of data column this object is associated with.
/// If not specified, then this column is displayed without a
/// data value (typically used to display a link action in a row).<br/>
/// When used with a <class>%ZEN.Component.tablePane</class> component, this can also take one
/// of the following special values:<br/>
/// <ul>
/// <li>"$selector" - define a style for the special selector column in the table.</li>
/// <li>"$rownumber" - define a style for the row number column in the table.</li>
/// <li>"$checkbox" - define a style for the checkbox column in the table (when in multiSelect mode).</li>
/// </ul>
/// The name of a data column must be a valid name (and not an expression).
Property colName As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Internal property.<br>
/// This is used to hold the actual column name in the case where <property>colName</property>
/// is an #()# expression.
Property actualColName As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ Internal ];

/// Optional.
/// If defined, use this value for the column header.
Property header As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// If specified, this is an SQL expression used to get the value of this
/// column if the table is automatically constructing an SQL query.  If a subquery is to be
/// used as expression, it must be enclosed in braces.<br/>
/// For example: "FirstName||LastName"<br/>
///  "(select name from Sample.Person)"<br/>
/// If specified, colName must also be set. colExpression doesn't support column aliases, 
/// use colName instead. 
/// This value is encrypted and cannot be modified on the client.
Property colExpression As %ZEN.Datatype.string(ZENENCRYPT = 1);

/// Optional.
/// Tooltip help for column header.
/// This is a localizable value.
Property title As %ZEN.Datatype.caption;

/// Optional.
/// Tooltip help for data column.
/// This is a localizable value.
Property cellTitle As %ZEN.Datatype.caption;

/// Optional.
/// Additional style to apply to cells (td element) in this column.<br>
/// This is a CSS style string: e.g., "color: red;"
Property style As %ZEN.Datatype.style(ZENEXPRESSION = 1);

/// Optional.
/// If true, do not display this column.
Property hidden As %ZEN.Datatype.boolean(ZENEXPRESSION = 1);

/// Optional.
/// If true, do not allow sorting on this column.
Property disableSort As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional.
/// If defined, use this value as the width of the column.
Property width As %ZEN.Datatype.length(ZENEXPRESSION = 1);

/// Optional.
/// Name of Server-side callback method that provides HTML content
/// for cells within this column.<br>
/// If defined, this callback is invoked on the server when this 
/// component is drawn. It provides HTML content by using &html or
/// by using the WRITE command.<br>
/// This must be the name of a server-only method in the page
/// class that contains this view component.
Property OnDrawCell As %ZEN.Datatype.delegator(FORMALSPEC = "table:%ZEN.Component.tablePane,name:%ZEN.Datatype.string,seed:%ZEN.Datatype.string", RETURNTYPE = "%Status");

/// Optional.
/// This value is passed to the <method>OnDrawCell</method> method associated
/// with this column.
Property seed As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Optional.
/// If defined, render this column as a link using this URL.
/// If you want to invoke a method, start the URL with "javascript:":<br/>
/// link="javascript:zenPage.myMethod();"<br/>
/// Optionally, set this to "#" (to make the column display as a link) and
/// use the <property>onclick</property> event for this column.
Property link As %ZEN.Datatype.uri;

/// Optional. If provided, link has to be defined.
/// If defined, render this column as a link using the image provided by this URL 
/// pointing to the URI defined by link.
Property linkImage As %ZEN.Datatype.uri;

/// Optional.
/// If this column has an action (link or onclick) and does <em>not</em> contain
/// data, then use this caption for the link.
/// If linkCaption and linkImage is defined, linkCaption is used as alt text for the image.
Property linkCaption As %ZEN.Datatype.caption;

/// Optional.
/// If defined, and this column has a link, this is a confirmation
/// message displayed before the link is executed.<br/>
/// If there is an <property>onclick</property> defined for this column, then this
/// is ignored.<br/>
/// This is a localizable value.
Property linkConfirm As %ZEN.Datatype.caption;

/// Optional.
/// If defined, specifies that this column should display a
/// search filter box and what type of filter control to display.<br>
/// If you do not provide a value for <property>colName</property> then
/// the filter will not be created.<br>
/// The possible filter types include:
/// <ul>
/// <li>"text" - display a text box.</li>
/// <li>"date" - display a date using a popup calendar control.
/// If <property>filterOp</property> is "BETWEEN", then 2 controls are displayed.</li>
/// <li>"datetime" - same as "date" except that a complete timestamp (date and time) is used.</li>
/// <li>"enum" - display a set of enumerated values in a combobox. The possible choices are 
/// specified by <property>filterEnum</property> and <property>filterEnumDisplay</property>.</li>
/// <li>"query" - display a set of values in a combobox. The contents of the
/// combobox are provided by executing the query specified by <property>filterQuery</property>.</li>
/// <li>"custom" - display a custom filter using the server-side callback method specified by <property>OnDrawFilter</property>.</li>
/// </ul>
Property filterType As %ZEN.Datatype.string(VALUELIST = ",text,date,datetime,enum,query,custom");

/// Optional.
/// Value of the column filter for this column.<br>
/// Typically this acquires a value after user input, but you can
/// set this property to define an initial value.
Property filterValue As %ZEN.Datatype.value;

/// Optional.
/// If <property>filterType</property> is "enum", this property defines
/// the set of enumerated logical values used by the filter as a comma-delimited list.
Property filterEnum As %ZEN.Datatype.csv;

/// Optional.
/// If <property>filterType</property> is "enum", this property defines
/// the set of enumerated <b>display</b> values used by the filter as a comma-delimited list.<br>
/// The logical values are defined by <property>filterEnum</property>.<br>
/// This is a localized value.
Property filterEnumDisplay As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// Optional.
/// If <property>filterType</property> is "query", this property defines
/// the SQL statement used to provide the set of values for a drop-down list.
/// If the query has more than 1 column, the first column is used as
/// the logical value (this is what is used in a search) and the second column
/// is used as a display value.
Property filterQuery As %ZEN.Datatype.sql;

/// Optional.
/// If defined, this is a label to display for the filter control.
/// If there is a multi-part filter control (such as a range),
/// then this is assumed to contain a comma-delimited list of labels.
Property filterLabel As %ZEN.Datatype.caption;

/// Optional.
/// If this column has a filter, this is the name of the <b>SQL operator</b> 
/// that should be used in conjunction with the filter.<br>
/// For UP[, <property>filterValue</property> will be converted to a case insensitive value.<br>
/// For "IN", <property>filterValue</property> is treated as a csv-list of IN-clause values.<br>
/// For "%CONTAINS", <property>filterValue</property> is treated as a csv-list of %CONTAINS-clause values.<br>
/// For "BETWEEN", <property>filterValue</property> is treated as a csv-list of 2 values used for the BETWEEN clause of the query.<br>
Property filterOp As %ZEN.Datatype.string(VALUELIST = ",%STARTSWITH,=,>=,<=,<>,>,<,[,IN,BETWEEN,%CONTAINS,UP[");

/// Optional.
/// If this column has a filter, this is the tooltip text displayed 
/// for the filter control.<br>
/// This is a localizable value.
Property filterTitle As %ZEN.Datatype.caption;

/// Optional.
/// Name of server-side callback method that provides HTML content
/// for the filter displayed for this column. This is used when the
/// value of <property>filterType</property> is set to "custom".<br>
/// If defined, this callback is invoked on the server when this 
/// component is drawn. It provides HTML content by using &html or
/// by using the WRITE command.<br>
/// This must be the name of a server-only method (with the correct signature)
/// in the page class that contains this column object.
Property OnDrawFilter As %ZEN.Datatype.delegator(FORMALSPEC = "table:%ZEN.Component.tablePane,name:%ZEN.Datatype.string,colinfo:%ZEN.Auxiliary.column", RETURNTYPE = "%Status");

/// onclick event handler:
/// This event is fired when the mouse is clicked within a cell in this column.
/// If the column does not have data associated with it you will have to set
/// the <property>linkCaption</property> property.<br/>
/// Note that this callback is called <i>before</i> the new row in the table is selected
/// so you will not have the current selectedIndex for the table when this callback is fired.
/// If you need that, use the tablePane's onselectrow callback.
Property onclick As %ZEN.Datatype.eventHandler;

/// Optional.
/// If specified, this is the earliest date allowed by the filter if filterType is dateTime.
/// This is a date in the form "YYYY-MM-DD".<br>
Property minDate As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Optional.
/// If specified, this is the latest date allowed by the filter if filterType is dateTime.
/// This is a date in the form "YYYY-MM-DD".<br>
Property maxDate As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Return the column name for this column.
ClientMethod getColName() [ Language = javascript ]
{
	return (''==this.actualColName) ? this.colName : this.actualColName;
}

}
