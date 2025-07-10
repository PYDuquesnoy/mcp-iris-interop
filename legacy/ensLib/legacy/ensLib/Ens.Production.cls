/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator Ensemble

Class Ens.Production Extends (%RegisteredObject, Ens.Settings) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Amount of time to wait for a click on Stop Production to succeed
Property ShutdownTimeout As %Numeric(MAXVAL = 3600, MINVAL = 0) [ InitialExpression = 120 ];

/// Amount of time to wait for Production updates to succeed <br>
/// This means both clicking UpdateProduction and clicking Apply for changes to a configuration item in a running production.
Property UpdateTimeout As %Numeric(MAXVAL = 3600, MINVAL = 0) [ InitialExpression = 10 ];

/// The default Alert Notification Manager for use by the Managed Alert framework.
Property AlertNotificationManager As Ens.DataType.ConfigName;

/// The default Alert Notification Operation for use by the Managed Alert framework.
/// The Notification Manager can be configured to send notifications to other hosts within the production,
/// but this setting provides a fallback for situations which are not captured by the logic in the Notification Manager.
Property AlertNotificationOperation As Ens.DataType.ConfigName;

/// A comma-separated list of recipients that should be used for alert notifications
/// when no other recipients have been specified by the notification framework.
Property AlertNotificationRecipients As %Library.String(MAXLEN = 2048);

/// The default number of minutes within which a Managed Alert should be acted upon.
Property AlertActionWindow As %Library.Integer [ InitialExpression = {##class(Ens.Alerting.Utils).#DEFAULTACTIONWINDOW} ];

Parameter SETTINGS = "ShutdownTimeout,UpdateTimeout,AlertNotificationManager:Alerting,AlertNotificationOperation:Alerting,AlertNotificationRecipients:Alerting,AlertActionWindow:Alerting";

Projection Production As Ens.Projection.Production;

ClassMethod Start() As %Status
{
	Quit ##class(Ens.Director).StartProduction($classname())
}

ClassMethod Update(pTimeout As %Numeric, pForce As %Boolean) As %Status
{
	Quit ##class(Ens.Director).UpdateProduction(.pTimeout,.pForce)
}

ClassMethod Stop(pTimeout As %Numeric, pForce As %Boolean) As %Status
{
	Quit ##class(Ens.Director).StopProduction(.pTimeout,.pForce)
}

/// Override this in your Production class to do setup before the Production starts
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
	Quit $$$OK
}

/// Override this in your Production class to do cleanup after the Production stops
ClassMethod OnStop(pTimeStarted As %String, pForced As %Boolean)
{
	Quit
}

/// Deprecated
ClassMethod Register() As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tSC=##class(Ens.Config.Production).LoadFromClass($classname())
		Do:$$$ISERR(tSC) $system.OBJ.DisplayError(tSC)
	} while (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod TestStart() As %Status
{
	Set tSC = ##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)
	If $$$ISERR(tSC) {
		$$$LOGSTATUS(tSC)
		Quit tSC
	}
	If tState=$$$eProductionStateRunning {
		if tProductionName '= $$$CurrentClass {
			w !,"Stop production "_tProductionName_"? [No] "  Read tInput,!  Quit:$Case($ZCVT(tInput,"L"),"yes":0,"y":0,:1) $$$ERROR($$$EnsErrGeneral,"Not stopping Production "_tProductionName)
			w "Stopping production ",tProductionName,!
			Set tSC = ..Stop() Quit:$$$ISERR(tSC) tSC
			Set tState=0
		}
		else { w !,"Already running "_$$$CurrentClass,! }
	}
	If tState'=$$$eProductionStateRunning {
		Set tSC = ..Start()
	}
	Quit tSC
}

ClassMethod GetSettingValue(pName As %String, Output pStatus As %Status) As %String [ CodeMode = expression ]
{
##class(Ens.Director).GetProductionSettingValue("",.pName,.pStatus)
}

ClassMethod GetSettingsArray(Output pSettings) As %Status [ CodeMode = expression ]
{
##class(Ens.Director).GetProductionSettings("",.pSettings)
}

