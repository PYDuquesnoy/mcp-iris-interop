/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user add or edit the Field List for a Listing.<br>
/// An existing list (delimited by comma) may be passed in.
Class %DeepSee.UI.Dialog.FieldList Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property ELEMENT As %ZEN.Datatype.string(ZENURL = "ELEMENT");

Property Expression As %ZEN.Datatype.string(ZENURL = "VALUE");

Property WHAT As %ZEN.Datatype.string(ZENURL = "WHAT");

Property dataSource As %ZEN.Datatype.string(ZENURL = "DATASOURCE");

Property CONTEXT As %ZEN.Datatype.string(ZENURL = "CONTEXT");

/// Translation domain of the cube
Property domain As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
#dataSourceViewbox {
	display:inline-block; 
	height:400px; 
	max-height:400px; 
	overflow:auto;
	max-width:200px;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup labelPosition="left">
<label id="cubeName" label="Cube name:" enclosingClass="zenLabel"/>
<label id="ELEMENT" label="Element name:" enclosingClass="zenLabel"/>
</vgroup>
<label id="titleText" label="Use the form below to create and maintain a Field List. Select a field by double clicking a property from the tree." enclosingStyle="padding:2px;"/>
<hgroup cellStyle="padding:4px;" cellVAlign="top">
<group id="dataSourceViewbox" layout="none" >  
<dynaTree id="dataSource"  label="Source Class"
 imageContracted="images/disclosure-contracted.gif"
 imageExpanded="images/disclosure-expanded.gif"
 imageNode="images/spacer.gif"
 childIndent="10"
 ondblclick="zenPage.selectProperty(zenThis);" dragEnabled="false"
	showLines="false" showFolders="false"
	OnGetTreeInfo="GetDataSourceInfo">
<parameter id="sourceP1" paramName="dataSource" value="#(%page.dataSource)#" />
</dynaTree>
</group>
<spacer width="5px"/>
<vgroup>
<listBox id="lstFields" label="Field List" width="350px" listHeight="200px" 
onchange="zenPage.selectedRow(zenThis);"/>
<spacer height="1"/>
<textarea id="txtField" label="Edit Field:" rows="2" cols="47"
dropEnabled="false" onkeyup="zenPage.doEdit(zenThis);"/>
<text id="headerField" label="Edit Header:" hidden="false" size="46" onkeyup="zenPage.doEdit(zenThis);"/>
<button id="btnUpdate" caption="Update" disabled="true" title="Button is enabled when field is modified." onclick="zenPage.doUpdate();"/>
</vgroup>

<vgroup id="idGroupButtons">
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/close_a_16.png" width="16" height="16" title="Remove the selected field" onclick="zenPage.doRemove();"/>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/up_16.png" width="16" height="16" title="Move the selected field up" onclick="zenPage.moveItem('up');"/>
<image src="deepsee/down_16.png" width="16" height="16" title="Move the selected field down" onclick="zenPage.moveItem('dn');"/>
</vgroup>

</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set value = $$$TextHTML("Unknown")
	If ..WHAT = "ListingFieldList" Set value = $$$TextHTML("Listing - Field List")
	Else  If ..WHAT = "ListingOrderBy" Set value = $$$TextHTML("Listing - Order By")
	Else  If ..WHAT = "LevelDependsOn" Set value = $$$TextHTML("Level - Depends On")
	Quit value
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Set value = ""
	If (..WHAT = "ListingFieldList") { 
		If (..CONTEXT = "ListingGroupManager") {
			Set value = $$$TextHTML("Edit field list for this listing.")
		} Else {
			Set value = $$$TextHTML("Edit field list for Architect.")
		}
	} ElseIf (..WHAT = "ListingOrderBy") { 
		If (..CONTEXT = "ListingGroupManager") {
			Set value = $$$TextHTML("Edit order by for this listing.")
		} Else {
			Set value = $$$TextHTML("Edit order by for Architect.")
		}
	} ElseIf (..WHAT = "LevelDependsOn") {
		Set value = $$$TextHTML("Edit level depends on for Architect.")
	}
	Quit value
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	try {
		var values = "";
		var fieldObj = zen('lstFields');
		var len = fieldObj.getOptionCount();
		if ('ListingFieldList'==zenPage.WHAT) {
			// DTB814 - handle the JSON value in this mode
			var currValueArray = null;
			
			if (len > 0) {
				currValueArray = JSON.parse(fieldObj.getOptionValue(0));
				values = currValueArray[0] + ((currValueArray.length>1) ? ' ' + currValueArray[1] + ' ' + currValueArray[2] : '' );
			}
			for (var i=1; i<len; i++) {
				currValueArray = JSON.parse(fieldObj.getOptionValue(i));
				values = values + "," + currValueArray[0] + ((currValueArray.length>1) ? ' ' + currValueArray[1] + ' ' + currValueArray[2] : '' );
			}
		}
		else {
			if (len > 0) {
				values = fieldObj.getOptionValue(0);
			}
			for (var i=1; i<len; i++) {
				values = values + "," + fieldObj.getOptionValue(i);
			}
		}
		
		return encodeURIComponent(values);
		}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return '';
}

