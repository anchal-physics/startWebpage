#!/bin/bash

prepTemplateFile() {
    file=$1
    sed -i .bak 's|<repoName>|'"$repoName"'|' $file
    sed -i .bak 's|<webpageTitle>|'"$webpageTitle"'|' $file
    sed -i .bak 's|<contactEmail>|'"$contactEmail"'|' $file
    sed -i .bak 's|githubUsername>|'"$outputFileName"'|' $file
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
echo 'Installing bundler'
sudo gem install bundler

echo
echo 'Installing github-pages gem'
getTemplateFile Gemfile
echo 'If you are prompted for password, please enter your sudo password:'
bundle install
rm Gemfile Gemfile.lock

echo
echo 'Logging into Github'
gh auth login

echo
echo 'Choose a name for your webpage project. For example: personalWebpage'
echo 'This will make your site address: https://<github_username>.github.io/personalWebpage/'
read -p 'This will be the name of your repo: '
repoName=$REPLY

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

cloneURL=$(strrep $repoURL https:// git@)
cloneURL="$(strrep $cloneURL / :)".git

git clone $cloneURL

cd $repoName

baseURL="$repoURL"/blob/master

echo
echo 'Starting a new jekyll website'
jekyll start $repoName
mv ./$repoName/* ./
rm -r $repoName

getTemplateFile .gitignore

echo
read -p 'Please enter the title to your website:'
webpageTitle=$REPLY

echo
read -p 'Please enter a contact email:'
contactEmail=$REPLY

githubUsername=$(strrep $repoURL https://github.com/ "")
githubUsername=$(strrep $githubUsername /$repoName/ "")

rm _config.yml
getTemplateFile _config.yml
prepTemplateFile _config.yml

getTemplateFile testLocally.sh
chmod +x testLocally.sh

mkdir _includes
cd _includes
getTemplateFile _includes/FOOTER.HTML
prepTemplateFile FOOTER.HTML
cd ..

mkdir data
cd data
mkdir figures
cd figures
getTemplateFile data/figures/GitHub-Mark-120px-plus.png
cd ../..

rm index.md
getTemplateFile index.md

cd _pages
rm ./*.md
getTemplateFile 2022-09-05-template_post.md
cd ..

mkdir .github
cd .github
mkdir workflow
cd workflow
getTemplateFile .github/workflows/deploy.yml
cd ../..

git add .
git commit -m "Initializing webpage."
git push

echo "Your webpage is now live at https://"$githubUsername".github.io/"$repoName"/"
echo "You can make changes to your local files at index.md, _pages, or _post"
echo "and push to update the webpage."
echo "You can test your changes locally by running ./testLocally.sh "
echo "and going to the server address that is printed out."
echo "Once done, you canuse ctrl-c to stop local test."