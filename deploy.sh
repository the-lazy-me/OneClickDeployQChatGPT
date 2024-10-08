#!/bin/bash

# 定义颜色
RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 显示脚本来源
echo -e "${GREEN}您当前正在运行的是：QChatGPT+NapCat 一键部署脚本${NC}"
echo -e "${GREEN}脚本来源：B站UP主-TheLazy-${NC}"
echo -e "${GREEN}此脚本的来源及教程：https://github.com/the-lazy-me/OneClickDeployQChatGPT${NC}"

# 提示用户是否继续
while true; do
    echo -e "${YELLOW}此脚本适用于在 Linux 系统上首次部署 QChatGPT+NapCat，是否继续？${NC}"
    echo -e "${YELLOW}输入 y 代表继续，输入 n 代表取消${NC}"
    echo -n ">>> "
    read input
    case $input in
        [yY])
            echo -e "${GREEN}开始执行部署脚本...${NC}"
            break
        ;;
        [nN])
            echo -e "${RED}已取消${NC}"
            exit 0
        ;;
        *)
            echo -e "${RED}无效输入，请输入 y 或 n。${NC}"
        ;;
    esac
done

# 检查 jq 是否安装，如果未安装则自动安装
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}jq 未安装，即将安装 jq${NC}"
    
    # 检测操作系统并安装 jq
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update > /dev/null 2>&1
        sudo apt-get install -y jq > /dev/null 2>&1
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y epel-release > /dev/null 2>&1
        sudo yum install -y jq > /dev/null 2>&1
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install -y jq > /dev/null 2>&1
    elif [ -x "$(command -v brew)" ]; then
        brew install jq > /dev/null 2>&1
    else
        echo -e "\n${RED}无法检测到支持的包管理器，请手动安装 jq。${NC}"
        exit 1
    fi
    echo -e "${GREEN}jq 安装完成${NC}"
else
    echo -e "${GREEN}jq 已安装${NC}"
fi

# 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker 未安装，即将进行Docker安装...${NC}"
    
    # 获取地理位置
    location=$(curl -s https://ipinfo.io/json | jq -r '.country')
    
    if [ "$location" == "CN" ]; then
        echo -e "\n${YELLOW}检测到您在中国大陆，使用阿里云镜像安装 Docker${NC}"
        echo -e "${YELLOW}请耐心等待安装完成${NC}"
        sudo curl -fsSL https://gitee.com/tech-shrimp/docker_installer/releases/download/latest/linux.sh | bash -s docker --mirror Aliyun > /dev/null 2>&1
    else
        echo -e "\n${YELLOW}使用默认方式安装 Docker${NC}"
        echo -e "${YELLOW}请耐心等待安装完成${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh > /dev/null 2>&1
        sh get-docker.sh > /dev/null 2>&1
        rm get-docker.sh > /dev/null 2>&1
    fi
    
    sudo systemctl start docker > /dev/null 2>&1
    sudo systemctl enable docker > /dev/null 2>&1
    
    echo -e "${GREEN}Docker 安装完成${NC}"
else
    echo -e "${GREEN}Docker 已安装${NC}"
fi

# 提示用户输入机器人QQ
while true; do
    echo -e "${YELLOW}请输入机器人QQ号码：${NC}"
    echo -n ">>> "
    read bot_qq
    if [ -n "$bot_qq" ]; then
        break
    else
        echo -e "${RED}机器人QQ号码不能为空，请重新输入。${NC}"
    fi
done

# 提示用户输入API key并进行校验
while true; do
    echo -e "${YELLOW}请输入你在 https://ai.thelazy.top 获取的令牌：${NC}"
    echo -n ">>> "
    read api_key
    if [ -n "$api_key" ]; then
        # 解析 base-url
        if [[ "$api_key" == *@* ]]; then
            base_url=${api_key#*@}
            api_key=${api_key%%@*}
        else
            base_url="https://ai.thelazy.top/v1"
        fi

        echo -e "${YELLOW}正在校验令牌...请稍等${NC}"
        response=$(curl -s --location -g --request POST "$base_url/chat/completions" \
            --header 'Accept: application/json' \
            --header "Authorization: Bearer $api_key" \
            --header 'Content-Type: application/json' \
            --data-raw '{
                "model": "gpt-4o",
                "messages": [
                  {
                    "role": "user",
                    "content": "Hi!"
                  }
                ]
        }')
        if echo "$response" | grep -q '"choices"'; then
            echo -e "${GREEN}令牌校验成功${NC}"
            break
        else
            echo -e "${RED}令牌无效，请重新输入${NC}"
        fi
    else
        echo -e "${RED}令牌不能为空，请重新输入${NC}"
    fi
done

# 提示用户输入管理员QQ号
while true; do
    echo -e "${YELLOW}请输入管理员QQ号（一般来说就是你的大号）：${NC}"
    echo -n ">>> "
    read admin_qq
    if [ -n "$admin_qq" ]; then
        break
    else
        echo -e "${RED}管理员QQ号不能为空，请重新输入。${NC}"
    fi
done

# 检测并处理同名容器
for container in QChatGPT NapCat; do
    if [ "$(docker ps -a -q -f name=$container)" ]; then
        echo -e "${YELLOW}检测到已有名为 $container 的容器，是否删除已有的容器？（y/n，默认为 y）${NC}"
        echo -n ">>>  "
        read input
        case $input in
            [nN])
                echo -e "${RED}已取消${NC}"
                exit 0
            ;;
            *)
                docker rm -f $container
                echo -e "${GREEN}已删除容器 $container${NC}"
            ;;
        esac
    fi
