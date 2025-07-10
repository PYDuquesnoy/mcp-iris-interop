/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.DeepSee.ActivityVolumeAndDurationDashboard Extends %DeepSee.UserLibrary.Container [ DependsOn = Ens.DeepSee.ActivityVolumeAndDurationKPI, System = 4 ]
{

XData Contents [ XMLNamespace = "http://www.intersystems.com/deepsee/library" ]
{
<items>
<dashboard xmlns="http://www.intersystems.com/deepsee/library" name="ActivityVolumeAndDuration" folderName="Ens/Analytics" title="Activity Volume And Duration" description="" keywords="" owner="" shared="true" public="true" locked="false" resource="" timeCreated="2014-07-16T22:37:16.228Z" createdBy="" category="" bookCover="" scheme="" worklistCount="2" snapTo="true" snapGrid="true" gridRows="10" gridCols="10" canResize="true" canModify="true" showTitleBar="false" companyName="" companyLogo="" companyStyle="" backgroundColor="" backgroundImage="" backgroundRepeat="" backgroundSize="" backgroundOpacity="">
  <widget name="Widget1" type="scoreCardWidget" subtype="regular" subtypeClass="" title="" dataSource="Ens/DeepSee/ActivityVolumeAndDurationKPI.kpi" dataLink="" drillDownDataSource="" width="200" height="200" sidebarContent="" showSidebar="false" sidebarWidth="" maximized="true" homeRowL="0" homeColL="0" colSpanL="7" rowSpanL="9" showToolbar="true" theme="" dataColorList="">
    <control name="" action="applyFilter" target="" targetProperty="Period" location="widget" type="dropdown" controlClass="" label="Period of Time" title="" value="Minute" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>
    <control name="" action="applyFilter" target="" targetProperty="Instance" location="widget" type="dropdown" controlClass="" label="Instance" title="" value="" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>
    <control name="" action="applyFilter" target="" targetProperty="Namespace" location="widget" type="dropdown" controlClass="" label="Namespace" title="" value="" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>
    <control name="" action="applyFilter" target="" targetProperty="SiteDimension" location="widget" type="dropdown" controlClass="" label="Site Dimension" title="" value="" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>
    <control name="" action="applyFilter" target="" targetProperty="SortBy" location="widget" type="dropdown" controlClass="" label="Sort by" title="" value="Name" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>    
    <!--<control name="" action="refresh" target="" targetProperty="" location="widget" type="timer" controlClass="" timeout="60" label="" title="" value="" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>-->
    <control name="" action="refresh" target="" targetProperty="" location="widget" type="button" controlClass="" label="Refresh" title="Refresh results" value="" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>
    <control name="" action="reloadDashboard" target="" targetProperty="" location="widget" type="auto" controlClass="" label="Reset" title="Reload dashboard with initial filter selections" value="" text="" readOnly="false" valueList="" displayList="" activeWhen=""></control>
    <override name="scoreCard">{width:1069,selectedSeries:-1,columns:[
    {display:'itemNo',width:'30',_type:'scoreCardColumn'},
    {align:'left',dataValue:'Name',display:'value',headerAlign:'left',label:'Name',_type:'scoreCardColumn'},
    {align:'left',dataValue:'Site Dimension',display:'value',headerAlign:'left',label:'Site Dimension',_type:'scoreCardColumn'},
    {align:'right',dataValue:'Total Count',headerAlign:'right',label:'Total Count',_type:'scoreCardColumn'},
    {align:'left',dataValue:'Count Trend',display:'trendBars',headerAlign:'left',label:'Count Trend',showAs:'value',style:'fill:rgb(63,119,7);',_type:'scoreCardColumn'},
    {align:'right',dataValue:'Avg. Duration',format:'#.###',headerAlign:'right',label:'Avg. Duration',_type:'scoreCardColumn'},
    {dataValue:'Std. Deviation',display:'value',format:'#.###',label:'Std. Deviation',_type:'scoreCardColumn'},
    {align:'left',dataValue:'Duration Trend',display:'trendLine',headerAlign:'left',label:'Duration Trend',showAs:'value',_type:'scoreCardColumn'},
    {align:'right',dataValue:'Avg. Queue Time',display:'value',format:'#.###',headerAlign:'right',label:'Avg. Queue Time',_type:'scoreCardColumn'},
    {dataValue:'Queue Trend',display:'trendLine',label:'Queue Trend',style:'stroke:rgb(0,75,152);',_type:'scoreCardColumn'}
     ],rowHeight:25,_type:'scoreCard'}</override>
  </widget>
</dashboard>
</items>
}

}
