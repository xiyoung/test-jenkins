FROM node:7.3.0

COPY . /home/project

WORKDIR /home/project

EXPOSE 3000

CMD ["npm","start"]