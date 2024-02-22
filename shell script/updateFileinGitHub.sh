USER_NAME = "bjadhav"
TOKEN= $PAT
REPOSITORY = https://github.com/bjadhav/webapps.git                       
                        
# Clone the GitHub repository using the provided username and token                       
git clone https://${USER_NAME}:${TOKEN}@github.com/${USER_NAME}/${REPOSITORY}

# Display the contents of the original file (assuming the correct file name is 'webapp-deploy.yaml')
cat webapp-deploy.yaml

# Replace occurrences of '32' with the value of the 'BUILD_NUMBER' variable in 'deploy.yaml'
sed -i '' "s/32/${BUILD_NUMBER}/g" deploy.yaml

# Display the contents of the modified 'webapp-deploy.yaml'
cat webapp-deploy.yaml

# Add the modified 'webapp-deploy.yaml' file to the staging area
git add webapp-deploy.yaml

# Commit the changes with a meaningful message
git commit -m 'Updated the deploy yaml | Jenkins Pipeline'

# Display information about the remote repository
git remote -v

# Push the committed changes to the 'main' branch of the GitHub repository
git push https://github.com/iam-veeramalla/cicd-demo-manifests-repo.git HEAD:main