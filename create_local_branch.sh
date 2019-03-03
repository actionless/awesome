#!/bin/bash
set -euo pipefail

branches=(
	# local overrides
	'actionless'

	# my branches

	# psychon

	# elv13
    'notif_replace_id2'

    # blueyed

	# other

    # PR
    #'pr/596'

)

cd ~/projects
rm -r tmp-awesome/awesome -f || true
cp -prf awesome tmp-awesome/
cp awesome/PKGBUILD ~/build/awesome-git/

cd tmp-awesome/awesome
git reset --hard

git fetch --all --tags
git checkout master
git pull upstream master

git branch -D local
git checkout -b local


for branch in ${branches[@]}; do
	echo "======================"
	echo " merge $branch "
    git checkout $branch
    git checkout local
	git merge upstream/$branch -m "merge $branch" || git merge $branch -m "merge $branch"
done

git push origin local -f
git push origin --tags

if [[ ${1-a} = '-b' ]]; then
    cd ~/build/awesome-git
    makepkg -fi --syncdeps
fi

cd ~/projects/awesome
