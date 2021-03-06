Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue

function CreateSite
{
	param ([string]$title, [string]$url)
	$site = Get-SPSite -WebApplication "http://sp2013win2012r2/" | Where-Object {$_.Url -eq $url} 
	if($site -ne $null)
	{
		# Write-Host "Deleting site at $($url)"
		# Remove-SPSite $url -Confirm:$false
		return $site
	}
	Write-Host  "Creating $($title) at $($url)"
    return New-SPSite -Url $url -Name $title -Template "STS#0" -OwnerAlias "MULAWA\administrator" -SecondaryOwnerAlias "MULAWA\mulawam"
}

function CreateWeb
{
	param ([string]$url, [string]$webRelativeUrl )
	$site = Get-SPSite -WebApplication "http://sp2013win2012r2/" | Where-Object {$_.Url -eq $url} 
	if($site -ne $null)
	{
		$web = $site.OpenWeb($webRelativeUrl, $true)
		if( $web.Exists -eq $true)
		{
		 	return $web
		}
	
		$web = $site.RootWeb.Webs.Add($webRelativeUrl)
		Write-Host  "Creating subsite at $($webRelativeUrl)"
		return $web;
	}
	
    
}

function CreateEventObj{
	param([string] $title, [string] $description, [datetime]$eventDate)
	$event = @{}
	$event.Title = $title;
	$event.Description = $description;
	$event.EventDate = $eventDate;
	return $event;
}

function CreateEventListItem{
 	param([Object]$eventList, [Object]$event)
	
	$eventListItem = $eventList.AddItem();
	$eventListItem["Title"] = $event.Title;
	$eventListItem["EventDescription"] = $event.Description;
	$eventListItem["EventDate"] = $event.EventDate;
	$eventListItem.Update()
}

function CreateEventsFromArray {
 		param([Object] $site, [Object] $events)
	$eventsList =  $site.RootWeb.Lists.TryGetList("Boxing Events");
	foreach($event in $events)
	{
		CreateEventListItem $eventsList $event
	}
}

function EnableWebEventFeaure{
	param([string] $featureId, [Object] $site)
	$featureActivated = Get-SPFeature -Web $site.RootWeb | where {$_.Id -eq $featureId}
	if(!$featureActivated)
	{
		Enable-SPFeature -Identity $featureId -Url $site.Url		
	}
}


function EnableSiteCatalogFeature{
	param([string] $featureId, [Object] $site)
	$featureActivated = Get-SPFeature -Site $site.Url | where {$_.Id -eq $featureId}
	if(!$featureActivated)
	{
		Enable-SPFeature -Identity $featureId -Url $site.Url 		
	}
}



function EnableDeveloperDashboard()
{
	$settings = [Microsoft.SharePoint.Administration.SPWebService]::ContentService.DeveloperDashboardSettings;
	$settings.DisplayLevel = "On";
	$settings.Update();
}


$catalogSiteUrl = "http://sp2013win2012r2/sites/home";
$amateurBoxingSiteUrl = "http://sp2013win2012r2/sites/amateur";
$proBoxingSiteUrl = "http://sp2013win2012r2/sites/pro";
$catalogSite = CreateSite "Boxing Catalog" $catalogSiteUrl
#$amateurSite = CreateSite "Amateur Boxing" $amateurBoxingSiteUrl;
#$proSite = CreateSite "Professional Boxing" $proBoxingSiteUrl;

#EnableWebEventFeaure "68e6f780-5761-46cc-b028-7d920f0351fa" $amateurSite
#EnableWebEventFeaure "68e6f780-5761-46cc-b028-7d920f0351fa" $proSite
# EnableSiteCatalogFeature "f9dfb2aa-e5f6-45f1-b8fe-44baea94fcfc", $catalogSite

# Enable-SPFeature -Identity "68e6f780-5761-46cc-b028-7d920f0351fa" -Url $amateurBoxingSiteUrl
# Enable-SPFeature -Identity "68e6f780-5761-46cc-b028-7d920f0351fa" -Url $proBoxingSiteUrl
# Enable-SPFeature -Identity "f9dfb2aa-e5f6-45f1-b8fe-44baea94fcfc" -Url $catalogSiteUrl

$proEvents = @();
$proEvents += CreateEventObj "Max Schmeling vs Joe Louis, The Fight of the Decade" "For NYSAC, NBA & World Heavyweight titles." "1938-06-22";
$proEvents += CreateEventObj "Ali vs Joe Frazier, The Fight of the Century" "The Ring, WBA & WBC World Heavyweight titles." "1971-03-08";
$proEvents += CreateEventObj "Floyd Mayweather, Jr. vs Manny Pacquiao" "For WBA (Super), WBC, The Ring & Lineal Welterweight titles." "2015-05-02";

$amateurEvents = @();
$amateurEvents += CreateEventObj "Zbigniew Pietrzykowski vs Cassius Clay" "Olimpic Games, Semi-finals, Rome" "1960-08-18";
$amateurEvents += CreateEventObj "Jerzy Kulej vs Evgeni Frolov" "Olimpic Games, Final, Tokyo" "1964-10-23";
$amateurEvents += CreateEventObj "Marian Kasprzyk vs Ricardas Tamulis" "Olimpic Games, Final, Tokyo" "1964-10-23";

# CreateEventsFromArray $amateurSite $amateurEvents
# CreateEventsFromArray $proSite $proEvents

EnableDeveloperDashboard;

function CreateMilionDocumentsWeb()
{
	$docsWeb = CreateWeb $proBoxingSiteUrl "docs"
	#$docLibType = $docsWeb.ListTemplates | Where-Object {$_.Type -eq 101}

	#$docsWeb.Lists.Add("Documents","Milion documents",$docLibType)

	$docLib = $docsWeb.Lists.TryGetList("Documents");
	$i = 0;
	#while($i -le 1000)
	#{ 
	#   $i++;	
	#   $docLib.RootFolder.SubFolders.Add("Folder($i)");
	#}
	$i = 0;
	[byte[]]$bytes = Get-Content "CreateHome.ps1" -Encoding byte
	while($i -le 1000)
	{ 
	   $i++;
	   $j = 0;
	   while($j -le 1000)
	   {
	      $j++;
	   	  $doc = $docsWeb.Files.Add($docLib.RootFolder.Url+"/Folder($i)/Doc$j.txt",$bytes, $true)
	   }
	}
}

