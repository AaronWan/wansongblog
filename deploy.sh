#!/bin/bash
hexo generate
hexo deploy
git add .
git commit -am 'update'
git push