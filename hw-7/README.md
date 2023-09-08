# Prepare Git

    git clone https://github.com/Hillel-DevOps-230720/andrii-rudenko ~/hillel.devops
    cd ~/hillel.devops
    tee .env >/dev/null <<EOF
    GITHUB_USER=konstantait
    GITHUB_TOKEN=ghp_******************
    EOF
    export $(grep -v '^#' .env | xargs -d '\n')

    git remote show origin
    git remote set-url origin https://$GITHUB_USER:$GITHUB_TOKEN@github.com/Hillel-DevOps-230720/andrii-rudenko.git
    git remote show origin

    git checkout -b hw-7
    tee .gitignore >/dev/null <<EOF
    .github/
    .pre-commit-config.yaml
    .env
    venv/
    EOF
    git add .gitignore
    git commit -m "Initial commit"
    git push --set-upstream origin hw-7
    git config --global --replace-all alias.ac '!git add -A && git commit -m "Initial commit"'
    git config --list | grep alias

    sudo apt install python3.10-venv
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    echo -e 'pre-commit' >> requirements.txt
    pip install -r requirements.txt

    tee .pre-commit-config.yaml >/dev/null <<EOF
    repos:
    - repo: https://github.com/pre-commit/pre-commit-hooks
      rev: v2.3.0
      hooks:
        - id: end-of-file-fixer
        - id: trailing-whitespace
    - repo: https://github.com/Yelp/detect-secrets
      rev: v1.4.0
      hooks:
       - id: detect-secrets
    EOF
    pre-commit install

    mkdir -p ./.github/workflows

    tee ./.github/auto_assign.yml >/dev/null <<EOF
    addAssignees: true
    reviewers:
      - saaverdo
    EOF

    tee ./.github/workflows/auto_assign.yml >/dev/null <<EOF
    name: 'Auto Assign'
    on: pull_request
    jobs:
    add-reviews:
    runs-on: ubuntu-latest
    steps:
      - uses: kentaro-m/auto-assign-action@v1.1.2
    EOF

    mkdir ./hw-7 && touch ./hw-7/README.md
    git ac
    git push