/// User edited a field. Change background color and enable Update button.
ClientMethod doEdit(editObj) [ Language = javascript ]
{
	if (zen('lstFields').getValue() != editObj.getValue()) {
		zen('btnUpdate').setDisabled(false);
		editObj.setProperty('controlStyle','background:rgb(255,243,190);');
	}
}

/// User clicked the Remove image. Remove the field from Field List box.
ClientMethod doRemove() [ Language = javascript ]
{
	var fieldObj = zen('lstFields');
	var len = fieldObj.getOptionCount();
	if (len == 0) return;
	var idx = fieldObj.getProperty("selectedIndex");
	if (idx < 0) {
		alert($$$Text("Please select the field you want to remove and try again."));
		return;
	}
	fieldObj.removeOption(idx);
	zen("txtField").setValue("");
	zen("headerField").setValue("");		// DTB819
}

/// User clicked the Update button. Update the selected row with new value.
ClientMethod doUpdate() [ Language = javascript ]
{
	var fieldValue = this.combineSqlFieldToJSON(true);		// DTB538		// DTB814 - Use new clientmethod call
	var fieldDisplay = this.combineSqlFieldToString(false);		// DTB814 - Use new clientmethod call
	
	var fieldObj = zen('lstFields');
	var idx = fieldObj.getProperty("selectedIndex");
	fieldObj.setOption(idx,fieldValue,fieldDisplay);		// DTB538
	zen('btnUpdate').setDisabled(true);
	zen('txtField').setProperty('controlStyle','background:white;');
	zen('headerField').setProperty('controlStyle','background:white;');		// DTB538
}

/// User clicked the Move Up/Down image. Move the field up or down one level in the Field List box. dir = "up" or "dn".
ClientMethod moveItem(dir) [ Language = javascript ]
{
	var fieldObj = zen('lstFields');
	var len = fieldObj.getOptionCount();
	if (len == 0) return;
	var idx = fieldObj.getProperty("selectedIndex");
	if (idx < 0) {
		alert($$$Text("Please select the field you want to move and try again."));
		return;
	}
	var row = idx;
	if (dir == "up") {
		row--;
	} else {
		row++;	
	}
	if (row >= 0) fieldObj.moveOption(idx,row);
}

/// User selected a property from the tree. Get the SQLName for the selected value and put it into the Field List box.
ClientMethod selectProperty(sourceObj) [ Language = javascript ]
{
	var propFullValue = sourceObj.getNodeValue(sourceObj.getProperty("selectedIndex"));
	var fieldObj = zen('lstFields');
	var result = this.GetSQLNames(this.dataSource,propFullValue,this.WHAT);
	if (result.Error != "") {
		alert(result.Error);
		return;	
	}
	var parsedSQL = this.parseSqlField(result.SQLNames);		// DTB815 - Parse for all modes
	
	if ('ListingFieldList'==zenPage.WHAT) {
		fieldObj.appendOption(this.combineSqlFieldToJSON(true,parsedSQL),this.combineSqlFieldToString(false,parsedSQL));		// DTB541	// DTB814 - Use new logical/display clientmethods
	}
	else {
		fieldObj.appendOption(parsedSQL[0],parsedSQL[0]);		// DTB815
	}
}

/// Parse a JSON string entry in the field list. Return an array with the field identifier and the header.
ClientMethod parseSqlField(value) [ Language = javascript ]
{
	var valueArray = JSON.parse(value);		// DTB814 - The value is now a pre-parsed array containing [field,AS,header]
	
	// Store field and remove it from the working list
	var field = valueArray[0];
	valueArray.splice(0,1);
	
	// Remove 'AS' from the remaining array
	if (valueArray[0]&&('AS'==valueArray[0].toUpperCase())) {
		valueArray.splice(0,1);
	}
	
	// Everything remaining is the Header section. Remove quotes and $$$TEXT to expose
	// the bare header.
	var header = '';
	if (valueArray[0]) {
		header = valueArray[0];
	}
	
	if ((header)&&(('"'==header[0])&&('"'==header[header.length-1]))) {
		header = header.substring(1,header.length-1)
	}
	if (header&&('$$$TEXT'==header.substring(0,7).toUpperCase())) {
		header = header.substring(8,header.length-1)
		
		hArray = header.split(',')
		header = hArray.slice(0,hArray.length-1).join(',')
		// The remaining header may or may not be quoted
		if ((header)&&(('"'==header[0])&&('"'==header[header.length-1]))) {
			header = header.substring(1,header.length-1)
		}
	}

	return [field,header];
}

