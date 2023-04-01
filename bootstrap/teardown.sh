# Cleanup script to delete the cluster created by the init.sh script
# exit if PROJECT_ID is not set
if [[ -z "${PROJECT_ID}" ]]; then
  echo "The value of PROJECT_ID is not set. Be sure to run export PROJECT_ID=YOUR-PROJECT first"
  return
fi
# Removing the cluster
echo "Deleting AP-demo-cluster..."
gcloud container clusters delete AP-demo-cluster --project "$PROJECT_ID" --region "us-west1" --async