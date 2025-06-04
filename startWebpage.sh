#!/bin/bash

prepTemplateFile() {
    file=$1
    sed -i .bak 's|<repoName>|'"$repoName"'|' $file
    sed -i .bak 's|<webpageTitle>|'"$webpageTitle"'|' $file
    sed -i .bak 's|<contactEmail>|'"$contactEmail"'|' $file
    sed -i .bak 's|<githubUsername>|'"$githubUsername"'|' $file
    rm $file.bak
}

getTemplateFile() {
    file=$1
    curl -LJO https://raw.githubusercontent.com/anchal-physics/startWebpage/main/templateFiles/$file
}

gitPushTemplateFile() {
    file=$1
    git add $file
    git commit -m 'Adding template file '"$file"
    git push
}

getPrepPush() {
    file=$1
    getTemplateFile $file
    prepTemplateFile $file
    gitPushTemplateFile $file
}

strrep() {
    text=$1
    pattern=$2
    newstr=$3
    echo ${text/$pattern/$newstr}
}

echo 'Welcome to startWebpage.'
echo 'We will get you to your webpage in minutes'
echo 'Press ctrl+c anytime to exit the software.'
echo

if ! command -v gh &> /dev/null
then
  echo 'I did not find gh installed on your computer.'
  read -p 'I will attempt installing gh (github CLI), is that ok ?(y/n) '
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
      if ! command -v brew &> /dev/null
      then
          echo
          echo 'I did not find brew installed on your computer.'
          read -p 'I will attempt installing brew, is that ok ?(y/n) '
          if [[ $REPLY =~ ^[Yy]$ ]]
          then
              echo 'Installing brew'
              /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          fi
      fi

      echo
      echo 'Installing gh...'
      echo 'Ensuring you have reading and writing permissions for required directories'
      sudo chown -R $(whoami) /usr/local/share/zsh /usr/local/share/zsh/site-functions
      chmod u+w /usr/local/share/zsh /usr/local/share/zsh/site-functions
      brew install gh
  fi
fi

echo
echo 'Installing ruby on your system:'
sudo gem install ruby

echo
echo 'Installing bundler -v 2.4.22'
sudo gem install bundler -v 2.4.22

echo
echo 'Installing github-pages gem'
getTemplateFile Gemfile
echo 'If you are prompted for password, please enter your sudo password:'
bundle install
rm Gemfile Gemfile.lock

echo
echo 'Logging into Github'
gh auth login

githubUsername="$(gh api user | jq -r '.login')"

echo
echo 'Choose a name for your webpage project. For example: workWebpage'
echo 'This will make your site address: https://'$githubUsername'.github.io/workWebpage/'
echo 'Leave empty (just press enter) to make your site as: https://'$githubUsername'.github.io . This option is good for creating personal webpage'
read -p 'This will be the name of your repo: '
if [ -z "$REPLY" ]; then
  repoAtBase=0
  repoName=$githubUsername'.github.io'
else
  repoAtBase=1
  repoName=$REPLY
fi

echo
echo 'Git repo will be created and cloned to current directory'
read -p 'Do you wish to initiate the git repo in a different location ?(y/n) '
if [[ $REPLY =~ ^[Yy]$ ]]
then
    read -p 'Enter full or relative path of new location:'
    cd $REPLY
fi

# echo
# read -p 'Do you want your repo to be public (y) or private (n)?'
# if [[ $REPLY =~ ^[Yy]$ ]]
# then
#     privacy="--public"
# fi
# if [[ $REPLY =~ ^[Nn]$ ]]
# then
#     privacy="--private"
# fi
privacy="--public"

echo
echo 'Now creating your repo remotely on Github and cloning a local copy.'
repoURL="$(gh repo create $repoName $privacy)"

# cloneURL=$(strrep $repoURL https:// git@)
# cloneURL="$(strrep $cloneURL / :)".git

# git clone $cloneURL
git clone 'git@github.com:'$githubUsername'/'$repoName'.git'

cd $repoName

baseURL="$repoURL"/blob/master

echo
echo 'Starting a new jekyll website'
jekyll new $repoName
mv ./$repoName/* ./
rm -r $repoName

getTemplateFile .gitignore

echo
read -p 'Please enter the title to your website:'
webpageTitle=$REPLY

echo
read -p 'Please enter a contact email:'
contactEmail=$REPLY


echo
echo "Creating _config.yml file..."
rm _config.yml
getTemplateFile _config.yml
prepTemplateFile _config.yml
prepTemplateFile _config.yml

rm ./*.md
rm ./*.markdown

echo
echo "Creating README.md file..."
getTemplateFile README.md
prepTemplateFile README.md
prepTemplateFile README.md

echo
echo "Creating index.md file..."
getTemplateFile index.md

echo
echo "Creating _pages ..."
rm -r _pages
mkdir _pages
cd _pages
getTemplateFile _pages/about.md
getTemplateFile _pages/blog.md
cd ..

echo
echo "Creating _posts ..."
rm -r _posts
mkdir _posts
cd _posts
getTemplateFile _posts/2022-09-05-template_post.md
cd ..

echo
echo "Getting local test file..."
getTemplateFile testLocally.sh
chmod +x testLocally.sh

echo
echo "Creating _includes/FOOTER.HTML file..."
mkdir _includes
cd _includes
getTemplateFile _includes/FOOTER.HTML
prepTemplateFile FOOTER.HTML
prepTemplateFile FOOTER.HTML
cd ..

echo
echo "Getting data/figures/GitHub-Mark-120px-plus.png file..."
mkdir data
cd data
mkdir figures
cd figures
getTemplateFile data/figures/GitHub-Mark-120px-plus.png
cd ../..

echo
echo "Creating GitHub Action file .github/workflows/deploy.yml ..."
rm -r .github
mkdir .github
cd .github
mkdir workflows
cd workflows
getTemplateFile .github/workflows/deploy.yml
cd ../..

git add .
git commit -m "Initializing webpage."
git push -f

git checkout -b gh-pages
git push -u origin gh-pages
git checkout $(git remote show origin | sed -n '/HEAD branch/s/.*: //p')

# gh api 'repos/'$githubUsername'/'$repoName'/pages' -f "source[branch]=gh-pages" -f "source[path]=/"

if [ $repoAtBase -eq 0 ]; then
    echo "Your webpage will be live in about 2 min at https://"$githubUsername".github.io/"
else
    echo "Your webpage will be live in about 2 min at https://"$githubUsername".github.io/"$repoName"/"
fi
echo "You can make changes to your local files at index.md, _pages, or _post"
echo "and push to update the webpage."
echo "You can test your changes locally by running ./testLocally.sh "
echo "and going to the server address that is printed out."
echo "Once done, you canuse ctrl-c to stop local test."
