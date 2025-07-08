Class Demo.JMS.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Demo.JMS.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
<Description></Description>
<ActorPoolSize>2</ActorPoolSize>
<Item Name="JavaGatewayManager" Category="" ClassName="EnsLib.JavaGateway.Service" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
<Setting Target="Host" Name="Port">33333</Setting>
<Setting Target="Host" Name="ClassPath">../../dev/java/lib/JDK18/cache-enslib-jms-2.0.0.jar;../../dev/java/lib/jms/wljmsclient.jar;../../dev/java/lib/jms/wlthint3client.jar</Setting>
</Item>
<Item Name="TestingService" Category="" ClassName="EnsLib.Testing.Service" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
</Item>
<Item Name="Demo.JMS.Operation" Category="" ClassName="Demo.JMS.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
<Setting Target="Adapter" Name="JavaGatewayPort">33333</Setting>
<Setting Target="Adapter" Name="JMSServer">t3://va-ins-vdif1:7003</Setting>
<Setting Target="Adapter" Name="JMSFactory">esr.jms.connectionFactory.InboundConnFactory</Setting>
<Setting Target="Adapter" Name="JMSQueue">Edb.jms.queue.DistributedInboundQueryQueue</Setting>
<Setting Target="Adapter" Name="JMSCredentials">WebLogic</Setting>
<Setting Target="Adapter" Name="JMSLogFileName">JMS_Demo_Operation.log</Setting>
<Setting Target="Host" Name="ReplyCodeActions">E=R</Setting>
</Item>
<Item Name="Demo.HL7.FileService" Category="" ClassName="EnsLib.HL7.Service.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
<Setting Target="Adapter" Name="FilePath">../../Data/JMS/HL7In</Setting>
<Setting Target="Adapter" Name="FileSpec">*.*</Setting>
<Setting Target="Host" Name="MessageSchemaCategory">2.7.1</Setting>
<Setting Target="Host" Name="TargetConfigNames">Demo.JMS.RoutingRule</Setting>
</Item>
<Item Name="Demo.JMS.RoutingRule" Category="" ClassName="EnsLib.HL7.MsgRouter.RoutingEngine" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
<Setting Target="Host" Name="Validation"></Setting>
<Setting Target="Host" Name="BusinessRuleName">Demo.JMS.RoutingRule</Setting>
</Item>
<Item Name="EnsLib.JMS.Operation" Category="" ClassName="EnsLib.JMS.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
<Setting Target="Adapter" Name="JavaGatewayPort">33333</Setting>
<Setting Target="Adapter" Name="JMSServer">t3://va-ins-vdif1:7003</Setting>
<Setting Target="Adapter" Name="JMSFactory">esr.jms.connectionFactory.InboundConnFactory</Setting>
<Setting Target="Adapter" Name="JMSQueue">Edb.jms.queue.DistributedInboundQueryQueue</Setting>
<Setting Target="Adapter" Name="JMSCredentials">WebLogic</Setting>
<Setting Target="Adapter" Name="JMSLogFileName">JMS_EnsLib_Operation.log</Setting>
</Item>
<Item Name="EnsLib.JMS.Service" Category="" ClassName="EnsLib.JMS.Service" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
<Setting Target="Adapter" Name="JavaGatewayPort">33333</Setting>
<Setting Target="Adapter" Name="JMSServer">t3://va-ins-vdif1:7003</Setting>
<Setting Target="Adapter" Name="JMSFactory">esr.jms.connectionFactory.InboundConnFactory</Setting>
<Setting Target="Adapter" Name="JMSQueue">Edb.jms.queue.DistributedInboundQueryQueue</Setting>
<Setting Target="Adapter" Name="JMSCredentials">WebLogic</Setting>
<Setting Target="Adapter" Name="JMSLogFileName">JMS_EnsLib_Service.log</Setting>
<Setting Target="Host" Name="TargetConfigNames">Demo.JMS.Process</Setting>
</Item>
<Item Name="Demo.JMS.Process" Category="" ClassName="Demo.JMS.Process" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
</Item>
</Production>
}

}
