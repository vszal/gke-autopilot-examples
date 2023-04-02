# GKE Autopilot demos - configuration and examples for common use cases

[GKE Autopilot](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview) is cluster mode of operation where GKE manages your cluster control plane, node pools, and worker nodes. This means you don't provision and manage nodes yourself, the way you do it with GKE Standard. How do you specify the attributes of the underlying nodes in this model? At the workload level! This creates a much faster time to value because developers can specify precisely what they need on a per-workload basis without waiting for Platform teams to provision nodes and configure taints.

The demos in this tutorial are aimed at providing you with examples of common use cases, the Autopilot way.

## The demos
Each demo is in a subdirectory of the main repo. They are designed to run successively from `demo-01-deploy-sample-app` forward. For easy access, a Guided tutorial is also provided via Google Cloud CloudShell. If you prefer to use an environment outside of CloudShell, see [tutorial.md](tutorial.md). 

## Guided tutorial in Cloud Shell
Use Google Cloud's Cloud Shell envirnoment to run this demo. Clicking this button provisions a Cloud Shell Editor and launches an interactive tutorial which steps you through the process. Google Cloud account and project required.

[![Start tutorial in cloud shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/open?git_repo=https://github.com/vszal/gke-autopilot-examples&cloudshell_workspace=.&cloudshell_tutorial=tutorial.md)
