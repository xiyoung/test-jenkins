FROM node:7.3.0

RUN mkdir -p /home/project

COPY . /home/project

WORKDIR /home/project

EXPOSE 3000

CMD ["npm","start"]