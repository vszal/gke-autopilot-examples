if [[ -z "${PROJECT_ID}" ]]; then
  echo "The value of PROJECT_ID is not set. Be sure to run export PROJECT_ID=YOUR-PROJECT first"
  return
fi
# sets the current project for gcloud
#gcloud config set project $PROJECT_ID
# Enables the GKE API
gcloud services enable container.googleapis.com 
# Create demo cluster
echo "creating AP-demo-cluster..."
gcloud container --project "$PROJECT_ID" clusters create-auto "AP-demo-cluster" \
--region "us-west1" --release-channel "regular"

echo "All done, proceed to the next step - demos!"