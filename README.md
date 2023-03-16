# Splunking with Jamf
### X World 2023 presentation

How to make data-driven decisions to prioritise and operationalise your Jamf deployment.

## Setup

There is plenty of existing documentation for this, see below.

### Splunk Add-in

https://learn.jamf.com/bundle/technical-paper-splunk-current/page/Integrating_Splunk_with_Jamf_Pro.html

https://www.youtube.com/watch?v=4tsV-wZE6aw

### Webhooks

https://learn.jamf.com/bundle/technical-paper-splunk-current/page/Jamf_Pro_Webhooks_for_Splunk.html

We had to use the URL format `https://http-inputs-XXXX.splunkcloud.com/services/collector/raw`
The suggested one `https://http-inputs-XXXX.splunkcloud.com/services/collector/event` never worked

Format the Header Authentication like this `{"Authorization":"Splunk 2f75XXXX-XXXX-XXXX-XXXX-XXXXXXXX9e68"}`

### CSV Import

Use this script to export all the policies name and IDs

[PoliciesID_Extract.sh
](https://github.com/ooftee/Splunking_with_Jamf/blob/main/PoliciesID_Extract.sh)

## Basic Searches

NOTE: Index and source name may vary in your environment.

### macOS Versions
Timechart of all different versions over time

```
index="jamf" computerOS.version=* 
| timechart span=1d dc(computer_meta.id) as version by computerOS.version
```

Refine by merging all Ventura and Monterey versions

```
index="jamf" computerOS.version=12.* | timechart span=1d dc(computer_meta.id) as Monterey 
| appendcols 
  [search index="jamf" computerOS.version=13.* | timechart span=1d dc(computer_meta.id) as Ventura | fields Ventura]
```

### Using smart groups

Smart group allows you to report in splunk on atributes that might not be collected by the add-in or webhooks like EDR status.
If you can create a jamf smart group, splunk can report on it.

```
index="jamf" groupMembership.groupId=820 
| timechart span=24h dc(computer_meta.id) as Total
```

### API Stats

API monitoring is great feature of wehbooks, it can’t be done from anywhere else.

```
index="jamf" source="http:jamf_webhook" "webhook.webhookEvent"=RestAPIOperation 
| stats count by event.authorizedUsername, event.restAPIOperationType, event.objectTypeName
```

### Policies
As we have imported the policies' names we can now use wildcards to find things like the total of successful patches.

```
index="jamf" source="http:jamf_webhook" policyName="Patch -*" event.successful="true" | stats count
```

## Alerts

### Device added to ADE
```
index="jamf" source="http:jamf_webhook" "webhook.webhookEvent"=DeviceAddedToDEP
```

### API Usage
```
index="jamf" source="http:jamf_webhook" "webhook.webhookEvent"=RestAPIOperation 
| search "event.restAPIOperationType"=PUT OR "event.restAPIOperationType"=POST
```

### Policy Failure over 4%
```
index="jamf" source="http:jamf_webhook" 
| eventstats count(eval('event.successful'=="true")) as "Success" 
| eventstats count(eval('event.successful'=="false")) as "Failure" 
| eval Percent=round(Failure/Success*100,2) 
| search Percent > 4
```