/// Apply multiple settings to a production
/// <var>pProductionName</var> is the name of the Production to which to apply the settings <br/>
/// <var>pSettings</var> is a local array of settings structured in the following way: <br/>
///    pSettings(&lt;itemName&gt;,&lt;target&gt;,&lt;settingName&gt;)=&lt;settingValue&gt; <br/>
/// Where:  <br/>
///    &lt;itemName&gt; is the configuration item name in the production  <br/>
///     &lt;target&gt; Is one of:  <br/>
///         Item: Means the setting is a property of the item itself, such as PoolSize  <br/>
///         Host: Sets a host setting  <br/>
///         Adapter: Sets an adapter setting  <br/>
///     &lt;settingName&gt; is the setting name  <br/>
///     &lt;settingValue&gt; is the desired value of the setting. <br/>
ClassMethod ApplySettings(pProductionName As %String, ByRef pSettings) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tState As %Integer
		#dim tRunningProduction As %String
		#dim tProduction As Ens.Config.Production
		#dim tItem,tTarget,tSetting
		
		// Grab the state of the production
		Set tSC = ##class(Ens.Director).GetProductionStatus(.tRunningProduction,.tState)
		If $$$ISERR(tSC) {
			$$$LOGSTATUS(tSC)
			Quit
		}
		
		// Open the production up
		Set tProduction = ##class(Ens.Config.Production).%OpenId(pProductionName,,.tSC) Quit:$$$ISERR(tSC)
		
		// Walk the bag of settings
		Set tItem = ""
		While ($$$ISOK(tSC)) {
			Set tItem = $ORDER(pSettings(tItem))
			Quit:tItem=""
			
			#dim tItemObj As Ens.Config.Item

			// We want to force swizzle of items if the production is running so all items are modified
			Set tItemObj = tProduction.FindItemByConfigName(tItem, .tSC, 1)
			If '$IsObject(tItemObj) {
				Set tSC=$$$ERROR($$$EnsErrProductionSettingInvalid,pProductionName,tItem)
				Quit
			}
			// If tItemObj is an object but tSC is an error we will now quit
			If $$$ISERR(tSC) Quit

			// Now, for each item, we must see what we're applying it to
			Set tTarget = ""
			While ($$$ISOK(tSC)) {
				Set tTarget = $ORDER(pSettings(tItem,tTarget))
				Quit:tTarget=""

				// And what actual setting this is ...
				Set tSetting = ""
				While ($$$ISOK(tSC)) {
					Set tSetting = $ORDER(pSettings(tItem,tTarget,tSetting))
					Quit:tSetting=""
				
					If tTarget="Item" {
						// If the target is an item, then we're setting a property *on* the config item
						If $$$comMemberDefined("Ens.Config.Item",$$$cCLASSproperty,tSetting) {
							Set $ZOBJPROPERTY(tItemObj,tSetting) = pSettings(tItem,tTarget,tSetting)
						} Else {
							// No such property, report an error
							Set tSC=$$$ERROR($$$PropertyDoesNotExist,tSetting)
							Quit
						}
					} Else {
						// Apply the setting
						#dim tSettingObj As Ens.Config.Setting
						Set tSettingObj = tItemObj.FindSettingByName(tSetting,tTarget)
						If '$IsObject(tSettingObj) {
							// This is a new setting
							Set tSettingObj = ##class(Ens.Config.Setting).%New()
							Set tSettingObj.Name = tSetting
							Do tItemObj.Settings.Insert(tSettingObj)
						}
						
						// We can finally set the setting
						Set tSettingObj.Target = tTarget
						Set tSettingObj.Value = pSettings(tItem,tTarget,tSetting)
					}
				}
			}
		}
		// If we errored, bail out
		Quit:$$$ISERR(tSC)
				
		// Save the changes we made to the production
		Set tSC = tProduction.%Save(1)
		Quit:$$$ISERR(tSC)

		// Regenerate the XData in the corresponding class
		Set tSC = tProduction.SaveToClass()
		Quit:$$$ISERR(tSC)

		// Finally, does the production need updating?
		If (tRunningProduction=pProductionName)&&(tState=$$$eProductionStateRunning) {
			// Update the running production with the new settings
			Set tSC = ##class(Ens.Director).UpdateProduction(##class(Ens.Director).GetRunningProductionUpdateTimeout())
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This method is called when config changes to the Production or any item are saved from the portal
ClassMethod OnConfigChange(pProduction As Ens.Config.Production, pItem As Ens.Config.Item)
{
}

}
