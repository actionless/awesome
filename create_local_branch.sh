#!/bin/bash
set -euo pipefail

branches=(
	# local overrides
	'actionless'

	# my branches
	#'rounded-naughty'
    'dpi-in-default-theme'
    #'dpi-in-default-theme-2'
    'wibox-shape-take-4'
    'rounded-naughty-2'

	#'hotkeys_module_instance'

	# psychon
    #'wibox-shape'

	# elv13
    #'pr/644'

    # blueyed

	# other

    # PR
    #'pr/596'


    #'pr/1198'

    #"cmake-fix"
)

cd ~/projects
rm -r tmp-awesome/awesome -f || true
cp -prf awesome tmp-awesome/
cp awesome/PKGBUILD ~/build/awesome-git/
cp awesome/awesome_no_argb ~/build/awesome-git/

cd tmp-awesome/awesome
git reset --hard

git fetch upstream
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

cd ~/build/awesome-git
makepkg -fi --syncdeps

cd ~/projects/awesome