done

# 检测挂载目录是否存在，如果存在则删除
if [ -d "/home/QChatGPT/data" ] || [ -d "/home/QChatGPT/plugins" ]; then
    rm -rf /home/QChatGPT/data
    rm -rf /home/QChatGPT/plugins
fi

# 创建必要的目录
mkdir -p /home/QChatGPT/data /home/QChatGPT/plugins

# 创建 Docker 网络
docker network create qchatgpt-net

echo -e "${YELLOW}开始运行 QChatGPT容器...${NC}"
# 运行 QChatGPT 容器
docker run -d \
  --name QChatGPT \
  -p 5140:5140 \
  -v /home/QChatGPT/data:/app/data \
  -v /home/QChatGPT/plugins:/app/plugins \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  --network qchatgpt-net \
  rockchin/qchatgpt:latest

# 等待 QChatGPT 容器启动
container_name="QChatGPT"
max_attempts=30
attempt=1

echo -e "${YELLOW}等待 QChatGPT 容器启动中...${NC}"
while [ $attempt -le $max_attempts ]; do
    if docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null | grep -q "true"; then
        echo -e "${GREEN}容器 '$container_name' 已启动并运行${NC}"
        echo -e "${YELLOW}等待配置文件生成...${NC}"
        break
    fi
    sleep 1
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo -e "${RED}容器 '$container_name' 未能在预期时间内启动${NC}"
    exit 1
fi

# 等待配置文件生成
while [ ! -f "/home/QChatGPT/data/config/provider.json" ] || [ ! -f "/home/QChatGPT/data/config/system.json" ] || [ ! -f "/home/QChatGPT/data/config/platform.json" ]; do
    sleep 1
done
echo -e "${GREEN}配置文件已生成${NC}"

# 修改 platform.json["platform-adapters"][2]["enable"] 为 true
jq '.["platform-adapters"][2]["enable"] = true' /home/QChatGPT/data/config/platform.json > /home/QChatGPT/data/config/platform.tmp.json && mv /home/QChatGPT/data/config/platform.tmp.json /home/QChatGPT/data/config/platform.json

# 修改 platform.json["platform-adapters"][2]["port"] 为 5140
jq '.["platform-adapters"][2]["port"] = 5140' /home/QChatGPT/data/config/platform.json > /home/QChatGPT/data/config/platform.tmp.json && mv /home/QChatGPT/data/config/platform.tmp.json /home/QChatGPT/data/config/platform.json

