# Splunking with Jamf
### X World 2023 presentation

How to make data-driven decisions to prioritise and operationalise your Jamf deployment.

## Setup

### Splunk Add-in

https://learn.jamf.com/bundle/technical-paper-splunk-current/page/Integrating_Splunk_with_Jamf_Pro.html

https://www.youtube.com/watch?v=4tsV-wZE6aw

### Webhooks

https://learn.jamf.com/bundle/technical-paper-splunk-current/page/Jamf_Pro_Webhooks_for_Splunk.html

Use https://http-inputs-seek.splunkcloud.com/services/collector/raw format

Header Authentication {"Authorization":"Splunk 2f75XXXX-XXXX-XXXX-XXXX-XXXXXXXX9e68"}

### CSV Import

[PoliciesID_Extract.sh
](https://github.com/ooftee/Splunking_with_Jamf/blob/main/PoliciesID_Extract.sh)

## Basic Searches

### macOS Versions
Timechart of all different versions over time
`index="jamf" computerOS.version=* | timechart span=1d dc(computer_meta.id) as id by computerOS.version`

Refine by merging all Ventura and Monterey versions
`index="jamf" computerOS.version=12.* | timechart span=1d dc(computer_meta.id) as Monterey 
| appendcols 
[search index="jamf" computerOS.version=13.* | timechart span=1d dc(computer_meta.id) as Ventura | fields Ventura]`

### Using smart groups
`index="jamf" groupMembership.groupId=820 | timechart span=24h dc(computer_meta.id) as Total
`
### API Stats
`index="jamf" source="http:jamf_webhook" "webhook.webhookEvent"=RestAPIOperation | stats count by event.authorizedUsername, event.restAPIOperationType, event.objectTypeName`

### Policies
Total of successful patches last week
`index="jamf" source="http:jamf_webhook" policyName="Patch -*" event.successful="true" | stats count`
