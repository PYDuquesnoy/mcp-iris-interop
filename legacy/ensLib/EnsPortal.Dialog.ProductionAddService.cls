/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Add a new component to a production
Class EnsPortal.Dialog.ProductionAddService Extends EnsPortal.Dialog.ProductionAddHost [ System = 4 ]
{

Parameter PAGENAME = "Add Business Service";

XData Style
{
<style type="text/css">
/* @doc="Wrapper for body of tabgroup, when tab bar is shown." */
.tabGroupBody {
	width: 570px;
	height: 445px; /* at least 430 needed for IE, additional 15 needed for Firefox 3.6 */
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
			<tabGroup name="groupService" id="groupService" showTabBar="true" remember="true">
				<tab caption="All Services">
					<form name="formServiceOTHER" id="formServiceOTHER">
						<spacer height="20"/>
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is exposed and required for regular Business Services -->
								<selector name="ServiceOTHERClassName" id="ServiceOTHERClassName" label="Service Class" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40" labelClass="labelRequired" required="true"
									title="Choose a base class for this Business Service. Only valid Business Service class names appear in the list. If there are no such items available, the list is empty."
									multiSelect="false" context="Ens.ContextSearch/BusinessServices" />
								<!-- Every Business Service form variant has a Name, Category, Comment, and Enabled -->
								<spacer name="ServiceOTHERLineAboveCommonFields" id="ServiceOTHERLineAboveCommonFields" height="10"/>
								<text required="false" readOnly="false" hidden="false"
									name="ServiceOTHERName" id="ServiceOTHERName" label="Service Name"
									size="43" enclosingStyle="padding-bottom:4px;"
									title="Enter a name for this Business Service. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. If you do not enter a name, the Service Class name is used."
								/>
								<selector name="ServiceOTHERCategory" id="ServiceOTHERCategory" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
								<textarea required="false" readOnly="false" hidden="false"
									name="ServiceOTHERComment" id="ServiceOTHERComment" label="Comment"
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
									title="Provide a brief comment about this Business Service. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="ServiceOTHEREnabled" id="ServiceOTHEREnabled" label="Enable Now"
									enclosingStyle="padding-bottom:4px;"
									title="Check the box if you want this Business Service to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
							</vgroup>
							<spacer width="5"/>
						</hgroup>
					<!-- End of form -->
					</form>
				</tab>
				<tab caption="HL7 Input" id="tabHL7Input">
					<vgroup valign="top" id="=vformGroupHL7">
						<form name="formServiceHL7" id="formServiceHL7">
							<spacer height="12"/>
							<hgroup>
								<spacer width="5" />
								<vgroup labelPosition="left" >
									<!-- HL7 Service has several variants, according to protocol which you choose here as Input Type -->
									<radioSet required="true" readOnly="false" hidden="false" value=""
									  name="ServiceHL7InOutType" id="ServiceHL7InOutType" label="Input Type"
									  labelClass="labelRequired"  enclosingStyle="padding-bottom:4px;"
									  title="Specify how incoming messages are received."
									  valueList="TCP,File,FTP,HTTP,SOAP" displayList="TCP,File,FTP,HTTP,SOAP"
									  onclick="zenPage.changeType('Service','HL7');"
									/>
									<!-- Class Name is hidden by design, for HL7 and X12 -->
									<text required="false" readOnly="true" hidden="true"
									    name="ServiceHL7ClassName" id="ServiceHL7ClassName" label="Service Class"
										labelClass="labelRequired" size="43" enclosingStyle="padding-bottom:4px;"
									/>
									<!-- Every HL7 Service form variant has the following 4 fields: Name, Category, Comment, and Enabled -->
									<spacer name="ServiceHL7LineAboveCommonFields" id="ServiceHL7LineAboveCommonFields" height="10"/>
									<text required="true" readOnly="false" hidden="true" value="#(%page.GetFrom())#"
									 	name="ServiceHL7Name" id="ServiceHL7Name" label="HL7 Service Name"
										labelClass="labelRequired" size="43"  enclosingStyle="padding-bottom:4px;"
										title="Enter a name for this HL7 Service. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _"
									/>
									<selector name="ServiceHL7Category" id="ServiceHL7Category" label="Display Category" hidden="true"
										enclosingStyle="padding-bottom:4px;" size="40"
										title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
										multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
									<textarea required="false" readOnly="false" hidden="true"
										name="ServiceHL7Comment" id="ServiceHL7Comment" label="Comment"
										rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
										title="Provide a brief comment about this HL7 Service. This annotation appears in the configuration summary for the production."
									 />
									<checkbox required="false" readOnly="false" hidden="true" value="0"
										name="ServiceHL7Enabled" id="ServiceHL7Enabled" label="Enable Now"
										enclosingStyle="padding-bottom:4px;"
										title="Check the box if you want this HL7 Service to begin processing messages immediately. Otherwise, leave the box unchecked."
									 />
								</vgroup>
							</hgroup>
							<!-- Specialty fields for all HL7 Services -->
							<spacer name="ServiceHL7LineAboveServiceFields" id="ServiceHL7LineAboveServiceFields" height="10" hidden="true" />
							<fieldSet id="ServiceHL7DefaultableFields"
								hidden="true"
								legend=""
								layout="vertical"
								title="Values that can use default">
								<vgroup labelPosition="left" >
										<radioSet required="true" readOnly="false" hidden="true" value="Create"
											name="ServiceHL7TargetAuto" id="ServiceHL7TargetAuto" label="HL7 Service Target*" showLabel="true"
											labelClass="labelRequired" enclosingStyle="padding-bottom:4px;"
											title="Identify the target item that will receive messages from this HL7 Service. Selecting Create New Router will create a new HL7 Message Router as the target for your new HL7 Service. Selecting Choose From List lets you choose a target production item from a list. Select None for Now to leave the Target setting empty for now."
											valueList="Create,Choose,None" displayList="Create New Router,Choose From List,None for Now"
											onclick="zenPage.changeTarget('ServiceHL7');"
										/>
									<selector hidden="true"
										name="ServiceHL7TargetAutoPackage" id="ServiceHL7TargetAutoPackage" label="New Rule Package"
										 enclosingStyle="padding-bottom:4px;" size="40"
										title="Choose or enter the package name for the auto-created rule. Leave blank to use the production's package. This field is ignored if the business service name begins with a package. If the package of the production or routing process is used instead of a specified value, the name of the generated rule class will end with 'RoutingRule'"
										multiSelect="0" context="Ens.ContextSearch/ClassPackages"
										/>
									<selector hidden="true"
										name="ServiceHL7TargetName" id="ServiceHL7TargetName" label="Target"
										enclosingStyle="padding-bottom:4px;" size="40"
										title="Choose the production item that will receive messages from this HL7 Service. This list includes only those production items that could be valid HL7 Service Targets. If there are no such items available, the list is empty."
										multiSelect="0" context="Ens.ContextSearch/ProductionItems?targets=1"
										/>
									<dataCombo editable="true" unrestricted="true" hidden="true"
										name="ServiceHL7SchemaCategory" id="ServiceHL7SchemaCategory" label="HL7 Schema Category*" showLabel="true"
										enclosingStyle="padding-bottom:4px;" size="40" dropdownHeight="85px"
										title="Choose the HL7 Schema Category of the messages that you expect to receive from this source. You must specify a Schema before the Service will work, but you can create a Service without it."
										queryClass="EnsLib.HL7.Message" queryName="EnumerateTypeCategories"
										displayColumns="1" valueColumn="1" choiceColumn="1"
										>
									</dataCombo>

									<!-- Specialty fields for Services with various Protocols/Adapters (show/hide based on Item Type choices) -->
									<!-- Server Address (FTP Service) -->
									<text required="false" readOnly="false" hidden="true"
									 	name="ServiceHL7Addr1" id="ServiceHL7Addr1" label="Server Address*"
										size="43"  enclosingStyle="padding-bottom:4px;"
										title="Enter the IP address for the remote server. You may enter a server name if your domain host controller can resolve it."
										/>
									<!-- Port (TCP Service, FTP Service (21), HTTP Service (9980), SOAP Service (1980)) -->
										<text required="false" readOnly="false"
										 	name="ServiceHL7Port1" id="ServiceHL7Port1" label="Port Number*" showLabel="true"
											size="43"  enclosingStyle="padding-bottom:4px;"
											title="Enter the port number for the incoming connection. Double Click to show possible default value if empty."
										/>

									<!-- Credentials (FTP Service) -->
									<dataCombo editable="true" unrestricted="false" hidden="true"
										name="ServiceHL7Cred" id="ServiceHL7Cred" label="Credentials*"
										enclosingStyle="padding-bottom:4px;" size="40" dropdownHeight="85px"
										title="Choose the configured name of the set of IRIS credentials (username, password) to be used to access the remote system. If there are no credentials defined, the list is empty."
										queryClass="Ens.Config.Credentials" queryName="List"
										displayColumns="1" valueColumn="1" choiceColumn="1"
										>
									</dataCombo>
									<!-- File Path (File Service) -->
									<hgroup id="ServiceHL7FilePath1Grp" label="File Path*" valign="middle" hidden="true" enclosingStyle="padding-bottom:4px;" labelPosition="left"
										title="Enter the path on the IRIS server where the HL7 Service can find input files. Do not include a filename specification in this path.">
										<text required="false" readOnly="false"
										 	name="ServiceHL7FilePath1" id="ServiceHL7FilePath1" size="43"
											title="Enter the path on the IRIS server where the HL7 Service can find input files. Do not include a filename specification in this path."
											/>
										<image src="deepsee/zoom_24.png"
											title="Select the path on the IRIS server where the HL7 Service can find input files. Do not include a filename specification in this path."
											onclick="zenPage.selectDirectory('ServiceHL7FilePath1');"/>
									</hgroup>
									<!-- File Path (FTP Service) -->
									<text required="false" readOnly="false" hidden="true"
									 	name="ServiceHL7FilePath2" id="ServiceHL7FilePath2" label="File Path*"
										size="43"  enclosingStyle="padding-bottom:4px;"
										title="Enter the path on the remote FTP server where the HL7 Service can find input files. Do not include a filename specification in this path."
										/>
									<!--  Archive Path (File Service, FTP Service) -->
									<hgroup id="ServiceHL7ArchiveGrp" label="Archive Path*" valign="middle" hidden="true" enclosingStyle="padding-bottom:4px;"
										title="Enter the path on the IRIS server where the HL7 Service can place copies of the original input files after processing them. Otherwise, the files will be deleted.">
										<text required="false" readOnly="false"
										 	name="ServiceHL7Archive" id="ServiceHL7Archive" size="43"
											title="Enter the path on the IRIS server where the HL7 Service can place copies of the original input files after processing them. Otherwise, the files will be deleted."
										/>
										<image src="deepsee/zoom_24.png"
											title="Select the path on the IRIS server where the HL7 Service can place copies of the original input files after processing them. Otherwise, the files will be deleted."
											onclick="zenPage.selectDirectory('ServiceHL7Archive');"
										/>
									</hgroup>
									<!--  Filenames (File Service, FTP Service) -->
									<text required="false" readOnly="false" hidden="true"
									 	name="ServiceHL7FileSpec1" id="ServiceHL7FileSpec1" label="Filenames*"
										size="43"  enclosingStyle="padding-bottom:4px;"
										title="Using * as a wildcard, specify the files to look for. You may provide a semicolon-separated list of wildcard patterns."
										/>
									<hgroup name="ServiceHL7UseDefaultGrp" id="ServiceHL7UseDefaultGrp" labelClass="useDefaultLabel" labelPosition="left" label="*Default applies if no value">
									<checkbox hidden="false" value="1" labelClass="useDefaultLabel" 
										name="ServiceHL7UseDefault" id="ServiceHL7UseDefault" label="*Default applies if no value" showLabel="false"
										title="Empty Values will not be saved in the production definition and therefore a default value if any will be used. Uncheck this to save empty values for the settings labeled with an asterisk."
										onchange="zenPage.toggleDefaultForEmpty('Service','HL7');"
									/>
									<spacer width="4px"/>
									<image src="deepsee/help_24.png" showLabel="false"
										title="Show possible default values."
										onclick="var sync=zenPage.showPossibleDefaults('Service','HL7');"
									/>
									</hgroup>
								</vgroup>
							</fieldSet>
							<spacer width="5"/>
						<!-- End of form -->
						</form>
					</vgroup>
				</tab>
				<tab caption="X12 Input" id="tabX12Input">
					<vgroup valign="top" id="=vformGroupX12">
						<form name="formServiceX12" id="formServiceX12">
							<spacer height="12" />
							<hgroup>
								<spacer width="5" />
								<vgroup labelPosition="left" >
									<!-- X12 Service has several variants, according to protocol which you choose here as Input Type -->
									<radioSet required="true" readOnly="false" hidden="false" value=""
										name="ServiceX12InOutType" id="ServiceX12InOutType" label="Input Type"
										labelClass="labelRequired"  enclosingStyle="padding-bottom:4px;"
										title="Specify how incoming messages are received."
										valueList="TCP,File,FTP,SOAP" displayList="TCP,File,FTP,SOAP"
										onclick="zenPage.changeType('Service','X12');"
									/>
									<!-- Class Name is hidden by design, for HL7 and X12 -->
									<text required="false" readOnly="true" hidden="true"
										name="ServiceX12ClassName" id="ServiceX12ClassName" label="Service Class"
										labelClass="labelRequired" size="43" enclosingStyle="padding-bottom:4px;"
									/>
									<!-- Every X12 Service form variant has the following 4 fields: Name, Category, Comment, and Enabled -->
									<spacer name="ServiceX12LineAboveCommonFields" id="ServiceX12LineAboveCommonFields" height="10"/>
									<text required="true" readOnly="false" hidden="true" value="#(%page.GetFrom())#"
										name="ServiceX12Name" id="ServiceX12Name" label="X12 Service Name"
										labelClass="labelRequired" size="43"  enclosingStyle="padding-bottom:4px;"
										title="Enter a name for this X12 Service. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _."
									/>
									<selector name="ServiceX12Category" id="ServiceX12Category" label="Display Category" hidden="true"
										enclosingStyle="padding-bottom:4px;" size="40"
										title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
										multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
									<textarea required="false" readOnly="false" hidden="true"
										name="ServiceX12Comment" id="ServiceX12Comment" label="Comment"
										rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
										title="Provide a brief comment about this X12 Service. This annotation appears in the configuration summary for the production."
									/>
									<checkbox required="false" readOnly="false" hidden="true" value="0"
										name="ServiceX12Enabled" id="ServiceX12Enabled" label="Enable Now"
										enclosingStyle="padding-bottom:4px;"
										title="Check the box if you want this X12 Service to begin processing messages immediately. Otherwise, leave the box unchecked."
									/>
								</vgroup>
							</hgroup>
							<!-- Specialty fields for all X12 Services -->
							<spacer name="ServiceX12LineAboveServiceFields" id="ServiceX12LineAboveServiceFields" height="10"/>
							<fieldSet id="ServiceX12DefaultableFields"
								hidden="true"
								legend=""
								layout="vertical"
								title="Values that can use default">
								<vgroup labelPosition="left" >
									<radioSet required="true" readOnly="false" hidden="true" value="Create"
										name="ServiceX12TargetAuto" id="ServiceX12TargetAuto" label="X12 Service Target*"
										labelClass="labelRequired" enclosingStyle="padding-bottom:4px;"
										title="Identify the target item that will receive messages from this X12 Service. Selecting Create New Router will create a new Message Router as the target for your new X12 Service. Selecting Choose From List lets you choose a target production item from a list. Select None for Now to leave the Target setting empty for now."
										valueList="Create,Choose,None" displayList="Create New Router,Choose From List,None for Now"
										onclick="zenPage.changeTarget('ServiceX12');"
									/>
									<selector hidden="true"
										name="ServiceX12TargetAutoPackage" id="ServiceX12TargetAutoPackage" label="New Rule Package"
										enclosingStyle="padding-bottom:4px;" size="40"
										title="Choose or enter the package name for the auto-created rule. Leave blank to use the production's package. This field is ignored if the business service name begins with a package. If the package of the production or routing process is used instead of a specified value, the name of the generated rule class will end with 'RoutingRule'"
										multiSelect="0" context="Ens.ContextSearch/ClassPackages"
									/>
									<selector hidden="true"
										name="ServiceX12TargetName" id="ServiceX12TargetName" label="Target"
										enclosingStyle="padding-bottom:4px;" size="40"
										title="Choose the production item that will receive messages from this X12 Service. This list includes only those production items that could be valid X12 Service Targets. If there are no such items available, the list is empty."
										multiSelect="0" context="Ens.ContextSearch/ProductionItems?targets=1"
									/>
									<!-- Specialty fields for Services with various Protocols/Adapters (show/hide based on Item Type choices) -->
									<!-- Server Address (FTP Service) -->
									<text required="false" readOnly="false" hidden="true"
										name="ServiceX12Addr1" id="ServiceX12Addr1" label="Server Address*"
										size="43"  enclosingStyle="padding-bottom:4px;"
										title="Enter the IP address for the remote server. You may enter a server name if your domain host controller can resolve it."
									/>
									<!-- Port (TCP Service, FTP Service (21)), SOAP Service (1980)) -->
									<text required="false" readOnly="false" hidden="true"
										name="ServiceX12Port1" id="ServiceX12Port1" label="Port Number*"
										size="43"  enclosingStyle="padding-bottom:4px;"
										title="Enter the port number for the incoming connection."
									/>
									<!-- Credentials (FTP Service) -->
									<dataCombo editable="true" unrestricted="false" hidden="true"
										name="ServiceX12Cred" id="ServiceX12Cred" label="Credentials*"
										enclosingStyle="padding-bottom:4px;" size="40" dropdownHeight="85px"
										title="Choose the configured name of the set of IRIS credentials (username, password) to be used to access the remote system. If there are no credentials defined, the list is empty."
										queryClass="Ens.Config.Credentials" queryName="List"
										displayColumns="1" valueColumn="1" choiceColumn="1"
									/>
									<!-- File Path (File Service) -->
									<hgroup id="ServiceX12FilePath1Grp" label="File Path*" valign="middle" hidden="true" enclosingStyle="padding-bottom:4px;"
										title="Enter the path on the IRIS server where the X12 Service can find input files. Do not include a filename specification in this path.">
										<text required="false" readOnly="false"
											name="ServiceX12FilePath1" id="ServiceX12FilePath1" size="43"
											title="Enter the path on the IRIS server where the X12 Service can find input files. Do not include a filename specification in this path."
										/>
										<image src="deepsee/zoom_24.png"
											title="Select the path on the IRIS server where the X12 Service can find input files. Do not include a filename specification in this path."
											onclick="zenPage.selectDirectory('ServiceX12FilePath1');"
										/>
									</hgroup>
									<!-- File Path (FTP Service) -->
									<text required="false" readOnly="false" hidden="true"
										name="ServiceX12FilePath2" id="ServiceX12FilePath2" label="File Path*"
										size="43"  enclosingStyle="padding-bottom:4px;"
										title="Enter the path on the remote FTP server where the X12 Service can find input files. Do not include a filename specification in this path."
									/>
									<!--  Archive Path (File Service, FTP Service) -->
									<hgroup id="ServiceX12ArchiveGrp" label="Archive Path*" valign="middle" hidden="true" enclosingStyle="padding-bottom:4px;"
										title="Enter the path on the IRIS server where the X12 Service can place copies of the original input files after processing them. Otherwise, the files will be deleted.">
										<text required="false" readOnly="false"
											name="ServiceX12Archive" id="ServiceX12Archive" size="43"
											title="Enter the path on the IRIS server where the X12 Service can place copies of the original input files after processing them. Otherwise, the files will be deleted."
										/>
										<image src="deepsee/zoom_24.png"
											title="Select the path on the IRIS server where the X12 Service can place copies of the original input files after processing them. Otherwise, the files will be deleted."
											onclick="zenPage.selectDirectory('ServiceX12Archive');"/>
									</hgroup>
									<!--  Filenames (File Service, FTP Service) -->
									<text required="false" readOnly="false" hidden="true"
										name="ServiceX12FileSpec1" id="ServiceX12FileSpec1" label="Filenames*"
										size="43"  enclosingStyle="padding-bottom:4px;"
										title="Using * as a wildcard, specify the files to look for. You may provide a semicolon-separated list of wildcard patterns."
									/>
									<hgroup name="ServiceX12UseDefaultGrp" id="ServiceX12UseDefaultGrp" labelClass="useDefaultLabel" labelPosition="left" label="*Default applies if no value">
										<checkbox hidden="false" value="1" labelClass="useDefaultLabel" 
											name="ServiceX12UseDefault" id="ServiceX12UseDefault" label="*Default applies if no value" showLabel="false"
											enclosingStyle="padding-bottom:4px;"
											title="Empty Values will not be saved in the production definition and therefore a default value if any will be used. Uncheck this to save empty values for the settings labeled with an asterisk."
											onchange="zenPage.toggleDefaultForEmpty('Service','X12');"
										/>
										<spacer width="4px"/>
										<image src="deepsee/help_24.png" showLabel="false"
											title="Show possible default values."
											onclick="var sync=zenPage.showPossibleDefaults('Service','X12');"
										/>
									</hgroup>
								</vgroup>
							</fieldSet>
							<spacer width="5"/>
						<!-- End of form -->
						</form>
					</vgroup>
				</tab>
				<tab caption="Business Metric">
					<form name="formServiceMETRIC" id="formServiceMETRIC">
						<spacer height="20" />
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is exposed and required for Business Metrics -->
								<selector name="ServiceMETRICClassName" id="ServiceMETRICClassName" label="Metric Class" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40" labelClass="labelRequired" required="true"
									title="Choose a base class for this Business Metric Service. Only valid Business Metric class names appear in the list. If there are no such items available, the list is empty."
									multiSelect="false" context="Ens.ContextSearch/BusinessMetrics"
								/>
								<!-- Every Business Service form variant has a Name, Category, Comment, and Enabled -->
								<spacer name="ServiceMETRICLineAboveCommonFields" id="ServiceMETRICLineAboveCommonFields" height="10"/>
								<text required="false" readOnly="false" hidden="false"
									name="ServiceMETRICName" id="ServiceMETRICName" label="Metric Name"
									size="43" enclosingStyle="padding-bottom:4px;"
									title="Enter a name for this Business Metric Service. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. If you do not enter a name, the Class Name is used."
								/>
								<selector name="ServiceMETRICCategory" id="ServiceMETRICCategory" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories"
								/>
								<textarea required="false" readOnly="false" hidden="false"
									name="ServiceMETRICComment" id="ServiceMETRICComment" label="Comment"
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
									title="Provide a brief comment about this Business Metric Service. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="ServiceMETRICEnabled" id="ServiceMETRICEnabled" label="Enable Now"
									enclosingStyle="padding-bottom:4px;"
									title="Check the box if you want this Business Metric Service to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
								<!-- Specialty fields for Business Metric Services -->
								<text required="false" readOnly="false" hidden="false" value="5"
									name="ServiceMETRICCallInterval" id="ServiceMETRICCallInterval" label="Call Interval"
									size="43"  enclosingStyle="padding-bottom:4px;"
									title="Specify how frequently (in seconds) this Business Metric Service should recalculate its values."
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
			<label id="helpSubject" enclosingClass="labelComment" label="Use this form to add a new business service to the production." />
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

/// <p>
/// The return value of this method is a string that provides
/// a service name, router name, rule class name and/or rule alias name,
/// by means of consecutive comma-separated entries as follows:
/// <p>
/// First position: The derived service &lt;configurationName&gt; (all cases)<br/>
/// Second position: "+" if a router by the specified name (second position) needs to be created; "-" if it was requested to be created but already exists; otherwise "" (blank).<br/>
/// Third position: The derived router &lt;configurationName&gt; (if it needs to be created)<br/>
/// Fourth position: "+" if the original rule class or alias name had to have a package name prepended; otherwise blank<br/>
/// Fifth position: The rule &lt;aliasName&gt; if a suitable class name had to be derived and this is the alias (the original name provided for the rule)<br/>
/// Sixth position: The rule &lt;className&gt; (all cases); if empty, there is no rule<br/>
/// Seventh position: "-" if a rule with this class name already exists, otherwise blank<br/>
/// <p>
Method DeriveAllNames(pProdId As %String, pProtocol As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set msg = ""

	Set production = ##class(Ens.Config.Production).%OpenId(pProdId)
	If $IsObject($G(production)) {

		// get service name
		Set tName = ..%GetValueById("Service"_pProtocol_"Name") // get name of service

		Set tName = $ZCVT(tName,"O","HTML")
		Do ..%SetValueById("Service"_pProtocol_"Name",tName)

		Set:tName="" tName = ..%GetValueById("Service"_pProtocol_"ClassName")
		Set msg = msg_tName

		// should we create a new router for our target?
		If ..%GetValueById("Service"_pProtocol_"TargetAuto")="Create" { // yes, create a new router
			// create a new router only if it does not already exist
			If pProtocol="HL7" {
				Set tRouterType = "EnsLib.HL7.MsgRouter.RoutingEngine"
			}
			ElseIf pProtocol = "X12" {
				Set tRouterType = "EnsLib.MsgRouter.VDocRoutingEngine"
			}
			Else {
			}
			Set tRouterName = tName_"_Router" // name the router
			If ($P(..ItemAlreadyExists(production.Name,tRouterName,tRouterType),":",1) = "Duplicate") {
				// this is acceptable, just skip creating the new one
				Set msg = msg_",-,"_tRouterName_",,,"
			}
			Else {
				// indicate the name of the router and (if any) rule to be created
				#; Find from drop down
				#dim tAutoPackage = ..%GetValueById("Service"_pProtocol_"TargetAutoPackage")

				#dim tAppendRRText = 1
				If (tName'[".") && (tAutoPackage'="") && ($Piece(pProdId,".",1,*-1)'=tAutoPackage) {
					Set tAppendRRText = 0
				}

				If tAppendRRText Set tName = tName_"RoutingRule"

				Set msg = msg_",+,"_tRouterName_","_..DeriveRuleNames(pProdId,tName,tAutoPackage)
			}
		}
		Else {
			// no auto-create for this service
			Set msg = msg_",,,,,"
		}
	}

	Quit msg
}

/// This method is invoked when the user completes the Wizard pressing "OK".
/// Returns a null string if it succeeds, or an error message otherwise.
Method OnWizardCompletion(pProdId As %String, pForm As %String, pType As %String, pCreate As %Boolean, pServiceName As %String, pRouterName As %String, pRuleAlias As %String, pRuleClass As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tmsg = ""

	Try {
		Set production = ##class(Ens.Config.Production).%OpenId(pProdId)
		If $IsObject($G(production)) {
			// Add the new host to the Production
			If pForm="formServiceOTHER" {
				Set tSC = ..AddNewItem(pForm, "ServiceOTHER", production, .item)
				If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
			}
			ElseIf pForm="formServiceHL7" {
				Set tSC = ..AddNewItem(pForm, "ServiceHL7", production, .item)
				If $$$ISOK(tSC) {
					// schema category
					Set schema = ..%GetValueById("ServiceHL7SchemaCategory")
					Do ..ItemSettingsInsert(.item,"MessageSchemaCategory","Host",schema)
					// should we create a new router for our target?
					If ..%GetValueById("ServiceHL7TargetAuto")="Create" {
						Set target = pRouterName // connect HL7 service to HL7 router
						If (pCreate) { // a router of this name does NOT already exist
							// add new HL7 router to work with the new HL7 service
							Set itemRouter = ##class(Ens.Config.Item).%New()
							Set itemRouter.PoolSize = 1
							Set itemRouter.ClassName = "EnsLib.HL7.MsgRouter.RoutingEngine"
							Set itemRouter.Category = item.Category // same as HL7 service
							Set itemRouter.Enabled = item.Enabled // same as HL7 service
							Set itemRouter.Name = pRouterName
							Do production.Items.Insert(itemRouter)
							Set tSC = ..SubmitRoutingRule("HL7",pServiceName,schema,itemRouter,pRuleAlias,pRuleClass,"") //Pass empty string to validation
							If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
						}
					}
					Else { // either the name is blank, or it is the chosen target
						Set target = ..%GetValueById("ServiceHL7TargetName")
					}

					// service target
					Do ..ItemSettingsInsert(.item,"TargetConfigNames","Host",target)

					// adapter settings
					Do ..AddServiceSettings(pForm, "ServiceHL7", item)
				}
				Else {
					Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			ElseIf pForm="formServiceX12" { // X12 Output
				Set tSC = ..AddNewItem(pForm, "ServiceX12", production, .item)
				If $$$ISOK(tSC) {
					// should we create a new router for our target?
					If ..%GetValueById("ServiceX12TargetAuto")="Create" {
						Set target = pRouterName // connect X12 service to X12 router
						If (pCreate) { // a router of this name does NOT already exist
							// add new X12 router to work with the new X12 service
							Set itemRouter = ##class(Ens.Config.Item).%New()
							Set itemRouter.PoolSize = 1
							Set itemRouter.ClassName = "EnsLib.EDI.X12.MsgRouter.RoutingEngine"
							Set itemRouter.Category = item.Category // same as X12 service
							Set itemRouter.Enabled = item.Enabled // same as X12 service
							Set itemRouter.Name = pRouterName
							Do production.Items.Insert(itemRouter)
							Set tSC = ..SubmitRoutingRule("X12",pRouterName,,itemRouter,pRuleAlias,pRuleClass,"") //Pass empty string to validation
							If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
						}
					}
					Else { // either the name is blank, or it is the chosen target
						Set target = ..%GetValueById("ServiceX12TargetName")
					}

					// service target
					Do ..ItemSettingsInsert(.item,"TargetConfigNames","Host",target)

					// adapter settings
					Do ..AddServiceSettings(pForm, "ServiceX12", item)
				}
				Else {
					Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			ElseIf pForm="formServiceMETRIC" { // Business Metric
				Set tSC = ..AddNewItem(pForm, "ServiceMETRIC", production, .item)
				If $$$ISOK(tSC) {
					// call interval
					Do ..ItemSettingsInsert(.item,"CallInterval","Adapter",..%GetValueById("ServiceMETRICCallInterval"),1 /* can't be empty*/)

					If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
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

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Business Service Wizard","Ensemble")
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
	Quit $$$TextHTML("Add a new Business Service to this Production.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.retValue;
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the action is canceled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	var tabs = zen('groupService');
	if (tabs) {
		currentTab = tabs.getCurrTabNo();
	}
	var currentTabCaption = tabs.children[currentTab-1].caption;

	var formName;
	var hostType;
	var createRouter;
	var serviceName;
	var routerName;
	var aliasName;
	var className;
	var msgToConfirm;

	switch (currentTabCaption) {
		case $$$Text('All Services'):
			formName = 'formServiceOTHER';
			hostType = 'OTHER';
			createRouter = false;
			serviceName = "";
			routerName = "";
			aliasName = "";
			className = "";
			break;
		case $$$Text('HL7 Input'):
			formName = 'formServiceHL7';
			hostType = 'HL7';
			break;
		case $$$Text('X12 Input'):
			formName = 'formServiceX12';
			hostType = 'X12';
			break;
		case $$$Text('Business Metric'):
			formName = 'formServiceMETRIC';
			hostType = 'METRIC';
			createRouter = false;
			serviceName = "";
			routerName = "";
			aliasName = "";
			className = "";
			break;
		default:
			return false;
			break;
	}

	try {
		var isValid = zenPage.validateAll('Service', hostType);
		if (isValid) {
			if ( (hostType == 'HL7') || (hostType == 'X12') ) {
				var names = zenPage.DeriveAllNames(zenPage.ProductionName, hostType);
				var name = names.split(",")
				// service name [0] router flag [1] router name [2] rule flag [3] alias name [4] class name [5] rule exists flag [6]
				serviceName = name[0];
				switch (name[1]) {
					case "+": // auto-create requested and needed
						routerName = name[2];
						msgToConfirm = $$$FormatText($$$Text("You have requested that a router be automatically created for your service. A router will be created with the name %1. This name is automatically derived from the Service Name."),routerName);
						msgToConfirm += (" " + $$$Text("If this is acceptable, click OK. If you wish to use different names for your new service and router, click Cancel and adjust the Service Name field."));
						msgToConfirm += (" " + $$$Text("The Validation setting of the router will use the default."));
						if (!confirm(msgToConfirm)) {
							return false;
						}
						createRouter = true;
						aliasName = name[4];
						className = name[5];
						if (name[6] == "-") { // rule already exists
							msgToConfirm = $$$FormatText($$$Text("According to IRIS naming conventions, the routing rule class for your automatically created router already exists: %1."),className);
							msgToConfirm += (" " + $$$Text("A new rule class will not be automatically created, but your new router will be configured with this rule."));
							msgToConfirm += (" " + $$$Text("You may change this configuration later."));
							if (!confirm(msgToConfirm)) {
								return false;
							}
						}
						else { // we are creating the rule
							if (aliasName.length > 0) { // had to construct a class name, so will use the provided field value as an alias
								msgToConfirm = $$$Text("A routing rule will be automatically created for the router associated with your service.")
								msgToConfirm += (" " + $$$FormatText($$$Text("Due to restrictions on rule class names, your rule class will be called %1 and it will have the alias %2. These names are automatically derived from the Service Name."),className,aliasName));
								msgToConfirm += (" " + $$$Text("If this is acceptable, click OK. If you wish to rename your rule, router, and service, click Cancel and adjust the Service Name field."));
								if (!confirm(msgToConfirm)) {
									return false;
								}
							}
							else {
								if (name[3] == "+") { // had to prepend a package name to the provided field value
									msgToConfirm = $$$Text("A routing rule will be automatically created for the router associated with your service.");
									msgToConfirm += (" " + $$$FormatText($$$Text("The full name for your rule class will be %1. This name is automatically derived from the Service Name."),className));
									msgToConfirm += (" " + $$$Text("If this is acceptable, click OK. If you wish to rename your rule, router, and service, click Cancel and adjust the Service Name field."));
									if (!confirm(msgToConfirm)) {
										return false;
									}
				 				}
							}
						}
						break;
					case "-": // auto-create requested but not needed
						routerName = name[2];
						msgToConfirm = $$$Text("You have requested that a router be automatically created for your service.");
						msgToConfirm += (" " + $$$FormatText($$$Text("A router with the corresponding name for your service already exists. This router, %1, will be automatically configured as the router for your new service."),routerName));
						msgToConfirm += (" " + $$$Text("If this is acceptable, click OK. If you wish to use different names for your new service and router, click Cancel and adjust the Service Name field."));
						if (!confirm(msgToConfirm)) {
							return false;
						}
						createRouter = false;
						aliasName = "";
						className = "";
						break;
					case "": // no auto-create
						createRouter = false;
						aliasName = "";
						className = "";
						break;
				}
			}
			var msg = zenPage.OnWizardCompletion(zenPage.ProductionName, formName, hostType, createRouter, serviceName, routerName, aliasName, className);
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

/// This callback is called after the server-side page
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()

	// send the production name to the category selector components
	Set sel = ..%GetComponentById("ServiceOTHERCategory")
	Set sel.context = sel.context _ "?productionName=" _ ..ProductionName

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("HL7") {
		Set sel = ..%GetComponentById("ServiceHL7Category")
		Set sel.context = sel.context _ "?productionName=" _ ..ProductionName
		Set sel = ..%GetComponentById("ServiceHL7TargetName")
		Set sel.context = sel.context _ "&productionName=" _ ..ProductionName
		Set sel = ..%GetComponentById("ServiceHL7TargetAutoPackage")
		Set sel.value = ..DefaultRulePackage()
	} Else {
		Set sel = ..%GetComponentById("groupService")
		For tTab=1:1:sel.children.Count(){
			If sel.children.GetAt(tTab).id = "tabHL7Input" {Do sel.children.RemoveAt(tTab)  Quit}
		}
	}

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("X12") {
		Set sel = ..%GetComponentById("ServiceX12Category")
		Set sel.context = sel.context _ "?productionName=" _ ..ProductionName
		Set sel = ..%GetComponentById("ServiceX12TargetName")
		Set sel.context = sel.context _ "&productionName=" _ ..ProductionName
		Set sel = ..%GetComponentById("ServiceX12TargetAutoPackage")
		Set sel.value = ..DefaultRulePackage()
	} Else {
		Set sel = ..%GetComponentById("groupService")
		For tTab=1:1:sel.children.Count(){
			If sel.children.GetAt(tTab).id = "tabX12Input" {Do sel.children.RemoveAt(tTab)  Quit}
		}
	}

	Set sel = ..%GetComponentById("ServiceMETRICCategory")
	Set sel.context = sel.context _ "?productionName=" _ ..ProductionName

	Quit tSC
}

}
