# QChatGPT+NapCat一键部署脚本教程

> 此脚本由[B站作者-TheLazy](https://space.bilibili.com/407410594?spm_id_from=333.1007.0.0)制作，能力有限，功能不足和可能的使用错误还请谅解

## 所用项目

- [QChatGPT](https://github.com/RockChinQ/QChatGPT)
- [NapCat](https://napneko.github.io/zh-CN/)

## 使用教程：

在Linux系统上，复制下面的命令，直接执行即可

```bash
sudo curl -fsSL -o deploy.sh https://pan.lazyshare.top/one-click-deploy-qchatgpt/deploy.sh && sudo chmod +x deploy.sh && sudo bash deploy.sh
```

## Q&A

1. 提示：令牌无效，请重新输入
   - 直接输入令牌，默认按来源于[此处](https://ai.thelazy.top)，如需使用官方或者其他，请在令牌后添加`@<官方或其他baseurl>`（若为官方，baseurl为`https://api.openai.com/v1`，如`令牌@https://api.openai.com/v1`，其他请按实际填写）
2. 此脚本适合各个Linux的分发版吗
   - `I don't know`，仅在`Ubuntu 22.04`测试过，如有使用问题，请提issue或加群（群号：619154800）询问
3. 配置文件在哪里？
   - 位于本机`/home/QChatGPT`目录下
