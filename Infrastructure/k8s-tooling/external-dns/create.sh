#!/bin/bash
set -e

# Define a list of valid AWS regions (update as needed)
VALID_REGIONS=(
  "ap-south-1" "eu-north-1" "eu-west-3" "eu-west-2" "eu-west-1"
  "ap-northeast-3" "ap-northeast-2" "ap-northeast-1"
  "ca-central-1" "sa-east-1"
  "ap-southeast-1" "ap-southeast-2"
  "eu-central-1"
  "us-east-1" "us-east-2" "us-west-1" "us-west-2"
)

# Function to check if a region is valid
is_valid_region() {
  local input_region=$1
  for region in "${VALID_REGIONS[@]}"; do
    if [ "$input_region" == "$region" ]; then
      return 0
    fi
  done
  return 1
}

# If AWS_REGION is set, use it. Otherwise, prompt the user.
if [ -n "$AWS_REGION" ]; then
  echo "AWS_REGION is already set to '$AWS_REGION'. Using it."
  REGION="$AWS_REGION"
else
  read -p "AWS_REGION is not set. Please enter your AWS region (e.g., us-east-1): " REGION
fi

# Validate the region; if invalid, keep prompting.
while ! is_valid_region "$REGION"; do
  echo "Error: '$REGION' is not a valid AWS region."
  read -p "Please enter a valid AWS region (e.g., us-east-1): " REGION
done

echo "Using AWS region: $REGION"

# Write/update the override file (.external-dns.override.yaml)
cat <<EOF > .external-dns.override.yaml
provider: aws
env:
  - name: AWS_REGION
    value: "$REGION"
EOF

echo "Updated .external-dns.override.yaml:"
cat .external-dns.override.yaml

# Add the external-dns Helm repository (if not already added)
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ || true
helm repo update

# Upgrade or install external-dns using your base values and the override file
helm upgrade --install external-dns external-dns/external-dns \
  -f values.yaml \
  -f .external-dns.override.yaml

echo "Helm upgrade/install completed."
