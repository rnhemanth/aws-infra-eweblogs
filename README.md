# aws-infra-deploy-eweblogs

This repository is used to deploy eweblogs to AWS

## General Information
This repository uses [github-runner](https://github.com/emisgroup/github-runner) [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

To clone this repository with submodule
```
git clone --recursive https://github.com/emisgroup/aws-infra-deploy-eweblogs.git
```

To also initialize, fetch and checkout any nested submodules
```
git submodule update --init --recursive
```

Pull latest changes for all git submodules
```
git submodule update --recursive --remote
