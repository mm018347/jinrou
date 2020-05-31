#! /bin/bash
forever stop jinrou
git pull
npm i
cd front/
npm i
npm run production-build
cd ..
SS_ENV=production SS_PACK=1 forever start -l ../logs/out.log -e ../logs/err.log -a --uid "jinrou" app.js
