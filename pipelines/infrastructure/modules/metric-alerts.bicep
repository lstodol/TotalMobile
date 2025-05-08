param actionGroupName string
param environment string

//You can not select region UK South, becasue it is not available 
param location string = 'Global'
param regionToMonitor string = 'UK South'
param locationQueryRules string = 'uksouth'
param alertServiceHealthName string 

param alertRuleNamePipelineFailedRuns string 
param alertRuleNamePipelineRunDuration string 
param alertRuleNamePipelineRunDuration30m string
param alertRuleNamePipelineRunDuration1h string
param alertRuleNamePipelineRunDuration2h string
param alertRuleNamePipelineRunDuration4h string
param alertRuleNamePipelineRunDuration8h string
param alertRuleNamePipelineRunDuration12h string
param alertRuleNamePipelineRunDuration24h string

param emailReceivers array = []
param dataFactoryResourceId string = '/subscriptions/your-subscription-id/resourceGroups/your-resource-group/providers/Microsoft.DataFactory/factories/your-data-factory-name'

var alertFlag = (environment == 'prod') ? true : false

resource actionGroup 'Microsoft.Insights/actionGroups@2021-09-01' = if (alertFlag) {
  name: actionGroupName
  location: location
  properties: {
    groupShortName: 'ADF-alert'
    enabled: true
    emailReceivers: [for (email, index) in emailReceivers: {
        name: email
        emailAddress: email
        useCommonAlertSchema: true
      }
    ]
  }
}

