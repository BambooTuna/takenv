FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
  LANG=ja_JP.UTF-8 \
  TZ=Asia/Tokyo

# bootstrap.sh の前提となる最小パッケージのみ。残りはすべて bootstrap.sh が導入する
RUN apt-get update && apt-get install -y \
  git curl sudo ca-certificates locales \
  && locale-gen ja_JP.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

# User configuration
ARG USER_UID=1000
ARG USER_GID=1000

# Create development user with specified UID/GID
RUN if getent passwd ${USER_UID} > /dev/null; then \
  userdel -r $(getent passwd ${USER_UID} | cut -d: -f1) || true; \
  fi && \
  if getent group ${USER_GID} > /dev/null; then \
  groupdel $(getent group ${USER_GID} | cut -d: -f1) || true; \
  fi && \
  groupadd -g ${USER_GID} devuser && \
  useradd -m -s /bin/zsh -u ${USER_UID} -g ${USER_GID} -G sudo devuser && \
  echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser && \
  chmod 0440 /etc/sudoers.d/devuser && \
  groupadd -f docker && usermod -aG docker devuser

USER devuser

# Copy repository and bootstrap (GUI cask はコンテナに存在しないためスキップ)
COPY --chown=devuser:devuser . /home/devuser/takenv
WORKDIR /home/devuser/takenv
RUN TAKENV_SKIP_CASKS=1 ./bootstrap.sh

# Copy and setup entrypoint
COPY --chown=devuser:devuser devcontainer/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sudo chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/zsh"]
