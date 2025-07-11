/// CSV Processing Production for CSV to XML Conversion
/// This production processes CSV files containing person data and converts them to XML
Class CSV.ProcessingProduction Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="CSV.ProcessingProduction" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>CSV to XML Processing Production</Description>
  <ActorPoolSize>1</ActorPoolSize>
  
  <Item Name="CSV.FileService" Category="CSV Processing" ClassName="CSV.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="Reads CSV files and converts to PersonRecord messages" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/in</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.csv</Setting>
    <Setting Target="Adapter" Name="ArchivePath"></Setting>
    <Setting Target="Host" Name="TargetConfigNames">CSV.XMLFileOperation</Setting>
    <Setting Target="Host" Name="SessionScope">Message</Setting>
  </Item>
  
  <Item Name="CSV.XMLFileOperation" Category="CSV Processing" ClassName="CSV.XMLFileOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="Converts PersonRecord messages to XML files" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/home/irisowner/dev/shared/out</Setting>
  </Item>
  
</Production>
}

}