/// Produce a JSON string for the complete parsed field entry by combining the Field and Header information into something of the form<br>
///   Field AS "$$$TEXT["Header","DOMAIN"]"<br>
/// If there is no Domain defined for the cube, the $$$TEXT[] will be omitted. Delimited identifiers are always assumed and the
/// double quotes are always added to the Header portion.
ClientMethod combineSqlFieldToJSON(useDomain, parsedFieldArray) [ Language = javascript ]
{
	// Method added by DTB814
	if (undefined==useDomain) {
		// Assume we want to localize
		useDomain = true;
	}

	var domain = this.domain;
	var fullFieldArray = [];
	if (!parsedFieldArray) {
		fullFieldArray.push(zen('txtField').getValue());
		var header = zen('headerField').getValue();
	}
	else {
		fullFieldArray.push(parsedFieldArray[0]);
		var header = parsedFieldArray[1];
	}
	
	if (''!=header) {
		fullFieldArray.push('AS');
		fullFieldArray.push('"' + ((useDomain&&(domain!='')) ? '$$$TEXT["'+header+'","'+domain+'"]' : header) + '"');
	}

	return JSON.stringify(fullFieldArray);
}

/// Produce a display string for the complete field entry by combining the Field and Header information into something of the form<br>
///   Field AS "$$$TEXT["Header","DOMAIN"]"<br>
/// If there is no Domain defined for the cube, the $$$TEXT[] will be omitted. Delimited identifiers are always assumed and the
/// double quotes are always added to the Header portion.
ClientMethod combineSqlFieldToString(useDomain, parsedFieldArray) [ Language = javascript ]
{
	// Method added by DTB538
	if (undefined==useDomain) {
		// Assume we want to localize
		useDomain = true;
	}

	var domain = this.domain;
	if (!parsedFieldArray) {
		var fullFieldText = zen('txtField').getValue();
		var header = zen('headerField').getValue();
	}
	else {
		var fullFieldText = parsedFieldArray[0];
		var header = parsedFieldArray[1];
	}
	
	if (''!=header) {
		fullFieldText += ' AS "' + ((useDomain&&(domain!='')) ? '$$$TEXT["'+header+'","'+domain+'"]' : header) + '"';
	}

	return fullFieldText;
}

