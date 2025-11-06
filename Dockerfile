# Usar Node.js como base
FROM node:18-alpine

# Definir diretório de trabalho
WORKDIR /app

# Copiar package.json e package-lock.json
COPY package*.json ./

# Instalar dependências
RUN npm install --production

# Copiar todo o código da aplicação
COPY . .

# Expor porta 5000 (porta interna do container)
EXPOSE 5000

# Comando para iniciar a aplicação
CMD ["npm", "start"]
