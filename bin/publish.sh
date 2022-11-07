git add -A data delays format-forecast format-rt
git commit -m"Update $(date)"
git pull -Xours
git push -v

git branch -D gh-pages
git checkout --orphan gh-pages
git rm -rf .
git add docs/index.html
git commit -m "Update report"
git push --force origin gh-pages
git checkout main