/// User clicked a row from the list box. Parse selected value and place it into the 
/// Field and Header boxes for editing.
ClientMethod selectedRow(fieldObj) [ Language = javascript ]
{
	var textObj = zen("txtField");
	var headerObj = zen("headerField");		// DTB538
	
	// DTB638 - Only parse for listingField mode
	if ("ListingFieldList"==zenPage.WHAT) {
		var parsedField = this.parseSqlField(fieldObj.getValue());		// DTB538
		//textObj.setValue(fieldObj.getValue());
		textObj.setValue(parsedField[0]);		// DTB538
		headerObj.setValue(parsedField[1]);		// DTB538
		
		textObj.setProperty('controlStyle','background:white;');
		headerObj.setProperty('controlStyle','background:white;');		// DTB538
	}
	else {
		textObj.setValue(fieldObj.getValue());
		textObj.setProperty('controlStyle','background:white;');
	}

	zen('btnUpdate').setDisabled(true);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
		Set ..%GetComponentById("ELEMENT").value = ..ELEMENT
		
		// If this was launched from the Listing Group Manager, look up the source class
		Set tCubeNameU = $$$UPPER(..cubeName)
		If (..CONTEXT="ListingGroupManager")&&(tCubeNameU'="") {
			Set ..dataSource = $G(^DeepSee.Cubes("cubes",tCubeNameU,"sourceClass"))
		}
		If (tCubeNameU'="") {
			Set ..domain = $PARAMETER(##class(%DeepSee.Utils).%GetCubeClass(tCubeNameU),"DOMAIN")		// DTB538
		}
		
		#; Load existing fields into list
		If ..Expression '= "" {
			Set tCombo = ..%GetComponentById("lstFields")
			
			// DTB950 - Use different processing for the SQL fieldList and MDX depensOn cases 
			If (..WHAT="ListingFieldList") {
				// + DTB552 - Replace in-line comma-delimited parsing with a slightly more sophisticated method
				Set tSC=##class(%DeepSee.UI.Dialog.FieldList).%ParseSQLFieldList(..Expression,..domain,.tFieldArray)
				If $$$ISERR(tSC) Quit
				
				Set tRow = $O(tFieldArray(""),1,tFieldData)
				While (tRow) {
					Set tOption = ##class(%ZEN.Auxiliary.option).%New()
					Do tCombo.options.Insert(tOption)
					Do ..%AddComponent(tOption)
					
					// DTB814 - The return of this field list should now have separate parts for the field identifier and 
					// headers. Preserve this server parsing in the value by passing a JSON array
					Set tCurrValueList = $LG(tFieldData,1)
					Set tCurrValue = []
					For ii=1:1:$LL(tCurrValueList) {
						Do tCurrValue.%Push($LG(tCurrValueList,ii))
					}
					Set tOption.value = tCurrValue.%ToJSON()
					
					Set tOption.text = $ListToString($LG(tFieldData,2)," ")		// DTB814 - Convert the $LB to a string
					Set tRow = $O(tFieldArray(tRow),1,tFieldData)
			 	}
			 	// - DTB552
			}
			ElseIf (..WHAT="LevelDependsOn") {
				// DTB950 - This is an MDX dependsOn list, which assumes [] quoted notation
				// This parsing is based on how the Generator parses these lists during compile
				Set tRow = 1
				Set tItem = $P(..Expression,",",1)
			 	While (tItem'="") {
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(..cubeName,tItem)
					If ($$$ISERR(tSC)) {
						Set tSC = $$$ERROR($$$GeneralError,"Invalid dependsOn spec: " _ tItem)
						$$$ThrowStatus(tSC)
					}
					
					Set tOption = ##class(%ZEN.Auxiliary.option).%New()
					Do tCombo.options.Insert(tOption)
					Do ..%AddComponent(tOption)
					Set tOption.text = tItem
					Set tOption.value = tItem
					Set tRow = tRow + 1
			 		Set tItem = $P(..Expression,",",tRow)
			 	}
			}
		}
		Set tHelp = $$$Text("Select a field by double clicking a property from the tree.")
		If ..WHAT = "ListingOrderBy" {
			Set ..%GetComponentById("txtField").hidden = 1
			Set ..%GetComponentById("btnUpdate").hidden = 1
			Set ..%GetComponentById("titleText").label = $$$Text("Use the form below to create and maintain the Order by list. ")_tHelp
			Set ..%GetComponentById("lstFields").label = $$$Text("Order by")
			Set ..%GetComponentById("headerField").hidden = 1		// DTB638
		} ElseIf ..WHAT = "LevelDependsOn" {
			Set ..%GetComponentById("dataSource").label = $$$Text("Cube Levels")
			Set ..%GetComponentById("txtField").hidden = 1
			Set ..%GetComponentById("btnUpdate").hidden = 1
			Set ..%GetComponentById("titleText").label = $$$Text("Use the form below to create and maintain the Depends on. ")_tHelp
			Set ..%GetComponentById("lstFields").label = $$$Text("Depends on")
			Set ..%GetComponentById("headerField").hidden = 1		// DTB638
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide contents of the data source tree.
ClassMethod GetDataSourceInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	If %page.WHAT = "LevelDependsOn",pRoot="" {
		Quit ..GetDependsOnInfo(pRoot, .pTree, .pParms)	
	}
	Set tDataSource = $G(pParms("dataSource"))
	If (tDataSource '= "") {
		If $$$comClassDefined(tDataSource) {
			Set tSC = ##class(%DeepSee.Utils).%GetDataSourceTree(tDataSource,.pTree,,,,pRoot)
		}
	}
	Quit tSC
}

ClassMethod GetDependsOnInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
     #; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
	Set tSC = $$$OK
	Do ##class(%DeepSee.Utils).%GetCubeLevels(%page.cubeName,.p,1,1)
	Set n = $O(p(""))
	While n '= "" {
		If $lg(p(n),1)="l" {
			Set p = "["_$lg(p(n),2)_"]"_"."_"["_$lg(p(n),3)_"]"_"."_"["_$lg(p(n),4)_"]"
			Set pTree(0,"ch",n) = ""
			Set pTree(n) = $LB(p,p,0,"",0,,p)
		}
		Set n = $O(p(n)) 
	}
	Quit tSC
}

