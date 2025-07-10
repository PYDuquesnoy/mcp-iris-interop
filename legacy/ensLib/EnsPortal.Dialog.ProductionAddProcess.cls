/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Add a new component to a production
Class EnsPortal.Dialog.ProductionAddProcess Extends (EnsPortal.Dialog.ProductionAddHost, EnsPortal.Util.PageLinks) [ System = 4 ]
{

Parameter PAGENAME = "Add Business Process";

/// For the OTHER tab, whether or not the class selected is a routing engine class
Property isRouter As %ZEN.Datatype.boolean;

/// For a routing process, whether or not the Auto-Create Rule box is checked
Property isChecked As %ZEN.Datatype.boolean;

XData Style
{
<style type="text/css">
/* @doc="Wrapper for body of tabgroup, when tab bar is shown." */
.tabGroupBody {
	width: 570px;
	height: 300px;
}
.useValidationLabel {
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
			<tabGroup name="groupProcess" id="groupProcess" showTabBar="true" remember="true">
				<tab caption="All Processes">
					<form name="formProcessOTHER" id="formProcessOTHER">
						<spacer height="20" />
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is exposed and required for regular Business Processes -->
								<selector name="ProcessOTHERClassName" id="ProcessOTHERClassName" label="Business Process Class" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40" labelClass="labelRequired" required="true"
									title="Choose a base class for this Business Process. Only valid Business Process class names appear in the list. If there are no such items available, the list is empty."
									multiSelect="false" context="Ens.ContextSearch/BusinessProcesses" onchange="zenPage.toggleRuleCheckbox();" />
								<!-- The following fields provide for the case where user might choose a routing Business Process class above -->
								<checkbox hidden="true" value="false"
									name="ProcessOTHERAutoRule" id="ProcessOTHERAutoRule" label="Auto-Create Rule"
									enclosingStyle="padding-bottom:4px;"
									title="The created rule name will be based on the business process name"
									onchange="zenPage.toggleRuleField('OTHER');"
								/>
								<selector readOnly="false" hidden="true"
									name="ProcessOTHERRuleName" id="ProcessOTHERRuleName" label="Routing Rule Name"
									context="Ens.ContextSearch/RoutingRuleNames" size="40" enclosingStyle="padding-bottom:4px;"
									title="Identify the rule that will route messages for this process. If this rule does not exist, the wizard will create it. If you enter a simple rule name, the rule will be created in the production package. If you enter a full rule name with a package name, a rule with that full name will be created. "
								/>
								<selector hidden="true"
									name="ProcessOTHERRulePackage" id="ProcessOTHERRulePackage" label="New Rule Package"
									 enclosingStyle="padding-bottom:4px;" size="40"
									title="Choose or enter the package name for the auto-created rule. Leave blank to use the production's package. This field is ignored if the routing process name begins with a package. If the package of the production or routing process is used instead of a specified value, the name of the generated rule class will end with 'RoutingRule'"
									multiSelect="0" context="Ens.ContextSearch/ClassPackages"
								/>
								<hgroup id="ProcessOTHERRuleValidationGrp" label="Validation (use default if empty)" valign="middle" hidden="true" enclosingStyle="padding-bottom:4px;"
										title="Enter Validation for router." labelPosition="left">
									<text required="false" readOnly="false" hidden="false"
										name="ProcessOTHERRuleValidation" id="ProcessOTHERRuleValidation"
										size="10" enclosingStyle="padding-bottom:4px;"
										title="Enter Validation for router."
									/>
									<spacer width="5px"/>
									<image src="deepsee/help_24.png"
										title="Show possible default value if empty."
										onclick="alert(zenPage.showPossibleDefault('ProcessOTHER','Validation'));"
									/>
									<spacer  width="20px"/>
									<checkbox hidden="false" value="0" labelClass="useValidationLabel"
										name="ProcessOTHERRuleNoValidation" id="ProcessOTHERRuleNoValidation" label="No Validation"
										title="Enable this to use no validation instead of default validation"
										onchange="zenPage.changeRuleValidation('ProcessOTHER');"
									/>
								</hgroup>
								<!-- Every Business Process form variant has a Name, Category, Comment, and Enabled -->
								<spacer name="ProcessOTHERLineAboveCommonFields" id="ProcessOTHERLineAboveCommonFields" height="10"/>
								<text required="false" readOnly="false" hidden="false"
									name="ProcessOTHERName" id="ProcessOTHERName" label="Business Process Name"
									size="43" enclosingStyle="padding-bottom:4px;"
									title="Enter a name for this Business Process. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. If you do not enter a name, the Process Class name is used."
								/>
								<selector name="ProcessOTHERCategory" id="ProcessOTHERCategory" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
								<textarea required="false" readOnly="false" hidden="false"
									name="ProcessOTHERComment" id="ProcessOTHERComment" label="Comment"
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
									title="Provide a brief comment about this Business Process. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="ProcessOTHEREnabled" id="ProcessOTHEREnabled" label="Enable Now"
									enclosingStyle="padding-bottom:4px;"
									title="Check the box if you want this Business Process to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
								<text required="true" readOnly="false" hidden="false"
									name="ProcessOTHERPool" id="ProcessOTHERPool" label="Pool Size"
									size="2" enclosingStyle="padding-bottom:4px;"
									title="Enter the Pool Size for this Business Process. If a Pool Size of 0 is entered then the item will be Enabled when added."
									value="1"
								/>
							</vgroup>
							<vgroup valign="top" id="ProcessOTHERRuleDetail" hidden="true">
								<spacer height="47" /><!-- line up horizontally with the ProcessOTHERRuleName field -->
								<image src="deepsee/zoom_24.png" id="btnRuleOTHER" title="Show details for the selected Rule."
									onclick="zenPage.showRuleDetails('ProcessOTHERRuleName');" />
							</vgroup>
							<spacer width="5"/>
						</hgroup>
					<!-- End of form -->
					</form>
				</tab>
				<tab caption="HL7 Router" id="tabHL7Router">
					<form name="formProcessHL7" id="formProcessHL7">
						<spacer height="12" />
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is hidden by design, for HL7 and X12 -->
								<text required="false" readOnly="true" hidden="true"
									name="ProcessHL7ClassName" id="ProcessHL7ClassName" label="Class Name"
									value="EnsLib.HL7.MsgRouter.RoutingEngine"
									labelClass="labelRequired" size="43" enclosingStyle="padding-bottom:4px;"
								/>
								<!-- The following fields provide routing rule options -->
								<checkbox hidden="false"
									name="ProcessHL7AutoRule" id="ProcessHL7AutoRule" label="Auto-Create Rule"
									enclosingStyle="padding-bottom:4px;"
									title="The created rule name will be based on the business process name"
									onchange="zenPage.toggleRuleField('HL7');"
								/>
								<selector readOnly="false" hidden="false"
									name="ProcessHL7RuleName" id="ProcessHL7RuleName" label="Routing Rule Name"
									context="Ens.ContextSearch/RoutingRuleNames" size="40" enclosingStyle="padding-bottom:4px;"
									title="Identify the rule that will route messages for this process. If this rule does not exist, the wizard will create it. If you enter a simple rule name, the rule will be created in the production package. If you enter a full rule name with a package name, a rule with that full name will be created. "
							 	/>
								<selector hidden="true"
									name="ProcessHL7RulePackage" id="ProcessHL7RulePackage" label="New Rule Package"
									 enclosingStyle="padding-bottom:4px;" size="40"
									title="Choose or enter the package name for the auto-created rule. Leave blank to use the production's package. This field is ignored if the routing process name begins with a package. If the package of the production or routing process is used instead of a specified value, the name of the generated rule class will end with 'RoutingRule'"
									multiSelect="0" context="Ens.ContextSearch/ClassPackages"
								/>
								<hgroup id="ProcessHL7RuleValidationGrp" label="Validation (use default if empty)" valign="middle" hidden="false" enclosingStyle="padding-bottom:4px;"
										title="Enter Validation for router." labelPosition="left">
										<text required="false" readOnly="false" hidden="false"
											name="ProcessHL7RuleValidation" id="ProcessHL7RuleValidation"
											size="10" enclosingStyle="padding-bottom:4px;"
										/>
										<spacer width="5px"/>
										<image src="deepsee/help_24.png"
											title="Show possible default value if empty."
											onclick="alert(zenPage.showPossibleDefault('ProcessHL7','Validation'));"
										/>
										<spacer  width="20px"/>
										<checkbox hidden="false" value="0" labelClass="useValidationLabel"
											name="ProcessHL7RuleNoValidation" id="ProcessHL7RuleNoValidation" label="No Validation"
											title="Enable this to use no validation instead of default validation"
											onchange="zenPage.changeRuleValidation('ProcessHL7');"
										/>
								</hgroup>
								<!-- Every HL7 Process form variant has the following 4 fields: Name, Category, Comment, and Enabled -->
								<spacer name="ProcessHL7LineAboveCommonFields" id="ProcessHL7LineAboveCommonFields" height="10"/>
								<text required="true" readOnly="false" hidden="false"
									name="ProcessHL7Name" id="ProcessHL7Name" label="HL7 Routing Process Name"
									labelClass="labelRequired" size="43"  enclosingStyle="padding-bottom:4px;"
									title="Enter a name for this HL7 Message Router. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. To specify a package for the routing process, use the format 'package.name'"
								/>
								<selector name="ProcessHL7Category" id="ProcessHL7Category" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
								<textarea required="false" readOnly="false" hidden="false"
									name="ProcessHL7Comment" id="ProcessHL7Comment" label="Comment"
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
									title="Provide a brief comment about this HL7 Message Router. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="ProcessHL7Enabled" id="ProcessHL7Enabled" label="Enable Now"
									enclosingStyle="padding-bottom:4px;"
									title="Check the box if you want this HL7 Message Router to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
							</vgroup>
							<vgroup valign="top" id="ProcessHL7RuleDetail" hidden="false">
								<spacer height="23" /><!-- line up horizontally with the ProcessHL7RuleName field -->
								<image src="deepsee/zoom_24.png" id="btnRuleHL7" title="Show details for the selected Rule."
									onclick="zenPage.showRuleDetails('ProcessHL7RuleName');" />
							</vgroup>
							<spacer width="5"/>
						</hgroup>
					<!-- End of form -->
					</form>
				</tab>
				<tab caption="X12 Router" id="tabX12Router">
					<form name="formProcessX12" id="formProcessX12">
						<spacer height="12" />
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is hidden by design, for HL7 and X12 -->
								<text required="false" readOnly="true" hidden="true"
									name="ProcessX12ClassName" id="ProcessX12ClassName" label="Class Name"
									value="EnsLib.EDI.X12.MsgRouter.RoutingEngine"
									labelClass="labelRequired" size="40" enclosingStyle="padding-bottom:4px;"
								/>
								<!-- The following fields provide routing rule options -->
								<checkbox hidden="false" value="false"
									name="ProcessX12AutoRule" id="ProcessX12AutoRule" label="Auto-Create Rule"
									enclosingStyle="padding-bottom:4px;"
									title="The created rule name will be based on the business process name"
									onchange="zenPage.toggleRuleField('X12');"
								/>
								<selector readOnly="false" hidden="false"
									name="ProcessX12RuleName" id="ProcessX12RuleName" label="Routing Rule Name"
									context="Ens.ContextSearch/RoutingRuleNames" size="40" enclosingStyle="padding-bottom:4px;"
									title="Identify the rule that will route messages for this process. If this rule does not exist, the wizard will create it. If you enter a simple rule name, the rule will be created in the production package. If you enter a full rule name with a package name, a rule with that full name will be created. "
								/>
								<selector hidden="true"
									name="ProcessX12RulePackage" id="ProcessX12RulePackage" label="New Rule Package"
									 enclosingStyle="padding-bottom:4px;" size="40"
									title="Choose or enter the package name for the auto-created rule. Leave blank to use the production's package. This field is ignored if the routing process name begins with a package. If the package of the production or routing process is used instead of a specified value, the name of the generated rule class will end with 'RoutingRule'"
									multiSelect="0" context="Ens.ContextSearch/ClassPackages"
								/>
								<hgroup id="ProcessX12RuleValidationGrp" label="Validation (use default if empty)" valign="middle" hidden="false" enclosingStyle="padding-bottom:4px;"
										title="Enter Validation for router." labelPosition="left">
									<text required="false" readOnly="false" hidden="false"
									 	name="ProcessX12RuleValidation" id="ProcessX12RuleValidation"
										size="10" enclosingStyle="padding-bottom:4px;"
										title="Enter Validation for router."
									/>
									<spacer width="5px"/>
									<image src="deepsee/help_24.png"
										title="Show possible default value if empty."
										onclick="alert(zenPage.showPossibleDefault('ProcessX12','Validation'));"
									/>
									<spacer  width="20px"/>
									<checkbox hidden="false" value="0" labelClass="useValidationLabel"
										name="ProcessX12RuleNoValidation" id="ProcessX12RuleNoValidation" label="No Validation"
										title="Enable this to use no validation instead of default validation"
										onchange="zenPage.changeRuleValidation('ProcessX12');"
									/>
								</hgroup>
								<!-- Every X12 Process form variant has the following 4 fields: Name, Category, Comment, and Enabled -->
								<spacer name="ProcessX12LineAboveCommonFields" id="ProcessX12LineAboveCommonFields" height="10"/>
								<text required="true" readOnly="false" hidden="false"
									name="ProcessX12Name" id="ProcessX12Name" label="X12 Routing Process Name"
									labelClass="labelRequired" size="43"  enclosingStyle="padding-bottom:4px;"
									title="Enter a name for this X12 Message Router. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. To specify a package for the routing process, use the format 'package.name'"
								/>
								<selector name="ProcessX12Category" id="ProcessX12Category" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
								<textarea required="false" readOnly="false" hidden="false"
									name="ProcessX12Comment" id="ProcessX12Comment" label="Comment"
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
									title="Provide a brief comment about this X12 Message Router. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="ProcessX12Enabled" id="ProcessX12Enabled" label="Enable Now"
									enclosingStyle="padding-bottom:4px;"
									title="Check the box if you want this X12 Message Router to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
							</vgroup>
							<vgroup valign="top" id="ProcessX12RuleDetail" hidden="false">
								<spacer height="23" /><!-- line up horizontally with the ProcessX12RuleName field -->
								<image src="deepsee/zoom_24.png" id="btnRuleX12" title="Show details for the selected Rule."
									onclick="zenPage.showRuleDetails('ProcessX12RuleName');" />
							</vgroup>
							<spacer width="5"/>
						</hgroup>
					<!-- End of form -->
					</form>
				</tab>
				<tab caption="Component">
					<form name="formProcessCOMPONENT" id="formProcessCOMPONENT">
						<spacer height="20" />
						<hgroup>
							<spacer width="5" />
							<vgroup labelPosition="left" >
								<!-- Class Name is exposed and required for Business Process Components -->
								<selector name="ProcessCOMPONENTClassName" id="ProcessCOMPONENTClassName" label="Component Class" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40" labelClass="labelRequired" required="true"
									title="Choose a base class for this Business Process Component. Only classes designated as components appear in the list. If there are no such items available, the list is empty."
									multiSelect="false" context="Ens.ContextSearch/BusinessComponents" />
								<!-- Every Business Process form variant has a Name, Category, Comment, and Enabled -->
								<spacer name="ProcessCOMPONENTLineAboveCommonFields" id="ProcessCOMPONENTLineAboveCommonFields" height="10"/>
								<text required="false" readOnly="false" hidden="false"
									name="ProcessCOMPONENTName" id="ProcessCOMPONENTName" label="Component Name"
									size="43" enclosingStyle="padding-bottom:4px;"
									title="Enter a name for this Business Process Component. Do not use the characters ;,:|!*-$ or [ in the name and do not start the name with _. If you do not enter a name, the Component Class name is used."
								/>
								<selector name="ProcessCOMPONENTCategory" id="ProcessCOMPONENTCategory" label="Display Category" hidden="false"
									enclosingStyle="padding-bottom:4px;" size="40"
									title="To group items together in the production configuration summary, give each item the same Category name. You may choose a name from the list, type in a new Category name, or type in a comma-separated list of names. If there are no Categories defined, the list is empty."
									multiSelect="true" context="Ens.ContextSearch/ProductionCategories" />
								<textarea required="false" readOnly="false" hidden="false"
									name="ProcessCOMPONENTComment" id="ProcessCOMPONENTComment" label="Comment"
									rows="1" cols="34" enclosingStyle="padding-bottom:4px;"
									title="Provide a brief comment about this Business Process Component. This annotation appears in the configuration summary for the production."
								/>
								<checkbox required="false" readOnly="false" hidden="false" value="0"
									name="ProcessCOMPONENTEnabled" id="ProcessCOMPONENTEnabled" label="Enable Now"
									enclosingStyle="padding-bottom:4px;"
									title="Check the box if you want this Business Process Component to begin processing messages immediately. Otherwise, leave the box unchecked."
								/>
								<text required="true" readOnly="false" hidden="false"
									name="ProcessCOMPONENTPool" id="ProcessCOMPONENTPool" label="Pool Size"
									size="2" enclosingStyle="padding-bottom:4px;"
									title="Enter the Pool Size for this Business Process Component. If a Pool Size of 0 is entered then the item will be Enabled when added."
									value="1"
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
			<label id="helpSubject" enclosingClass="labelComment" label="Use this form to add a new business process to the production." />
			<spacer height="10" />
			<label id="helpHover" enclosingClass="labelComment" label="For help with any setting in this form, hover the cursor over the setting name." />
			<spacer height="100" />
			<!-- useDefaultForEmptyValue not used on this page -->
			<checkbox required="false" readOnly="false" hidden="true" value="1"
				name="useDefaultForEmptyValue" id="useDefaultForEmptyValue" label="Validation setting with no value will use the Default value."
				enclosingStyle="padding-bottom:4px;"
				title="Uncheck the box if you want empty string to be saved in the production definition for Validation."
			/>
		</vgroup>
	</hgroup>
</pane>
}

/// We only use this for the OTHER tab. The HL7 and X12 routing processes are always router classes.
ClientMethod toggleRuleCheckbox() [ Language = javascript ]
{
	var cls = zen("ProcessOTHERClassName").getValue();
	var chk = zen("ProcessOTHERAutoRule");
	var nam = zen("ProcessOTHERRuleName");
	var det = zen("ProcessOTHERRuleDetail");
	var val = zen("ProcessOTHERRuleValidationGrp");
	var noVal = zen("ProcessOTHERRuleNoValidation");
	zenPage.isRouter = zenPage.IsRouterClass(cls);
	zenPage.hasValidation = zenPage.RouterHasValidationSetting(cls);
	if (zenPage.isRouter) {
		chk.setValue(false);
		nam.setValue("");
		chk.setHidden(0);
		nam.setHidden(0);
		det.setHidden(0);
		if (val) {
			val.setHidden(!zenPage.hasValidation);
			if (noVal) noVal.setHidden(!zenPage.hasValidation);
		}
	}
	else {
		chk.setValue(false);
		nam.setValue("");
		chk.setHidden(1);
		nam.setHidden(1);
		det.setHidden(1);
		if (val) {
			val.setHidden(1);
			if (noVal) noVal.setHidden(1);
		}
	}
}

ClassMethod IsRouterClass(pClass As %String) As %Boolean [ ZenMethod ]
{
	Set ret = 0
	If pClass'="" {
		Try {
			Set ret = $classmethod(pClass,"%IsA","EnsLib.MsgRouter.RoutingEngine")
		}
		Catch {
		}
	}
	Quit ret
}

ClientMethod toggleRuleField(tab) [ Language = javascript ]
{
	zenPage.isChecked = zen("Process"+tab+"AutoRule").getValue();
	var nam = zen("Process"+tab+"RuleName");
	var det = zen("Process"+tab+"RuleDetail");
	var package = zen("Process"+tab+"RulePackage");
	if (zenPage.isChecked) {
		nam.setValue("");
		nam.setHidden(1);
		det.setHidden(1);
		if (package) package.setHidden(0);
	}
	else {
		nam.setValue("");
		nam.setHidden(0);
		det.setHidden(0);
		if (package) package.setHidden(1);
	}
}

/// Launch the profile info dialog.
ClientMethod showRuleDetails(field) [ Language = javascript ]
{
	// get the class name or alias from the list
	var name = zen(field).getValue();
	if (''==name) {
		alert($$$Text("Click here after selecting a Rule to see the Rule's details."));
		return;
	}
	else { // make sure we are using a class name, not an alias, when popping up the rule editor
		var newName = this.GetClassName(name);
	}
	var parms = {
		rule:(newName!="")?newName : name
	};
	if (zenPage.ruleEditorBaseURL.indexOf('EnsPortal.RuleEditor')>0) {
		zenLaunchPopupWindow(zenLink(zenPage.ruleEditorBaseURL,this.studioMode),'','status,scrollbars,resizable=yes,width=1000,height=600',parms);
	} else {
		var ruleLink = zenPage.ruleEditorBaseURL+'&rule='+encodeURIComponent(newName);
		window.open(zenLink(ruleLink));
	}
}

/// Get the class name (in case what's been selected is an alias which is invalid as a class name).
/// If the id is already a class name, that class name will be returned as the return value.
ClassMethod GetClassName(id As %String) As %String [ ZenMethod ]
{
	Set tClassName = ##class(Ens.Projection.Rule).ResolveRuleAlias(id)
	try {
		Set tFound = $classmethod(tClassName,"%Extends","Ens.Rule.Definition")
	}
	catch {
		Set tFound = 0
	}
	Quit $S(tFound:tClassName, 1:"")
}

/// This method is invoked when the user completes the Wizard pressing "OK".
/// Returns a null string if it succeeds, or an error message otherwise.
/// The last two arguments, pAlias and pClass, are only used if the Business Process has an associated rule,
/// in which case they identify the alias (if any) and class name to use for the rule.
Method OnWizardCompletion(pProdId As %String, pForm As %String, pType As %String, pRuleAlias As %String, pRuleClass As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tmsg = ""

	Try {
		Set production = ##class(Ens.Config.Production).%OpenId(pProdId)
		If $IsObject($G(production)) { // Add the new host to the Production
			If pForm="formProcessOTHER" {
				Try {
					#;If not enabled then pool size of 1 otherwise leave as entered
					Set tPoolSize = +%page.%GetValueById("ProcessOTHERPool") ;
					If 'tPoolSize && '%page.%GetValueById("ProcessOTHEREnabled") Set tPoolSize=1
				} Catch {}
				Set tSC = ..AddNewItem(pForm, "ProcessOTHER", production, .item, tPoolSize)
				If $$$ISOK(tSC) {
					If ""'=pRuleClass { // this is a business process that is a routing process, so it needs a rule
						Set tSC = ..SubmitRoutingRule("OTHER",,,item,pRuleAlias,pRuleClass,%page.%GetValueById("ProcessOTHERRuleValidation"),%page.%GetValueById("ProcessOTHERRuleNoValidation"))
						If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
					}
				}
				Else {
					Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			ElseIf pForm="formProcessHL7" {
				Set tSC = ..AddNewItem(pForm, "ProcessHL7", production, .item, 1)
				If $$$ISOK(tSC) {
					Set tSC = ..SubmitRoutingRule("HL7",,,item,pRuleAlias,pRuleClass,%page.%GetValueById("ProcessHL7RuleValidation"),%page.%GetValueById("ProcessHL7RuleNoValidation"))
					If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
				}
				Else {
					Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			ElseIf pForm="formProcessX12" { // X12 Output
				Set tSC = ..AddNewItem(pForm, "ProcessX12", production, .item, 1)
				If $$$ISOK(tSC) {
					Set tSC = ..SubmitRoutingRule("X12",,,item,pRuleAlias,pRuleClass,%page.%GetValueById("ProcessX12RuleValidation"),%page.%GetValueById("ProcessX12RuleNoValidation"))
					If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
				}
			}
			ElseIf pForm="formProcessCOMPONENT" { // Component
				Try {
					#;If not enabled then pool size of 1 otherwise leave as entered
					Set tPoolSize = +%page.%GetValueById("ProcessCOMPONENTPool") ;
					If 'tPoolSize && '%page.%GetValueById("ProcessCOMPONENTEnabled") Set tPoolSize=1
				} Catch {}
				Set tSC = ..AddNewItem(pForm, "ProcessCOMPONENT", production, .item, tPoolSize)
				If $$$ISERR(tSC) Set tmsg = $system.Status.GetErrorText(tSC)
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
	Set sel = ..%GetComponentById("ProcessOTHERCategory")
	Set sel.context = sel.context _ "?productionName=" _ ..ProductionName
	Set sel = ..%GetComponentById("ProcessOTHERRulePackage")
	Set sel.value = ..DefaultRulePackage()

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("HL7") {
		Set sel = ..%GetComponentById("ProcessHL7Category")
		Set sel.context = sel.context _ "?productionName=" _ ..ProductionName
		Set sel = ..%GetComponentById("ProcessHL7RulePackage")
		Set sel.value = ..DefaultRulePackage()
	} Else {
		Set sel = ..%GetComponentById("groupProcess")
		For tTab=1:1:sel.children.Count(){
			If sel.children.GetAt(tTab).id = "tabHL7Router" {Do sel.children.RemoveAt(tTab)  Quit}
		}
	}

	If ##class(%Library.InteroperabilityMgr).IsPackageInstalled("X12") {
		Set sel = ..%GetComponentById("ProcessX12Category")
		Set sel.context = sel.context _ "?productionName=" _ ..ProductionName
		Set sel = ..%GetComponentById("ProcessX12RulePackage")
		Set sel.value = ..DefaultRulePackage()
	} Else {
		Set sel = ..%GetComponentById("groupProcess")
		For tTab=1:1:sel.children.Count(){
			If sel.children.GetAt(tTab).id = "tabX12Router" {Do sel.children.RemoveAt(tTab)  Quit}
		}
	}

	Set sel = ..%GetComponentById("ProcessCOMPONENTCategory")
	Set sel.context = sel.context _ "?productionName=" _ ..ProductionName

	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Business Process Wizard","Ensemble")
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
	Quit $$$TextHTML("Add a new Business Process to this Production.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return this.retValue;
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the action is canceled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	var tabs = zen('groupProcess');
	if (tabs) {
		currentTab = tabs.getCurrTabNo();
	}
	var currentTabCaption = tabs.children[currentTab-1].caption;

	var aliasName = '';
	var className = '';
	var formName, hostType, ruleName, msgToConfirm;

	switch (currentTabCaption) {
		case $$$Text('All Processes'):
			formName = 'formProcessOTHER';
			hostType = 'OTHER';
			ruleName = zenPage.calculateRuleName('OTHER');
			if (isNaN(zen('Process'+hostType+'Pool').getValue())) {
				alert($$$Text('Pool Size should have a numerical value'));
				return false;
			}
			break;
		case $$$Text('HL7 Router'):
			formName = 'formProcessHL7';
			hostType = 'HL7';
			ruleName = zenPage.calculateRuleName('HL7');
			break;
		case $$$Text('X12 Router'):
			formName = 'formProcessX12';
			hostType = 'X12';
			ruleName = zenPage.calculateRuleName('X12');
			break;
		case $$$Text('Component'):
			formName = 'formProcessCOMPONENT';
			hostType = 'COMPONENT';
			ruleName = '';
			if (isNaN(zen('Process'+hostType+'Pool').getValue())) {
				alert($$$Text('Pool Size should have a numerical value'));
				return false;
			}
			break;
		default:
			return false;
			break;
	}
	if (ruleName.split('\n')[0] == zenText('msgHostErrorsStart')) {
		alert(ruleName);
		return false;
	}
	// Generate a router name from the rule name, if router name is empty
	var nameCtl = zen('Process'+hostType+'Name');
	if ((ruleName != '') && (nameCtl.getValue() == '')) {
		nameCtl.setValue(ruleName + '_Router');
		if (!confirm($$$FormatText($$$Text('You specified a rule name but no router name. Do you want to create a router process named %1 ?'), ruleName + '_Router'))) {
			nameCtl.setValue(''); // re-clear it
			return false;
		}
	}
	try {
		var isValid = zenPage.validateAll('Process', hostType);
		if (isValid) {
			if ( (hostType == 'HL7')
			  || (hostType == 'X12')
			  || ((hostType == 'OTHER') && (ruleName.length > 0)) ) {

				// See if the provided name (ruleName) is okay to use as a rule class name
				var autoPackage = '';
				if (zenPage.isChecked) {
					var autoPackageCtl = zen("Process"+hostType+"RulePackage");
					if (autoPackageCtl) autoPackage = autoPackageCtl.getValue();
				}
				names = zenPage.DeriveRuleNames(zenPage.ProductionName, ruleName, autoPackage);
				var name = names.split(',') // flag [0] alias name [1] class name [2] rule exists flag [3]
				aliasName = name[1];
				className = name[2];

				// Provide messages relating to rule class names
				var ok = true;
				if (name[3] == '-') { // rule already exists
					if (zenPage.isChecked) { // user checked auto-create rule
						msgToConfirm = $$$FormatText($$$Text('According to IRIS naming conventions, the rule class for your routing process already exists: %1.'),className);
						msgToConfirm += (' ' + $$$Text('A new rule class will not be automatically created, but your new router will be configured with this rule.'));
						msgToConfirm += (' ' + $$$Text('You may change this configuration later.'));
						ok = confirm(msgToConfirm);
					}
				} else { // we are creating the rule
					if (aliasName.length > 0) { // had to construct a class name, so will use the provided field value as an alias
						if (zenPage.isChecked) {
							msgToConfirm = $$$FormatText($$$Text('Due to restrictions on rule class names, the rule class for your routing process will be called %1 and it will have the alias %2.'),className,aliasName);
							msgToConfirm += (' ' + $$$Text('If this is acceptable, click OK. If you wish to rename your rule, click Cancel and edit the Process Name field.'));
							ok = confirm(msgToConfirm);
						} else {
							msgToConfirm = $$$FormatText($$$Text('Due to restrictions on rule class names, the rule class for your routing process will be called %1 and it will have the alias %2.'),className,aliasName);
							msgToConfirm += (' ' + $$$Text('If this is acceptable, click OK. If you wish to rename your rule, click Cancel and edit the Rule Name field.'));
							ok = confirm(msgToConfirm);
						}
					} else {
						if (name[0] == '+') { // had to prepend a package name to the provided field value
							if (zenPage.isChecked) {
								msgToConfirm = $$$FormatText($$$Text('A rule class named %1 will be created.'),className);
								msgToConfirm += (' ' + $$$Text('If this is acceptable, click OK. If you wish to provide a different name for your rule, click Cancel and edit the Process Name field.'));
								ok = confirm(msgToConfirm);
							} else {
								msgToConfirm = $$$FormatText($$$Text('A rule class named %1 will be created.'),className);
								msgToConfirm += (' ' + $$$Text('If this is acceptable, click OK. If you wish to provide a different name for your rule, click Cancel and edit the Rule Name field.'));
								ok = confirm(msgToConfirm);
							}
						}
					}
				}
				if (!ok) {
					return false;
				}
			}
			/*
				Look to see if for fromProcessOTHER if ProcessOTHEREnabled is true or false.
				Also look to see if formProcessCOMPONENT if ProcessCOMPONENTEnabled is true or false.
				Advise that pool size will be set to 1 if not enabled and Pool Size of 0 specified.
			*/
			if ((hostType == 'OTHER')||(hostType == 'COMPONENT')) {
				if ((zen('Process'+hostType+'Pool').getValue()==0) && !zen('Process'+hostType+'Enabled').getValue() ) {
					var msgPoolDisable1 = $$$Text("'Enabled Now' is not checked and Pool Sized of 0 is specified.");
					var msgPoolDisable2 = $$$Text("To prevent disabling the general actor pool the new item will be created with a 'PoolSize' = 1.");
					var msgPoolDisable3 = $$$Text("(If 'Enabled Now' were to be checked 'PoolSize' can be set to 0)");
					var msgPoolDisable4 = $$$Text("Would you like to continue?");
					if (!confirm(msgPoolDisable1 + "\n" + msgPoolDisable2 + "\n" + msgPoolDisable3 + "\n\n" + msgPoolDisable4)) return false;
				}
			}
			var msg = zenPage.OnWizardCompletion(zenPage.ProductionName, formName, hostType, aliasName, className);
			if (msg != '') {
				isValid = false;
				alert(msg);
			}
		}
	} catch(ex) {
		zenExceptionHandler(ex,arguments);
		isValid = false;
	}

	if (isValid) {
		this.retValue = 1;
		return true;
	} else {
		this.retValue = 0;
		return false;
	}
}

ClientMethod calculateRuleName(hostType) As %String [ Language = javascript ]
{
	var msg = '', errmsg = '';
	var name, rule;

	switch(hostType) {
		case 'OTHER':
			var cls = zen('ProcessOTHERClassName').getValue();
			zenPage.isRouter = zenPage.IsRouterClass(cls);
			break;
		case 'HL7': // fall-through
		case 'X12':
			zenPage.isRouter = true;
			break;
		case 'COMPONENT':
			zenPage.isRouter = false;
			break;
	}
	if (zenPage.isRouter) {
		zenPage.isChecked = zen('Process'+hostType+'AutoRule').getValue();
		if (zenPage.isChecked) { // auto-create a routing rule and give it a name
			name = zen('Process'+hostType+'Name').getValue();
			if (name.length > 0) {
				/*	Do not append 'RoutingRule' to the auto generated rule name 
					if the BP name does not include a . (ie contains a perceived package) 
					and the user supplied a package name that is not the same as the production
					name (ie they could have left package blank.
				*/
				var addToEndOfName = true;
				// always add to end if include a period
				if (name.indexOf(".")<0) {
					var autoPackage = '';
					var autoPackageCtl = zen("Process"+hostType+"RulePackage");
					if (autoPackageCtl) {
						autoPackage = autoPackageCtl.getValue();
						if (autoPackage!="") {
							autoPackage += "."
							var packagePos = (zenPage.ProductionName.indexOf(autoPackage))
							if (packagePos!=0) {
								addToEndOfName = false;
							} else {
								//If no more periods then we are using the production default
								if (zenPage.ProductionName.indexOf(".",autoPackage.length)>-1) {
									addToEndOfName = false;
								}
							}
						}
					}
				}
				// good rule name - create a routing rule if identified
				if (addToEndOfName) {
					msg = name + 'RoutingRule'; 
				} else {
					msg = name;
				}
			} else {
				errmsg = zenText('msgHostErrorsStart')
				msg = errmsg + '\n' + zenText('msgHostName'); // kick it back
			}
		} else { //
			// Check rule name
			rule = zen('Process'+hostType+'RuleName').getValue();
			if (rule.length > 0) { // good rule name
				msg = rule; // good process name and good rule name
			} else { // bad rule name
				errmsg = zenText('msgHostErrorsStart')
				msg = errmsg + '\n' + zenText('msgHostRule'); // kick it back
			}
		}
	}
	if (errmsg != '') {
		msg += ('\n' + zenText('msgHostErrorsEnd') + ' ' + zenText('msgHostFixSave') + '\n');
	}
	return msg;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

ClassMethod RouterHasValidationSetting(pClass As %String) As %Boolean [ ZenMethod ]
{
	#dim ret = 0
	If pClass'="" {
		Try {
			#; Only interested in if has Validation and not default from EvalInitialExpression("Validation")
			#dim tSettings
			Do $classmethod(pClass,"GetSettings",.tSettings)
			#; Is the Validation setting exposed
			If $Data(tSettings(":","Validation"))#2 && ('$Data(tSettings(":","-Validation"))#2) {
				Set ret = 1
			}
		}
		Catch {
		}
	}
	Quit ret
}

ClientMethod changeRuleValidation(type) [ Language = javascript ]
{
	var noValCtl = zen(type+"RuleNoValidation");
	if (noValCtl) {
		var noVal = noValCtl.getValue();
		var valCtrl = zen(type+"RuleValidation");
		if (valCtrl) {
			valCtrl.setProperty('readOnly', noVal);
			if (noVal) valCtrl.setValue('');
		}
	}
}

}