resource metricAlertFailedRuns 'Microsoft.Insights/metricAlerts@2018-03-01' = if (alertFlag) {
  name: alertRuleNamePipelineFailedRuns
  location: location
  properties: {
    description: 'Alert rule for Azure Data Factory pipeline failures'
    severity:  0
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    evaluationFrequency: 'PT15M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          name: 'FailedRuns'
          metricNamespace: 'Microsoft.DataFactory/factories'
          metricName: 'PipelineFailedRuns'
          operator: 'GreaterThan'
          threshold:  0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

resource metricAlertLongRunning 'Microsoft.Insights/metricAlerts@2018-03-01' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration
  location: 'Global'
  properties: {
    description: 'Alert for long-running ADF pipelines'
    severity:  3
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    evaluationFrequency: 'PT15M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          threshold: 0
          name: 'LongRunning'
          metricNamespace: 'Microsoft.DataFactory/factories'
          metricName: 'PipelineElapsedTimeRuns'
          operator: 'GreaterThan'
          timeAggregation: 'Total'
          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

resource activitylogalerts_service_health_name_resource 'microsoft.insights/activitylogalerts@2020-10-01' = if (alertFlag) {
  name: alertServiceHealthName
  location: 'global'
  properties: {
    scopes: ['/subscriptions/${subscription().subscriptionId}']
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
        {
          field: 'properties.impactedServices[*].ServiceName'
          containsAny: [
            'Data Factory'
            'Diagnostic Logs'
            'Storage'
            'SQL Database'
            'Key Vault'
            'Azure Data Lake Storage Gen2'
            'Activity Logs & Alerts'
            'Action Groups'
            'Azure Databricks'
          ]
        }
        {
          field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
          containsAny: [regionToMonitor]
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroup.id
          webhookProperties: {}
        }
      ]
    }
    enabled: true
  }
}

//Long running ADF pipelines alerts (30 mins, 1 hr, 2hr, 4 hr, 8 hr)

resource metricAlertLongRunning30m 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration30m
  location: locationQueryRules
  properties: {
    description: 'Alert for long-running ADF pipelines - 30 mins'
    severity:  2
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    targetResourceTypes: [
      'Microsoft.DataFactory/factories'
    ]
    evaluationFrequency: 'PT30M'
    windowSize: 'PT30M'
    overrideQueryTimeRange: 'PT30M'
    criteria: {
      allOf: [
        {
          query: 'let monitoringThreshold = 30;\nlet nextMonitoringThreshold = 60;\nADFPipelineRun\n| where PipelineName == "_master" and Status == "InProgress" and TimeGenerated >= ago(30m)\n| extend RunTime = datetime_diff(\'minute\', now(), Start)\n| where RunTime >= monitoringThreshold and RunTime  < nextMonitoringThreshold\n| project RunId, PipelineName, RunTime, Status, Start\n| join kind=anti (\n    ADFPipelineRun\n    | where Status in ("Succeeded", "Failed")\n    | project RunId\n    )\n    on RunId\n'
          threshold: 30
          metricMeasureColumn: 'RunTime'
          operator: 'GreaterThanOrEqual'
          timeAggregation: 'Maximum'
          dimensions: []
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}

resource metricAlertLongRunning1h 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration1h
  location: locationQueryRules
  properties: {
    description: 'Alert for long-running ADF pipelines - 1 hour'
    severity:  2
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    targetResourceTypes: [
      'Microsoft.DataFactory/factories'
    ]
    evaluationFrequency: 'PT1H'
    windowSize: 'PT1H'
    overrideQueryTimeRange: 'PT1H'
    criteria: {
      allOf: [
        {
          query: 'let monitoringThreshold = 1;\nlet nextMonitoringThreshold = 2;\nADFPipelineRun\n| where PipelineName == "_master" and Status == "InProgress" and TimeGenerated >= ago(1h)\n| extend RunTime = datetime_diff(\'hour\', now(), Start)\n| where RunTime >= monitoringThreshold and RunTime  < nextMonitoringThreshold\n| project RunId, PipelineName, RunTime, Status, Start\n| join kind=anti (\n    ADFPipelineRun\n    | where Status in ("Succeeded", "Failed")\n    | project RunId\n    )\n    on RunId\n'
          threshold: 1
          metricMeasureColumn: 'RunTime'
          operator: 'GreaterThanOrEqual'
          timeAggregation: 'Maximum'
          dimensions: []
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}

resource metricAlertLongRunning2h 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration2h
  location: locationQueryRules
  properties: {
    description: 'Alert for long-running ADF pipelines - 2 hours'
    severity:  2
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    targetResourceTypes: [
      'Microsoft.DataFactory/factories'
    ]
    evaluationFrequency: 'PT2H'
    windowSize: 'PT2H'
    overrideQueryTimeRange: 'PT2H'
    criteria: {
      allOf: [
        {
          query: 'let monitoringThreshold = 2;\nlet nextMonitoringThreshold = 4;\nADFPipelineRun\n| where PipelineName == "_master" and Status == "InProgress" and TimeGenerated >= ago(2h)\n| extend RunTime = datetime_diff(\'hour\', now(), Start)\n| where RunTime >= monitoringThreshold and RunTime  < nextMonitoringThreshold\n| project RunId, PipelineName, RunTime, Status, Start\n| join kind=anti (\n    ADFPipelineRun\n    | where Status in ("Succeeded", "Failed")\n    | project RunId\n    )\n    on RunId\n'
          threshold: 2
          metricMeasureColumn: 'RunTime'
          operator: 'GreaterThanOrEqual'
          timeAggregation: 'Maximum'
          dimensions: []
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}

resource metricAlertLongRunning4h 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration4h
  location: locationQueryRules
  properties: {
    description: 'Alert for long-running ADF pipelines - 4 hours'
    severity:  2
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    targetResourceTypes: [
      'Microsoft.DataFactory/factories'
    ]
    evaluationFrequency: 'PT4H'
    windowSize: 'PT4H'
    overrideQueryTimeRange: 'PT4H'
    criteria: {
      allOf: [
        {
          query: 'let monitoringThreshold = 4;\nlet nextMonitoringThreshold = 8;\nADFPipelineRun\n| where PipelineName == "_master" and Status == "InProgress" and TimeGenerated >= ago(4h)\n| extend RunTime = datetime_diff(\'hour\', now(), Start)\n| where RunTime >= monitoringThreshold and RunTime  < nextMonitoringThreshold\n| project RunId, PipelineName, RunTime, Status, Start\n| join kind=anti (\n    ADFPipelineRun\n    | where Status in ("Succeeded", "Failed")\n    | project RunId\n    )\n    on RunId\n'
          threshold: 4
          metricMeasureColumn: 'RunTime'
          operator: 'GreaterThanOrEqual'
          timeAggregation: 'Maximum'
          dimensions: []
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}

resource metricAlertLongRunning8h 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration8h
  location: locationQueryRules
  properties: {
    description: 'Alert for long-running ADF pipelines - 8 hours'
    severity:  2
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    targetResourceTypes: [
      'Microsoft.DataFactory/factories'
    ]
    evaluationFrequency: 'PT6H'
    windowSize: 'PT6H'
    overrideQueryTimeRange: 'PT6H'
    criteria: {
      allOf: [
        {
          query: 'let monitoringThreshold = 8;\nlet nextMonitoringThreshold = 16;\nADFPipelineRun\n| where PipelineName == "_master" and Status == "InProgress" and TimeGenerated >= ago(8h)\n| extend RunTime = datetime_diff(\'hour\', now(), Start)\n| where RunTime >= monitoringThreshold and RunTime  < nextMonitoringThreshold\n| project RunId, PipelineName, RunTime, Status, Start\n| join kind=anti (\n    ADFPipelineRun\n    | where Status in ("Succeeded", "Failed")\n    | project RunId\n    )\n    on RunId\n'
          threshold: 8
          metricMeasureColumn: 'RunTime'
          operator: 'GreaterThanOrEqual'
          timeAggregation: 'Maximum'
          dimensions: []
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}

//Long running ADF pipelines critical alerts (12 hr, 24h)
resource metricAlertLongRunning12h 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration12h
  location: locationQueryRules
  properties: {
    description: 'Alert for long-running ADF pipelines - 12 hours'
    severity:  0
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    targetResourceTypes: [
      'Microsoft.DataFactory/factories'
    ]
    evaluationFrequency: 'PT6H'
    windowSize: 'PT6H'
    overrideQueryTimeRange: 'PT6H'
    criteria: {
      allOf: [
        {
          query: 'let monitoringThreshold = 12;\nlet nextMonitoringThreshold = 24;\nADFPipelineRun\n| where PipelineName == "_master" and Status == "InProgress" and TimeGenerated >= ago(12h)\n| extend RunTime = datetime_diff(\'hour\', now(), Start)\n| where RunTime >= monitoringThreshold and RunTime  < nextMonitoringThreshold\n| project RunId, PipelineName, RunTime, Status, Start\n| join kind=anti (\n    ADFPipelineRun\n    | where Status in ("Succeeded", "Failed")\n    | project RunId\n    )\n    on RunId\n'
          threshold: 12
          metricMeasureColumn: 'RunTime'
          operator: 'GreaterThanOrEqual'
          timeAggregation: 'Maximum'
          dimensions: []
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}

resource metricAlertLongRunning24h 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (alertFlag) {
  name: alertRuleNamePipelineRunDuration24h
  location: locationQueryRules
  properties: {
    description: 'Alert for long-running ADF pipelines - 24 hours'
    severity:  0
    enabled: true
    scopes: [
      dataFactoryResourceId
    ]
    targetResourceTypes: [
      'Microsoft.DataFactory/factories'
    ]
    evaluationFrequency: 'PT24H'
    windowSize: 'PT24H'
    overrideQueryTimeRange: 'PT24H'
    criteria: {
      allOf: [
        {
          query: 'let monitoringThreshold = 24;\nADFPipelineRun\n| where PipelineName == "_master" and Status == "InProgress" and TimeGenerated >= ago(24h)\n| extend RunTime = datetime_diff(\'hour\', now(), Start)\n| where RunTime >= monitoringThreshold\n| project RunId, PipelineName, RunTime, Status, Start\n| join kind=anti (\n    ADFPipelineRun\n    | where Status in ("Succeeded", "Failed")\n    | project RunId\n    )\n    on RunId\n'
          threshold: 24
          metricMeasureColumn: 'RunTime'
          operator: 'GreaterThanOrEqual'
          timeAggregation: 'Maximum'
          dimensions: []
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}
