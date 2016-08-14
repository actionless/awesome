#!/bin/bash
set -euo pipefail

branches=(
	# local overrides
	'actionless'

	# my branches
	#'rounded-naughty'

	#'hotkeys_module_instance'

	# psychon

	# elv13
	'upstream_shape_api_p4'

	# other
)

cd ~/projects
rm -r tmp-awesome/awesome -f || true
cp -prf awesome tmp-awesome/
cp awesome/PKGBUILD ~/build/awesome-git/
cp awesome/awesome_no_argb ~/build/awesome-git/

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
