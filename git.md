```
cd ${PGDATA}

tee .gitignore 0<<EOF
**/*
!*.conf
!conf.d
EOF

git init
git add .
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git commit -m Initial

```
