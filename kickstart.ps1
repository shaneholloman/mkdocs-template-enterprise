# Check for gh CLI installation
if (gh --version 2>&1) {
  Write-Host "GitHub CLI is installed" -ForegroundColor Green
} else {
  Write-Host "GitHub CLI is not installed" -ForegroundColor Yellow
  Write-Host "To install GitHub CLI, visit: https://github.com/cli/cli#installation"
  exit 1
}

# Define the GitHub account or organization name
$githubAccount = "shaneholloman" # Change this to your personal account name if needed

# Initialize a new git repository
git init -b main

# Get the name of the current repository from the top-level directory
$repoName = Split-Path -Leaf (git rev-parse --show-toplevel)

# Create a new repository on GitHub using the gh CLI
gh repo create $githubAccount/$repoName --private --confirm

# Add the remote repository
git remote add origin "https://github.com/$githubAccount/$repoName.git"

# Add all files in the current directory to the git repository
git add .

# Commit the changes
git commit -m "Initial commit"

# Push the changes to GitHub
git push -u origin main

# Define a hashtable where the key is the name of the secret and the value is the secret value
$secrets = @{
  "DOCKERHUB_TOKEN"    = $env:DOCKERHUB_TOKEN
  "DOCKERHUB_USERNAME" = $env:DOCKERHUB_USERNAME
  "GALAXY_API_KEY"     = $env:GALAXY_API_KEY
  # Add more secrets here as needed
}

# Check if environment variables exist
$missingVars = @()
foreach ($key in $secrets.Keys) {
  if ([string]::IsNullOrEmpty($secrets[$key])) {
    $missingVars += $key
  }
}

if ($missingVars.Count -ne 0) {
  # Print 2 blank lines here to make the output easier to read
  Write-Host "`n`nThe following environment variables are missing, but you dont have to use them:"
  foreach ($var in $missingVars) {
    Write-Host $var
  }
  Write-Host "You may add them to your $profile file or set them in the current session"
  exit 1
}

# Loop through each secret to set it for the current repository
foreach ($key in $secrets.Keys) {
  $value = $secrets[$key]
  $command = "echo -n $value | gh secret set $key --repo=$githubAccount/$repoName"
  Invoke-Expression $command
}

# Tag and push after setting the secrets
$commitMessage = "tagging initial version"
$tagVersion = "0.0.1"
$tagMessage = "Initial version"

git commit --allow-empty -m $commitMessage
git tag -a $tagVersion -m $tagMessage

# Ask the user if the current git tag and message are correct
# Print 2 blank lines here to make the output easier to read
Write-Host "`n`nThe current git tag is $tagVersion with the message '$tagMessage'. Is this correct? (yes/no)"
$answer = Read-Host

if ($answer -match "^[Yy]") {
  git push origin $tagVersion
} else {
  Write-Host "Please edit the git tag and message in this script."
}
