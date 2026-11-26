@description('Email address that receives alert notifications')
param alertEmail string

@description('Resource ID of the App Service whose Http5xx metric is monitored')
param webAppId string

param actionGroupName string
param tags object = {}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'cl26mail'
    enabled: true
    emailReceivers: [
      {
        name: 'primary-email'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

resource http5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-cloud26-http5xx'
  location: 'global'
  tags: tags
  properties: {
    description: 'Campus Events is returning server errors'
    severity: 2
    enabled: true
    scopes: [
      webAppId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'Http5xxGreaterThanZero'
          metricName: 'Http5xx'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
