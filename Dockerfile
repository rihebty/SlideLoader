FROM camicroscope/image-decoders:latest

# WORKDIR /var/www
# # RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list
# # RUN sed -i 's|http://archive.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list
# RUN sed -i 's|lunar|jammy|g' /etc/apt/sources.list
# RUN sed -i 's|http://security.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list


# # RUN apt-get update
# # RUN apt-get -q update --fix-missing
# RUN apt-get update && apt-get upgrade -y
# RUN apt-get -q install -y python3-pip openssl
# RUN apt-get -q install -y openslide-tools python3-openslide
# RUN apt-get -q install -y openssl libcurl4-openssl-dev libssl-dev
# RUN apt-get -q install -y libvips libvips-dev vim
# 替换 Ubuntu 镜像源为阿里云源（提高安装速度），并将 Ubuntu 版本改为 23.04（或 23.10）
# RUN sed -i 's|http://archive.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
#     sed -i 's|http://security.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
#     sed -i 's|lunar|noble|g' /etc/apt/sources.list && \
#     sed -i 's|jammy|noble|g' /etc/apt/sources.list
RUN echo "Before modification:" && cat /etc/apt/sources.list && \
    sed -i 's|http://archive.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|lunar|noble|g' /etc/apt/sources.list && \
    sed -i 's|jammy|noble|g' /etc/apt/sources.list && \
    echo "After modification:" && cat /etc/apt/sources.list
# 更新软件包列表并升级已安装软件包
RUN apt-get update && apt-get upgrade -y

# 安装基础依赖：python3-pip 和 openssl
RUN apt-get install -y python3-pip openssl

# 安装 OpenSlide 相关工具
RUN apt-get install -y openslide-tools python3-openslide

# 安装 OpenSSL 开发工具包（libcurl4 和 libssl）
RUN apt-get install -y libcurl4-openssl-dev libssl-dev

# 安装图像处理库 libvips 和 vim 编辑器
RUN apt-get install -y libvips libvips-dev vim
### Install BioFormats wrapper

WORKDIR /root/src/BFBridge/python
RUN pip install -r requirements.txt --break-system-packages
RUN python3 compile_bfbridge.py

### Set up the server

WORKDIR /root/src/

RUN pip install pyvips --break-system-packages
RUN pip install flask --break-system-packages
RUN pip install gunicorn --break-system-packages
RUN pip install greenlet --break-system-packages
RUN pip install gunicorn[eventlet] --break-system-package

run openssl version -a

ENV FLASK_DEBUG True
ENV BFBRIDGE_LOGLEVEL=WARN

RUN mkdir -p /images/uploading

COPY openslide_copy.sh .
RUN bash openslide_copy.sh

COPY requirements.txt .
RUN pip3 install -r requirements.txt --break-system-packages

COPY ./ ./
RUN cp test_imgs/* /images/

EXPOSE 4000
EXPOSE 4001

#debug/dev only
# ENV FLASK_APP SlideServer.py
# CMD python3 -m flask run --host=0.0.0.0 --port=4000

# The Below BROKE the ability for users to upload images.
# # non-root user
# RUN chgrp -R 0 /var && \
#     chmod -R g+rwX /var && \
#     chgrp -R 0 /images/uploading && \
#     chmod -R g+rwX /images/uploading
#
# USER 1001

#prod only
CMD gunicorn -w 4 -b 0.0.0.0:4000 SlideServer:app --timeout 400
