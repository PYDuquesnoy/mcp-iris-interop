/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract MsgBank Production superclass. Create a concrete subclass of this Production in the namespace where you will run your MsgBank.
Class Ens.Enterprise.MsgBank.Production Extends Ens.Enterprise.Production [ Abstract, System = 4 ]
{

XData ProductionDefinition
{
<Production Name="Ens.Enterprise.MsgBank.Production" TestingEnabled="false" LogGeneralTraceEvents="false">
  <Description>Production for receiving and collating message bank submissions from one or more client IRIS namespaces 
  and for maintaining a local repository of production status information about each client namespace, for display on the Enterprise Monitor page.
   Open the the Monitor page on the same machine that that is hosting this Production.</Description>
  <ActorPoolSize>0</ActorPoolSize>
  <Setting Target="Production" Name="ShutdownTimeout">120</Setting>
  <Setting Target="Production" Name="UpdateTimeout">10</Setting>
  <Item Name="MonitorService" Category="" ClassName="Ens.Enterprise.MonitorService" PoolSize="1" Enabled="true" Foreground="false" InactivityTimeout="0" Comment="Populates global ^IRIS.Temp.Ens.EntMonitorStatus by polling namespaces from Systems List every CallInterval seconds" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="AlertGracePeriod">0</Setting>
    <Setting Target="Host" Name="AlertOnError">0</Setting>
    <Setting Target="Host" Name="ArchiveIO">0</Setting>
    <Setting Target="Adapter" Name="CallInterval">10</Setting>
  </Item>
  <Item Name="MsgBankService" Category="" ClassName="Ens.Enterprise.MsgBank.TCPService" PoolSize="100" Enabled="true" Foreground="false" InactivityTimeout="0" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="AlertGracePeriod">0</Setting>
    <Setting Target="Host" Name="AlertOnError">0</Setting>
    <Setting Target="Host" Name="ArchiveIO">0</Setting>
    <Setting Target="Adapter" Name="Endian">Big</Setting>
    <Setting Target="Adapter" Name="UseFileStream">0</Setting>
    <Setting Target="Adapter" Name="JobPerConnection">1</Setting>
    <Setting Target="Adapter" Name="AllowedIPAddresses"></Setting>
    <Setting Target="Adapter" Name="QSize">100</Setting>
    <Setting Target="Adapter" Name="CallInterval">5</Setting>
    <Setting Target="Adapter" Name="Port">9192</Setting>
    <Setting Target="Adapter" Name="StayConnected">-1</Setting>
    <Setting Target="Adapter" Name="ReadTimeout">10</Setting>
    <Setting Target="Adapter" Name="SSLConfig"></Setting>
  </Item>
</Production>
}

}