# 修改 provider.json["keys"]["openai"][0] 为 api_key
jq '.["keys"]["openai"][0] = "'$api_key'"' /home/QChatGPT/data/config/provider.json > /home/QChatGPT/data/config/provider.tmp.json && mv /home/QChatGPT/data/config/provider.tmp.json /home/QChatGPT/data/config/provider.json

# 修改 provider.json["requester"]["openai-chat-completions"]["base-url"] 为 base_url
jq '.["requester"]["openai-chat-completions"]["base-url"] = "'$base_url'"' /home/QChatGPT/data/config/provider.json > /home/QChatGPT/data/config/provider.tmp.json && mv /home/QChatGPT/data/config/provider.tmp.json /home/QChatGPT/data/config/provider.json

# 修改 provider.json["model"] 为 gpt-4o
jq '.["model"] = "gpt-4o"' /home/QChatGPT/data/config/provider.json > /home/QChatGPT/data/config/provider.tmp.json && mv /home/QChatGPT/data/config/provider.tmp.json /home/QChatGPT/data/config/provider.json

# 修改 system.json["admin-sessions"][0] 为 admin_qq
jq '.["admin-sessions"][0] = "'$admin_qq'"' /home/QChatGPT/data/config/system.json > /home/QChatGPT/data/config/system.tmp.json && mv /home/QChatGPT/data/config/system.tmp.json /home/QChatGPT/data/config/system.json

# 确认配置文件已正确更新
echo -e "${YELLOW}确认配置文件已正确更新...${NC}"
sleep 5

# 重启 QChatGPT 容器
docker restart QChatGPT

echo -e "${GREEN}配置文件更新完成${NC}"

# 再次等待 QChatGPT 容器启动
attempt=1
echo -e "${YELLOW}等待 QChatGPT 容器重启中...${NC}"
while [ $attempt -le $max_attempts ]; do
    if docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null | grep -q "true"; then
        echo -e "${GREEN}容器 '$container_name' 已重启并运行${NC}"
        break
    fi
    sleep 1
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo -e "${RED}容器 '$container_name' 未能在预期时间内重启${NC}"
    exit 1
fi

echo -e "${YELLOW}开始运行 NapCat 容器...${NC}"
# 运行 NapCat 容器
docker run -d \
  --name NapCat \
  -p 6099:6099 \
  -e ACCOUNT=$bot_qq \
  -e WSR_ENABLE=true \
  -e WS_URLS=["ws://qchatgpt:5140/ws"] \
  --restart always \
  --network qchatgpt-net \
  mlikiowa/napcat-docker:latest

# 等待 NapCat 容器启动
container_name="NapCat"
max_attempts=30
attempt=1

echo -e "${YELLOW}等待 NapCat 容器启动中...${NC}"
while [ $attempt -le $max_attempts ]; do
    if docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null | grep -q "true"; then
        echo -e "${GREEN}容器 '$container_name' 已启动并运行${NC}"
        docker logs NapCat
        break
    fi
    sleep 1
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    echo -e "${RED}容器 '$container_name' 未能在预期时间内启动${NC}"
    exit 1
fi

# 在NapCat logs中查找NapCat Shell App Loading是否出现
echo -e "${YELLOW}等待登录二维码的生成中...${NC}"
while true; do
    if docker logs NapCat 2>&1 | grep -q "NapCat Shell App Loading..."; then
        break
    fi
    sleep 1
done

# 查找docker logs NapCat中的NapCat Shell App Loading...是倒数第几行
line=$(docker logs NapCat 2>&1 | grep -n "NapCat Shell App Loading..." | tail -n 1 | cut -d ":" -f 1)

# 输出NapCat的日志，从NapCat Shell App Loading...开始
echo -e "${YELLOW}NapCat 容器日志（只需关注二维码即可）：${NC}"
docker logs NapCat 2>&1 | tail -n +$line

# 将NapCat容器内/usr/src/app/napcat/qrcode.png 复制到本地
docker cp NapCat:/usr/src/app/napcat/qrcode.png /usr/src/app/napcat/qrcode.png

echo -e "${GREEN}QChatGPT+NapCat部署脚本执行完毕${NC}"

echo -e "${GREEN}祝您使用愉快！${NC}"
