#!/bin/bash
set -euo pipefail

branches=(
	# local overrides
	'actionless'

	# my branches
	'hotkeys_module_instance'

	# psychon

	# elv13

	# other
)

cd ~/projects
rm -r tmp-awesome/awesome -f || true
cp -prf awesome tmp-awesome/
cp awesome/PKGBUILD ~/build/awesome-git/

cd tmp-awesome/awesome
git reset --hard

git checkout master
git pull upstream master

git branch -D local
git checkout -b local

for branch in ${branches[@]}; do
	echo "======================"
	echo " merge $branch "
	git merge $branch -m "merge $branch"
done

git push origin local -f

cd ~/build/awesome-git
makepkg -fi

cd ~/projects/awesome
