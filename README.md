# GKE Autopilot examples

## What is GKE Autopilot?
GKE Autopilot is cluster mode of operation where GKE manages your cluster control plane, node pools, and worker nodes. This means you don't provision and manage nodes yourself, the way you do it with GKE Standard. How do you specify the attributes of the underlying nodes in this model? At the workload level! This creates a much faster time to value because developers can specify precisely what they need on a per-workload basis without waiting for Platform teams to provision nodes and configure taints.

The demos in this tutorial are aimed at providing you with examples of common use cases, the Autopilot way.

## Demo 01 - Deploying the sample app
Now that your cluster is up and running, let's deploy the sample app, the [Online Boutique microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo). 


```bash
kubectl apply -f demo-01-deploy-sample-app/
```

Monitor the rollout progress
```bash
watch -d kubectl get pods
```

Wait a few minutes for ingress to get assigned. Confirm everything is up and running by getting and browsing to the ingress IP:
```bash
kubectl get svc frontend-external -o=jsonpath={.status.loadBalancer.ingress[0].ip}
```

### Nodes
Let's see the various deployments created
```bash
kubectl get deployments
```

Let's see the nodes Autopilot provisioned under the hood
```bash
kubectl get nodes
```

Let's check the machine type provisioned by default:
```bash
kubectl describe nodes |grep node.kubernetes.io/instance-type
```

Note that Autopilot defaults to the e2 series machine for each node by default with Autopilot.

## Demo 02 - Compute classes

Now let's tune our application by specifying [compute classes](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-compute-classes) for our workloads. [Compute classes](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-compute-classes#when-to-use) allow us to customize hardware requirements and over a curated subset of Compute Engine machine series.

*Note: This is a fictional example and I've selected arbitrary compute classes so do not read into my specific choices. The point is show you *how* to select compute classes.*


### Deploy machine type manifests
```bash
kubectl apply -f demo-02-compute-classes/
```

Watch new nodes spin up:
```bash
watch -d "kubectl get nodes"
```

We've set `adservice` workload use the Balanced compute class (N2/N2D machine types):

Open the file: <walkthrough-editor-select-regex filePath="demo-02-compute-classes/adservice.yaml" regex="compute-class">demo-02-compute-classes/adservice.yaml"</walkthrough-editor-select-regex>

`checkoutservice` workload use the Scale-Out compute class (T2/T2D machine types):

Open the file: <walkthrough-editor-select-regex filePath="demo-02-compute-classes/checkoutservice.yaml" regex="compute-class">demo-02-compute-classes/checkoutservice.yaml"</walkthrough-editor-select-regex>

List instance types and architectures
```bash
kubectl get nodes -o json|jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."beta.kubernetes.io/arch", "\n"'|sort -k3 -r
```

### Spot pods
`cartservice` workload has now been configured to use Spot Pod resources:

Open the file: <walkthrough-editor-select-regex filePath="demo-02-compute-classes/cartservice.yaml" regex="spot">demo-02-compute-classes/cartservice.yaml"</walkthrough-editor-select-regex>
List nodes looking for spot
```bash
kubectl get nodes -o json|jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."cloud.google.com/gke-spot"," ",.metadata.labels."beta.kubernetes.io/arch", "\n"'|sort -k3 -r
``` 

## Demo 03 - Provisioning spare capacity
Since Google manages the nodes, how do you spin up spare capacity for scaling up quickly? HPA will provision spin up new pods but if there is no spare capacity ....

Create balloon priority class
```bash 
kubectl apply -f demo-03-spare-capacity-balloon/balloon-priority.yaml 
```

Create balloon pods
```bash 
kubectl apply -f demo-03-spare-capacity-balloon/balloon-deploy.yaml 
```

Watch scale up of balloon pods
```bash
watch -d kubectl get pods,nodes
```
### Scale up by displaying balloon pods
Scale up frontend
```bash
kubectl scale --replicas=8 deployment frontend
```
Watch scale up of frontend, displacing the balloon pods. Recreation of low priority balloon pods.
```bash
watch -d kubectl get pods,nodes
```
