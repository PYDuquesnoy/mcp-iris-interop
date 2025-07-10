/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Add a new component to a production
Class EnsPortal.Dialog.ProductionAddOperation Extends EnsPortal.Dialog.ProductionAddHost [ System = 4 ]
{

Parameter PAGENAME = "Add Business Operation";

XData Style
{
<style type="text/css">
/* @doc="Wrapper for body of tabgroup, when tab bar is shown." */
.tabGroupBody {
	width: 570px;
	height: 335px; /* at least 320 needed for IE, additional 15 needed for Firefox 3.6 */ 
}
.useDefaultLabel {
	padding-right: 3px;
	font-size: 0.8em;
	font-style: oblique;
}
</style>
}

/// Contents of this dialog
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
	<spacer height="5" />
	<hgroup>
		<spacer width="20" />
		<vgroup>
			<spacer height="10" />
			<tabGroup name="groupOperation" id="groupOperation" showTabBar="true" remember="true" >
				<tab caption="All Operations">
					<form name="formOperationOTHER" id="formOperationOTHER">
						<spacer height="20" />
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is exposed and required for regular Business Operations -->
								<selector name="OperationOTHERClassName" id="OperationOTHERClassName" label="Operation Class" hidden="false" 
									enclosingStyle="padding-bottom:4px;" size="40" labelClass="labelRequired" required="true" 
									title="Choose a base class for this Business Operation. Only valid Business Operation class names appear in the list. If there are no such items available, the list is empty."
									multiSelect="false" context="Ens.ContextSearch/BusinessOperations" />
								<!-- Every Business Operation form variant has a Name, Category, Comment, and Enabled -->
								<spacer name="OperationOTHERLineAboveCommonFields" id="OperationOTHERLineAboveCommonFields" height="10"/>
								<text required="false" readOnly="false" hidden="false" 
									name="OperationOTHERName" id="OperationOTHERName" label="Operation Name" 
									size="43" enclosingStyle="padding-bottom:4px;" 
									title="Enter a name for this Business Operation. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. If you do not enter a name, the Operation Class name is used."
								/>
								<selector name="OperationOTHERCategory" id="OperationOTHERCategory" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"  
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
								<textarea required="false" readOnly="false" hidden="false"
									name="OperationOTHERComment" id="OperationOTHERComment" label="Comment" 
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;" 
									title="Provide a brief comment about this Business Operation. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="OperationOTHEREnabled" id="OperationOTHEREnabled" label="Enable Now" 
									enclosingStyle="padding-bottom:4px;" 
									title="Check the box if you want this Business Operation to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
							</vgroup>
							<spacer width="5"/>
						</hgroup>
						<!-- End of form -->
					</form>
				</tab>
				<tab caption="HL7 Output" id="tabHL7Output">
					<vgroup valign="top" id="=vformGroupXHL7">
						<form name="formOperationHL7" id="formOperationHL7">
							<spacer height="12" />
							<hgroup>
								<spacer width="5" />
								<vgroup labelPosition="left">
									<!-- HL7 Operation has several variants, according to protocol which you choose here as Output Type -->
									<radioSet required="true" readOnly="false" hidden="false" value=""
										name="OperationHL7InOutType" id="OperationHL7InOutType" label="Output Type" 
										labelClass="labelRequired"  enclosingStyle="padding-bottom:4px;" 
										title="Specify how outgoing messages are sent."
										valueList="TCP,File,FTP,HTTP,SOAP" displayList="TCP,File,FTP,HTTP,SOAP" 
										onclick="zenPage.changeType('Operation','HL7');"
									/>
									<!-- Class Name is hidden by design, for HL7 and X12 -->
									<text required="false" readOnly="true" hidden="true"
										name="OperationHL7ClassName" id="OperationHL7ClassName" label="Class Name" 
										labelClass="labelRequired" size="43" enclosingStyle="padding-bottom:4px;" 
									/>
									<!-- Every HL7 Operation form variant has the following 4 fields: Name, Category, Comment, and Enabled -->
									<spacer name="OperationHL7LineAboveCommonFields" id="OperationHL7LineAboveCommonFields" height="10"/>
									<text required="true" readOnly="false" hidden="true" value="#(%page.GetTo())#"
										name="OperationHL7Name" id="OperationHL7Name" label="HL7 Operation Name" 
										labelClass="labelRequired" size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter a name for this HL7 Operation. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _."
									/>
									<selector name="OperationHL7Category" id="OperationHL7Category" label="Display Category" hidden="true"
										enclosingStyle="padding-bottom:4px;" size="40"  
										title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
										multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
									<textarea required="false" readOnly="false" hidden="true"
										name="OperationHL7Comment" id="OperationHL7Comment" label="Comment" 
										rows="1" cols="34" enclosingStyle="padding-bottom:4px;" 
										title="Provide a brief comment about this HL7 Operation. This annotation appears in the configuration summary for the production."
									/>
									<checkbox required="false" readOnly="false" hidden="true" value="0"
										name="OperationHL7Enabled" id="OperationHL7Enabled" label="Enable Now" 
										enclosingStyle="padding-bottom:4px;" 
										title="Check the box if you want this HL7 Operation to begin processing messages immediately. Otherwise, leave the box unchecked."
									/>
								</vgroup>
							</hgroup>
							<!-- Specialty fields for Operations with various Protocols/Adapters (show/hide based on Item Type choices) -->
							<!-- Server Address (FTP Operation, HTTP Operation) -->
							<fieldSet id="OperationHL7DefaultableFields"
								hidden="true"
								legend="" 
								layout="vertical" 
								title="Values that can use default">
								<vgroup labelPosition="left" >
									<text required="false" readOnly="false" hidden="true" 
										name="OperationHL7Addr1" id="OperationHL7Addr1" label="Server Address*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the IP address for the remote server. You may enter a server name if your domain host controller can resolve it."
									/> 
									<!-- IP Address (TCP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationHL7Addr2" id="OperationHL7Addr2" label="IP Address*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the IPv4 or IPv6 address of the remote system. Start with ! to wait for a connection from the remote system. After ! you may enter a comma-separated list of addresses from which to accept connections. If no address follows the ! any remote system may connect."
									/>
									<!-- Port (TCP Operation, FTP Operation (21), HTTP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationHL7Port2" id="OperationHL7Port2" label="Port Number*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the port number for the outgoing connection."
									/>
									<!-- Credentials (FTP Operation, HTTP Operation) -->
									<dataCombo editable="true" unrestricted="false" hidden="true" 
										name="OperationHL7Cred" id="OperationHL7Cred" label="Credentials*"
										enclosingStyle="padding-bottom:4px;" size="40" dropdownHeight="85px"
										title="Choose the configured name of the set of IRIS credentials (username, password) to be used to access the remote system. If there are no credentials defined, the list is empty."
										queryClass="Ens.Config.Credentials" queryName="List"
										displayColumns="1" valueColumn="1" choiceColumn="1" 
									/>
									<!-- URL (HTTP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationHL7URL" id="OperationHL7URL" label="URL*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the URL path to request from the HTTP server. Do not include http:// or the server address in the URL."
									/>
									<!-- File Path (File Operation) -->
									<hgroup id="OperationHL7FilePath3Grp" label="File Path*" valign="middle" hidden="true" enclosingStyle="padding-bottom:4px;"
										title="Enter the path on the IRIS server where the HL7 Operation can place output files. Do not include a filename specification in this path.">
										<text required="false" readOnly="false" 
											name="OperationHL7FilePath3" id="OperationHL7FilePath3" size="43" 
											title="Enter the path on the IRIS server where the HL7 Operation can place output files. Do not include a filename specification in this path."
										/>
										<image src="deepsee/zoom_24.png"
											title="Select the path on the IRIS server where the HL7 Operation can place output files. Do not include a filename specification in this path."
											onclick="zenPage.selectDirectory('OperationHL7FilePath3');"/>
									</hgroup>
									<!-- File Path (FTP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationHL7FilePath4" id="OperationHL7FilePath4" label="File Path*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the path on the remote FTP server where the HL7 Operation can place output files. Do not include a filename specification in this path."
									/>
									<!--  Filename (File Operation, FTP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationHL7FileSpec2" id="OperationHL7FileSpec2" label="Filename*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Filename specification for output files. %f_%Q is the default. %f gives the configured name of the data source within IRIS, and %Q is a detailed date and time stamp."
									/>
									<hgroup name="OperationHL7UseDefaultGrp" id="OperationHL7UseDefaultGrp" labelClass="useDefaultLabel" labelPosition="left" label="*Default applies if no value">
										<checkbox hidden="false" value="1" labelClass="useDefaultLabel"
											name="OperationHL7UseDefault" id="OperationHL7UseDefault" label="*Default applies if empty" showLabel="false"
											enclosingStyle="padding-bottom:4px;"
											title="Empty Values will not be saved in the production definition. Uncheck this to save empty values for the settings labeled with an asterisk."
											onchange="zenPage.toggleDefaultForEmpty('Operation','HL7');"
										/>
										<spacer width="4px"/>
										<image src="deepsee/help_24.png" showLabel="false"
											title="Show possible default values."
											onclick="var sync=zenPage.showPossibleDefaults('Operation','HL7');"
										/>
									</hgroup>
								</vgroup>
							</fieldSet>
							<spacer width="5"/>
						<!-- End of form -->
						</form>
					</vgroup>
				</tab>
				<tab caption="X12 Output" id="tabX12Output">
					<vgroup valign="top" id="=vformGroupX12">
						<form name="formOperationX12" id="formOperationX12">
							<spacer height="12" />
							<hgroup>
								<spacer width="5" />
								<vgroup labelPosition="left" >
									<!-- X12 Operation has several variants, according to protocol which you choose here as Output Type -->
									<radioSet required="true" readOnly="false" hidden="false" value=""
										name="OperationX12InOutType" id="OperationX12InOutType" label="Output Type" 
										labelClass="labelRequired"  enclosingStyle="padding-bottom:4px;" 
										title="Specify how outgoing messages are sent."
										valueList="TCP,File,FTP,SOAP" displayList="TCP,File,FTP,SOAP" 
										onclick="zenPage.changeType('Operation','X12');"
									/>
									<!-- Class Name is hidden by design, for HL7 and X12 -->
									<text required="false" readOnly="true" hidden="true"
										name="OperationX12ClassName" id="OperationX12ClassName" label="Class Name" 
										labelClass="labelRequired" size="43" enclosingStyle="padding-bottom:4px;" 
									/>
									<!-- Every X12 Operation form variant has the following 4 fields: Name, Category, Comment, and Enabled -->
									<spacer name="OperationX12LineAboveCommonFields" id="OperationX12LineAboveCommonFields" height="10"/>
									<text required="true" readOnly="false" hidden="true" value="#(%page.GetTo())#"
										name="OperationX12Name" id="OperationX12Name" label="X12 Operation Name" 
										labelClass="labelRequired" size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter a name for this X12 Operation. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _."
									/>
									<selector name="OperationX12Category" id="OperationX12Category" label="Display Category" hidden="true"
										enclosingStyle="padding-bottom:4px;" size="40"  
										title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
										multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
									<textarea required="false" readOnly="false" hidden="true"
										name="OperationX12Comment" id="OperationX12Comment" label="Comment" 
										rows="1" cols="34" enclosingStyle="padding-bottom:4px;" 
										title="Provide a brief comment about this X12 Operation. This annotation appears in the configuration summary for the production."
									/>
									<checkbox required="false" readOnly="false" hidden="true" value="0"
										name="OperationX12Enabled" id="OperationX12Enabled" label="Enable Now" 
										enclosingStyle="padding-bottom:4px;" 
										title="Check the box if you want this X12 Operation to begin processing messages immediately. Otherwise, leave the box unchecked."
									/>
								</vgroup>
							</hgroup>
							<!-- Specialty fields for Operations with various Protocols/Adapters (show/hide based on Item Type choices) -->
							<spacer name="OperationX12LineAboveServiceFields" id="OperationX12LineAboveServiceFields" height="10"/>
							<fieldSet id="OperationX12DefaultableFields"
								hidden="true"
								legend="" 
								layout="vertical" 
								title="Values that can use default">
								<vgroup labelPosition="left" >
									<!-- Server Address (FTP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationX12Addr1" id="OperationX12Addr1" label="Server Address*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the IP address for the remote server. You may enter a server name if your domain host controller can resolve it."
									/>
									<!-- IP Address (TCP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationX12Addr2" id="OperationX12Addr2" label="IP Address*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the IPv4 or IPv6 address of the remote system. Start with ! to wait for a connection from the remote system. After ! you may enter a comma-separated list of addresses from which to accept connections. If no address follows the ! any remote system may connect."
									/>
									<!-- Port (TCP Operation, FTP Operation (21)) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationX12Port2" id="OperationX12Port2" label="Port Number*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the port number for the outgoing connection."
									/>
									<!-- Credentials (FTP Operation) -->
									<dataCombo editable="true" unrestricted="false" hidden="true" 
										name="OperationX12Cred" id="OperationX12Cred" label="Credentials*"
										enclosingStyle="padding-bottom:4px;" size="40" dropdownHeight="85px"
										title="Choose the configured name of the set of IRIS credentials (username, password) to be used to access the remote system. If there are no credentials defined, the list is empty."
										queryClass="Ens.Config.Credentials" queryName="List"
										displayColumns="1" valueColumn="1" choiceColumn="1" 
									/>
									<!-- File Path (File Operation) -->
									<hgroup id="OperationX12FilePath3Grp" label="File Path*" valign="middle" hidden="true" enclosingStyle="padding-bottom:4px;"
										title="Enter the path on the IRIS server where the X12 Operation can place output files. Do not include a filename specification in this path.">
										<text required="false" readOnly="false" 
										 	name="OperationX12FilePath3" id="OperationX12FilePath3" size="43" 
											title="Enter the path on the IRIS server where the X12 Operation can place output files. Do not include a filename specification in this path."
											/>
										<image src="deepsee/zoom_24.png"
											title="Select the path on the IRIS server where the X12 Operation can place output files. Do not include a filename specification in this path."
											onclick="zenPage.selectDirectory('OperationX12FilePath3');"/>
									</hgroup>
									<!-- File Path (FTP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationX12FilePath4" id="OperationX12FilePath4" label="File Path*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Enter the path on the remote FTP server where the X12 Operation can place output files. Do not include a filename specification in this path."
									/>
									<!--  Filename (File Operation, FTP Operation) -->
									<text required="false" readOnly="false" hidden="true" 
										name="OperationX12FileSpec2" id="OperationX12FileSpec2" label="Filename*" 
										size="43"  enclosingStyle="padding-bottom:4px;" 
										title="Filename specification for output files. %f_%Q is the default. %f gives the configured name of the data source within IRIS, and %Q is a detailed date and time stamp."
									/>
									<hgroup name="OperationX12UseDefaultGrp" id="OperationX12UseDefaultGrp" labelClass="useDefaultLabel" labelPosition="left" label="*Default applies if no value">
										<checkbox hidden="false" value="1" labelClass="useDefaultLabel"
											name="OperationX12UseDefault" id="OperationX12UseDefault" label="*Default applies if empty" showLabel="false"
											enclosingStyle="padding-bottom:4px;"
											title="Empty Values will not be saved in the production definition. Uncheck this to save empty values for the settings labeled with an asterisk."
											onchange="zenPage.toggleDefaultForEmpty('Operation','X12');"
										/>
										<spacer width="4px"/>
										<image src="deepsee/help_24.png" showLabel="false"
											title="Show possible default values."
											onclick="var sync=zenPage.showPossibleDefaults('Operation','X12');"
										/>
									</hgroup>
								</vgroup>
							</fieldSet>	
							<spacer width="5"/>
						<!-- End of form -->
						</form>
					</vgroup>
				</tab>
				<tab caption="Workflow">
					<form name="formOperationWORKFLOW" id="formOperationWORKFLOW">
						<spacer height="20" />
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is exposed and required for Workflow Operations -->
								<selector name="OperationWORKFLOWClassName" id="OperationWORKFLOWClassName" label="Class Name" hidden="false" 
									enclosingStyle="padding-bottom:4px;" size="40" labelClass="labelRequired" required="true" 
									title="Choose a base class for this Workflow Operation. Only valid Workflow Operation class names appear in the list."
									multiSelect="false" context="Ens.ContextSearch/WorkflowOperations" />
								<!-- Every Business Operation form variant has a Name, Category, Comment, and Enabled -->
								<spacer name="OperationWORKFLOWLineAboveCommonFields" id="OperationWORKFLOWLineAboveCommonFields" height="10"/>
								<text required="false" readOnly="false" hidden="false" 
								 	name="OperationWORKFLOWName" id="OperationWORKFLOWName" label="Operation Name" 
									size="43" enclosingStyle="padding-bottom:4px;" 
									title="Enter a name for this Workflow Operation. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. If you do not enter a name, the Class Name is used."
								/>
								<selector name="OperationWORKFLOWCategory" id="OperationWORKFLOWCategory" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"  
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
								<textarea required="false" readOnly="false" hidden="false"
									name="OperationWORKFLOWComment" id="OperationWORKFLOWComment" label="Comment" 
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;" 
									title="Provide a brief comment about this Workflow Operation. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="OperationWORKFLOWEnabled" id="OperationWORKFLOWEnabled" label="Enable Now" 
									enclosingStyle="padding-bottom:4px;" 
									title="Check the box if you want this Workflow Operation to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
								<!-- Specialty fields for Workflow Operations -->
								<combobox required="false" readOnly="false" hidden="false" value="0"
									name="OperationWORKFLOWAutoCreateRole" id="OperationWORKFLOWAutoCreateRole" label="Auto-Create Role" 
									valueList="1,0" displayList="True,False" 
									size="40"  enclosingStyle="padding-bottom:4px;" 
									title="Choose whether or not this Workflow Operation should automatically create a Workflow Role when the production is started. The default is False."
								/>
							</vgroup>
							<spacer width="5"/>
						</hgroup>
					<!-- End of form -->
					</form>
				</tab>
			</tabGroup>
		</vgroup>
		<spacer width="20" />
		<vgroup valign="top">
			<spacer height="40" />
			<label id="helpSubject" enclosingClass="labelComment" label="Use this form to add a new business operation to the production." />
			<spacer height="10" />
			<label id="helpHover" enclosingClass="labelComment" label="For help with any setting in this form, hover the cursor over the setting name." />
			<spacer height="100" />
			<vgroup labelPosition="left" >
				<!-- Hidden control that is updated by HL7 or X12 tab specific use default check box -->
				<checkbox required="false" readOnly="false" hidden="true" value="1"
					name="useDefaultForEmptyValue" id="useDefaultForEmptyValue"
				/>
			</vgroup>
		</vgroup>
	</hgroup>
</pane>
}

/// This method is invoked when the user completes the Wizard pressing "OK".
/// Returns a null string if it succeeds, or an error message otherwise.
Method OnWizardCompletion(pProdId As %String, pForm As %String, pType As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK

	Set tmsg = ""
	
	Try {
		Set production = ##class(Ens.Config.Production).%OpenId(pProdId)
		If $IsObject($G(production)) {
			// Add the new host to the Production
			If pForm="formOperationOTHER" { 
				Set tSC = ..AddNewItem(pForm, "OperationOTHER", production, .item)
				If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
			}
			ElseIf pForm="formOperationHL7" {
				Set tSC = ..AddNewItem(pForm, "OperationHL7", production, .item)
				If $$$ISOK(tSC) {
					// adapter settings
					Do ..AddOperationSettings(pForm, "OperationHL7", item)
				}
				Else {
					Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			ElseIf pForm="formOperationX12" { // X12 Output
				Set tSC = ..AddNewItem(pForm, "OperationX12", production, .item)
				If $$$ISOK(tSC) {
					// adapter settings
					Do ..AddOperationSettings(pForm, "OperationX12", item)
				}
				Else {
					Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			ElseIf pForm="formOperationWORKFLOW" { // Workflow Operation
				Set tSC = ..AddNewItem(pForm, "OperationWORKFLOW", production, .item)
				If $$$ISOK(tSC) {	
					// AutoCreateRole
					Do ..ItemSettingsInsert(.item,"AutoCreateRole","Host",..%GetValueById("OperationWORKFLOWAutoCreateRole"),1 /* can't be empty*/)
				}
				Else {
					Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			Else {
				Set tmsg = $$$Text("Unrecognized option on form.")
			}
	
			If $$$ISOK(tSC) && (tmsg="") {
				// save production (and item), update production class and account for Source Control
				Set tSC = ##class(EnsPortal.Template.prodConfigSCPage).CallProductionUpdateAndSaveToClass(production,"","SaveProduction")
			}
			If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
		}
		Else {
			Set tmsg = $$$Text("Unable to open Production object.")
		}
	
	}
	Catch (ex) {
		Set tmsg = ex.DisplayString()
	}

	Quit tmsg
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super() ; ProductionAddHost implements security check for %Ens_ProductionConfig:WRITE
	If $$$ISERR(tSC) Quit tSC

	// send the production name to the category selector components 
	Set sel = ..%GetComponentById("OperationOTHERCategory")
	Set sel.context = sel.context _ "?productionName=" _ ..ProductionName

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("HL7") {
		Set sel = ..%GetComponentById("OperationHL7Category")
		Set sel.context = sel.context _ "?productionName=" _ ..ProductionName
	} Else {
		Set sel = ..%GetComponentById("groupOperation")
		For tTab=1:1:sel.children.Count(){
			If sel.children.GetAt(tTab).id = "tabHL7Output" {Do sel.children.RemoveAt(tTab)  Quit}
		}
	}

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("X12") {
		Set sel = ..%GetComponentById("OperationX12Category")
		Set sel.context = sel.context _ "?productionName=" _ ..ProductionName
	} Else {
		Set sel = ..%GetComponentById("groupOperation")
		For tTab=1:1:sel.children.Count(){
			If sel.children.GetAt(tTab).id = "tabX12Output" {Do sel.children.RemoveAt(tTab)  Quit}
		}
	}

	Set sel = ..%GetComponentById("OperationWORKFLOWCategory")
	Set sel.context = sel.context _ "?productionName=" _ ..ProductionName

	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Business Operation Wizard","Ensemble")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add a new Business Operation to this Production.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.retValue;
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the action is canceled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	var tabs = zen('groupOperation');
	if (tabs) {
		currentTab = tabs.getCurrTabNo();
	}
	var currentTabCaption = tabs.children[currentTab-1].caption;

	switch (currentTabCaption) {
		case $$$Text('All Operations'):
			var formName = 'formOperationOTHER';
			var hostType = 'OTHER';
			break;
		case $$$Text('HL7 Output'):
			var formName = 'formOperationHL7';
			var hostType = 'HL7';
			break;
		case $$$Text('X12 Output'):
			var formName = 'formOperationX12';
			var hostType = 'X12';
			break;
		case $$$Text('Workflow'):
			var formName = 'formOperationWORKFLOW';
			var hostType = 'WORKFLOW';
			break;
		default:
			return false;
			break;
	}
	
	try {
		var isValid = zenPage.validateAll('Operation', hostType);
		if (isValid) {
			var msg = zenPage.OnWizardCompletion(zenPage.ProductionName, formName, hostType)
			if (msg != '') {
				isValid = false;
				alert(msg);
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
		isValid = false;
	}

	if (isValid) {
		this.retValue = 1;
		return true;
	}
	else {
		this.retValue = 0;
		return false;
	}
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

}
