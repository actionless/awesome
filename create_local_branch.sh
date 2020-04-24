#!/bin/bash
set -euo pipefail

AWESOME_BUILD_DIR=/tmp/awesome-build/

branches=(
	# local overrides
	#'actionless'
        fix-empty-string-matcher
        placement-skip-fullscreen
        fix-markup-escape

)

cd ~/projects
rm -r tmp-awesome/awesome -f || true
cp -prf awesome tmp-awesome/
mkdir -p "$AWESOME_BUILD_DIR"
cp awesome/{PKGBUILD,awesome*.desktop} "$AWESOME_BUILD_DIR"

cd tmp-awesome/awesome
git reset --hard

git fetch --all --tags
git checkout master
git pull upstream master

git branch -D local
git checkout -b local


for branch in "${branches[@]}" ; do
	echo "======================"
	echo " merge $branch "
	git checkout "$branch"
	git checkout local
	git merge upstream/"$branch" -m "merge $branch" || git merge "$branch" -m "merge $branch"
done

git push origin local -f
git push origin --tags

if [[ ${1-a} = '-b' ]]; then
	cd "$AWESOME_BUILD_DIR"
	makepkg -fi --syncdeps
fi

cd ~/projects/awesome
