<walkthrough-metadata>
  <meta name="title" content="GKE Autopilot configuraiton examples" />
  <meta name="description" content="Guide for helping you get up and running with Google Kubernetes Engine Autopilot mode" />
  <meta name="component_id" content="103" />
</walkthrough-metadata>

<walkthrough-disable-features toc></walkthrough-disable-features>

# GKE Autopilot demos guided walkthrough

## Select a project

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

Once you've selected a project, click "Start".

## Set the PROJECT_ID environment variable

Set the PROJECT_ID environment variable. This variable will be used in forthcoming steps.
```bash
export PROJECT_ID=<walkthrough-project-id/>
```

### Create a cluster

Run this script to enable the GKE API and create a GKE Autopilot cluster named "AP-demo-cluster":
```bash
. ./bootstrap/init.sh
```

Cluster creation can take a few minutes. Grab a coffee and come back in a few mins.

## Demo 01 - Deploying the sample app
Now that your cluster is up and running, the first step is deploying the sample app, the [Online Boutique microservices demo](https://github.com/GoogleCloudPlatform/microservices-demo). This is a microservices demo with several services, spanning various language platforms. Check out the  manifests in `demo-01-deploy-sample-app`.


Deploy the app services:
```bash
kubectl apply -f demo-01-deploy-sample-app/
```
Note that we have not yet provisioned node pools or nodes, as Autopilot will do that for you.

Monitor the rollout progress of both pods and nodes:
```bash
watch -d kubectl get pods,nodes
```

### Inspect the nodes
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

### Test the demo app website via ingress
After a few minutes the ingress IP will get assigned. Confirm everything is up in a different browser tab.

Get the ingress URL:
```bash
kubectl get svc frontend-external -o=jsonpath={.status.loadBalancer.ingress[0].ip}
echo http://$(kubectl get svc frontend-external -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')
```

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

## Demo 03 - GPU for AI/ML (TensorFlow)

Let's say our store has some AI/ML models as well. Autopilot supports the provisioning of GPUs like A100 and T4. 
Open the file: <walkthrough-editor-select-regex filePath="demo-03-GPU/tensorflow.yaml" regex="gpu|accelerator">demo-03-GPU/tensorflow.yaml"</walkthrough-editor-select-regex>

This demo creates a Tensorflow environment with a Jupyter notebook. 
```bash
kubectl apply -f demo-03-GPU/
```

Watch the Tensorflow pod and GPU node spin up:
```bash
watch -n 1 kubectl get pods,nodes
```

Confirm we're using GPU and Spot
```bash
kubectl get nodes -o json|jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."cloud.google.com/gke-spot"," ",.metadata.labels."cloud.google.com/gke-accelerator",  "\n"'|sort -k3 -r
```

### Jupyter AI/ML tutorial

After a few minutes, ingress should be aligned for your Jupyter notebook. Get the ingress IP:
```bash
kubectl get svc tensorflow-jupyter -o=jsonpath={.status.loadBalancer.ingress[0].ip}
```

Refer to William Denniss's [blog post](https://wdenniss.com/tensorflow-on-gke-autopilot-with-gpu-acceleration) detailing the TensorFlow demo.

### Tear down GPU workload

The GPU workload we just created will not be used in the rest of the demos and so you can tear it down now to save costs:


## Demo 04 - Provisioning spare capacity
Since Google manages the nodes, how do you spin up spare capacity for scaling up quickly? HPA will provision spin up new pods but if there is no spare capacity ....

Create balloon priority class
```bash 
kubectl apply -f demo-04-spare-capacity-balloon/balloon-priority.yaml 
```

Create balloon pods
```bash 
kubectl apply -f demo-04-spare-capacity-balloon/balloon-deploy.yaml 
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
watch -n 1 kubectl get pods,nodes
```
You should see three things happening:
* The original balloon pods will start terminating immediately because they are low priority, making way for...
* Frontend scaling up quickly, with most pods up and running in ~30s
* New balloon pods spinning up more slowly on newly provisioned infrastructure

If we were to scale up again, the latest balloon pods would get displaced and we'd continue buffering headroom this way.

## Demo 05 Workload Separation with Autopilot

For this use case, we want to ensure that both `frontend` and `paymentservice.yaml` workloads run on their own nodes, with no other workloads co-mingled. We'll achieve this by setting node labels using nodeSelector and a corresponding toleration. 

Open the file: <walkthrough-editor-select-regex filePath="demo-05-workload-separation/frontend.yaml" regex="toleration">demo-05-workload-separation/frontend.yaml"</walkthrough-editor-select-regex> and look for the toleration and nodeSelector. In this case, the node label is "frontend-servers".

Scale frontend service to 8 replicas
```bash
kubectl scale --replicas=8 deployment frontend
```

Open the file: <walkthrough-editor-select-regex filePath="demo-05-workload-separation/paymentservice.yaml" regex="toleration">demo-05-workload-separation/paymentservice.yaml"</walkthrough-editor-select-regex> and look for the toleration and nodeSelector. In this case, the node label is "PCI" (say we're trying to isolate these workloads for PCI reasons).

Scale up paymentservice to 2 replicas
```bash
kubectl scale --replicas=2 deployment frontend
```

Notice the current "co-mingled" distribution of workloads on nodes:
```bash
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

Redeploy the workloads with workload separation
```bash
kubectl apply -f demo-05-workload-separation
```

Watch the separation happen, which may take several minutes:
```bash
watch -n 1 kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

There are more docs on this topic [here](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-separation#separate-workloads-autopilot).

## Demo 06 Single zone



Now let's say we want to run a certain service in a particular zone. Perhaps we have persistent data there and we want close proximity. 

Open the file: <walkthrough-editor-select-regex filePath="demo-06-single-zone/productcatalogservice.yaml" regex="topology">demo-06-single-zone/productcatalogservice.yaml"</walkthrough-editor-select-regex> and look for the nodeSelector section. In this case, us-west1-b is preset as the zone but you can change this if desired.

```bash
kubectl get nodes --label-columns failure-domain.beta.kubernetes.io/zone
```
You'll see a mix of zones a, b, and possibly others.

Find productcatalogservice and make note of the zone this pod is in.
```bash
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

Redeploy with the selected zone.
```bash
kubectl apply -f demo-06-single-zone/
```

For a more thorough discussion, see William Denniss's [blog post](https://wdenniss.com/autopilot-specific-zones) on this topic.

## Demo 07 High Availability