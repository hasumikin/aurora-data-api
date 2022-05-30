# syntax = docker/dockerfile:experimental

FROM lambci/lambda:build-ruby2.7

RUN curl -sL https://rpm.nodesource.com/setup_12.x | bash - \
  && yum -y install nodejs postgresql wget && yum -y clean all

RUN mkdir /home/ec2-user && chown ec2-user /home/ec2-user
RUN mkdir /home/ec2-user/bin && chown ec2-user /home/ec2-user/bin
RUN mkdir /app && chown ec2-user /app

WORKDIR /app
COPY --chown=ec2-user Gemfile Gemfile.lock package.json package-lock.json /app/
RUN gem install bundler
RUN bundle install

COPY --chown=ec2-user . /app

USER ec2-user
RUN npm install
RUN wget -O - https://github.com/k0kubun/sqldef/releases/latest/download/psqldef_linux_amd64.tar.gz \
  | tar xvz -C /home/ec2-user/bin

EXPOSE 4000
CMD ["/bin/bash"]

