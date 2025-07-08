/// 
Class Demo.JMS.RoutingRule Extends Ens.Rule.Definition
{

Parameter RuleAssistClass = "EnsLib.HL7.MsgRouter.RuleAssist";

XData RuleDefinition [ XMLNamespace = "http://www.intersystems.com/rule" ]
{
<ruleDefinition alias="Demo.JMS.RoutingRule" context="EnsLib.HL7.MsgRouter.RoutingEngine" production="Demo.JMS.Production">
<ruleSet name="Demo RuleSet" effectiveBegin="" effectiveEnd="">
<rule name="Demo Rule">
<when condition="1">
<send transform="Demo.JMS.HL7toJMS" target="EnsLib.JMS.Operation"></send>
<return></return>
</when>
</rule>
</ruleSet>
</ruleDefinition>
}

}
