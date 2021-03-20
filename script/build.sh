#!/bin/sh

echo 'beging build Details app...'

mvn package -Dmaven.test.skip=true

ls -la target/

tar -zcvf Reviews.tar.gz target/rob-reviews-1.0.jar

echo 'finish build Details app...'
