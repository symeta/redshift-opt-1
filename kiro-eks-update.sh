
> eks cluster mc-dec13 in virginia region is 1.33. how to upgrade it to 1.34?

> I'll help you upgrade your EKS cluster from version 1.33 to 1.34. Let me first check the current status of your cluster and 
then perform the upgrade.
Running aws cli command (using tool: aws):

Service name: eks
Operation name: describe-cluster
Parameters: 
- name: "mc-dec13"
Region: us-east-1
Label: Check current EKS cluster status
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y

 - Completed in 2.515s

> Now I'll upgrade the cluster to version 1.34:
Running aws cli command (using tool: aws):

Service name: eks
Operation name: update-cluster-version
Parameters: 
- version: "1.34"
- name: "mc-dec13"
Region: us-east-1
Label: Upgrade EKS cluster to version 1.34
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y

 - Completed in 0.508s

> Let me check the update status to see if the upgrade has started:
Running aws cli command (using tool: aws):

Service name: eks
Operation name: describe-update
Parameters: 
- name: "mc-dec13"
- update-id: "latest"
Region: us-east-1
Label: Check cluster upgrade status
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y

 ⋮ 
 ● Execution failed after 2.40s:

An error occurred (ResourceNotFoundException) when calling the DescribeUpdate operation: No update found for ID: latest


> Let me list the updates to see the current status:
Running aws cli command (using tool: aws):

Service name: eks
Operation name: list-updates
Parameters: 
- name: "mc-dec13"
Region: us-east-1
Label: List cluster updates
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y

 - Completed in 1.982s

> It seems the upgrade command didn't initiate properly. Let me try the upgrade again with the correct syntax:
Running aws cli command (using tool: aws):

Service name: eks
Operation name: update-cluster-version
Parameters: 
- name: "mc-dec13"
- version: "1.34"
Region: us-east-1
Label: Upgrade EKS cluster to version 1.34
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y

 - Completed in 0.897s

> The output suggests the command executed but didn't return the expected JSON response. Let me check if there are any available
versions first:
Searching the web for: AWS EKS Kubernetes version 1.34 availability 2024 2025 (using tool: web_search)

Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y


 ✓ Found 10 search results
 - Completed in 2.191s

> Based on the search results, Kubernetes 1.34 is available on EKS. Let me try a different approach to initiate the upgrade:
I will run the following command: aws eks update-cluster-version --region us-east-1 --name mc-dec13 --kubernetes-version 1.34 (using tool: shell)
Purpose: Upgrade EKS cluster using direct AWS CLI command


Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y

{
    "update": {
        "id": "288766e4-c076-337b-8e78-f6c79ea78e06",
        "status": "InProgress",
        "type": "VersionUpdate",
        "params": [
            {
                "type": "Version",
                "value": "1.34"
            },
            {
                "type": "PlatformVersion",
                "value": "eks.9"
            }
        ],
        "createdAt": "2025-12-14T17:47:58.022000+08:00",
        "errors": []
    }
}
 - Completed in 3.833s

> Perfect! The upgrade has been initiated successfully. Let me check the current status:
Running aws cli command (using tool: aws):

Service name: eks
Operation name: describe-update
Parameters: 
- update-id: "288766e4-c076-337b-8e78-f6c79ea78e06"
- name: "mc-dec13"
Region: us-east-1
Label: Check cluster upgrade progress
Allow this action? Use 't' to trust (always allow) this tool for the session. [y/n/t]:

> y

 - Completed in 1.968s

> Great! Your EKS cluster upgrade from version 1.33 to 1.34 is now in progress. Here's what happened:

Upgrade Status:
- Update ID: 288766e4-c076-337b-8e78-f6c79ea78e06
- Status: InProgress
- Target Version: 1.34
- Platform Version: eks.9
- Started: December 14, 2025 at 17:47:58

What to expect:
- The control plane upgrade typically takes 10-15 minutes
- Your workloads will continue running during the upgrade
- The cluster endpoint may be briefly unavailable during the process

Next steps after control plane upgrade:
1. Update your node groups to version 1.34
2. Update any add-ons (CoreDNS, kube-proxy, VPC CNI)
3. Test your applications

You can monitor the progress with:
bash
aws eks describe-update --region us-east-1 --name mc-dec13 --update-id 288766e4-c076-337b-8e78-f6c79ea78e06


The upgrade will be complete when the status changes to Successful.

Here's what I found:

References:
[1] Amazon EKS Supports Kubernetes 1.34 - https://mwpro.co.uk/blog/2025/10/07/amazon-eks-and-amazon-eks-distro-now-supports-
kubern...
[2] Amazon EKS and Amazon EKS Distro now supports Kubernetes version 1.34 - https://cloudsteak.com/aws-amazon-eks-and-amazon-eks
-distro-now-supports-kubernetes-vers...
[3] Amazon EKS and Amazon EKS Distro now supports Kubernetes version 1.34 - https://www.westloop.io/post/amazon-eks-and-amazon-
eks-distro-now-supports-kubernetes-ve...
 ▸ Credits: 0.39 • Time: 2m 14s

> 