/// Get SQL Names from property name. Similar logic as in IsDate of Architect.
ClassMethod GetSQLNames(sourceClass As %String, fullName As %String, WHAT As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Try {
		Set proxy = ##class(%ZEN.proxyObject).%New()
		Set proxy.Error = ""
		Set proxy.SQLNames = ""
		Set cnt = 1
		Set prop = $P(fullName,".",cnt)
		Set tLen = $L(fullName,".")
		Set source = sourceClass		// DTB545
		While prop '= "" {
			Set tStatus = ..GetPropName(source, prop, .propNames)		// DTB545 - Use the current source, not the page's source
			If tStatus '= "" {
				Set proxy.Error = tStatus
				Set prop = ""
				Quit
			}
			// DTB545 - Move this earlier
			Set tLastClass = source		// DTB541
			Set tLastProp = prop		// DTB541
			
			Set name = $O(propNames(""))
			If name '[ "%Library",##class(%Dictionary.CompiledClass).%ExistsId(name) {
				Set source = name
			} Else {
				Set source = sourceClass	
			}
			#; JMD1500 find type of class
			Set tSourceType = "persistent"
			If $classmethod(source,"%IsA","%Library.SerialObject") {
				Set tSourceType = "serial"
			}

			// PFS032 - Use tLastClass instead of updated source type of this prop
			Set tSQL = ##class(%DeepSee.Utils).%GetSQLColumnName(tLastClass,prop)
			#; if SQL name does not exists then use property name.
			#; JMD1500 use correct seperator
			If (WHAT = "LevelDependsOn") {
				Set tSep = "."
			}
			ElseIf (tSourceType = "serial") {
				Set tSep = "_"
			}
			Else {
				Set tSep = "->"
			}
			Set proxy.SQLNames = proxy.SQLNames _ $S(tSQL'="":tSQL,1:prop) _ $S(cnt<tLen:tSep,1:"")
			Set cnt = cnt + 1
			
			Set prop = $P(fullName,".",cnt)
		}
		
		If proxy.SQLNames = "" Set proxy.SQLNames = ##class(%DeepSee.Utils).%GetSQLColumnName(sourceClass,fullName)
		If proxy.SQLNames = "" Set proxy.SQLNames = fullName
		
		// DTB541 - See if there is a class-defined caption defined for the property at the end of the chain
		// The $$$TEXT[] translation is not added at this stage, that is done by the client.
		$$$comMemberArrayGetLvar(tCaption,tLastClass,$$$cCLASSproperty,tLastProp,$$$cXXXXparamvalue,"CAPTION")
		
		Set tCaption = $ZCVT(tCaption, "O", "JS") //DP-402089
		Set proxy.SQLNames = $ZCVT(proxy.SQLNames, "O", "JS") //DP-402089: Ensure that double quotes in SQL reserved words get correctly parsed when being converted to JSON

		If (tCaption'="") {
			// DTB815 - Return as a JSON array
			Set proxy.SQLNames = "[""" _ proxy.SQLNames _ """,""AS"",""" _ tCaption _ """]"
		}
		Else {
			// DTB815 - Return as a JSON array
			Set proxy.SQLNames = "[""" _ proxy.SQLNames _ """]"
		}
	}
	Catch(ex) {
		Set proxy.Error = $$$Text("Error occurred in GetSQLNames: ")_$ZCVT(ex.AsStatus(),"O","JS")
	}
	Quit proxy
}

ClassMethod GetPropName(sourceClass, property, Output propNames) As %String
{
	Set Status = ""
	Set property = $TR(property,"[]","")
	Kill propNames
	&sql(declare NNN cursor for 
		select c.name 
		from %Dictionary.CompiledClass c, %Dictionary.CompiledProperty p 
		where p.parent = :sourceClass and p.name = :property and c.name = p.type
	)
	&sql(open NNN)
	If SQLCODE<0 set Status = "SQLCODE: "_SQLCODE
	For {
		&sql(fetch NNN into :name)
		Quit:SQLCODE
		Set propNames(name) = ""
	}
	If SQLCODE<0 set Status = $S(Status'="":Status _ ", ",1:"")_SQLCODE
	&sql(close NNN)
	If SQLCODE<0 set Status = $S(Status'="":Status _ ", ",1:"")_SQLCODE
	QUIT Status
}

/// Split a single fieldList string into the individual fields. This is more
/// sophisticated than a simple comma-delimited split.
ClassMethod %ParseSQLFieldList(pFieldString = "", pDomain = "", Output pFieldArray) As %Status
{
	// Method added by DTB552
	// DTB649 - Call into common Utils version
	Quit ##class(%DeepSee.Utils).%ParseSQLFieldList(pFieldString,pDomain,.pFieldArray)
}

}
